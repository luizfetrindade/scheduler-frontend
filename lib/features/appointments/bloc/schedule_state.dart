import 'package:equatable/equatable.dart';
import 'package:scheduler_frontend/features/appointments/bloc/schedule_event.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';

sealed class ScheduleState extends Equatable {
  const ScheduleState();
  @override
  List<Object?> get props => [];
}

class ScheduleInitial extends ScheduleState {
  const ScheduleInitial();
}

class ScheduleLoading extends ScheduleState {
  final DateTime selectedDate;
  final ScheduleViewMode viewMode;
  const ScheduleLoading({required this.selectedDate, required this.viewMode});
  @override
  List<Object?> get props => [selectedDate, viewMode];
}

class ScheduleLoaded extends ScheduleState {
  final Map<String, List<AppointmentModel>> appointmentsByDate;
  final DateTime selectedDate;
  final ScheduleViewMode viewMode;
  final bool hasPartialError;

  const ScheduleLoaded({
    required this.appointmentsByDate,
    required this.selectedDate,
    required this.viewMode,
    this.hasPartialError = false,
  });

  @override
  List<Object?> get props =>
      [appointmentsByDate, selectedDate, viewMode, hasPartialError];
}

class ScheduleError extends ScheduleState {
  final String message;
  final DateTime selectedDate;
  final ScheduleViewMode viewMode;

  const ScheduleError({
    required this.message,
    required this.selectedDate,
    required this.viewMode,
  });

  @override
  List<Object?> get props => [message, selectedDate, viewMode];
}

class ScheduleActionSuccess extends ScheduleState {
  final String message;
  final DateTime selectedDate;
  final ScheduleViewMode viewMode;

  const ScheduleActionSuccess({
    required this.message,
    required this.selectedDate,
    required this.viewMode,
  });

  @override
  List<Object?> get props => [message, selectedDate, viewMode];
}

class ScheduleActionFailure extends ScheduleState {
  final String message;
  final DateTime selectedDate;
  final ScheduleViewMode viewMode;

  const ScheduleActionFailure({
    required this.message,
    required this.selectedDate,
    required this.viewMode,
  });

  @override
  List<Object?> get props => [message, selectedDate, viewMode];
}
