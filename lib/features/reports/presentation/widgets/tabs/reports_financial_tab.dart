import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    if (rev.realized == 0 && rev.confirmed == 0 && rev.previousRealized == 0 && rev.previousConfirmed == 0) {
      return const Center(
          child: Text('Sem receita registrada neste período'));
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _revenueBlock(
                  context,
                  'Realizada',
                  currencyFmt.format(rev.realized),
                  calcDelta(rev.previousRealized, rev.realized),
                  fmtDelta,
                  Colors.green.shade400,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _revenueBlock(
                  context,
                  'Confirmada',
                  currencyFmt.format(rev.confirmed),
                  calcDelta(rev.previousConfirmed, rev.confirmed),
                  fmtDelta,
                  Colors.blue.shade400,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _revenueBlock(
                  context,
                  'Perdida',
                  currencyFmt.format(rev.lost),
                  calcDelta(rev.previousLost, rev.lost),
                  fmtDelta,
                  Colors.red.shade400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          KpiCardWithDelta(
            label: 'Ticket Médio / Agend.',
            value: currencyFmt.format(rev.averageTicket),
            delta: calcDelta(rev.previousAverageTicket, rev.averageTicket),
            deltaLabel: fmtDelta(
                calcDelta(rev.previousAverageTicket, rev.averageTicket)),
            accentColor: Colors.teal.shade400,
          ),
          const SizedBox(height: 16),
          if (dailyAsCount.isNotEmpty)
            DailySeriesChart(
                series: dailyAsCount, title: 'Evolução da Receita (R\$)'),
          const SizedBox(height: 16),
          TopServicesList(services: rev.topServices),
        ],
      ),
    );
  }

  Widget _revenueBlock(
    BuildContext context,
    String label,
    String value,
    double d,
    String Function(double) fmtDelta,
    Color color,
  ) {
    final isPos = d >= 0;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border(top: BorderSide(color: color, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 9, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13)),
          Text(
            fmtDelta(d),
            style: TextStyle(
              fontSize: 10,
              color:
                  isPos ? Colors.green.shade400 : Colors.red.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
