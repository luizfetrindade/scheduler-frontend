import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scheduler_frontend/features/reports/data/reports_model.dart';
import 'package:scheduler_frontend/features/reports/utils/health_score.dart';
import 'package:scheduler_frontend/features/reports/utils/smart_alerts.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/health_score_card.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/smart_alerts_list.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/kpi_card_with_delta.dart';

class ReportsGeneralTab extends StatelessWidget {
  final ReportsModel model;
  const ReportsGeneralTab({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    final appts = model.appointments;
    final rev = model.revenue;
    final occ = model.occupancy;
    final clients = model.clients;

    if (appts.total == 0 && appts.previousTotal == 0 && rev.previousRealized == 0) {
      return const Center(child: Text('Nenhum agendamento neste período'));
    }

    final revenueDelta = rev.previousRealized > 0
        ? (rev.realized - rev.previousRealized) / rev.previousRealized
        : 0.0;
    final score = computeHealthScore(
      occupancyRate: occ.occupancyRate,
      revenueDelta: revenueDelta,
      clientReturnRate: clients.returnRate,
      cancellationRate: appts.cancellationRate,
      noShowRate: appts.noShowRate,
    );
    final alerts = buildAlerts(model);
    final currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    String pctFmt(double v) => '${(v * 100).toStringAsFixed(1)}%';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HealthScoreCard(
              score: score,
              badges: _scoreBadges(score, revenueDelta, clients)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.6,
            children: [
              KpiCardWithDelta(
                label: 'Receita Realizada',
                value: currencyFmt.format(rev.realized),
                delta: revenueDelta,
                deltaLabel: _deltaLabel(revenueDelta),
                accentColor: Colors.green.shade400,
              ),
              KpiCardWithDelta(
                label: 'Agendamentos',
                value: '${appts.total}',
                delta: appts.previousTotal > 0
                    ? (appts.total - appts.previousTotal) /
                        appts.previousTotal
                    : 0,
                deltaLabel: _deltaLabel(appts.previousTotal > 0
                    ? (appts.total - appts.previousTotal) /
                        appts.previousTotal
                    : 0),
                accentColor: Colors.blue.shade400,
              ),
              KpiCardWithDelta(
                label: 'Taxa de Ocupação',
                value: pctFmt(occ.occupancyRate),
                delta: occ.occupancyRate - occ.previousOccupancyRate,
                deltaLabel: _deltaLabel(
                    occ.occupancyRate - occ.previousOccupancyRate),
                accentColor: occ.occupancyRate < 0.6
                    ? Colors.red.shade400
                    : Colors.orange.shade400,
              ),
              KpiCardWithDelta(
                label: 'Clientes Novos',
                value: '${clients.newClients}',
                delta: clients.previousNewClients > 0
                    ? (clients.newClients - clients.previousNewClients) /
                        clients.previousNewClients
                    : 0,
                deltaLabel: _deltaLabel(clients.previousNewClients > 0
                    ? (clients.newClients - clients.previousNewClients) /
                        clients.previousNewClients
                    : 0),
                accentColor: Colors.purple.shade400,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SmartAlertsList(alerts: alerts),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _miniCard(
                  context,
                  label: 'Receita perdida (cancelamentos)',
                  value: currencyFmt.format(rev.lost),
                  color: Colors.red.shade400,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniCard(
                  context,
                  label: 'Taxa de retorno de clientes',
                  value: pctFmt(clients.returnRate),
                  color: Colors.purple.shade400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<String> _scoreBadges(
      double score, double revDelta, ClientsReport clients) {
    final badges = <String>[];
    if (revDelta > 0) badges.add('Receita ↑');
    if (clients.newClients > clients.previousNewClients) {
      badges.add('Clientes ↑');
    }
    return badges;
  }

  String _deltaLabel(double delta) {
    final pct = (delta * 100).abs().toStringAsFixed(1);
    return delta >= 0 ? '+$pct%' : '-$pct%';
  }

  Widget _miniCard(BuildContext context,
      {required String label,
      required String value,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }
}
