import 'package:flutter/material.dart';
import 'package:scheduler_frontend/design_system/tokens/app_colors_extension.dart';

abstract final class AppTheme {
  static ThemeData dark() => ThemeData(
        fontFamily: 'Lexend',
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFA855F7),
          surface: Color(0xFF1A1A1A),
          onSurface: Color(0xFFF5F5F5),
        ),
        extensions: [AppColorsExtension.dark()],
      );

  static ThemeData light() => ThemeData(
        fontFamily: 'Lexend',
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFDAD7CD),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF588157),
          surface: Color(0xFFBEC8B2),
          onSurface: Color(0xFF2D4A35),
        ),
        extensions: [AppColorsExtension.light()],
      );
}
