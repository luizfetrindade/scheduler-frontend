import 'package:flutter/material.dart';
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

    if (appts.total == 0 && appts.previousTotal == 0) {
      return const Center(child: Text('Nenhum agendamento neste período'));
    }

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
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.6,
            children: [
              KpiCardWithDelta(
                label: 'Agendamentos',
                value: '${appts.total}',
                delta: calcDelta(appts.previousTotal.toDouble(),
                    appts.total.toDouble()),
                deltaLabel: fmtDelta(calcDelta(appts.previousTotal.toDouble(),
                    appts.total.toDouble())),
                accentColor: Colors.blue.shade400,
              ),
              KpiCardWithDelta(
                label: 'Cancelamentos',
                value:
                    '${(appts.cancellationRate * 100).toStringAsFixed(1)}%',
                delta: -(appts.cancellationRate -
                    appts.previousCancellationRate),
                deltaLabel: fmtDelta(-(appts.cancellationRate -
                    appts.previousCancellationRate)),
                accentColor: Colors.red.shade400,
              ),
              KpiCardWithDelta(
                label: 'No-show',
                value:
                    '${(appts.noShowRate * 100).toStringAsFixed(1)}%',
                delta:
                    -(appts.noShowRate - appts.previousNoShowRate),
                deltaLabel: fmtDelta(
                    -(appts.noShowRate - appts.previousNoShowRate)),
                accentColor: Colors.orange.shade400,
              ),
              KpiCardWithDelta(
                label: 'Ocupação',
                value:
                    '${(occ.occupancyRate * 100).toStringAsFixed(1)}%',
                delta: occ.occupancyRate - occ.previousOccupancyRate,
                deltaLabel: fmtDelta(
                    occ.occupancyRate - occ.previousOccupancyRate),
                accentColor: occ.occupancyRate < 0.6
                    ? Colors.red.shade400
                    : Colors.green.shade400,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Taxa de Ocupação',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12)),
                    Text(
                      '${(occ.occupancyRate * 100).round()}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: occ.occupancyRate < 0.6
                            ? Colors.red.shade400
                            : Colors.orange.shade400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: occ.occupancyRate,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                Text(
                  '${occ.totalBooked} de ${occ.totalSlotsAvailable} slots ocupados',
                  style:
                      const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          StatusBarChart(appointments: appts),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Horários de pico',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 8),
                ...occ.peakHours.take(5).map(
                  (h) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 48,
                          child: Text(
                            '${h.hour.toString().padLeft(2, '0')}h',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: occ.peakHours.first.count > 0
                                ? h.count /
                                    occ.peakHours.first.count
                                : 0,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${h.count}',
                            style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          DayOfWeekChart(data: appts.byDayOfWeek),
        ],
      ),
    );
  }
}
