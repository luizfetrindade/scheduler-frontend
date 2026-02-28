import 'package:equatable/equatable.dart';

enum AppointmentStatus { pending, confirmed, cancelled, noShow, completed }

extension AppointmentStatusX on AppointmentStatus {
  static AppointmentStatus fromString(String value) => switch (value.toUpperCase()) {
        'CONFIRMED' => AppointmentStatus.confirmed,
        'CANCELLED' => AppointmentStatus.cancelled,
        'NO_SHOW' => AppointmentStatus.noShow,
        'COMPLETED' => AppointmentStatus.completed,
        _ => AppointmentStatus.pending,
      };

  String get label => switch (this) {
        AppointmentStatus.pending => 'Pendente',
        AppointmentStatus.confirmed => 'Confirmado',
        AppointmentStatus.cancelled => 'Cancelado',
        AppointmentStatus.noShow => 'Não compareceu',
        AppointmentStatus.completed => 'Concluído',
      };

  String get apiValue => switch (this) {
        AppointmentStatus.pending => 'PENDING',
        AppointmentStatus.confirmed => 'CONFIRMED',
        AppointmentStatus.cancelled => 'CANCELLED',
        AppointmentStatus.noShow => 'NO_SHOW',
        AppointmentStatus.completed => 'COMPLETED',
      };
}

class AppointmentModel extends Equatable {
  final String id;
  final DateTime startsAt;
  final DateTime endsAt;
  final AppointmentStatus status;
  final String clientName;
  final String? serviceName;
  final int? serviceDurationMinutes;
  final String? staffId;
  final String? notes;

  const AppointmentModel({
    required this.id,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.clientName,
    this.serviceName,
    this.serviceDurationMinutes,
    this.staffId,
    this.notes,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final client = json['client'] as Map<String, dynamic>?;
    final service = json['service'] as Map<String, dynamic>?;
    return AppointmentModel(
      id: json['id'] as String,
      startsAt: DateTime.parse(json['startsAt'] as String),
      endsAt: DateTime.parse(json['endsAt'] as String),
      status: AppointmentStatusX.fromString(json['status'] as String? ?? 'PENDING'),
      clientName: client?['name'] as String? ?? 'Cliente',
      serviceName: service?['name'] as String?,
      serviceDurationMinutes: service?['durationMinutes'] as int?,
      staffId: json['staffId'] as String?,
      notes: json['notes'] as String?,
    );
  }

  AppointmentModel copyWith({AppointmentStatus? status}) => AppointmentModel(
        id: id,
        startsAt: startsAt,
        endsAt: endsAt,
        status: status ?? this.status,
        clientName: clientName,
        serviceName: serviceName,
        serviceDurationMinutes: serviceDurationMinutes,
        staffId: staffId,
        notes: notes,
      );

  @override
  List<Object?> get props => [id, startsAt, endsAt, status, clientName, serviceName, staffId];
}
