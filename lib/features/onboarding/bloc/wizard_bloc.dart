import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scheduler_frontend/features/onboarding/bloc/wizard_event.dart';
import 'package:scheduler_frontend/features/onboarding/bloc/wizard_state.dart';

class WizardBloc extends Bloc<WizardEvent, WizardState> {
  final Future<String> Function(String name) _createBusiness;
  final Future<bool> Function(String businessId) _hasServices;
  final Future<bool> Function(String businessId) _hasProfessionals;

  // Mutable orchestration config — updated when the active business changes.
  String _businessId;
  bool _isSoloMode;

  WizardBloc({
    required Future<String> Function(String) createBusiness,
    required Future<bool> Function(String) hasServices,
    required Future<bool> Function(String) hasProfessionals,
    required bool isSoloMode,
    required String businessId,
  })  : _createBusiness = createBusiness,
        _hasServices = hasServices,
        _hasProfessionals = hasProfessionals,
        _isSoloMode = isSoloMode,
        _businessId = businessId,
        super(const WizardInitial()) {
    on<WizardCheckRequested>(_onCheck);
    on<WizardStepSkipped>(_onStepSkipped);
    on<WizardStepCompleted>(_onStepCompleted);
    on<WizardBusinessSubmitted>(_onBusinessSubmitted);
  }

  /// Updates business context and triggers a fresh completeness check.
  void reinitialize({required String businessId, required bool isSoloMode}) {
    _businessId = businessId;
    _isSoloMode = isSoloMode;
    add(const WizardCheckRequested());
  }

  Future<void> _onCheck(
    WizardCheckRequested event,
    Emitter<WizardState> emit,
  ) async {
    emit(const WizardLoading());

    if (_businessId.isEmpty) {
      emit(WizardLoaded({
        WizardStep.negocios: const WizardStepStatus(
          step: WizardStep.negocios,
          isComplete: false,
        ),
      }));
      return;
    }

    try {
      final hasServices = await _hasServices(_businessId);
      final hasProfessionals =
          _isSoloMode ? true : await _hasProfessionals(_businessId);

      final steps = <WizardStep, WizardStepStatus>{
        WizardStep.servicos: WizardStepStatus(
          step: WizardStep.servicos,
          isComplete: hasServices,
        ),
        if (!_isSoloMode)
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

  Future<void> _onBusinessSubmitted(
    WizardBusinessSubmitted event,
    Emitter<WizardState> emit,
  ) async {
    emit(const WizardLoading());
    try {
      final businessId = await _createBusiness(event.name);
      _businessId = businessId;
      add(const WizardCheckRequested());
    } catch (e) {
      emit(const WizardError('Algo deu errado. Tente novamente.'));
    }
  }
}
