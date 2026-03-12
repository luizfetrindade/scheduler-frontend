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
        scaffoldBackgroundColor: const Color(0xFFF3E3D0),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF81A6C6),
          surface: Color(0xFFD2C4B4),
          onSurface: Color(0xFF81A6C6),
        ),
        extensions: [AppColorsExtension.light()],
      );
}
