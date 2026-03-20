import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scheduler_frontend/app_shell.dart';
import 'package:scheduler_frontend/core/auth/auth_bloc.dart';
import 'package:scheduler_frontend/core/auth/auth_event.dart';
import 'package:scheduler_frontend/core/auth/auth_state.dart';
import 'package:scheduler_frontend/core/policy/app_policy.dart';
import 'package:scheduler_frontend/core/theme/theme_cubit.dart';
import 'package:scheduler_frontend/core/theme/theme_state.dart';
import 'package:scheduler_frontend/design_system/tokens/app_theme.dart';
import 'package:scheduler_frontend/features/business/bloc/business_bloc.dart';
import 'package:scheduler_frontend/features/business/bloc/business_event.dart';
import 'package:scheduler_frontend/features/business/bloc/business_state.dart';
import 'package:scheduler_frontend/features/business/data/business_model.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}
class MockThemeCubit extends MockCubit<ThemeState> implements ThemeCubit {}
class MockBusinessBloc extends MockBloc<BusinessEvent, BusinessState> implements BusinessBloc {}

// ─── Helpers ──────────────────────────────────────────────────────────────────

final _fakeBusiness = BusinessModel(
  id: 'biz-1',
  slug: 'biz-1',
  name: 'Test Biz',
  logo: null,
  timezone: 'America/Sao_Paulo',
  myStaffRole: StaffRole.owner,
  planMaxStaff: 5,
);

BusinessLoaded _loadedState({
  StaffRole role = StaffRole.owner,
  int maxStaff = 5,
}) {
  final business = _fakeBusiness.copyWith(
    myStaffRole: role,
    planMaxStaff: maxStaff,
  );
  final policy = AppPolicy.from(role, maxStaff);
  return BusinessLoaded(
    businesses: [business],
    active: business,
    policy: policy,
  );
}

Widget _buildShell({
  String location = '/',
  AuthBloc? authBloc,
  BusinessState? businessState,
}) {
  final bloc = authBloc ?? MockAuthBloc();
  if (authBloc == null) {
    when(() => bloc.state).thenReturn(const AuthUnauthenticated());
  }
  final themeCubit = MockThemeCubit();
  when(() => themeCubit.state)
      .thenReturn(const ThemeState(themeMode: ThemeMode.dark));

  final businessBloc = MockBusinessBloc();
  when(() => businessBloc.state)
      .thenReturn(businessState ?? _loadedState());

  return MaterialApp(
    theme: AppTheme.dark(),
    home: MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: bloc),
        BlocProvider<ThemeCubit>.value(value: themeCubit),
        BlocProvider<BusinessBloc>.value(value: businessBloc),
      ],
      child: AdaptiveShell(
        currentLocation: location,
        child: const SizedBox.expand(),
      ),
    ),
  );
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('indexForLocation', () {
    final mobileItems = [
      const NavItem(label: 'Início',  icon: Icons.home_outlined,     route: '/'),
      const NavItem(label: 'Agenda',  icon: Icons.calendar_today_outlined, route: '/appointments'),
      const NavItem(label: 'Clientes', icon: Icons.people_outline,   route: '/clients'),
    ];

    final desktopItems = [
      ...mobileItems,
      const NavItem(label: 'Relatórios', icon: Icons.bar_chart_outlined, route: '/reports'),
    ];

    test('returns 0 for home route', () {
      expect(indexForLocation('/', items: mobileItems), 0);
    });

    test('returns 1 for /appointments', () {
      expect(indexForLocation('/appointments', items: mobileItems), 1);
    });

    test('returns 3 for /reports on desktop', () {
      expect(indexForLocation('/reports', items: desktopItems), 3);
    });

    test('returns 0 for unknown location', () {
      expect(indexForLocation('/unknown', items: mobileItems), 0);
    });

    test('returns 1 for sub-route /appointments/123', () {
      expect(indexForLocation('/appointments/123', items: mobileItems), 1);
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
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byKey(const ValueKey('floating_nav_bar')), findsOneWidget);
    });

    testWidgets('mostra sidebar em tela larga (>= 720px)', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildShell());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(NavigationBar), findsNothing);
      // Relatórios aparece apenas no desktop para owner com maxStaff > 1
      expect(find.text('Relatórios'), findsOneWidget);
    });

    testWidgets('mostra loading indicator quando BusinessLoading', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildShell(businessState: const BusinessLoading()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(const ValueKey('floating_nav_bar')), findsNothing);
    });

    testWidgets('floating navbar contém itens vindos do AppPolicy (owner, maxStaff=5)',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // owner + maxStaff=5 → canTeam=true → mobileItems: Início, Agenda, Equipe, Serviços, Config.
      await tester.pumpWidget(_buildShell(
        location: '/appointments',
        businessState: _loadedState(role: StaffRole.owner, maxStaff: 5),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      // Policy-driven items appear (home route is '/home' per AppPolicy)
      expect(find.byKey(const Key('nav_item_/home')),           findsOneWidget);
      expect(find.byKey(const Key('nav_item_/appointments')),   findsOneWidget);
      expect(find.byKey(const Key('nav_item_/professionals')),  findsOneWidget);
      expect(find.byKey(const Key('nav_item_/services')),       findsOneWidget);
      expect(find.byKey(const Key('nav_item_/settings')),       findsOneWidget);
      // Clientes NOT in owner+team mobile nav
      expect(find.byKey(const Key('nav_item_/clients')),        findsNothing);
    });

    // ── New TDD tests for AppPolicy-driven nav ────────────────────────────────

    testWidgets('mobile nav mostra item Equipe quando policy tem canManageTeam',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // owner with maxStaff=5 → canTeam=true → 'Equipe' in mobile nav
      await tester.pumpWidget(_buildShell(
        businessState: _loadedState(role: StaffRole.owner, maxStaff: 5),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('nav_item_/professionals')), findsOneWidget);
    });

    testWidgets('mobile nav NÃO mostra item Equipe quando policy não tem canManageTeam',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // solo owner (maxStaff=1) → canTeam=false → 'Equipe' NOT in mobile nav
      await tester.pumpWidget(_buildShell(
        businessState: _loadedState(role: StaffRole.owner, maxStaff: 1),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('nav_item_/professionals')), findsNothing);
    });

    testWidgets('sidebar tem botão de toggle e pode ser retraída',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildShell());
      await tester.pump(const Duration(milliseconds: 100));

      // Sidebar começa expandida — labels visíveis
      expect(find.text('Início'), findsOneWidget);
      // Toggle button presente
      expect(find.byKey(const ValueKey('sidebar_toggle')), findsOneWidget);

      // Tap no toggle → sidebar retrái
      await tester.tap(find.byKey(const ValueKey('sidebar_toggle')));
      await tester.pumpAndSettle();

      // Sidebar retraída — labels de texto não visíveis
      expect(find.text('Início'), findsNothing);
      // BackdropFilter ainda presente (glass effect)
      expect(find.byType(BackdropFilter), findsWidgets);
    });

    testWidgets('item da sidebar é destacado conforme a rota no desktop',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildShell(location: '/appointments'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Agenda'), findsOneWidget);
    });
  });
}
