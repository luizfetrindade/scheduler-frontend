import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_http/flutter_http.dart';
import 'package:scheduler_frontend/features/appointments/bloc/appointments_event.dart';
import 'package:scheduler_frontend/features/appointments/bloc/appointments_state.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_repository.dart';

class AppointmentsBloc extends Bloc<AppointmentsEvent, AppointmentsState> {
  final AppointmentRepository _repository;

  AppointmentsBloc(this._repository) : super(const AppointmentsInitial()) {
    on<AppointmentsLoadRequested>(_onLoadRequested);
    on<AppointmentStatusChanged>(_onStatusChanged);
  }

  Future<void> _onLoadRequested(
    AppointmentsLoadRequested event,
    Emitter<AppointmentsState> emit,
  ) async {
    emit(const AppointmentsLoading());
    final result = await _repository.getAppointments(
      slug: event.slug,
      date: event.date,
    );
    switch (result) {
      case Success(:final data):
        // Sort by start time (backend also sorts, but ensure order client-side)
        final sorted = List<AppointmentModel>.from(data)
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
        emit(AppointmentsLoaded(sorted));
      case HttpFailure(:final failure):
        emit(AppointmentsError(_message(failure)));
    }
  }

  Future<void> _onStatusChanged(
    AppointmentStatusChanged event,
    Emitter<AppointmentsState> emit,
  ) async {
    if (state is! AppointmentsLoaded) return;
    final current = state as AppointmentsLoaded;

    // Optimistic update — immediately reflect the change in the UI
    final optimistic = current.appointments
        .map((a) => a.id == event.appointmentId
            ? a.copyWith(status: event.status)
            : a)
        .toList();
    emit(AppointmentsLoaded(optimistic));

    final result = await _repository.updateStatus(
      slug: event.slug,
      appointmentId: event.appointmentId,
      status: event.status,
    );

    // Rollback on failure
    if (result.isFailure) {
      emit(AppointmentsLoaded(current.appointments));
    }
  }

  String _message(AppFailure failure) => switch (failure) {
        NetworkFailure() => 'Sem conexão com a internet',
        _ => 'Não foi possível carregar os agendamentos',
      };
}
