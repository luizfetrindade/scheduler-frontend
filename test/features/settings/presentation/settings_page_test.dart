import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scheduler_frontend/core/cache/preferences_service.dart';
import 'package:scheduler_frontend/core/theme/theme_cubit.dart';
import 'package:scheduler_frontend/core/theme/theme_state.dart';
import 'package:scheduler_frontend/design_system/tokens/app_theme.dart';
import 'package:scheduler_frontend/features/settings/presentation/settings_page.dart';

Future<Widget> buildPage([ThemeMode mode = ThemeMode.dark]) async {
  SharedPreferences.setMockInitialValues(
    mode == ThemeMode.light ? {'theme_mode': 'light'} : {},
  );
  final prefs = PreferencesService();
  await prefs.init();

  return BlocProvider(
    create: (_) => ThemeCubit(prefs),
    child: MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      home: const SettingsPage(),
    ),
  );
}

void main() {
  group('SettingsPage', () {
    testWidgets('exibe Switch com valor false em dark mode', (tester) async {
      await tester.pumpWidget(await buildPage(ThemeMode.dark));
      final sw = tester.widget<Switch>(find.byType(Switch));
      expect(sw.value, isFalse);
    });

    testWidgets('exibe Switch com valor true em light mode', (tester) async {
      await tester.pumpWidget(await buildPage(ThemeMode.light));
      final sw = tester.widget<Switch>(find.byType(Switch));
      expect(sw.value, isTrue);
    });

    testWidgets('exibe ícone dark_mode em dark mode', (tester) async {
      await tester.pumpWidget(await buildPage(ThemeMode.dark));
      expect(find.byIcon(Icons.dark_mode), findsOneWidget);
    });

    testWidgets('exibe ícone light_mode em light mode', (tester) async {
      await tester.pumpWidget(await buildPage(ThemeMode.light));
      expect(find.byIcon(Icons.light_mode), findsOneWidget);
    });

    testWidgets('tap no Switch dispara toggle (modo muda de dark para light)', (tester) async {
      await tester.pumpWidget(await buildPage(ThemeMode.dark));
      await tester.tap(find.byType(Switch));
      await tester.pump();
      final sw = tester.widget<Switch>(find.byType(Switch));
      expect(sw.value, isTrue);
    });
  });
}
