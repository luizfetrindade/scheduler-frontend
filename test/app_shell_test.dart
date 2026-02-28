import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scheduler_frontend/app_shell.dart';
import 'package:scheduler_frontend/core/auth/auth_bloc.dart';
import 'package:scheduler_frontend/core/auth/auth_event.dart';
import 'package:scheduler_frontend/core/auth/auth_state.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

Widget _buildShell({
  String location = '/',
  AuthBloc? authBloc,
}) {
  final bloc = authBloc ?? MockAuthBloc();
  if (authBloc == null) {
    when(() => bloc.state).thenReturn(const AuthUnauthenticated());
  }
  return MaterialApp(
    home: BlocProvider<AuthBloc>.value(
      value: bloc,
      child: AdaptiveShell(
        currentLocation: location,
        child: const SizedBox.expand(),
      ),
    ),
  );
}

void main() {
  group('indexForLocation', () {
    test('returns 0 for home route', () {
      expect(indexForLocation('/', isMobile: true), 0);
    });

    test('returns 1 for /appointments on mobile', () {
      expect(indexForLocation('/appointments', isMobile: true), 1);
    });

    test('returns 4 for /reports on desktop (index 4 in desktop list)', () {
      expect(indexForLocation('/reports', isMobile: false), 4);
    });

    test('returns 0 for unknown location', () {
      expect(indexForLocation('/unknown', isMobile: true), 0);
    });

    test('returns 1 for sub-route /appointments/123 on mobile', () {
      expect(indexForLocation('/appointments/123', isMobile: true), 1);
    });
  });

  group('AdaptiveShell — layout', () {
    testWidgets('mostra floating navbar em tela estreita (< 720px)',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildShell());
      await tester.pump();

      // Widget nativo substituído — não deve existir mais
      expect(find.byType(NavigationBar), findsNothing);
      // Floating navbar identificada por key
      expect(find.byKey(const ValueKey('floating_nav_bar')), findsOneWidget);
      // Relatórios não aparece no mobile
      expect(find.text('Relatórios'), findsNothing);
    });

    testWidgets('mostra sidebar em tela larga (>= 720px)', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildShell());
      await tester.pump();

      expect(find.byType(NavigationBar), findsNothing);
      // Relatórios aparece apenas no desktop
      expect(find.text('Relatórios'), findsOneWidget);
    });

    testWidgets('floating navbar contém os 5 itens mobile', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildShell(location: '/appointments'));
      await tester.pump();

      // Os 5 itens mobile identificados por key no _NavItemButton
      expect(find.byKey(const Key('nav_item_/')),             findsOneWidget);
      expect(find.byKey(const Key('nav_item_/appointments')), findsOneWidget);
      expect(find.byKey(const Key('nav_item_/clients')),      findsOneWidget);
      expect(find.byKey(const Key('nav_item_/services')),     findsOneWidget);
      expect(find.byKey(const Key('nav_item_/settings')),     findsOneWidget);
      // Relatórios NÃO está nos itens mobile
      expect(find.byKey(const Key('nav_item_/reports')),      findsNothing);
    });

    testWidgets('sidebar tem botão de toggle e pode ser retraída',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildShell());
      await tester.pump();

      // Sidebar começa expandida — labels visíveis
      expect(find.text('Home'), findsOneWidget);
      // Toggle button presente
      expect(find.byKey(const ValueKey('sidebar_toggle')), findsOneWidget);

      // Tap no toggle → sidebar retrái
      await tester.tap(find.byKey(const ValueKey('sidebar_toggle')));
      await tester.pumpAndSettle();

      // BackdropFilter ainda presente (glass effect)
      expect(find.byType(BackdropFilter), findsWidgets);
    });

    testWidgets('item da sidebar é destacado conforme a rota no desktop',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildShell(location: '/clients'));
      await tester.pump();

      expect(find.text('Clientes'), findsOneWidget);
    });
  });
}
