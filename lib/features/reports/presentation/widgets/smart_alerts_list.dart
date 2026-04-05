import 'package:flutter/material.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/reports/utils/smart_alerts.dart';

class SmartAlertsList extends StatelessWidget {
  final List<ReportAlert> alerts;
  const SmartAlertsList({super.key, required this.alerts});

  Color _accentColor(AlertSeverity s) => switch (s) {
        AlertSeverity.high => AppColors.error,
        AlertSeverity.medium => const Color(0xFFFBBF24),
        AlertSeverity.positive => AppColors.success,
      };

  IconData _icon(AlertSeverity s) => switch (s) {
        AlertSeverity.high => Icons.warning_amber_rounded,
        AlertSeverity.medium => Icons.lightbulb_outline,
        AlertSeverity.positive => Icons.emoji_events_outlined,
      };

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alertas do período',
          style: AppTypography.bodyMd.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...alerts.map((a) {
          final accent = _accentColor(a.severity);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: BaseCard(
              padding: AppSpacing.md,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 3,
                    height: 36,
                    color: accent,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Icon(_icon(a.severity), size: 18, color: accent),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.message,
                          style: AppTypography.bodySm.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          a.detail,
                          style: AppTypography.caption.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
