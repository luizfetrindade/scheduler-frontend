import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/reports/data/reports_model.dart';

class DailySeriesChart extends StatelessWidget {
  final List<DailyPoint> series;

  const DailySeriesChart({super.key, required this.series});

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) return const SizedBox.shrink();

    final spots = series
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.count.toDouble()))
        .toList();

    final maxCount = series.map((d) => d.count).reduce((a, b) => a > b ? a : b);
    final maxY = (maxCount + 1).toDouble();

    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Agendamentos por Dia',
            style: AppTypography.bodyMd.copyWith(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: AppColors.surfaceHigh, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: AppTypography.caption
                            .copyWith(color: AppColors.textDisabled),
                      ),
                      interval: maxY > 4 ? (maxY / 4).ceilToDouble() : 1,
                    ),
                  ),
                  bottomTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.purple500,
                    barWidth: 2.5,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.purple700.withValues(alpha: 0.2),
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
