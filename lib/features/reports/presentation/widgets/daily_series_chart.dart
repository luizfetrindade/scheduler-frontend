import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/reports/data/reports_model.dart';

const _weekdayAbbr = ['', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

class DailySeriesChart extends StatelessWidget {
  final List<DailyPoint> series;

  const DailySeriesChart({super.key, required this.series});

  String _label(int index) {
    final date = DateTime.tryParse(series[index].date);
    if (date == null) return '';
    final day = date.day.toString().padLeft(2, '0');
    final weekday = _weekdayAbbr[date.weekday];
    return '$weekday\n$day';
  }

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) return const SizedBox.shrink();

    final colors = context.appColors;

    final spots = series
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.count.toDouble()))
        .toList();

    final maxCount = series.map((d) => d.count).reduce((a, b) => a > b ? a : b);
    final maxY = (maxCount + 1).toDouble();

    final labelInterval = series.length > 14
        ? 7.0
        : series.length > 7
            ? 2.0
            : 1.0;

    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Agendamentos por Dia',
            style: AppTypography.bodyMd.copyWith(
                color: colors.textPrimary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: colors.surfaceHigh, strokeWidth: 1),
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
                            .copyWith(color: colors.textDisabled),
                      ),
                      interval: maxY > 4 ? (maxY / 4).ceilToDouble() : 1,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: labelInterval,
                      getTitlesWidget: (v, _) {
                        final index = v.toInt();
                        if (index < 0 || index >= series.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          _label(index),
                          textAlign: TextAlign.center,
                          style: AppTypography.caption
                              .copyWith(color: colors.textDisabled),
                        );
                      },
                    ),
                  ),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: colors.primary,
                    barWidth: 2.5,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: colors.primaryLight.withValues(alpha: 0.4),
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
