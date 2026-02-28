import 'package:flutter/material.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';

class StatsSummaryRow extends StatelessWidget {
  final int total;
  final int pending;
  final int confirmed;

  const StatsSummaryRow({
    super.key,
    required this.total,
    required this.pending,
    required this.confirmed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(value: total, label: 'Total', color: AppColors.textPrimary),
        const SizedBox(width: AppSpacing.md),
        _StatCard(value: pending, label: 'Pendentes', color: AppColors.purple300),
        const SizedBox(width: AppSpacing.md),
        _StatCard(value: confirmed, label: 'Confirmados', color: AppColors.success),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: BaseCard(
        child: Column(
          children: [
            Text(
              '$value',
              style: AppTypography.displayLg.copyWith(color: color),
            ),
            const SizedBox(height: 4),
            Text(label, style: AppTypography.caption, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
