import 'package:flutter/material.dart';
import 'package:scheduler_frontend/features/reports/utils/health_score.dart';

class HealthScoreCard extends StatelessWidget {
  final double score;
  final List<String> badges;

  const HealthScoreCard({
    super.key,
    required this.score,
    this.badges = const [],
  });

  Color _scoreColor() {
    if (score >= 80) return Colors.green.shade400;
    if (score >= 60) return Colors.blue.shade400;
    if (score >= 40) return Colors.orange.shade400;
    return Colors.red.shade400;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _scoreColor(), width: 3),
            ),
            alignment: Alignment.center,
            child: Text(
              score.round().toString(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _scoreColor(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  healthScoreLabel(score),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: badges
                      .map(
                        (b) => Chip(
                          label: Text(
                            b,
                            style: const TextStyle(fontSize: 10),
                          ),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
