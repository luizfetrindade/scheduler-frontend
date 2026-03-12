import 'package:flutter/material.dart';

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color background;
  final Color surface;
  final Color surfaceHigh;
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;

  const AppColorsExtension({
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
  });

  static AppColorsExtension dark() => const AppColorsExtension(
        background:    Color(0xFF0D0D0D),
        surface:       Color(0xFF1A1A1A),
        surfaceHigh:   Color(0xFF242424),
        primary:       Color(0xFFA855F7),
        primaryLight:  Color(0xFFC084FC),
        primaryDark:   Color(0xFF7E22CE),
        textPrimary:   Color(0xFFF5F5F5),
        textSecondary: Color(0xFFA3A3A3),
        textDisabled:  Color(0xFF525252),
      );

  static AppColorsExtension light() => const AppColorsExtension(
        background:    Color(0xFFF3E3D0),
        surface:       Color(0xFFD2C4B4),
        surfaceHigh:   Color(0xFFBFB3A4),
        primary:       Color(0xFF81A6C6),
        primaryLight:  Color(0xFFAACDDC),
        primaryDark:   Color(0xFF5A8BAD),
        textPrimary:   Color(0xFF2C1E14),
        textSecondary: Color(0xFF7A6B5A),
        textDisabled:  Color(0xFFB0A090),
      );

  @override
  AppColorsExtension copyWith({
    Color? background,
    Color? surface,
    Color? surfaceHigh,
    Color? primary,
    Color? primaryLight,
    Color? primaryDark,
    Color? textPrimary,
    Color? textSecondary,
    Color? textDisabled,
  }) =>
      AppColorsExtension(
        background:    background    ?? this.background,
        surface:       surface       ?? this.surface,
        surfaceHigh:   surfaceHigh   ?? this.surfaceHigh,
        primary:       primary       ?? this.primary,
        primaryLight:  primaryLight  ?? this.primaryLight,
        primaryDark:   primaryDark   ?? this.primaryDark,
        textPrimary:   textPrimary   ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textDisabled:  textDisabled  ?? this.textDisabled,
      );

  @override
  AppColorsExtension lerp(AppColorsExtension? other, double t) {
    if (other == null) return this;
    return AppColorsExtension(
      background:    Color.lerp(background,    other.background,    t)!,
      surface:       Color.lerp(surface,       other.surface,       t)!,
      surfaceHigh:   Color.lerp(surfaceHigh,   other.surfaceHigh,   t)!,
      primary:       Color.lerp(primary,       other.primary,       t)!,
      primaryLight:  Color.lerp(primaryLight,  other.primaryLight,  t)!,
      primaryDark:   Color.lerp(primaryDark,   other.primaryDark,   t)!,
      textPrimary:   Color.lerp(textPrimary,   other.textPrimary,   t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textDisabled:  Color.lerp(textDisabled,  other.textDisabled,  t)!,
    );
  }
}

extension AppColorsX on BuildContext {
  AppColorsExtension get appColors =>
      Theme.of(this).extension<AppColorsExtension>()!;
}
