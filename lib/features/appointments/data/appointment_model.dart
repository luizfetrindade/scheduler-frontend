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

enum AppointmentType { appointment, block }

extension AppointmentTypeX on AppointmentType {
  static AppointmentType fromString(String value) => switch (value.toUpperCase()) {
        'BLOCK' => AppointmentType.block,
        _ => AppointmentType.appointment,
      };

  String get apiValue => switch (this) {
        AppointmentType.appointment => 'APPOINTMENT',
        AppointmentType.block => 'BLOCK',
      };
}

class AppointmentModel extends Equatable {
  final String id;
  final AppointmentType type;
  final DateTime startsAt;
  final DateTime endsAt;
  final AppointmentStatus status;
  final String clientName;
  final String? title;
  final String? serviceName;
  final int? serviceDurationMinutes;
  final String? staffId;
  final String? notes;
  final String? recurrenceRule;
  final String? recurrenceGroupId;

  const AppointmentModel({
    required this.id,
    this.type = AppointmentType.appointment,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.clientName,
    this.title,
    this.serviceName,
    this.serviceDurationMinutes,
    this.staffId,
    this.notes,
    this.recurrenceRule,
    this.recurrenceGroupId,
  });

  bool get isBlock => type == AppointmentType.block;
  bool get isRecurring => recurrenceGroupId != null;

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final client = json['client'] as Map<String, dynamic>?;
    final service = json['service'] as Map<String, dynamic>?;
    return AppointmentModel(
      id: json['id'] as String,
      type: AppointmentTypeX.fromString(json['type'] as String? ?? 'APPOINTMENT'),
      startsAt: DateTime.parse(json['startsAt'] as String),
      endsAt: DateTime.parse(json['endsAt'] as String),
      status: AppointmentStatusX.fromString(json['status'] as String? ?? 'PENDING'),
      clientName: client?['name'] as String? ?? 'Cliente',
      title: json['title'] as String?,
      serviceName: service?['name'] as String?,
      serviceDurationMinutes: service?['durationMinutes'] as int?,
      staffId: json['staffId'] as String?,
      notes: json['notes'] as String?,
      recurrenceRule: json['recurrenceRule'] as String?,
      recurrenceGroupId: json['recurrenceGroupId'] as String?,
    );
  }

  AppointmentModel copyWith({AppointmentStatus? status}) => AppointmentModel(
        id: id,
        type: type,
        startsAt: startsAt,
        endsAt: endsAt,
        status: status ?? this.status,
        clientName: clientName,
        title: title,
        serviceName: serviceName,
        serviceDurationMinutes: serviceDurationMinutes,
        staffId: staffId,
        notes: notes,
        recurrenceRule: recurrenceRule,
        recurrenceGroupId: recurrenceGroupId,
      );

  @override
  List<Object?> get props => [
        id, type, startsAt, endsAt, status, clientName, title,
        serviceName, staffId, recurrenceRule, recurrenceGroupId,
      ];
}
