import 'package:flutter/material.dart';

abstract final class AppColors {
  // Iron Gray (light theme palette)
  static const Color kCharcoal          = Color(0xFF3D3935);
  static const Color kLinen             = Color(0xFFFAF8F5);
  static const Color kLinenDeep         = Color(0xFFF0EDE8);
  static const Color kEspresso          = Color(0xFF1A1512);
  static const Color kBark              = Color(0xFF6B5E52);
  static const Color kTaupe             = Color(0xFFA89B8C);
  static const Color kParchment         = Color(0xFFE8E3DC);
  static const Color kParchmentDeep     = Color(0xFFD4CCC4);
  static const Color kCharcoalContainer = Color(0xFFEDEAE7);
  static const Color kWarmNeutral       = Color(0xFFF5F2EE);

  // Ivory Ink (dark theme palette)
  static const Color kCream         = Color(0xFFF2EBE0);
  static const Color kSmoke         = Color(0xFF251E19);
  static const Color kSmokeDeep     = Color(0xFF2D2520);
  static const Color kEspressoDeep  = Color(0xFF221A14);
  static const Color kWarmContainer = Color(0xFF332B25);
  static const Color kTextWarm      = Color(0xFFF0EBE5);
  static const Color kAsh           = Color(0xFFA89B8C);
  static const Color kSlate         = Color(0xFF7A6E64);
  static const Color kEmber         = Color(0xFF3A302A);

  // Semantic — kept as-is
  static const Color error   = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);
  static const Color blocked = Color(0xFF64748B);
}
