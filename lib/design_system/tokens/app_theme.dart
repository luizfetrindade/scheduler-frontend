import 'package:flutter/material.dart';
import 'package:scheduler_frontend/design_system/tokens/app_colors.dart';
import 'package:scheduler_frontend/design_system/tokens/app_colors_extension.dart';
import 'package:scheduler_frontend/design_system/tokens/app_radius.dart';
import 'package:scheduler_frontend/design_system/tokens/app_typography.dart';

abstract final class AppTheme {
  static ThemeData light() => ThemeData(
        useMaterial3: true,
        fontFamily: 'Lexend',
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.kLinen,
        colorScheme: const ColorScheme.light(
          surface: AppColors.kWhite,
          onSurface: AppColors.kEspresso,
          surfaceContainerHighest: AppColors.kWarmNeutral,
          primary: AppColors.kCharcoal,
          onPrimary: AppColors.kWhite,
          primaryContainer: AppColors.kCharcoalContainer,
          onPrimaryContainer: AppColors.kCharcoal,
          secondary: AppColors.kBark,
          onSecondary: AppColors.kWhite,
          secondaryContainer: AppColors.kWarmNeutral,
          onSecondaryContainer: AppColors.kEspresso,
          tertiary: AppColors.kTaupe,
          outline: AppColors.kParchment,
          outlineVariant: AppColors.kParchmentDeep,
          onSurfaceVariant: AppColors.kBark,
        ),
        textTheme: const TextTheme(
          displayLarge: AppTypography.displayLg,
          headlineLarge: AppTypography.headingMd,
          titleLarge: AppTypography.titleLarge,
          bodyLarge: AppTypography.bodyMd,
          bodyMedium: AppTypography.bodySm,
          labelLarge: AppTypography.labelLarge,
          bodySmall: AppTypography.caption,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.kLinen,
          elevation: 0,
          foregroundColor: AppColors.kEspresso,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.kCharcoal,
            foregroundColor: AppColors.kWhite,
            elevation: 0,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: AppColors.kWhite,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: AppColors.kParchment),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: AppColors.kParchment),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: AppColors.kCharcoal, width: 1.5),
          ),
          labelStyle: TextStyle(color: AppColors.kBark),
          hintStyle: TextStyle(color: AppColors.kTaupe),
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          color: AppColors.kWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.xl)),
            side: BorderSide(color: AppColors.kParchment),
          ),
        ),
        extensions: [AppColorsExtension.light()],
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        fontFamily: 'Lexend',
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.kNightBase,
        colorScheme: const ColorScheme.dark(
          surface: AppColors.kSmoke,
          onSurface: AppColors.kTextWarm,
          surfaceContainerHighest: AppColors.kSmokeDeep,
          primary: AppColors.kCream,
          onPrimary: AppColors.kEspresso,
          primaryContainer: AppColors.kWarmContainer,
          onPrimaryContainer: AppColors.kCream,
          secondary: AppColors.kAsh,
          onSecondary: AppColors.kEspresso,
          secondaryContainer: AppColors.kSmokeDeep,
          onSecondaryContainer: AppColors.kTextWarm,
          tertiary: AppColors.kSlate,
          outline: AppColors.kEmber,
          outlineVariant: AppColors.kSmokeDeep,
          onSurfaceVariant: AppColors.kAsh,
        ),
        textTheme: const TextTheme(
          displayLarge: AppTypography.displayLg,
          headlineLarge: AppTypography.headingMd,
          titleLarge: AppTypography.titleLarge,
          bodyLarge: AppTypography.bodyMd,
          bodyMedium: AppTypography.bodySm,
          labelLarge: AppTypography.labelLarge,
          bodySmall: AppTypography.caption,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.kNightBase,
          elevation: 0,
          foregroundColor: AppColors.kTextWarm,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.kCream,
            foregroundColor: AppColors.kEspresso,
            elevation: 0,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: AppColors.kSmoke,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: AppColors.kEmber),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: AppColors.kEmber),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: AppColors.kCream, width: 1.5),
          ),
          labelStyle: TextStyle(color: AppColors.kTextWarm),  // brighter for floating label
          hintStyle:  TextStyle(color: AppColors.kAsh),       // muted for placeholder
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          color: AppColors.kSmoke,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.xl)),
            side: BorderSide(color: AppColors.kEmber),
          ),
        ),
        extensions: [AppColorsExtension.dark()],
      );
}
