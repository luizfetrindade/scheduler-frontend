import 'package:flutter/material.dart';
import 'package:scheduler_frontend/features/reports/utils/smart_alerts.dart';

class SmartAlertsList extends StatelessWidget {
  final List<ReportAlert> alerts;
  const SmartAlertsList({super.key, required this.alerts});

  Color _bgColor(AlertSeverity s) => switch (s) {
        AlertSeverity.high => Colors.red.shade900.withValues(alpha: 0.2),
        AlertSeverity.medium => Colors.orange.shade900.withValues(alpha: 0.2),
        AlertSeverity.positive => Colors.green.shade900.withValues(alpha: 0.2),
      };

  Color _borderColor(AlertSeverity s) => switch (s) {
        AlertSeverity.high => Colors.red.shade400,
        AlertSeverity.medium => Colors.orange.shade400,
        AlertSeverity.positive => Colors.green.shade400,
      };

  String _icon(AlertSeverity s) => switch (s) {
        AlertSeverity.high => '⚠️',
        AlertSeverity.medium => '💡',
        AlertSeverity.positive => '🏆',
      };

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alertas do período',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...alerts.map(
          (a) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _bgColor(a.severity),
              borderRadius: BorderRadius.circular(8),
              border: Border(
                  left: BorderSide(color: _borderColor(a.severity), width: 3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_icon(a.severity), style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.message,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        a.detail,
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
