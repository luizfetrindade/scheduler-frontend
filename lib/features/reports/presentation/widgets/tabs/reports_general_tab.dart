import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
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
    final colors = context.appColors;

    if (appts.total == 0 &&
        appts.previousTotal == 0 &&
        rev.previousRealized == 0) {
      return Center(
        child: Text(
          'Nenhum agendamento neste período',
          style: AppTypography.bodyMd.copyWith(color: colors.textSecondary),
        ),
      );
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HealthScoreCard(
            score: score,
            badges: _scoreBadges(score, revenueDelta, clients),
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
                label: 'Receita Realizada',
                value: currencyFmt.format(rev.realized),
                delta: revenueDelta,
                deltaLabel: _deltaLabel(revenueDelta),
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
              ),
              KpiCardWithDelta(
                label: 'Taxa de Ocupação',
                value: pctFmt(occ.occupancyRate),
                delta: occ.occupancyRate - occ.previousOccupancyRate,
                deltaLabel: _deltaLabel(
                    occ.occupancyRate - occ.previousOccupancyRate),
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
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SmartAlertsList(alerts: alerts),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: BaseCard(
                  padding: AppSpacing.md,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Receita perdida',
                        style: AppTypography.caption.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        currencyFmt.format(rev.lost),
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: BaseCard(
                  padding: AppSpacing.md,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Taxa de retorno',
                        style: AppTypography.caption.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        pctFmt(clients.returnRate),
                        style: AppTypography.bodyMd.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
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
}
