import 'package:equatable/equatable.dart';
import 'package:scheduler_frontend/features/professionals/data/professional_model.dart';

sealed class ProfessionalsState extends Equatable {
  const ProfessionalsState();
  @override
  List<Object?> get props => [];
}

class ProfessionalsInitial extends ProfessionalsState {
  const ProfessionalsInitial();
}

class ProfessionalsLoading extends ProfessionalsState {
  const ProfessionalsLoading();
}

class ProfessionalsLoaded extends ProfessionalsState {
  final List<ProfessionalModel> professionals;
  const ProfessionalsLoaded(this.professionals);
  @override
  List<Object?> get props => [professionals];
}

/// Keeps list visible during create/update/delete to avoid UI flicker.
class ProfessionalsActionInProgress extends ProfessionalsState {
  final List<ProfessionalModel> professionals;
  const ProfessionalsActionInProgress(this.professionals);
  @override
  List<Object?> get props => [professionals];
}

class ProfessionalsError extends ProfessionalsState {
  final String message;
  final List<ProfessionalModel> professionals;
  const ProfessionalsError(this.message, {this.professionals = const []});
  @override
  List<Object?> get props => [message, professionals];
}
