import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/reports/data/reports_model.dart';

class StatusBarChart extends StatelessWidget {
  final AppointmentsReport appointments;

  const StatusBarChart({super.key, required this.appointments});

  static const _statusOrder = [
    'COMPLETED', 'CONFIRMED', 'PENDING', 'CANCELLED', 'NO_SHOW'
  ];
  static const _statusLabels = {
    'COMPLETED': 'Concluído',
    'CONFIRMED': 'Confirmado',
    'PENDING': 'Pendente',
    'CANCELLED': 'Cancelado',
    'NO_SHOW': 'Não comp.',
  };
  static const _statusColors = {
    'COMPLETED': AppColors.success,
    'CONFIRMED': AppColors.purple300,
    'PENDING': Color(0xFFFBBF24),
    'CANCELLED': AppColors.error,
    'NO_SHOW': AppColors.blocked,
  };

  @override
  Widget build(BuildContext context) {
    final entries = _statusOrder
        .where((s) => (appointments.byStatus[s] ?? 0) > 0)
        .toList();

    if (entries.isEmpty) return const SizedBox.shrink();

    final barGroups = entries.asMap().entries.map((e) {
      final status = e.value;
      final count = (appointments.byStatus[status] ?? 0).toDouble();
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: count,
            color: _statusColors[status] ?? AppColors.purple500,
            width: 24,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    final maxY = entries
            .map((s) => (appointments.byStatus[s] ?? 0).toDouble())
            .reduce((a, b) => a > b ? a : b) +
        1;

    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Por Status',
            style: AppTypography.bodyMd.copyWith(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: AppColors.surfaceHigh, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx >= entries.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _statusLabels[entries[idx]] ?? entries[idx],
                            style: AppTypography.caption
                                .copyWith(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                      reservedSize: 32,
                    ),
                  ),
                  leftTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
