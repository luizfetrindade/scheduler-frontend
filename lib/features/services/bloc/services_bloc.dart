import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_http/flutter_http.dart';
import 'package:scheduler_frontend/features/services/bloc/services_event.dart';
import 'package:scheduler_frontend/features/services/bloc/services_state.dart';
import 'package:scheduler_frontend/features/services/data/service_model.dart';
import 'package:scheduler_frontend/features/services/data/service_repository.dart';

class ServicesBloc extends Bloc<ServicesEvent, ServicesState> {
  final ServiceRepository _repository;

  ServicesBloc(this._repository) : super(const ServicesInitial()) {
    on<ServicesLoadRequested>(_onLoad);
    on<ServiceCreateRequested>(_onCreate);
    on<ServiceUpdateRequested>(_onUpdate);
    on<ServiceDeleteRequested>(_onDelete);
  }

  List<ServiceModel> get _currentList => switch (state) {
        ServicesLoaded(:final services) => services,
        ServicesActionInProgress(:final services) => services,
        ServicesError(:final services) => services,
        _ => const [],
      };

  Future<void> _onLoad(
    ServicesLoadRequested event,
    Emitter<ServicesState> emit,
  ) async {
    emit(const ServicesLoading());
    final result = await _repository.getServices(businessId: event.businessId);
    switch (result) {
      case Success(:final data):
        emit(ServicesLoaded(data));
      case HttpFailure(:final failure):
        emit(ServicesError(_message(failure)));
    }
  }

  Future<void> _onCreate(
    ServiceCreateRequested event,
    Emitter<ServicesState> emit,
  ) async {
    final current = _currentList;
    emit(ServicesActionInProgress(current));

    final result = await _repository.createService(
      businessId: event.businessId,
      name: event.name,
      description: event.description,
      price: event.price,
      durationMinutes: event.durationMinutes,
    );

    switch (result) {
      case Success(:final data):
        emit(ServicesLoaded([...current, data]));
      case HttpFailure(:final failure):
        emit(ServicesError(_mutationMessage(failure), services: current));
    }
  }

  Future<void> _onUpdate(
    ServiceUpdateRequested event,
    Emitter<ServicesState> emit,
  ) async {
    final current = _currentList;
    emit(ServicesActionInProgress(current));

    final result = await _repository.updateService(
      businessId: event.businessId,
      serviceId: event.serviceId,
      name: event.name,
      description: event.description,
      price: event.price,
      durationMinutes: event.durationMinutes,
      isActive: event.isActive,
    );

    switch (result) {
      case Success(:final data):
        final updated = current
            .map((s) => s.id == data.id ? data : s)
            .toList();
        emit(ServicesLoaded(updated));
      case HttpFailure(:final failure):
        emit(ServicesError(_mutationMessage(failure), services: current));
    }
  }

  Future<void> _onDelete(
    ServiceDeleteRequested event,
    Emitter<ServicesState> emit,
  ) async {
    final current = _currentList;
    emit(ServicesActionInProgress(current));

    final result = await _repository.deleteService(
      businessId: event.businessId,
      serviceId: event.serviceId,
    );

    switch (result) {
      case Success():
        final updated =
            current.where((s) => s.id != event.serviceId).toList();
        emit(ServicesLoaded(updated));
      case HttpFailure(:final failure):
        emit(ServicesError(_mutationMessage(failure), services: current));
    }
  }

  String _message(AppFailure failure) => switch (failure) {
        NetworkFailure() => 'Sem conexão com a internet',
        _ => 'Não foi possível carregar os serviços',
      };

  String _mutationMessage(AppFailure failure) => switch (failure) {
        NetworkFailure() => 'Sem conexão com a internet',
        _ => 'Não foi possível completar a ação. Tente novamente.',
      };
}
