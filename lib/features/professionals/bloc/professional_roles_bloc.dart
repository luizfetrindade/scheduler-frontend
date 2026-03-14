import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_http/flutter_http.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_event.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_state.dart';
import 'package:scheduler_frontend/features/professionals/data/professional_role_model.dart';
import 'package:scheduler_frontend/features/professionals/data/professional_roles_repository.dart';

class ProfessionalRolesBloc
    extends Bloc<ProfessionalRolesEvent, ProfessionalRolesState> {
  final ProfessionalRolesRepository _repository;

  ProfessionalRolesBloc(this._repository)
      : super(const ProfessionalRolesInitial()) {
    on<ProfessionalRolesLoadRequested>(_onLoad);
    on<ProfessionalRolesCreateRequested>(_onCreate);
    on<ProfessionalRolesUpdateRequested>(_onUpdate);
    on<ProfessionalRolesDeleteRequested>(_onDelete);
  }

  List<ProfessionalRoleModel> get _currentList => switch (state) {
        ProfessionalRolesLoaded(:final roles) => roles,
        ProfessionalRolesActionInProgress(:final roles) => roles,
        ProfessionalRolesError(:final roles) => roles,
        _ => const [],
      };

  Future<void> _onLoad(
    ProfessionalRolesLoadRequested event,
    Emitter<ProfessionalRolesState> emit,
  ) async {
    emit(const ProfessionalRolesLoading());
    final result = await _repository.getRoles(businessId: event.businessId);
    switch (result) {
      case Success(:final data):
        emit(ProfessionalRolesLoaded(data));
      case HttpFailure(:final failure):
        emit(ProfessionalRolesError(_message(failure)));
    }
  }

  Future<void> _onCreate(
    ProfessionalRolesCreateRequested event,
    Emitter<ProfessionalRolesState> emit,
  ) async {
    final current = _currentList;
    emit(ProfessionalRolesActionInProgress(current));
    final result = await _repository.createRole(
      businessId: event.businessId,
      name: event.name,
    );
    switch (result) {
      case Success(:final data):
        emit(ProfessionalRolesLoaded([...current, data]));
      case HttpFailure(:final failure):
        emit(ProfessionalRolesError(_mutationMessage(failure), roles: current));
    }
  }

  Future<void> _onUpdate(
    ProfessionalRolesUpdateRequested event,
    Emitter<ProfessionalRolesState> emit,
  ) async {
    final current = _currentList;
    emit(ProfessionalRolesActionInProgress(current));
    final result = await _repository.updateRole(
      businessId: event.businessId,
      roleId: event.roleId,
      name: event.name,
    );
    switch (result) {
      case Success(:final data):
        final updated =
            current.map((r) => r.id == data.id ? data : r).toList();
        emit(ProfessionalRolesLoaded(updated));
      case HttpFailure(:final failure):
        emit(ProfessionalRolesError(_mutationMessage(failure), roles: current));
    }
  }

  Future<void> _onDelete(
    ProfessionalRolesDeleteRequested event,
    Emitter<ProfessionalRolesState> emit,
  ) async {
    final current = _currentList;
    emit(ProfessionalRolesActionInProgress(current));
    final result = await _repository.deleteRole(
      businessId: event.businessId,
      roleId: event.roleId,
    );
    switch (result) {
      case Success():
        emit(ProfessionalRolesLoaded(
          current.where((r) => r.id != event.roleId).toList(),
        ));
      case HttpFailure(:final failure):
        emit(ProfessionalRolesError(_mutationMessage(failure), roles: current));
    }
  }

  String _message(AppFailure failure) => switch (failure) {
        NetworkFailure() => 'Sem conexão com a internet',
        _ => 'Não foi possível carregar os cargos',
      };

  String _mutationMessage(AppFailure failure) => switch (failure) {
        NetworkFailure() => 'Sem conexão com a internet',
        _ => 'Não foi possível completar a ação. Tente novamente.',
      };
}
