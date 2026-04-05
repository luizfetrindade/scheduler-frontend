import 'package:flutter/material.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/reports/utils/health_score.dart';

class HealthScoreCard extends StatelessWidget {
  final double score;
  final List<String> badges;

  const HealthScoreCard({
    super.key,
    required this.score,
    this.badges = const [],
  });

  Color _scoreColor(BuildContext context) {
    final colors = context.appColors;
    if (score >= 80) return AppColors.success;
    if (score >= 60) return colors.primary;
    if (score >= 40) return const Color(0xFFFBBF24);
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scoreColor = _scoreColor(context);

    return BaseCard(
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: scoreColor, width: 3),
            ),
            alignment: Alignment.center,
            child: Text(
              score.round().toString(),
              style: AppTypography.titleLarge.copyWith(
                color: scoreColor,
                fontWeight: FontWeight.w700,
                fontSize: 26,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saúde do negócio',
                  style: AppTypography.caption.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  healthScoreLabel(score),
                  style: AppTypography.bodyMd.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (badges.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: badges
                        .map((b) => _HealthBadge(label: b))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthBadge extends StatelessWidget {
  final String label;
  const _HealthBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceHigh,
        border: Border.all(color: colors.outline, width: 1),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: colors.textSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),
    );
  }
}
