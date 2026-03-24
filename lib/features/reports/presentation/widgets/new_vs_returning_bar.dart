import 'package:flutter/material.dart';

class NewVsReturningBar extends StatelessWidget {
  final int newClients;
  final int returningClients;
  const NewVsReturningBar(
      {super.key, required this.newClients, required this.returningClients});

  @override
  Widget build(BuildContext context) {
    final total = newClients + returningClients;
    if (total == 0) return const SizedBox.shrink();
    final newPct = newClients / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Novos vs. Recorrentes',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: [
              Expanded(
                flex: (newPct * 100).round(),
                child: Container(height: 16, color: const Color(0xFF7c3aed)),
              ),
              Expanded(
                flex: ((1 - newPct) * 100).round(),
                child: Container(height: 16, color: const Color(0xFF16a34a)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$newClients novos (${(newPct * 100).round()}%)',
              style:
                  const TextStyle(fontSize: 11, color: Color(0xFF7c3aed)),
            ),
            Text(
              '$returningClients recorrentes (${((1 - newPct) * 100).round()}%)',
              style:
                  const TextStyle(fontSize: 11, color: Color(0xFF16a34a)),
            ),
          ],
        ),
      ],
    );
  }
}
