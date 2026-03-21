import 'package:flutter/material.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/professionals/data/professional_model.dart';

Color _parseColor(String hex) {
  final cleaned = hex.replaceAll('#', '');
  try {
    return Color(int.parse('FF$cleaned', radix: 16));
  } catch (_) {
    return const Color(0xFF4A90E2);
  }
}

class ProfessionalCard extends StatelessWidget {
  final ProfessionalModel professional;
  final VoidCallback onTap;
  final VoidCallback? onToggleActive;

  const ProfessionalCard({
    super.key,
    required this.professional,
    required this.onTap,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final swatchColor = _parseColor(professional.color);
    final initials = professional.name.isNotEmpty
        ? professional.name[0].toUpperCase()
        : '?';

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
            border: Border.all(color: context.appColors.outline),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Colored avatar ──
              Container(
                width: 40,
                height: 40,
                color: swatchColor.withValues(alpha: 0.15),
                child: Center(
                  child: Text(
                    initials,
                    style: AppTypography.bodyMd.copyWith(
                      color: swatchColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // ── Name + role ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      professional.name,
                      style: AppTypography.labelLarge.copyWith(
                        color: context.appColors.textPrimary,
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

              // ── Status badge ──
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                color: professional.isActive
                    ? AppColors.success.withValues(alpha: 0.1)
                    : context.appColors.surfaceHigh,
                child: Text(
                  professional.isActive ? 'Ativo' : 'Inativo',
                  style: AppTypography.caption.copyWith(
                    color: professional.isActive
                        ? AppColors.success
                        : context.appColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),

              // ── Active toggle ──
              Switch(
                value: professional.isActive,
                onChanged: onToggleActive != null ? (_) => onToggleActive!() : null,
                activeColor: context.appColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
