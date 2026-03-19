import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/reports/data/reports_model.dart';

class SummaryCards extends StatelessWidget {
  final ReportsModel data;

  const SummaryCards({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final pct = NumberFormat.percentPattern('pt_BR');
    final colors = context.appColors;

    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            label: 'Agendamentos',
            value: data.appointments.total.toString(),
            icon: Icons.calendar_month_outlined,
            iconColor: colors.primaryLight,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _KpiCard(
            label: 'Receita',
            value: currency.format(data.revenue.realized),
            icon: Icons.attach_money_outlined,
            iconColor: AppColors.success,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _KpiCard(
            label: 'Cancelamentos',
            value: pct.format(data.appointments.cancellationRate),
            icon: Icons.cancel_outlined,
            iconColor: AppColors.error,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _KpiCard(
            label: 'Ocupação',
            value: pct.format(data.occupancy.occupancyRate),
            icon: Icons.donut_large_outlined,
            iconColor: colors.primary,
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return BaseCard(
      padding: AppSpacing.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.bodyMd.copyWith(
                color: colors.textPrimary, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.caption
                .copyWith(color: colors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
