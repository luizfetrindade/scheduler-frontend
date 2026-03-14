import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_http/flutter_http.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professionals_event.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professionals_state.dart';
import 'package:scheduler_frontend/features/professionals/data/professional_model.dart';
import 'package:scheduler_frontend/features/professionals/data/professional_repository.dart';

class ProfessionalsBloc extends Bloc<ProfessionalsEvent, ProfessionalsState> {
  final ProfessionalRepository _repository;

  ProfessionalsBloc(this._repository) : super(const ProfessionalsInitial()) {
    on<ProfessionalsLoadRequested>(_onLoad);
    on<ProfessionalsCreateRequested>(_onCreate);
    on<ProfessionalsUpdateRequested>(_onUpdate);
    on<ProfessionalsDeleteRequested>(_onDelete);
  }

  List<ProfessionalModel> get _currentList => switch (state) {
        ProfessionalsLoaded(:final professionals) => professionals,
        ProfessionalsActionInProgress(:final professionals) => professionals,
        ProfessionalsError(:final professionals) => professionals,
        _ => const [],
      };

  Future<void> _onLoad(
    ProfessionalsLoadRequested event,
    Emitter<ProfessionalsState> emit,
  ) async {
    emit(const ProfessionalsLoading());
    final result =
        await _repository.getProfessionals(businessId: event.businessId);
    switch (result) {
      case Success(:final data):
        emit(ProfessionalsLoaded(data));
      case HttpFailure(:final failure):
        emit(ProfessionalsError(_message(failure)));
    }
  }

  Future<void> _onCreate(
    ProfessionalsCreateRequested event,
    Emitter<ProfessionalsState> emit,
  ) async {
    final current = _currentList;
    emit(ProfessionalsActionInProgress(current));
    final result = await _repository.createProfessional(
      businessId: event.businessId,
      name: event.name,
      color: event.color,
      roleId: event.roleId,
      phone: event.phone,
      bio: event.bio,
    );
    switch (result) {
      case Success(:final data):
        emit(ProfessionalsLoaded([...current, data]));
      case HttpFailure(:final failure):
        emit(ProfessionalsError(_mutationMessage(failure), professionals: current));
    }
  }

  Future<void> _onUpdate(
    ProfessionalsUpdateRequested event,
    Emitter<ProfessionalsState> emit,
  ) async {
    final current = _currentList;
    emit(ProfessionalsActionInProgress(current));
    final result = await _repository.updateProfessional(
      businessId: event.businessId,
      professionalId: event.professionalId,
      name: event.name,
      roleId: event.roleId,
      phone: event.phone,
      bio: event.bio,
      color: event.color,
      isActive: event.isActive,
    );
    switch (result) {
      case Success(:final data):
        final updated = current.map((p) => p.id == data.id ? data : p).toList();
        emit(ProfessionalsLoaded(updated));
      case HttpFailure(:final failure):
        emit(ProfessionalsError(_mutationMessage(failure), professionals: current));
    }
  }

  Future<void> _onDelete(
    ProfessionalsDeleteRequested event,
    Emitter<ProfessionalsState> emit,
  ) async {
    final current = _currentList;
    emit(ProfessionalsActionInProgress(current));
    final result = await _repository.deleteProfessional(
      businessId: event.businessId,
      professionalId: event.professionalId,
    );
    switch (result) {
      case Success():
        emit(ProfessionalsLoaded(
          current.where((p) => p.id != event.professionalId).toList(),
        ));
      case HttpFailure(:final failure):
        emit(ProfessionalsError(_mutationMessage(failure), professionals: current));
    }
  }

  String _message(AppFailure failure) => switch (failure) {
        NetworkFailure() => 'Sem conexão com a internet',
        _ => 'Não foi possível carregar os profissionais',
      };

  String _mutationMessage(AppFailure failure) => switch (failure) {
        NetworkFailure() => 'Sem conexão com a internet',
        _ => 'Não foi possível completar a ação. Tente novamente.',
      };
}
