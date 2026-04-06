import 'package:flutter/material.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/reports/data/reports_model.dart';

class DayOfWeekChart extends StatelessWidget {
  final List<DayOfWeekPoint> data;
  const DayOfWeekChart({super.key, required this.data});

  static const _labels = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final colors = context.appColors;
    final maxCount =
        data.map((d) => d.count).reduce((a, b) => a > b ? a : b);

    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dias mais movimentados',
            style: AppTypography.bodyMd.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...data.map((d) {
            final ratio = maxCount > 0 ? d.count / maxCount : 0.0;
            final isPeak = d.count == maxCount && maxCount > 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      _labels[d.day],
                      style: AppTypography.caption.copyWith(
                        color: isPeak
                            ? colors.textPrimary
                            : colors.textSecondary,
                        fontWeight:
                            isPeak ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 10,
                      color: colors.surfaceHigh,
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: ratio,
                        child: Container(
                          height: 10,
                          color: isPeak
                              ? colors.primary
                              : colors.primary.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${d.count}',
                      style: AppTypography.caption.copyWith(
                        color: isPeak
                            ? colors.textPrimary
                            : colors.textSecondary,
                        fontWeight:
                            isPeak ? FontWeight.w600 : FontWeight.w400,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
