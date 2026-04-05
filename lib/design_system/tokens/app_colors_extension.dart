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
  final Color outline;
  final Color sidebarBackground;
  final Color sidebarForeground;
  final Color accent;

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
    required this.outline,
    required this.sidebarBackground,
    required this.sidebarForeground,
    required this.accent,
  });

  static AppColorsExtension light() => const AppColorsExtension(
        background:        Color(0xFFF8F6F2), // Warm off-white
        surface:           Color(0xFFFFFFFF), // White
        surfaceHigh:       Color(0xFFF2EFEA), // WarmNeutral
        primary:           Color(0xFF2C2825), // Deeper charcoal for better contrast
        primaryLight:      Color(0xFFEDEAE7), // CharcoalContainer
        primaryDark:       Color(0xFF1A1512), // Espresso
        textPrimary:       Color(0xFF1C1816), // Near-black warm
        textSecondary:     Color(0xFF5C5047), // Deeper bark for better readability
        textDisabled:      Color(0xFF9A8E80), // Warmer taupe
        outline:           Color(0xFFD5CEC5), // Stronger border
        sidebarBackground: Color(0xFF2C2825), // Match primary
        sidebarForeground: Color(0xFFF8F6F2), // Match background
        accent:            Color(0xFF4A7A2E), // More vibrant green
      );

  static AppColorsExtension dark() => const AppColorsExtension(
        background:        Color(0xFF1C1B1A), // neutralized — less reddish
        surface:           Color(0xFF252322), // Smoke — neutralized
        surfaceHigh:       Color(0xFF2D2B2A), // SmokeDeep — neutralized
        primary:           Color(0xFFF2EBE0), // Cream
        primaryLight:      Color(0xFF312F2E), // WarmContainer — neutralized
        primaryDark:       Color(0xFFF0EBE5), // TextWarm
        textPrimary:       Color(0xFFF0EBE5), // TextWarm
        textSecondary:     Color(0xFFA89B8C), // Ash
        textDisabled:      Color(0xFF7A6E64), // Slate
        outline:           Color(0xFF383635), // Ember — neutralized
        sidebarBackground: Color(0xFF1E1D1C), // EspressoDeep — neutralized
        sidebarForeground: Color(0xFFF0EBE5), // TextWarm
        accent:            Color(0xFF6A7C5E), // SageGreen
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
    Color? outline,
    Color? sidebarBackground,
    Color? sidebarForeground,
    Color? accent,
  }) =>
      AppColorsExtension(
        background:        background        ?? this.background,
        surface:           surface           ?? this.surface,
        surfaceHigh:       surfaceHigh       ?? this.surfaceHigh,
        primary:           primary           ?? this.primary,
        primaryLight:      primaryLight      ?? this.primaryLight,
        primaryDark:       primaryDark       ?? this.primaryDark,
        textPrimary:       textPrimary       ?? this.textPrimary,
        textSecondary:     textSecondary     ?? this.textSecondary,
        textDisabled:      textDisabled      ?? this.textDisabled,
        outline:           outline           ?? this.outline,
        sidebarBackground: sidebarBackground ?? this.sidebarBackground,
        sidebarForeground: sidebarForeground ?? this.sidebarForeground,
        accent:            accent            ?? this.accent,
      );

  @override
  AppColorsExtension lerp(AppColorsExtension? other, double t) {
    if (other == null) return this;
    return AppColorsExtension(
      background:        Color.lerp(background,        other.background,        t)!,
      surface:           Color.lerp(surface,           other.surface,           t)!,
      surfaceHigh:       Color.lerp(surfaceHigh,       other.surfaceHigh,       t)!,
      primary:           Color.lerp(primary,           other.primary,           t)!,
      primaryLight:      Color.lerp(primaryLight,      other.primaryLight,      t)!,
      primaryDark:       Color.lerp(primaryDark,       other.primaryDark,       t)!,
      textPrimary:       Color.lerp(textPrimary,       other.textPrimary,       t)!,
      textSecondary:     Color.lerp(textSecondary,     other.textSecondary,     t)!,
      textDisabled:      Color.lerp(textDisabled,      other.textDisabled,      t)!,
      outline:           Color.lerp(outline,           other.outline,           t)!,
      sidebarBackground: Color.lerp(sidebarBackground, other.sidebarBackground, t)!,
      sidebarForeground: Color.lerp(sidebarForeground, other.sidebarForeground, t)!,
      accent:            Color.lerp(accent,            other.accent,            t)!,
    );
  }
}

extension AppColorsX on BuildContext {
  AppColorsExtension get appColors {
    final ext = Theme.of(this).extension<AppColorsExtension>();
    assert(
      ext != null,
      'AppColorsExtension not found in Theme. '
      'Register it via ThemeData(extensions: [AppColorsExtension.dark()]) '
      'or use AppTheme.dark()/AppTheme.light().',
    );
    return ext!;
  }
}
