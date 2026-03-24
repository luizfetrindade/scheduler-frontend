import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scheduler_frontend/features/reports/data/reports_model.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/kpi_card_with_delta.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/new_vs_returning_bar.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/at_risk_clients_list.dart';

class ReportsClientsTab extends StatelessWidget {
  final ReportsModel model;
  const ReportsClientsTab({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    final clients = model.clients;
    if (clients.total == 0) {
      return const Center(
          child: Text('Nenhum cliente atendido neste período'));
    }

    final currencyFmt =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    double calcDelta(double prev, double curr) =>
        prev > 0 ? (curr - prev) / prev : 0.0;
    String fmtDelta(double d) {
      final pct = (d * 100).abs().toStringAsFixed(1);
      return d >= 0 ? '+$pct%' : '-$pct%';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NewVsReturningBar(
            newClients: clients.newClients,
            returningClients: clients.returningClients,
          ),
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
                label: 'Taxa de Retorno',
                value:
                    '${(clients.returnRate * 100).toStringAsFixed(1)}%',
                delta: clients.returnRate - clients.previousReturnRate,
                deltaLabel: fmtDelta(
                    clients.returnRate - clients.previousReturnRate),
                accentColor: Colors.purple.shade400,
              ),
              KpiCardWithDelta(
                label: 'Frequência Média',
                value: '${clients.averageFrequencyDays} dias',
                delta: 0,
                deltaLabel: '',
                accentColor: Colors.blue.shade400,
              ),
              KpiCardWithDelta(
                label: 'Ticket Médio / Cliente',
                value:
                    currencyFmt.format(clients.averageTicketPerClient),
                delta: calcDelta(
                    clients.previousAverageTicketPerClient,
                    clients.averageTicketPerClient),
                deltaLabel: fmtDelta(calcDelta(
                    clients.previousAverageTicketPerClient,
                    clients.averageTicketPerClient)),
                accentColor: Colors.green.shade400,
              ),
              KpiCardWithDelta(
                label: 'Clientes Ativos',
                value: '${clients.total}',
                delta: 0,
                deltaLabel: '',
                accentColor: Colors.teal.shade400,
              ),
            ],
          ),
          const SizedBox(height: 16),
          AtRiskClientsList(clients: clients.atRisk),
        ],
      ),
    );
  }
}
