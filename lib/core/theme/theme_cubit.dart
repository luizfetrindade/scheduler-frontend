import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scheduler_frontend/core/cache/preferences_service.dart';
import 'package:scheduler_frontend/core/theme/theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  final PreferencesService _prefs;
  static const _key = 'theme_mode';

  ThemeCubit(this._prefs)
      : super(ThemeState(
          themeMode: _prefs.getString(_key) == 'light'
              ? ThemeMode.light
              : ThemeMode.dark,
        ));

  Future<void> toggle() async {
    final next = state.themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    await _prefs.setString(_key, next == ThemeMode.light ? 'light' : 'dark');
    emit(ThemeState(themeMode: next));
  }
}
