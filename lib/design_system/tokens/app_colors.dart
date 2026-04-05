import 'package:flutter/material.dart';

abstract final class AppColors {
  // Iron Gray (light theme palette)
  static const Color kWhite             = Color(0xFFFFFFFF);
  static const Color kCharcoal          = Color(0xFF3D3935);
  static const Color kLinen             = Color(0xFFFAF8F5);
  static const Color kLinenDeep         = Color(0xFFF0EDE8);
  static const Color kEspresso          = Color(0xFF1A1512);
  static const Color kBark              = Color(0xFF6B5E52);
  static const Color kTaupe             = Color(0xFFA89B8C); // same value as kAsh — intentional, palettes coincide here
  static const Color kParchment         = Color(0xFFDDD7CE);
  static const Color kParchmentDeep     = Color(0xFFD4CCC4);
  static const Color kCharcoalContainer = Color(0xFFEDEAE7);
  static const Color kWarmNeutral       = Color(0xFFF5F2EE);

  // Ivory Ink (dark theme palette) — neutralized to reduce reddish cast
  static const Color kNightBase     = Color(0xFF1C1B1A); // main dark background
  static const Color kCream         = Color(0xFFF2EBE0);
  static const Color kSmoke         = Color(0xFF252322);
  static const Color kSmokeDeep     = Color(0xFF2D2B2A);
  static const Color kEspressoDeep  = Color(0xFF1E1D1C);
  static const Color kWarmContainer = Color(0xFF312F2E);
  static const Color kTextWarm      = Color(0xFFF0EBE5);
  static const Color kAsh           = Color(0xFFA89B8C); // same value as kTaupe — intentional, palettes coincide here
  static const Color kSlate         = Color(0xFF7A6E64);
  static const Color kEmber         = Color(0xFF383635);

  // Semantic — kept as-is
  static const Color error   = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);
  static const Color blocked = Color(0xFF64748B);
}
