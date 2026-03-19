import 'package:flutter/material.dart';

abstract final class AppShadows {
  // Light — Iron Gray
  static const List<BoxShadow> cardLight = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2)),
  ];
  static const List<BoxShadow> cardWrapperLight = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  // Dark — Ivory Ink
  static const List<BoxShadow> cardDark = [
    BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> cardWrapperDark = [
    BoxShadow(color: Color(0x44000000), blurRadius: 16, offset: Offset(0, 6)),
  ];

  // Theme-aware helpers
  static List<BoxShadow> card(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? cardDark : cardLight;

  static List<BoxShadow> cardWrapper(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? cardWrapperDark : cardWrapperLight;
}
