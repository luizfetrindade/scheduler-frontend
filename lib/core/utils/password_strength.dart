/// Password strength rules and scoring.
///
/// Each [PasswordRule] describes one requirement. [PasswordStrength] aggregates
/// all rules and exposes a [level] so callers can block weak passwords.
library;

enum PasswordStrengthLevel { weak, medium, strong }

class PasswordRule {
  final String label;
  final bool Function(String) check;

  const PasswordRule({required this.label, required this.check});
}

abstract final class PasswordStrength {
  static final List<PasswordRule> rules = [
    PasswordRule(
      label: 'Mínimo de 8 caracteres',
      check: (p) => p.length >= 8,
    ),
    PasswordRule(
      label: 'Uma letra maiúscula',
      check: (p) => p.contains(RegExp(r'[A-Z]')),
    ),
    PasswordRule(
      label: 'Uma letra minúscula',
      check: (p) => p.contains(RegExp(r'[a-z]')),
    ),
    PasswordRule(
      label: 'Um número',
      check: (p) => p.contains(RegExp(r'[0-9]')),
    ),
    PasswordRule(
      label: 'Um caractere especial (!@#\$%^&*)',
      check: (p) => p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]')),
    ),
  ];

  /// Number of rules [password] satisfies.
  static int score(String password) =>
      rules.where((r) => r.check(password)).length;

  /// Strength level derived from the score.
  static PasswordStrengthLevel level(String password) {
    final s = score(password);
    if (s <= 2) return PasswordStrengthLevel.weak;
    if (s <= 4) return PasswordStrengthLevel.medium;
    return PasswordStrengthLevel.strong;
  }

  /// Returns true only when all rules are satisfied.
  static bool isStrong(String password) =>
      level(password) == PasswordStrengthLevel.strong;
}
