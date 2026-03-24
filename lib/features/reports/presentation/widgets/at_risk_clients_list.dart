import 'package:flutter/material.dart';
import 'package:scheduler_frontend/features/reports/data/reports_model.dart';

class AtRiskClientsList extends StatelessWidget {
  final List<AtRiskClient> clients;
  const AtRiskClientsList({super.key, required this.clients});

  @override
  Widget build(BuildContext context) {
    if (clients.isEmpty) return const SizedBox.shrink();
    final preview = clients.take(2).toList();
    final hasMore = clients.length > 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Clientes para reativar',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.shade900,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${clients.length} clientes',
                style:
                    const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...preview.map(
          (c) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.name,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      if (c.lastServiceName != null)
                        Text(
                          'Último: ${c.lastServiceName}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '${c.daysSinceLastVisit} dias',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: c.daysSinceLastVisit > 90
                        ? Colors.red.shade400
                        : Colors.orange.shade400,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '+ ${clients.length - 2} clientes inativos...',
              style: TextStyle(
                fontSize: 11,
                color:
                    Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
