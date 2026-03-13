import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/reports/data/reports_model.dart';

class RevenueDonut extends StatelessWidget {
  final RevenueReport revenue;

  const RevenueDonut({super.key, required this.revenue});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final total = revenue.confirmed + revenue.lost;

    if (total == 0) return const SizedBox.shrink();

    final pending = revenue.confirmed - revenue.realized;
    final sections = [
      if (revenue.realized > 0)
        PieChartSectionData(
          value: revenue.realized,
          color: AppColors.success,
          title: '',
          radius: 48,
        ),
      if (pending > 0)
        PieChartSectionData(
          value: pending,
          color: AppColors.purple500,
          title: '',
          radius: 48,
        ),
      if (revenue.lost > 0)
        PieChartSectionData(
          value: revenue.lost,
          color: AppColors.error,
          title: '',
          radius: 48,
        ),
    ];

    return BaseCard(
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: PieChart(PieChartData(
              sections: sections,
              centerSpaceRadius: 32,
              sectionsSpace: 2,
            )),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Receita',
                  style: AppTypography.bodyMd.copyWith(
                      color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.md),
                _LegendRow(
                  color: AppColors.success,
                  label: 'Realizada',
                  value: currency.format(revenue.realized),
                ),
                const SizedBox(height: AppSpacing.xs),
                _LegendRow(
                  color: AppColors.purple500,
                  label: 'Confirmada',
                  value: currency.format(revenue.confirmed),
                ),
                const SizedBox(height: AppSpacing.xs),
                _LegendRow(
                  color: AppColors.error,
                  label: 'Perdida',
                  value: currency.format(revenue.lost),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendRow(
      {required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label,
            style:
                AppTypography.bodySm.copyWith(color: AppColors.textSecondary)),
        const Spacer(),
        Text(value,
            style:
                AppTypography.bodySm.copyWith(color: AppColors.textPrimary)),
      ],
    );
  }
}
