import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_http/flutter_http.dart';
import 'package:scheduler_frontend/features/clients/bloc/clients_event.dart';
import 'package:scheduler_frontend/features/clients/bloc/clients_state.dart';
import 'package:scheduler_frontend/features/clients/data/client_model.dart';
import 'package:scheduler_frontend/features/clients/data/client_repository.dart';

class ClientsBloc extends Bloc<ClientsEvent, ClientsState> {
  final ClientRepository _repository;

  ClientsBloc(this._repository) : super(const ClientsInitial()) {
    on<ClientsLoadRequested>(_onLoad);
    on<ClientCreateRequested>(_onCreate);
    on<ClientUpdateRequested>(_onUpdate);
    on<ClientDeleteRequested>(_onDelete);
    on<ClientHistoryLoadRequested>(_onLoadHistory);
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  List<ClientModel> get _currentClients => switch (state) {
        ClientsLoaded(:final clients) => clients,
        ClientsActionInProgress(:final clients) => clients,
        ClientsError(:final clients) => clients,
        _ => const [],
      };

  ClientHistory get _currentHistory => switch (state) {
        ClientsLoaded(:final history) => history,
        ClientsActionInProgress(:final history) => history,
        ClientsError(:final history) => history,
        _ => const {},
      };

  // ── Handlers ─────────────────────────────────────────────────────────────

  Future<void> _onLoad(
    ClientsLoadRequested event,
    Emitter<ClientsState> emit,
  ) async {
    emit(const ClientsLoading());
    final result = await _repository.getClients(businessId: event.businessId);
    switch (result) {
      case Success(:final data):
        emit(ClientsLoaded(data));
      case HttpFailure(:final failure):
        emit(ClientsError(_loadMessage(failure)));
    }
  }

  Future<void> _onCreate(
    ClientCreateRequested event,
    Emitter<ClientsState> emit,
  ) async {
    final clients = _currentClients;
    final history = _currentHistory; // snapshot — must be preserved on success
    emit(ClientsActionInProgress(clients, history: history));

    final result = await _repository.createClient(
      businessId: event.businessId,
      name: event.name,
      phone: event.phone,
      email: event.email,
    );

    switch (result) {
      case Success(:final data):
        // Pass history snapshot so cached history entries are not lost
        emit(ClientsLoaded([...clients, data], history: history));
      case HttpFailure(:final failure):
        emit(ClientsError(_mutationMessage(failure), clients: clients, history: history));
    }
  }

  Future<void> _onUpdate(
    ClientUpdateRequested event,
    Emitter<ClientsState> emit,
  ) async {
    final clients = _currentClients;
    final history = _currentHistory; // snapshot — must be preserved on success
    emit(ClientsActionInProgress(clients, history: history));

    final result = await _repository.updateClient(
      businessId: event.businessId,
      clientId: event.clientId,
      name: event.name,
      phone: event.phone,
      email: event.email,
    );

    switch (result) {
      case Success(:final data):
        final updated = clients.map((c) => c.id == data.id ? data : c).toList();
        // Pass history snapshot so cached history entries are not lost
        emit(ClientsLoaded(updated, history: history));
      case HttpFailure(:final failure):
        emit(ClientsError(_mutationMessage(failure), clients: clients, history: history));
    }
  }

  Future<void> _onDelete(
    ClientDeleteRequested event,
    Emitter<ClientsState> emit,
  ) async {
    final clients = _currentClients;
    final history = _currentHistory;
    emit(ClientsActionInProgress(clients, history: history));

    final result = await _repository.deleteClient(
      businessId: event.businessId,
      clientId: event.clientId,
    );

    switch (result) {
      case Success():
        final updated = clients.where((c) => c.id != event.clientId).toList();
        // Also evict deleted client from history cache
        final updatedHistory = Map<String, List<ClientHistoryItem>>.from(history)
          ..remove(event.clientId);
        emit(ClientsLoaded(updated, history: updatedHistory));
      case HttpFailure(:final failure):
        emit(ClientsError(_mutationMessage(failure), clients: clients, history: history));
    }
  }

  Future<void> _onLoadHistory(
    ClientHistoryLoadRequested event,
    Emitter<ClientsState> emit,
  ) async {
    final clients = _currentClients;
    final history = _currentHistory;

    // Skip if already cached (even if empty — zero-history clients should not be re-fetched)
    if (history.containsKey(event.clientId)) return;

    final result = await _repository.getClientHistory(
      businessId: event.businessId,
      clientId: event.clientId,
    );

    switch (result) {
      case Success(:final data):
        final updatedHistory = {...history, event.clientId: data};
        emit(ClientsLoaded(clients, history: updatedHistory));
      case HttpFailure():
        // History load failure is silent — card shows loading indicator indefinitely
        // (no error state emitted to avoid disrupting the list UX)
        break;
    }
  }

  // ── Error messages ────────────────────────────────────────────────────────

  String _loadMessage(AppFailure failure) => switch (failure) {
        NetworkFailure() => 'Sem conexão com a internet',
        _ => 'Não foi possível carregar os clientes',
      };

  String _mutationMessage(AppFailure failure) => switch (failure) {
        NetworkFailure() => 'Sem conexão com a internet',
        _ => 'Não foi possível completar a ação. Tente novamente.',
      };
}
