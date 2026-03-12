import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scheduler_frontend/core/cache/preferences_service.dart';
import 'package:scheduler_frontend/core/theme/theme_cubit.dart';
import 'package:scheduler_frontend/core/theme/theme_state.dart';

Future<PreferencesService> _prefs([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  final svc = PreferencesService();
  await svc.init();
  return svc;
}

void main() {
  group('ThemeCubit — estado inicial', () {
    test('dark quando chave ausente (first launch)', () async {
      final cubit = ThemeCubit(await _prefs());
      expect(cubit.state.themeMode, ThemeMode.dark);
      await cubit.close();
    });

    test('light quando chave = "light"', () async {
      final cubit = ThemeCubit(await _prefs({'theme_mode': 'light'}));
      expect(cubit.state.themeMode, ThemeMode.light);
      await cubit.close();
    });

    test('dark quando chave = "dark"', () async {
      final cubit = ThemeCubit(await _prefs({'theme_mode': 'dark'}));
      expect(cubit.state.themeMode, ThemeMode.dark);
      await cubit.close();
    });
  });

  group('ThemeCubit — toggle()', () {
    test('dark → light: emite ThemeMode.light', () async {
      final prefs = await _prefs();
      final cubit = ThemeCubit(prefs);
      expect(cubit.state.themeMode, ThemeMode.dark);
      await cubit.toggle();
      expect(cubit.state.themeMode, ThemeMode.light);
      await cubit.close();
    });

    test('light → dark: emite ThemeMode.dark', () async {
      final prefs = await _prefs({'theme_mode': 'light'});
      final cubit = ThemeCubit(prefs);
      expect(cubit.state.themeMode, ThemeMode.light);
      await cubit.toggle();
      expect(cubit.state.themeMode, ThemeMode.dark);
      await cubit.close();
    });

    test('toggle persiste "light" no SharedPreferences', () async {
      final prefs = await _prefs();
      final cubit = ThemeCubit(prefs);
      await cubit.toggle();
      expect(prefs.getString('theme_mode'), 'light');
      await cubit.close();
    });

    test('toggle persiste "dark" no SharedPreferences', () async {
      final prefs = await _prefs({'theme_mode': 'light'});
      final cubit = ThemeCubit(prefs);
      await cubit.toggle();
      expect(prefs.getString('theme_mode'), 'dark');
      await cubit.close();
    });
  });
}
