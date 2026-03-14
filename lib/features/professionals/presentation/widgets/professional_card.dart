import 'package:flutter/material.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/professionals/data/professional_model.dart';

class ProfessionalCard extends StatelessWidget {
  final ProfessionalModel professional;
  final VoidCallback onTap;
  final VoidCallback onToggleActive;

  const ProfessionalCard({
    super.key,
    required this.professional,
    required this.onTap,
    required this.onToggleActive,
  });

  Color _parseColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final swatchColor = _parseColor(professional.color);

    return Opacity(
      opacity: professional.isActive ? 1.0 : 0.6,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: context.appColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: context.appColors.surfaceHigh),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: swatchColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      professional.name,
                      style: AppTypography.bodySm.copyWith(
                        color: context.appColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (professional.roleName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        professional.roleName!,
                        style: AppTypography.caption.copyWith(
                          color: context.appColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: professional.isActive
                      ? context.appColors.surfaceHigh
                      : context.appColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  professional.isActive ? 'Ativo' : 'Inativo',
                  style: AppTypography.caption.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                ),
              ),
              Switch(
                value: professional.isActive,
                onChanged: (_) => onToggleActive(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
