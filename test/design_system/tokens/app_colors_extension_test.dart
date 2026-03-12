import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/design_system/tokens/app_colors_extension.dart';

void main() {
  group('AppColorsExtension.dark()', () {
    final dark = AppColorsExtension.dark();

    test('background é #0D0D0D', () => expect(dark.background, const Color(0xFF0D0D0D)));
    test('surface é #1A1A1A', () => expect(dark.surface, const Color(0xFF1A1A1A)));
    test('surfaceHigh é #242424', () => expect(dark.surfaceHigh, const Color(0xFF242424)));
    test('primary é #A855F7', () => expect(dark.primary, const Color(0xFFA855F7)));
    test('primaryLight é #C084FC', () => expect(dark.primaryLight, const Color(0xFFC084FC)));
    test('primaryDark é #7E22CE', () => expect(dark.primaryDark, const Color(0xFF7E22CE)));
    test('textPrimary é #F5F5F5', () => expect(dark.textPrimary, const Color(0xFFF5F5F5)));
    test('textSecondary é #A3A3A3', () => expect(dark.textSecondary, const Color(0xFFA3A3A3)));
    test('textDisabled é #525252', () => expect(dark.textDisabled, const Color(0xFF525252)));
  });

  group('AppColorsExtension.light()', () {
    final light = AppColorsExtension.light();

    test('background é #F3E3D0', () => expect(light.background, const Color(0xFFF3E3D0)));
    test('surface é #D2C4B4', () => expect(light.surface, const Color(0xFFD2C4B4)));
    test('surfaceHigh é #BFB3A4', () => expect(light.surfaceHigh, const Color(0xFFBFB3A4)));
    test('primary é #81A6C6', () => expect(light.primary, const Color(0xFF81A6C6)));
    test('primaryLight é #AACDDC', () => expect(light.primaryLight, const Color(0xFFAACDDC)));
    test('primaryDark é #5A8BAD', () => expect(light.primaryDark, const Color(0xFF5A8BAD)));
    test('textPrimary é #81A6C6', () => expect(light.textPrimary, const Color(0xFF81A6C6)));
    test('textSecondary é #AACDDC', () => expect(light.textSecondary, const Color(0xFFAACDDC)));
    test('textDisabled é #C5DCE8', () => expect(light.textDisabled, const Color(0xFFC5DCE8)));
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
