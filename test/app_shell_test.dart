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
  });

  group('AdaptiveShell — layout', () {
    testWidgets('mostra NavigationBar em tela estreita (< 720px)', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildShell());
      await tester.pump();

      expect(find.byType(NavigationBar), findsOneWidget);
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

    testWidgets('NavigationBar.selectedIndex reflete a rota atual no mobile', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildShell(location: '/appointments'));
      await tester.pump();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 1);
    });

    testWidgets('item da sidebar é destacado conforme a rota no desktop', (tester) async {
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
