import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/design_system/tokens/app_colors_extension.dart';

void main() {
  group('AppColorsExtension.dark()', () {
    final dark = AppColorsExtension.dark();

    test('background é #1A1512', () => expect(dark.background, const Color(0xFF1A1512)));
    test('surface é #251E19', () => expect(dark.surface, const Color(0xFF251E19)));
    test('surfaceHigh é #2D2520', () => expect(dark.surfaceHigh, const Color(0xFF2D2520)));
    test('primary é #F2EBE0', () => expect(dark.primary, const Color(0xFFF2EBE0)));
    test('primaryLight é #332B25', () => expect(dark.primaryLight, const Color(0xFF332B25)));
    test('primaryDark é #F0EBE5', () => expect(dark.primaryDark, const Color(0xFFF0EBE5)));
    test('textPrimary é #F0EBE5', () => expect(dark.textPrimary, const Color(0xFFF0EBE5)));
    test('textSecondary é #A89B8C', () => expect(dark.textSecondary, const Color(0xFFA89B8C)));
    test('textDisabled é #7A6E64', () => expect(dark.textDisabled, const Color(0xFF7A6E64)));
    test('outline é #3A302A', () => expect(dark.outline, const Color(0xFF3A302A)));
    test('sidebarBackground é #221A14', () => expect(dark.sidebarBackground, const Color(0xFF221A14)));
    test('sidebarForeground é #F0EBE5', () => expect(dark.sidebarForeground, const Color(0xFFF0EBE5)));
  });

  group('AppColorsExtension.light()', () {
    final light = AppColorsExtension.light();

    test('background é #FAF8F5', () => expect(light.background, const Color(0xFFFAF8F5)));
    test('surface é #FFFFFF', () => expect(light.surface, const Color(0xFFFFFFFF)));
    test('surfaceHigh é #F5F2EE', () => expect(light.surfaceHigh, const Color(0xFFF5F2EE)));
    test('primary é #3D3935', () => expect(light.primary, const Color(0xFF3D3935)));
    test('primaryLight é #EDEAE7', () => expect(light.primaryLight, const Color(0xFFEDEAE7)));
    test('primaryDark é #1A1512', () => expect(light.primaryDark, const Color(0xFF1A1512)));
    test('textPrimary é #1A1512', () => expect(light.textPrimary, const Color(0xFF1A1512)));
    test('textSecondary é #6B5E52', () => expect(light.textSecondary, const Color(0xFF6B5E52)));
    test('textDisabled é #A89B8C', () => expect(light.textDisabled, const Color(0xFFA89B8C)));
    test('outline é #E8E3DC', () => expect(light.outline, const Color(0xFFE8E3DC)));
    test('sidebarBackground é #3D3935', () => expect(light.sidebarBackground, const Color(0xFF3D3935)));
    test('sidebarForeground é #FAF8F5', () => expect(light.sidebarForeground, const Color(0xFFFAF8F5)));
  });

  group('AppColorsExtension.copyWith()', () {
    test('substitui apenas background, mantém demais', () {
      final base = AppColorsExtension.dark();
      final updated = base.copyWith(background: const Color(0xFFAAAAAA));
      expect(updated.background, const Color(0xFFAAAAAA));
      expect(updated.surface, base.surface);
      expect(updated.primary, base.primary);
    });
  });

  group('AppColorsExtension.lerp()', () {
    final dark = AppColorsExtension.dark();
    final light = AppColorsExtension.light();

    test('t=0.0 retorna valores de this', () {
      final result = dark.lerp(light, 0.0);
      expect(result.background, dark.background);
      expect(result.primary, dark.primary);
    });
    test('t=1.0 retorna valores de other', () {
      final result = dark.lerp(light, 1.0);
      expect(result.background, light.background);
      expect(result.primary, light.primary);
    });
    test('other=null retorna this', () {
      final result = dark.lerp(null, 0.5);
      expect(result.background, dark.background);
    });
  });
}
