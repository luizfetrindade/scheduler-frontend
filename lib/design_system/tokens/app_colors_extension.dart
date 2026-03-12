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
    required this.sidebarBackground,
    required this.sidebarForeground,
  });

  static AppColorsExtension dark() => const AppColorsExtension(
        background:        Color(0xFF0D0D0D),
        surface:           Color(0xFF1A1A1A),
        surfaceHigh:       Color(0xFF242424),
        primary:           Color(0xFFA855F7),
        primaryLight:      Color(0xFFC084FC),
        primaryDark:       Color(0xFF7E22CE),
        textPrimary:       Color(0xFFF5F5F5),
        textSecondary:     Color(0xFFA3A3A3),
        textDisabled:      Color(0xFF525252),
        sidebarBackground: Color(0xFF1A1A1A),
        sidebarForeground: Color(0xFFA3A3A3),
      );

  static AppColorsExtension light() => const AppColorsExtension(
        background:        Color(0xFFDAD7CD),
        surface:           Color(0xFFBEC8B2),
        surfaceHigh:       Color(0xFFA3B18A),
        primary:           Color(0xFF588157),
        primaryLight:      Color(0xFFA3B18A),
        primaryDark:       Color(0xFF3A5A40),
        textPrimary:       Color(0xFF2D4A35),
        textSecondary:     Color(0xFF3A5A40),
        textDisabled:      Color(0xFF7A9A7A),
        sidebarBackground: Color(0xFF4A5759),
        sidebarForeground: Color(0xFFDAD7CD),
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
