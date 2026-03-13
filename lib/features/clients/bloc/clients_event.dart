import 'package:equatable/equatable.dart';

sealed class ClientsEvent extends Equatable {
  const ClientsEvent();
  @override
  List<Object?> get props => [];
}

class ClientsLoadRequested extends ClientsEvent {
  final String businessId;
  const ClientsLoadRequested(this.businessId);
  @override
  List<Object?> get props => [businessId];
}

class ClientCreateRequested extends ClientsEvent {
  final String businessId;
  final String name;
  final String phone;
  final String? email;

  const ClientCreateRequested({
    required this.businessId,
    required this.name,
    required this.phone,
    this.email,
  });

  @override
  List<Object?> get props => [businessId, name, phone, email];
}

class ClientUpdateRequested extends ClientsEvent {
  final String businessId;
  final String clientId;
  final String name;
  final String phone;
  final String? email;

  const ClientUpdateRequested({
    required this.businessId,
    required this.clientId,
    required this.name,
    required this.phone,
    this.email,
  });

  @override
  List<Object?> get props => [businessId, clientId, name, phone, email];
}

class ClientDeleteRequested extends ClientsEvent {
  final String businessId;
  final String clientId;

  const ClientDeleteRequested({
    required this.businessId,
    required this.clientId,
  });

  @override
  List<Object?> get props => [businessId, clientId];
}

class ClientHistoryLoadRequested extends ClientsEvent {
  final String businessId;
  final String clientId;

  const ClientHistoryLoadRequested({
    required this.businessId,
    required this.clientId,
  });

  @override
  List<Object?> get props => [businessId, clientId];
}
