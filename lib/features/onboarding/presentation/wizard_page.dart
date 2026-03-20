import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scheduler_frontend/core/router/app_routes.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/onboarding/bloc/wizard_bloc.dart';
import 'package:scheduler_frontend/features/onboarding/bloc/wizard_event.dart';
import 'package:scheduler_frontend/features/onboarding/bloc/wizard_state.dart';
import 'package:scheduler_frontend/features/onboarding/presentation/wizard_services_step.dart';
import 'package:scheduler_frontend/features/onboarding/presentation/wizard_team_step.dart';

class WizardPageWrapper extends StatelessWidget {
  const WizardPageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WizardBloc, WizardState>(
      builder: (context, state) {
        final steps = state is WizardLoaded
            ? state.steps.keys.toList()
            : [WizardStep.servicos];
        return WizardPage(
          steps: steps,
          onComplete: () => context.go(AppRoutes.home),
        );
      },
    );
  }
}

class WizardPage extends StatefulWidget {
  final List<WizardStep> steps;
  final VoidCallback onComplete;

  const WizardPage({
    required this.steps,
    required this.onComplete,
    super.key,
  });

  @override
  State<WizardPage> createState() => _WizardPageState();
}

class _WizardPageState extends State<WizardPage> {
  int _currentStep = 0;

  void _next() {
    if (_currentStep < widget.steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      widget.onComplete();
    }
  }

  void _skip() {
    context
        .read<WizardBloc>()
        .add(WizardStepSkipped(widget.steps[_currentStep]));
    _next();
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentStep];
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProgressDots(
                steps: widget.steps,
                currentStep: _currentStep,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                _titleFor(step),
                style: AppTypography.headingMd.copyWith(
                  color: context.appColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(child: _buildStep(step)),
              const SizedBox(height: AppSpacing.md),
              BaseButton(
                label: _currentStep == widget.steps.length - 1
                    ? 'Concluir'
                    : 'Próximo',
                onPressed: _next,
              ),
              const SizedBox(height: AppSpacing.sm),
              BaseButton(
                label: 'Pular por agora',
                variant: BaseButtonVariant.ghost,
                onPressed: _skip,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(WizardStep step) {
    return switch (step) {
      WizardStep.servicos => const WizardServicesStep(),
      WizardStep.equipe => const WizardTeamStep(),
      _ => const SizedBox.shrink(),
    };
  }

  String _titleFor(WizardStep step) => switch (step) {
        WizardStep.servicos => 'Adicione seus serviços',
        WizardStep.equipe => 'Convide sua equipe',
        _ => 'Configure',
      };
}

class _ProgressDots extends StatelessWidget {
  final List<WizardStep> steps;
  final int currentStep;

  const _ProgressDots({required this.steps, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        steps.length,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: i == currentStep ? 16 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: i < currentStep
                ? context.appColors.primary.withValues(alpha: 0.4)
                : i == currentStep
                    ? context.appColors.primary
                    : context.appColors.outline,
          ),
        ),
      ),
    );
  }
}
