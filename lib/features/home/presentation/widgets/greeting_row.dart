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
    final accent = context.appColors.accent;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        RichText(
          text: TextSpan(
            style: AppTypography.headingMd.copyWith(
              color: context.appColors.textPrimary,
            ),
            children: [
              TextSpan(text: '$_greeting, '),
              TextSpan(
                text: firstName,
                style: TextStyle(color: accent),
              ),
              const TextSpan(text: '!'),
            ],
          ),
        ),
        Text(dateStr, style: AppTypography.caption),
      ],
    );
  }
}
