import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_http/flutter_http.dart';
import 'package:intl/intl.dart';
import 'package:scheduler_frontend/features/appointments/bloc/schedule_event.dart';
import 'package:scheduler_frontend/features/appointments/bloc/schedule_state.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_repository.dart';

class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  final AppointmentRepository _repository;
  String _slug = '';

  ScheduleBloc(this._repository) : super(const ScheduleInitial()) {
    on<ScheduleInitialized>(_onInitialized);
    on<SchedulePreviousPeriod>(_onPreviousPeriod);
    on<ScheduleNextPeriod>(_onNextPeriod);
    on<ScheduleDateSelected>(_onDateSelected);
    on<ScheduleViewModeChanged>(_onViewModeChanged);
    on<ScheduleAppointmentCreateRequested>(_onCreateRequested);
    on<ScheduleBlockCreateRequested>(_onBlockCreateRequested);
    on<ScheduleAppointmentCancelRequested>(_onCancelRequested);
    on<ScheduleRecurrenceCancelRequested>(_onRecurrenceCancelRequested);
  }

  Future<void> _onInitialized(
    ScheduleInitialized event,
    Emitter<ScheduleState> emit,
  ) async {
    _slug = event.slug;
    final mode = _currentViewMode ?? ScheduleViewMode.day;
    await _load(emit, event.date, mode);
  }

  Future<void> _onPreviousPeriod(
    SchedulePreviousPeriod event,
    Emitter<ScheduleState> emit,
  ) async {
    final date = _currentDate;
    final mode = _currentViewMode;
    if (date == null || mode == null) return;

    final offset = mode == ScheduleViewMode.day ? -1 : -7;
    await _load(emit, date.add(Duration(days: offset)), mode);
  }

  Future<void> _onNextPeriod(
    ScheduleNextPeriod event,
    Emitter<ScheduleState> emit,
  ) async {
    final date = _currentDate;
    final mode = _currentViewMode;
    if (date == null || mode == null) return;

    final offset = mode == ScheduleViewMode.day ? 1 : 7;
    await _load(emit, date.add(Duration(days: offset)), mode);
  }

  Future<void> _onDateSelected(
    ScheduleDateSelected event,
    Emitter<ScheduleState> emit,
  ) async {
    final mode = _currentViewMode ?? ScheduleViewMode.day;
    await _load(emit, event.date, mode);
  }

  Future<void> _onViewModeChanged(
    ScheduleViewModeChanged event,
    Emitter<ScheduleState> emit,
  ) async {
    final currentMode = _currentViewMode;
    if (currentMode == event.mode) return;

    final date = _currentDate ?? DateTime.now();
    await _load(emit, date, event.mode);
  }

  Future<void> _load(
    Emitter<ScheduleState> emit,
    DateTime date,
    ScheduleViewMode mode,
  ) async {
    emit(ScheduleLoading(selectedDate: date, viewMode: mode));

    if (mode == ScheduleViewMode.day) {
      await _loadDay(emit, date, mode);
    } else {
      await _loadWeek(emit, date, mode);
    }
  }

  Future<void> _loadDay(
    Emitter<ScheduleState> emit,
    DateTime date,
    ScheduleViewMode mode,
  ) async {
    final result = await _repository.getAppointments(
      slug: _slug,
      date: date,
    );
    switch (result) {
      case Success(:final data):
        final sorted = List<AppointmentModel>.from(data)
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
        final key = DateFormat('yyyy-MM-dd').format(date);
        emit(ScheduleLoaded(
          appointmentsByDate: {key: sorted},
          selectedDate: date,
          viewMode: mode,
        ));
      case HttpFailure(:final failure):
        emit(ScheduleError(
          message: _message(failure),
          selectedDate: date,
          viewMode: mode,
        ));
    }
  }

  Future<void> _loadWeek(
    Emitter<ScheduleState> emit,
    DateTime date,
    ScheduleViewMode mode,
  ) async {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    final days = List.generate(7, (i) => monday.add(Duration(days: i)));

    final results = await Future.wait(
      days.map((d) => _repository.getAppointments(slug: _slug, date: d)),
    );

    final Map<String, List<AppointmentModel>> byDate = {};
    var hasPartialError = false;

    for (var i = 0; i < 7; i++) {
      final key = DateFormat('yyyy-MM-dd').format(days[i]);
      switch (results[i]) {
        case Success(:final data):
          final sorted = List<AppointmentModel>.from(data)
            ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
          byDate[key] = sorted;
        case HttpFailure():
          hasPartialError = true;
          byDate[key] = [];
      }
    }

    emit(ScheduleLoaded(
      appointmentsByDate: byDate,
      selectedDate: date,
      viewMode: mode,
      hasPartialError: hasPartialError,
    ));
  }

  Future<void> _onCreateRequested(
    ScheduleAppointmentCreateRequested event,
    Emitter<ScheduleState> emit,
  ) async {
    final date = _currentDate ?? DateTime.now();
    final mode = _currentViewMode ?? ScheduleViewMode.day;

    final result = await _repository.createAppointment(
      slug: _slug,
      clientName: event.clientName,
      clientEmail: event.clientEmail,
      startsAt: event.startsAt,
      durationMinutes: event.durationMinutes,
      notes: event.notes,
      recurrenceRule: event.recurrenceRule,
      serviceId: event.serviceId,
    );

    switch (result) {
      case Success():
        emit(ScheduleActionSuccess(
          message: 'Agendamento criado com sucesso',
          selectedDate: date,
          viewMode: mode,
        ));
      case HttpFailure(:final failure):
        emit(ScheduleActionFailure(
          message: _mutationMessage(failure),
          selectedDate: date,
          viewMode: mode,
        ));
    }
  }

  Future<void> _onBlockCreateRequested(
    ScheduleBlockCreateRequested event,
    Emitter<ScheduleState> emit,
  ) async {
    final date = _currentDate ?? DateTime.now();
    final mode = _currentViewMode ?? ScheduleViewMode.day;

    final result = await _repository.createBlock(
      slug: _slug,
      startsAt: event.startsAt,
      durationMinutes: event.durationMinutes,
      title: event.title,
      notes: event.notes,
      staffId: event.staffId,
      recurrenceRule: event.recurrenceRule,
    );

    switch (result) {
      case Success():
        emit(ScheduleActionSuccess(
          message: 'Horário bloqueado com sucesso',
          selectedDate: date,
          viewMode: mode,
        ));
      case HttpFailure(:final failure):
        emit(ScheduleActionFailure(
          message: _mutationMessage(failure),
          selectedDate: date,
          viewMode: mode,
        ));
    }
  }

  Future<void> _onCancelRequested(
    ScheduleAppointmentCancelRequested event,
    Emitter<ScheduleState> emit,
  ) async {
    final date = _currentDate ?? DateTime.now();
    final mode = _currentViewMode ?? ScheduleViewMode.day;

    final result = await _repository.cancelAppointment(
      slug: _slug,
      appointmentId: event.appointmentId,
    );

    switch (result) {
      case Success():
        emit(ScheduleActionSuccess(
          message: 'Agendamento cancelado',
          selectedDate: date,
          viewMode: mode,
        ));
      case HttpFailure(:final failure):
        emit(ScheduleActionFailure(
          message: _mutationMessage(failure),
          selectedDate: date,
          viewMode: mode,
        ));
    }
  }

  Future<void> _onRecurrenceCancelRequested(
    ScheduleRecurrenceCancelRequested event,
    Emitter<ScheduleState> emit,
  ) async {
    final date = _currentDate ?? DateTime.now();
    final mode = _currentViewMode ?? ScheduleViewMode.day;

    final result = event.cancelFuture
        ? await _repository.cancelFutureOccurrences(
            slug: _slug,
            appointmentId: event.appointmentId,
          )
        : await _repository.cancelAppointment(
            slug: _slug,
            appointmentId: event.appointmentId,
          );

    switch (result) {
      case Success():
        emit(ScheduleActionSuccess(
          message: event.cancelFuture
              ? 'Ocorrências futuras canceladas'
              : 'Agendamento cancelado',
          selectedDate: date,
          viewMode: mode,
        ));
      case HttpFailure(:final failure):
        emit(ScheduleActionFailure(
          message: _mutationMessage(failure),
          selectedDate: date,
          viewMode: mode,
        ));
    }
  }

  DateTime? get _currentDate => switch (state) {
        ScheduleLoading(:final selectedDate) => selectedDate,
        ScheduleLoaded(:final selectedDate) => selectedDate,
        ScheduleError(:final selectedDate) => selectedDate,
        ScheduleActionSuccess(:final selectedDate) => selectedDate,
        ScheduleActionFailure(:final selectedDate) => selectedDate,
        _ => null,
      };

  ScheduleViewMode? get _currentViewMode => switch (state) {
        ScheduleLoading(:final viewMode) => viewMode,
        ScheduleLoaded(:final viewMode) => viewMode,
        ScheduleError(:final viewMode) => viewMode,
        ScheduleActionSuccess(:final viewMode) => viewMode,
        ScheduleActionFailure(:final viewMode) => viewMode,
        _ => null,
      };

  String _message(AppFailure failure) => switch (failure) {
        NetworkFailure() => 'Sem conexão com a internet',
        _ => 'Não foi possível carregar a agenda',
      };

  String _mutationMessage(AppFailure failure) => switch (failure) {
        NetworkFailure() => 'Sem conexão com a internet',
        _ => 'Não foi possível completar a ação. Tente novamente.',
      };
}
