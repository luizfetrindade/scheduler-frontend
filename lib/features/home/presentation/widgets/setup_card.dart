import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scheduler_frontend/core/router/app_routes.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/onboarding/bloc/wizard_state.dart';

class SetupCard extends StatelessWidget {
  final WizardLoaded wizardState;

  const SetupCard({required this.wizardState, super.key});

  @override
  Widget build(BuildContext context) {
    if (wizardState.isAllComplete) return const SizedBox.shrink();

    return Card(
      color: context.appColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Complete a configuração',
              style: AppTypography.labelLarge.copyWith(
                color: context.appColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: wizardState.steps.entries.map((entry) {
                final isComplete = entry.value.isComplete;
                return ActionChip(
                  label: Text(_labelFor(entry.key)),
                  avatar: Icon(
                    isComplete
                        ? Icons.check_circle_outline
                        : Icons.arrow_forward,
                    size: 16,
                    color: isComplete
                        ? context.appColors.primary
                        : context.appColors.textSecondary,
                  ),
                  onPressed: isComplete
                      ? null
                      : () => context.push(AppRoutes.onboarding),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _labelFor(WizardStep step) => switch (step) {
        WizardStep.servicos => 'Serviços',
        WizardStep.equipe => 'Equipe',
        _ => step.name,
      };
}
