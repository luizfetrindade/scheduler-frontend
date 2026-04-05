import 'package:equatable/equatable.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';

sealed class AppointmentsEvent extends Equatable {
  const AppointmentsEvent();
  @override
  List<Object?> get props => [];
}

class AppointmentsLoadRequested extends AppointmentsEvent {
  final String slug;
  final DateTime date;
  const AppointmentsLoadRequested({required this.slug, required this.date});
  @override
  List<Object?> get props => [slug, date];
}

/// Emitted on logout to wipe loaded data from memory.
class AppointmentsSessionCleared extends AppointmentsEvent {
  const AppointmentsSessionCleared();
}

class AppointmentStatusChanged extends AppointmentsEvent {
  final String slug;
  final String appointmentId;
  final AppointmentStatus status;
  const AppointmentStatusChanged({
    required this.slug,
    required this.appointmentId,
    required this.status,
  });
  @override
  List<Object?> get props => [slug, appointmentId, status];
}
