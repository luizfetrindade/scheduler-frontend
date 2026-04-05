import 'package:flutter/material.dart';
import 'package:scheduler_frontend/core/utils/password_strength.dart';
import 'package:scheduler_frontend/design_system/tokens/app_colors.dart';
import 'package:scheduler_frontend/design_system/tokens/app_spacing.dart';
import 'package:scheduler_frontend/design_system/tokens/app_typography.dart';

/// Displays a colour-coded strength bar and a checklist of password rules.
///
/// Intended to be placed directly below the password [TextField].
/// Re-renders reactively as [password] changes.
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final level = PasswordStrength.level(password);
    final score = PasswordStrength.score(password);
    final total = PasswordStrength.rules.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.sm),
        _StrengthBar(score: score, total: total, level: level),
        const SizedBox(height: AppSpacing.sm),
        ...PasswordStrength.rules.map(
          (rule) => _RuleRow(label: rule.label, met: rule.check(password)),
        ),
      ],
    );
  }
}

class _StrengthBar extends StatelessWidget {
  final int score;
  final int total;
  final PasswordStrengthLevel level;

  const _StrengthBar({
    required this.score,
    required this.total,
    required this.level,
  });

  Color get _color => switch (level) {
        PasswordStrengthLevel.weak => AppColors.error,
        PasswordStrengthLevel.medium => const Color(0xFFF59E0B),
        PasswordStrengthLevel.strong => AppColors.success,
      };

  String get _label => switch (level) {
        PasswordStrengthLevel.weak => 'Fraca',
        PasswordStrengthLevel.medium => 'Média',
        PasswordStrengthLevel.strong => 'Forte',
      };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / total,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(_color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          _label,
          style: AppTypography.bodySm.copyWith(
            color: _color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RuleRow extends StatelessWidget {
  final String label;
  final bool met;

  const _RuleRow({required this.label, required this.met});

  @override
  Widget build(BuildContext context) {
    final color = met ? AppColors.success : Colors.grey.shade500;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_outline : Icons.radio_button_unchecked,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.bodySm.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
