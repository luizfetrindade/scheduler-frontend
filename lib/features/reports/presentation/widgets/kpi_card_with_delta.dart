import 'package:flutter/material.dart';

class KpiCardWithDelta extends StatelessWidget {
  final String label;
  final String value;
  final double delta;
  final String deltaLabel;
  final Color accentColor;

  const KpiCardWithDelta({
    super.key,
    required this.label,
    required this.value,
    required this.delta,
    required this.deltaLabel,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = delta >= 0;
    final arrowColor =
        isPositive ? Colors.green.shade400 : Colors.red.shade400;
    final arrow = isPositive ? '↑' : '↓';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accentColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$arrow $deltaLabel',
            style: TextStyle(
              fontSize: 12,
              color: arrowColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
