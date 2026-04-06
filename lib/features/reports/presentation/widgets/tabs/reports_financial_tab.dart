import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/reports/data/reports_model.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/kpi_card_with_delta.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/daily_series_chart.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/top_services_list.dart';

class ReportsFinancialTab extends StatelessWidget {
  final ReportsModel model;
  const ReportsFinancialTab({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    final rev = model.revenue;
    final colors = context.appColors;

    if (rev.realized == 0 &&
        rev.confirmed == 0 &&
        rev.previousRealized == 0 &&
        rev.previousConfirmed == 0) {
      return Center(
        child: Text(
          'Sem receita registrada neste período',
          style: AppTypography.bodyMd.copyWith(color: colors.textSecondary),
        ),
      );
    }

    final currencyFmt =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    double calcDelta(double prev, double curr) =>
        prev > 0 ? (curr - prev) / prev : 0.0;
    String fmtDelta(double d) {
      final pct = (d * 100).abs().toStringAsFixed(1);
      return d >= 0 ? '+$pct%' : '-$pct%';
    }

    final dailyAsCount = rev.revenueDailySeries
        .map((p) => DailyPoint(date: p.date, count: p.amount.round()))
        .toList();

    final realizedDelta = calcDelta(rev.previousRealized, rev.realized);
    final confirmedDelta = calcDelta(rev.previousConfirmed, rev.confirmed);
    final lostDelta = calcDelta(rev.previousLost, rev.lost);
    final ticketDelta =
        calcDelta(rev.previousAverageTicket, rev.averageTicket);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BaseCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Receita',
                  style: AppTypography.bodyMd.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _RevenueRow(
                  label: 'Realizada',
                  value: currencyFmt.format(rev.realized),
                  delta: realizedDelta,
                  deltaLabel: fmtDelta(realizedDelta),
                ),
                Divider(color: colors.outline, height: AppSpacing.lg),
                _RevenueRow(
                  label: 'Confirmada',
                  value: currencyFmt.format(rev.confirmed),
                  delta: confirmedDelta,
                  deltaLabel: fmtDelta(confirmedDelta),
                ),
                Divider(color: colors.outline, height: AppSpacing.lg),
                _RevenueRow(
                  label: 'Perdida',
                  value: currencyFmt.format(rev.lost),
                  delta: lostDelta,
                  deltaLabel: fmtDelta(lostDelta),
                  invertDelta: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          KpiCardWithDelta(
            label: 'Ticket Médio / Agend.',
            value: currencyFmt.format(rev.averageTicket),
            delta: ticketDelta,
            deltaLabel: fmtDelta(ticketDelta),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (dailyAsCount.isNotEmpty)
            DailySeriesChart(
              series: dailyAsCount,
              title: 'Evolução da Receita (R\$)',
            ),
          const SizedBox(height: AppSpacing.lg),
          TopServicesList(services: rev.topServices),
        ],
      ),
    );
  }
}

class _RevenueRow extends StatelessWidget {
  final String label;
  final String value;
  final double delta;
  final String deltaLabel;
  final bool invertDelta;

  const _RevenueRow({
    required this.label,
    required this.value,
    required this.delta,
    required this.deltaLabel,
    this.invertDelta = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isPositive = invertDelta ? delta <= 0 : delta >= 0;
    final deltaColor = isPositive ? AppColors.success : AppColors.error;
    final arrow = delta >= 0 ? '↑' : '↓';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.bodyMd.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (deltaLabel.isNotEmpty)
          Text(
            '$arrow $deltaLabel',
            style: AppTypography.caption.copyWith(
              color: deltaColor,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}
