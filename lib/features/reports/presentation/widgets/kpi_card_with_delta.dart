import 'package:flutter/material.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';

class KpiCardWithDelta extends StatelessWidget {
  final String label;
  final String value;
  final double delta;
  final String deltaLabel;

  const KpiCardWithDelta({
    super.key,
    required this.label,
    required this.value,
    required this.delta,
    required this.deltaLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final hasDelta = deltaLabel.isNotEmpty;
    final isPositive = delta >= 0;
    final deltaColor = isPositive ? AppColors.success : AppColors.error;
    final arrow = isPositive ? '↑' : '↓';

    return BaseCard(
      padding: AppSpacing.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.headingMd.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (hasDelta) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '$arrow $deltaLabel',
              style: AppTypography.caption.copyWith(
                color: deltaColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
