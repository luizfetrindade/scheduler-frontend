import 'package:equatable/equatable.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';

sealed class AppointmentsState extends Equatable {
  const AppointmentsState();
  @override
  List<Object?> get props => [];
}

class AppointmentsInitial extends AppointmentsState {
  const AppointmentsInitial();
}

class AppointmentsLoading extends AppointmentsState {
  const AppointmentsLoading();
}

class AppointmentsLoaded extends AppointmentsState {
  final List<AppointmentModel> appointments;
  const AppointmentsLoaded(this.appointments);

  int get total => appointments.length;
  int get pending =>
      appointments.where((a) => a.status == AppointmentStatus.pending).length;
  int get confirmed =>
      appointments.where((a) => a.status == AppointmentStatus.confirmed).length;

  @override
  List<Object?> get props => [appointments];
}

class AppointmentsError extends AppointmentsState {
  final String message;
  const AppointmentsError(this.message);
  @override
  List<Object?> get props => [message];
}
