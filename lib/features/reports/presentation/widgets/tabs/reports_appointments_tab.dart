import 'package:flutter/material.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/reports/data/reports_model.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/kpi_card_with_delta.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/status_bar_chart.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/day_of_week_chart.dart';

class ReportsAppointmentsTab extends StatelessWidget {
  final ReportsModel model;
  const ReportsAppointmentsTab({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    final appts = model.appointments;
    final occ = model.occupancy;
    final colors = context.appColors;

    if (appts.total == 0 && appts.previousTotal == 0) {
      return Center(
        child: Text(
          'Nenhum agendamento neste período',
          style: AppTypography.bodyMd.copyWith(color: colors.textSecondary),
        ),
      );
    }

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
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.35,
            children: [
              KpiCardWithDelta(
                label: 'Agendamentos',
                value: '${appts.total}',
                delta: calcDelta(
                    appts.previousTotal.toDouble(), appts.total.toDouble()),
                deltaLabel: fmtDelta(calcDelta(
                    appts.previousTotal.toDouble(), appts.total.toDouble())),
              ),
              KpiCardWithDelta(
                label: 'Cancelamentos',
                value:
                    '${(appts.cancellationRate * 100).toStringAsFixed(1)}%',
                delta: -(appts.cancellationRate -
                    appts.previousCancellationRate),
                deltaLabel: fmtDelta(-(appts.cancellationRate -
                    appts.previousCancellationRate)),
              ),
              KpiCardWithDelta(
                label: 'No-show',
                value: '${(appts.noShowRate * 100).toStringAsFixed(1)}%',
                delta: -(appts.noShowRate - appts.previousNoShowRate),
                deltaLabel: fmtDelta(
                    -(appts.noShowRate - appts.previousNoShowRate)),
              ),
              KpiCardWithDelta(
                label: 'Ocupação',
                value:
                    '${(occ.occupancyRate * 100).toStringAsFixed(1)}%',
                delta: occ.occupancyRate - occ.previousOccupancyRate,
                deltaLabel: fmtDelta(
                    occ.occupancyRate - occ.previousOccupancyRate),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _OccupancyBar(occ: occ),
          const SizedBox(height: AppSpacing.lg),
          StatusBarChart(appointments: appts),
          const SizedBox(height: AppSpacing.lg),
          _PeakHoursCard(occ: occ),
          const SizedBox(height: AppSpacing.lg),
          DayOfWeekChart(data: appts.byDayOfWeek),
        ],
      ),
    );
  }
}

class _OccupancyBar extends StatelessWidget {
  final OccupancyReport occ;
  const _OccupancyBar({required this.occ});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BaseCard(
      padding: AppSpacing.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Taxa de Ocupação',
                style: AppTypography.bodySm.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(occ.occupancyRate * 100).round()}%',
                style: AppTypography.bodySm.copyWith(
                  color: occ.occupancyRate < 0.6
                      ? AppColors.error
                      : AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            height: 8,
            color: colors.surfaceHigh,
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: occ.occupancyRate.clamp(0.0, 1.0),
              child: Container(
                height: 8,
                color: occ.occupancyRate < 0.6
                    ? AppColors.error
                    : colors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${occ.totalBooked} de ${occ.totalSlotsAvailable} slots ocupados',
            style: AppTypography.caption.copyWith(
              color: colors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeakHoursCard extends StatelessWidget {
  final OccupancyReport occ;
  const _PeakHoursCard({required this.occ});

  @override
  Widget build(BuildContext context) {
    if (occ.peakHours.isEmpty) return const SizedBox.shrink();
    final colors = context.appColors;
    final maxCount =
        occ.peakHours.first.count > 0 ? occ.peakHours.first.count : 1;

    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Horários de pico',
            style: AppTypography.bodyMd.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...occ.peakHours.take(5).map(
            (h) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${h.hour.toString().padLeft(2, '0')}h',
                      style: AppTypography.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 8,
                      color: colors.surfaceHigh,
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor:
                            (h.count / maxCount).clamp(0.0, 1.0),
                        child: Container(
                          height: 8,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${h.count}',
                      style: AppTypography.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
