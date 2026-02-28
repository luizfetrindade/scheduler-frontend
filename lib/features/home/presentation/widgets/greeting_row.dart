import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';

class GreetingRow extends StatelessWidget {
  final String firstName;

  const GreetingRow({super.key, required this.firstName});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, d MMM', 'pt_BR').format(DateTime.now());
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$_greeting, $firstName!',
          style: AppTypography.headingMd,
        ),
        Text(dateStr, style: AppTypography.caption),
      ],
    );
  }
}
