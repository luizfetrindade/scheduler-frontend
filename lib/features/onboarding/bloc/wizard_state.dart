import 'package:equatable/equatable.dart';

enum WizardStep { negocios, horarios, servicos, equipe }

class WizardStepStatus extends Equatable {
  final WizardStep step;
  final bool isComplete;

  const WizardStepStatus({required this.step, required this.isComplete});

  @override
  List<Object?> get props => [step, isComplete];
}

sealed class WizardState extends Equatable {
  const WizardState();

  @override
  List<Object?> get props => [];
}

class WizardInitial extends WizardState {
  const WizardInitial();
}

class WizardLoading extends WizardState {
  const WizardLoading();
}

class WizardLoaded extends WizardState {
  final Map<WizardStep, WizardStepStatus> steps;

  const WizardLoaded(this.steps);

  bool get isAllComplete => steps.values.every((s) => s.isComplete);

  @override
  List<Object?> get props => [steps];
}

class WizardError extends WizardState {
  final String message;

  const WizardError(this.message);

  @override
  List<Object?> get props => [message];
}
