import 'package:equatable/equatable.dart';
import 'package:scheduler_frontend/features/onboarding/bloc/wizard_state.dart';

sealed class WizardEvent extends Equatable {
  const WizardEvent();

  @override
  List<Object?> get props => [];
}

/// Check completeness of all steps by querying existing data.
class WizardCheckRequested extends WizardEvent {
  const WizardCheckRequested();
}

/// User tapped "Pular por agora" — does not change step completion.
class WizardStepSkipped extends WizardEvent {
  final WizardStep step;

  const WizardStepSkipped(this.step);

  @override
  List<Object?> get props => [step];
}

/// User completed a step (saved data) — marks the step as done and refreshes.
class WizardStepCompleted extends WizardEvent {
  final WizardStep step;

  const WizardStepCompleted(this.step);

  @override
  List<Object?> get props => [step];
}
