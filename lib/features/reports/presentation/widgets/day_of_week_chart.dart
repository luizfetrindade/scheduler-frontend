import 'package:flutter/material.dart';
import 'package:scheduler_frontend/features/reports/data/reports_model.dart';

class DayOfWeekChart extends StatelessWidget {
  final List<DayOfWeekPoint> data;
  const DayOfWeekChart({super.key, required this.data});

  static const _labels = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final maxCount =
        data.map((d) => d.count).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dias mais movimentados',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...data.map((d) {
          final ratio = maxCount > 0 ? d.count / maxCount : 0.0;
          final isPeak = d.count == maxCount && maxCount > 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    _labels[d.day],
                    style: TextStyle(
                      fontSize: 10,
                      color: isPeak
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 10,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(
                        isPeak
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${d.count}',
                    style: const TextStyle(fontSize: 10)),
              ],
            ),
          );
        }),
      ],
    );
  }
}
