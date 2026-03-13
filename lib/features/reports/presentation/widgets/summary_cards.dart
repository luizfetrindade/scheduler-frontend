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

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.4,
      children: [
        _KpiCard(
          label: 'Agendamentos',
          value: data.appointments.total.toString(),
          icon: Icons.calendar_month_outlined,
          iconColor: AppColors.purple300,
        ),
        _KpiCard(
          label: 'Receita Realizada',
          value: currency.format(data.revenue.realized),
          icon: Icons.attach_money_outlined,
          iconColor: AppColors.success,
        ),
        _KpiCard(
          label: 'Cancelamentos',
          value: pct.format(data.appointments.cancellationRate),
          icon: Icons.cancel_outlined,
          iconColor: AppColors.error,
        ),
        _KpiCard(
          label: 'Ocupação',
          value: pct.format(data.occupancy.occupancyRate),
          icon: Icons.donut_large_outlined,
          iconColor: AppColors.purple500,
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
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: iconColor, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: AppTypography.headingMd
                      .copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(label,
                  style: AppTypography.bodySm
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}
