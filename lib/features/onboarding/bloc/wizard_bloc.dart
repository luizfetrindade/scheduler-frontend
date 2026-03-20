import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scheduler_frontend/features/onboarding/bloc/wizard_event.dart';
import 'package:scheduler_frontend/features/onboarding/bloc/wizard_state.dart';

class WizardBloc extends Bloc<WizardEvent, WizardState> {
  final Future<bool> Function(String businessId) _hasServices;
  final Future<bool> Function(String businessId) _hasProfessionals;
  final bool isSoloMode;
  final String businessId;

  WizardBloc({
    required Future<bool> Function(String) hasServices,
    required Future<bool> Function(String) hasProfessionals,
    required this.isSoloMode,
    required this.businessId,
  })  : _hasServices = hasServices,
        _hasProfessionals = hasProfessionals,
        super(const WizardInitial()) {
    on<WizardCheckRequested>(_onCheck);
    on<WizardStepSkipped>(_onStepSkipped);
    on<WizardStepCompleted>(_onStepCompleted);
  }

  Future<void> _onCheck(
    WizardCheckRequested event,
    Emitter<WizardState> emit,
  ) async {
    emit(const WizardLoading());
    try {
      final hasServices = await _hasServices(businessId);
      final hasProfessionals =
          isSoloMode ? true : await _hasProfessionals(businessId);

      final steps = <WizardStep, WizardStepStatus>{
        WizardStep.servicos: WizardStepStatus(
          step: WizardStep.servicos,
          isComplete: hasServices,
        ),
        if (!isSoloMode)
          WizardStep.equipe: WizardStepStatus(
            step: WizardStep.equipe,
            isComplete: hasProfessionals,
          ),
      };

      emit(WizardLoaded(steps));
    } catch (e) {
      emit(const WizardError('Algo deu errado. Tente novamente.'));
    }
  }

  void _onStepSkipped(WizardStepSkipped event, Emitter<WizardState> emit) {
    // Skipping does not change completion — WizardPage manages its own step index.
  }

  Future<void> _onStepCompleted(
    WizardStepCompleted event,
    Emitter<WizardState> emit,
  ) async {
    add(const WizardCheckRequested());
  }
}
