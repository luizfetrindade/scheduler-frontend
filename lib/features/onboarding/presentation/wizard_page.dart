import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scheduler_frontend/core/router/app_routes.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/onboarding/bloc/wizard_bloc.dart';
import 'package:scheduler_frontend/features/onboarding/bloc/wizard_event.dart';
import 'package:scheduler_frontend/features/onboarding/bloc/wizard_state.dart';
import 'package:scheduler_frontend/features/onboarding/presentation/wizard_business_step.dart';
import 'package:scheduler_frontend/features/onboarding/presentation/wizard_services_step.dart';
import 'package:scheduler_frontend/features/onboarding/presentation/wizard_team_step.dart';

/// Used by the `/onboarding` route — wraps [WizardPage] in a Scaffold.
class WizardPageWrapper extends StatelessWidget {
  final VoidCallback? onComplete;

  const WizardPageWrapper({this.onComplete, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WizardBloc, WizardState>(
      builder: (context, state) {
        final steps = state is WizardLoaded
            ? state.steps.keys.toList()
            : [WizardStep.negocios];

        final complete =
            onComplete ?? () => context.go(AppRoutes.home);

        return Scaffold(
          backgroundColor: context.appColors.background,
          body: SafeArea(
            child: WizardPage(steps: steps, onComplete: complete),
          ),
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

  @override
  void didUpdateWidget(WizardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clamp step index if list shrinks (e.g. after business creation
    // the negocios step disappears and servicos takes index 0).
    if (_currentStep >= widget.steps.length) {
      _currentStep = 0;
    }
  }

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

  bool get _isNegociosStep =>
      widget.steps.isNotEmpty &&
      widget.steps[_currentStep] == WizardStep.negocios;

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentStep];
    return Padding(
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
          if (!_isNegociosStep) ...[
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
        ],
      ),
    );
  }

  Widget _buildStep(WizardStep step) {
    return switch (step) {
      WizardStep.negocios => const WizardBusinessStep(),
      WizardStep.servicos => const WizardServicesStep(),
      WizardStep.equipe => const WizardTeamStep(),
      _ => const SizedBox.shrink(),
    };
  }

  String _titleFor(WizardStep step) => switch (step) {
        WizardStep.negocios => 'Crie seu negócio',
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
