import 'package:equatable/equatable.dart';

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

  const ScheduleAppointmentCreateRequested({
    required this.clientName,
    required this.startsAt,
    this.durationMinutes = 60,
    this.notes,
    this.recurrenceRule,
    this.serviceId,
  });

  @override
  List<Object?> get props =>
      [clientName, startsAt, durationMinutes, notes, recurrenceRule, serviceId];
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

enum ScheduleViewMode { day, week }
