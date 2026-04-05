import 'package:equatable/equatable.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';

sealed class ScheduleEvent extends Equatable {
  const ScheduleEvent();
  @override
  List<Object?> get props => [];
}

class ScheduleInitialized extends ScheduleEvent {
  final String slug;
  final DateTime date;
  const ScheduleInitialized({required this.slug, required this.date});
  @override
  List<Object?> get props => [slug, date];
}

class SchedulePreviousPeriod extends ScheduleEvent {
  const SchedulePreviousPeriod();
}

class ScheduleNextPeriod extends ScheduleEvent {
  const ScheduleNextPeriod();
}

class ScheduleDateSelected extends ScheduleEvent {
  final DateTime date;
  const ScheduleDateSelected(this.date);
  @override
  List<Object?> get props => [date];
}

class ScheduleViewModeChanged extends ScheduleEvent {
  final ScheduleViewMode mode;
  const ScheduleViewModeChanged(this.mode);
  @override
  List<Object?> get props => [mode];
}

class ScheduleAppointmentCreateRequested extends ScheduleEvent {
  final String clientName;
  final DateTime startsAt;
  final int durationMinutes;
  final String? notes;
  final String? recurrenceRule;
  final String? serviceId;
  final AppointmentStatus? status;

  const ScheduleAppointmentCreateRequested({
    required this.clientName,
    required this.startsAt,
    this.durationMinutes = 60,
    this.notes,
    this.recurrenceRule,
    this.serviceId,
    this.status,
  });

  @override
  List<Object?> get props =>
      [clientName, startsAt, durationMinutes, notes, recurrenceRule, serviceId, status];
}

class ScheduleBlockCreateRequested extends ScheduleEvent {
  final DateTime startsAt;
  final int durationMinutes;
  final String? title;
  final String? notes;
  final String? staffId;
  final String? recurrenceRule;

  const ScheduleBlockCreateRequested({
    required this.startsAt,
    required this.durationMinutes,
    this.title,
    this.notes,
    this.staffId,
    this.recurrenceRule,
  });

  @override
  List<Object?> get props =>
      [startsAt, durationMinutes, title, notes, staffId, recurrenceRule];
}

class ScheduleAppointmentCancelRequested extends ScheduleEvent {
  final String appointmentId;
  const ScheduleAppointmentCancelRequested(this.appointmentId);
  @override
  List<Object?> get props => [appointmentId];
}

class ScheduleRecurrenceCancelRequested extends ScheduleEvent {
  final String appointmentId;
  final bool cancelFuture;

  const ScheduleRecurrenceCancelRequested({
    required this.appointmentId,
    required this.cancelFuture,
  });

  @override
  List<Object?> get props => [appointmentId, cancelFuture];
}

class ScheduleFilterByProfessional extends ScheduleEvent {
  final String? professionalId; // null = show all
  const ScheduleFilterByProfessional(this.professionalId);
  @override
  List<Object?> get props => [professionalId];
}

class ScheduleAppointmentUpdateRequested extends ScheduleEvent {
  final String appointmentId;
  final String? clientName;
  final DateTime? startsAt;
  final int? durationMinutes;
  final String? notes;
  final String? serviceId;
  final bool clearNotes;
  final bool clearService;

  const ScheduleAppointmentUpdateRequested({
    required this.appointmentId,
    this.clientName,
    this.startsAt,
    this.durationMinutes,
    this.notes,
    this.serviceId,
    this.clearNotes = false,
    this.clearService = false,
  });

  @override
  List<Object?> get props => [appointmentId, clientName, startsAt, durationMinutes, notes, serviceId, clearNotes, clearService];
}

class ScheduleRecurrenceUpdateRequested extends ScheduleEvent {
  final String appointmentId;
  final String? clientName;
  final DateTime? startsAt;
  final int? durationMinutes;
  final String? notes;
  final String? serviceId;
  final bool clearNotes;
  final bool clearService;
  final bool updateFuture; // true = this and future, false = this only

  const ScheduleRecurrenceUpdateRequested({
    required this.appointmentId,
    this.clientName,
    this.startsAt,
    this.durationMinutes,
    this.notes,
    this.serviceId,
    this.clearNotes = false,
    this.clearService = false,
    required this.updateFuture,
  });

  @override
  List<Object?> get props => [appointmentId, clientName, startsAt, durationMinutes, notes, serviceId, clearNotes, clearService, updateFuture];
}

class ScheduleAppointmentStatusChanged extends ScheduleEvent {
  final String appointmentId;
  final AppointmentStatus status;

  const ScheduleAppointmentStatusChanged({
    required this.appointmentId,
    required this.status,
  });

  @override
  List<Object?> get props => [appointmentId, status];
}

enum ScheduleViewMode { day, week }
