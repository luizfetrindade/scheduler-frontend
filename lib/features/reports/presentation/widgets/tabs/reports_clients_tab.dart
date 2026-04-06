import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
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
    final colors = context.appColors;

    if (clients.total == 0 && clients.previousNewClients == 0) {
      return Center(
        child: Text(
          'Nenhum cliente atendido neste período',
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NewVsReturningBar(
            newClients: clients.newClients,
            returningClients: clients.returningClients,
          ),
          const SizedBox(height: AppSpacing.lg),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.35,
            children: [
              KpiCardWithDelta(
                label: 'Taxa de Retorno',
                value:
                    '${(clients.returnRate * 100).toStringAsFixed(1)}%',
                delta: clients.returnRate - clients.previousReturnRate,
                deltaLabel: fmtDelta(
                    clients.returnRate - clients.previousReturnRate),
              ),
              KpiCardWithDelta(
                label: 'Frequência Média',
                value: '${clients.averageFrequencyDays} dias',
                delta: 0,
                deltaLabel: '',
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
              ),
              KpiCardWithDelta(
                label: 'Clientes Ativos',
                value: '${clients.total}',
                delta: 0,
                deltaLabel: '',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AtRiskClientsList(clients: clients.atRisk),
        ],
      ),
    );
  }
}
