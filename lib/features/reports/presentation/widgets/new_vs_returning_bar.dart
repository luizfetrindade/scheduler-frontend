import 'package:flutter/material.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';

class NewVsReturningBar extends StatelessWidget {
  final int newClients;
  final int returningClients;
  const NewVsReturningBar({
    super.key,
    required this.newClients,
    required this.returningClients,
  });

  @override
  Widget build(BuildContext context) {
    final total = newClients + returningClients;
    if (total == 0) return const SizedBox.shrink();

    final colors = context.appColors;
    final newPct = newClients / total;
    final retPct = 1 - newPct;
    final newFlex = (newPct * 100).round().clamp(1, 99);
    final retFlex = (retPct * 100).round().clamp(1, 99);

    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Novos vs. Recorrentes',
            style: AppTypography.bodyMd.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                flex: newFlex,
                child: Container(height: 14, color: colors.primary),
              ),
              const SizedBox(width: 2),
              Expanded(
                flex: retFlex,
                child: Container(height: 14, color: colors.accent),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 8, height: 8, color: colors.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '$newClients novos (${(newPct * 100).round()}%)',
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(width: 8, height: 8, color: colors.accent),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '$returningClients recorrentes (${(retPct * 100).round()}%)',
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
