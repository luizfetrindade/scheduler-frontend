import 'package:equatable/equatable.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';

const _sentinel = Object();

class ClientModel extends Equatable {
  final String id;
  final String name;
  final String? phone;
  final String? email;

  const ClientModel({
    required this.id,
    required this.name,
    this.phone,
    this.email,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) => ClientModel(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
      );

  ClientModel copyWith({
    String? name,
    Object? phone = _sentinel,
    Object? email = _sentinel,
  }) =>
      ClientModel(
        id: id,
        name: name ?? this.name,
        phone: phone == _sentinel ? this.phone : phone as String?,
        email: email == _sentinel ? this.email : email as String?,
      );

  @override
  List<Object?> get props => [id, name, phone, email];
}

class ClientHistoryItem extends Equatable {
  final String id;
  final DateTime startsAt;
  final DateTime endsAt;
  final AppointmentStatus status;
  final String? serviceName;

  const ClientHistoryItem({
    required this.id,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    this.serviceName,
  });

  factory ClientHistoryItem.fromJson(Map<String, dynamic> json) =>
      ClientHistoryItem(
        id: json['id'] as String,
        startsAt: DateTime.parse(json['startsAt'] as String),
        endsAt: DateTime.parse(json['endsAt'] as String),
        status: AppointmentStatusX.fromString(json['status'] as String),
        serviceName: (json['service'] as Map<String, dynamic>?)?['name'] as String?,
      );

  @override
  List<Object?> get props => [id, startsAt, endsAt, status, serviceName];
}
