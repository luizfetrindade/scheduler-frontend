import 'package:equatable/equatable.dart';
import 'package:scheduler_frontend/features/clients/data/client_model.dart';

typedef ClientHistory = Map<String, List<ClientHistoryItem>>;

sealed class ClientsState extends Equatable {
  const ClientsState();
  @override
  List<Object?> get props => [];
}

class ClientsInitial extends ClientsState {
  const ClientsInitial();
}

class ClientsLoading extends ClientsState {
  const ClientsLoading();
}

class ClientsLoaded extends ClientsState {
  final List<ClientModel> clients;
  final ClientHistory history;

  const ClientsLoaded(this.clients, {this.history = const {}});

  @override
  List<Object?> get props => [clients, history];
}

/// Keeps list and history visible while a create/update/delete is in flight.
class ClientsActionInProgress extends ClientsState {
  final List<ClientModel> clients;
  final ClientHistory history;

  const ClientsActionInProgress(this.clients, {this.history = const {}});

  @override
  List<Object?> get props => [clients, history];
}

class ClientsError extends ClientsState {
  final String message;
  final List<ClientModel> clients;
  final ClientHistory history;

  const ClientsError(
    this.message, {
    this.clients = const [],
    this.history = const {},
  });

  @override
  List<Object?> get props => [message, clients, history];
}
