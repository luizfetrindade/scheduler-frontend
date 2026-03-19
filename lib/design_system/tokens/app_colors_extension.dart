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
  });

  static AppColorsExtension light() => const AppColorsExtension(
        background:        Color(0xFFFAF8F5), // Linen
        surface:           Color(0xFFFFFFFF), // White
        surfaceHigh:       Color(0xFFF5F2EE), // WarmNeutral
        primary:           Color(0xFF3D3935), // Charcoal
        primaryLight:      Color(0xFFEDEAE7), // CharcoalContainer
        primaryDark:       Color(0xFF1A1512), // Espresso
        textPrimary:       Color(0xFF1A1512), // Espresso
        textSecondary:     Color(0xFF6B5E52), // Bark
        textDisabled:      Color(0xFFA89B8C), // Taupe
        outline:           Color(0xFFE8E3DC), // Parchment
        sidebarBackground: Color(0xFF3D3935), // Charcoal
        sidebarForeground: Color(0xFFFAF8F5), // Linen
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
