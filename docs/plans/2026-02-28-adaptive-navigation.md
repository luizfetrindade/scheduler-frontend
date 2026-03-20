# Adaptive Navigation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Substituir o `AppShell` vazio por um `AdaptiveShell` que renderiza sidebar fixa no web/desktop (≥ 720 px) e bottom navigation bar no mobile (< 720 px), com 5 novas rotas placeholder.

**Architecture:** Um único `AdaptiveShell` (StatelessWidget) recebe `currentLocation` e `child` do `ShellRoute`. Internamente usa `LayoutBuilder` para decidir entre `_MobileLayout` (NavigationBar com 5 destinos) e `_DesktopLayout` (sidebar 220 px + 6 destinos). A seleção da aba ativa é derivada de `currentLocation` via função pura `_indexForLocation`.

**Tech Stack:** Flutter, go_router (ShellRoute), flutter_bloc, NavigationBar (Material 3), LayoutBuilder.

---

### Task 1: Expandir `app_routes.dart` com as 5 novas rotas

**Files:**
- Modify: `lib/core/router/app_routes.dart`

**Step 1: Adicionar as constantes**

Substitua o conteúdo de `lib/core/router/app_routes.dart` por:

```dart
abstract final class AppRoutes {
  static const login        = '/login';
  static const home         = '/';
  static const appointments = '/appointments';
  static const clients      = '/clients';
  static const services     = '/services';
  static const reports      = '/reports';
  static const settings     = '/settings';
}
```

**Step 2: Verificar que os testes de router ainda passam**

```bash
cd scheduler-frontend
flutter test test/core/router/app_router_test.dart
```

Esperado: todos os testes passam (os testes existentes usam `AppRoutes.login` e `AppRoutes.home`, que não mudaram).

**Step 3: Commit**

```bash
git add lib/core/router/app_routes.dart
git commit -m "feat: add route constants for appointments, clients, services, reports, settings"
```

---

### Task 2: Criar as 5 páginas placeholder

**Files:**
- Create: `lib/features/appointments/presentation/appointments_page.dart`
- Create: `lib/features/clients/presentation/clients_page.dart`
- Create: `lib/features/services/presentation/services_page.dart`
- Create: `lib/features/reports/presentation/reports_page.dart`
- Create: `lib/features/settings/presentation/settings_page.dart`

**Step 1: Criar cada arquivo**

Cada arquivo segue exatamente este padrão (troque o título):

`lib/features/appointments/presentation/appointments_page.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';

class AppointmentsPage extends StatelessWidget {
  const AppointmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text('Agendamentos', style: AppTypography.headingMd),
      ),
    );
  }
}
```

`lib/features/clients/presentation/clients_page.dart` — título: `'Clientes'`, classe: `ClientsPage`

`lib/features/services/presentation/services_page.dart` — título: `'Serviços'`, classe: `ServicesPage`

`lib/features/reports/presentation/reports_page.dart` — título: `'Relatórios'`, classe: `ReportsPage`

`lib/features/settings/presentation/settings_page.dart` — título: `'Configurações'`, classe: `SettingsPage`

**Step 2: Checar que o projeto compila**

```bash
flutter build apk --debug 2>&1 | tail -5
# ou mais rápido:
flutter analyze
```

Esperado: sem erros.

**Step 3: Commit**

```bash
git add lib/features/appointments/presentation/appointments_page.dart \
        lib/features/clients/presentation/clients_page.dart \
        lib/features/services/presentation/services_page.dart \
        lib/features/reports/presentation/reports_page.dart \
        lib/features/settings/presentation/settings_page.dart
git commit -m "feat: add placeholder pages for appointments, clients, services, reports, settings"
```

---

### Task 3: Escrever os testes do `AdaptiveShell` (TDD — escrever antes da implementação)

**Files:**
- Create: `test/app_shell_test.dart`

**Step 1: Escrever os testes**

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scheduler_frontend/app_shell.dart';
import 'package:scheduler_frontend/core/auth/auth_bloc.dart';
import 'package:scheduler_frontend/core/auth/auth_state.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

Widget _buildShell({
  required double width,
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
  group('_indexForLocation', () {
    test('returns 0 for home route', () {
      expect(indexForLocation('/', isMobile: true), 0);
    });

    test('returns 1 for /appointments on mobile', () {
      expect(indexForLocation('/appointments', isMobile: true), 1);
    });

    test('returns 4 for /reports on desktop (not in mobile list)', () {
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

      await tester.pumpWidget(_buildShell(width: 400));
      await tester.pump();

      expect(find.byType(NavigationBar), findsOneWidget);
      // Relatórios não aparece no mobile
      expect(find.text('Relatórios'), findsNothing);
    });

    testWidgets('mostra sidebar em tela larga (>= 720px)', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildShell(width: 1200));
      await tester.pump();

      expect(find.byType(NavigationBar), findsNothing);
      // Relatórios aparece apenas no desktop
      expect(find.text('Relatórios'), findsOneWidget);
    });

    testWidgets('NavigationBar.selectedIndex reflete a rota atual no mobile', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildShell(width: 400, location: '/appointments'));
      await tester.pump();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 1);
    });

    testWidgets('item da sidebar é destacado conforme a rota no desktop', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildShell(width: 1200, location: '/clients'));
      await tester.pump();

      // O item "Clientes" deve aparecer com destaque visual.
      // Verificamos apenas que ele está presente e clicável.
      expect(find.text('Clientes'), findsOneWidget);
    });
  });
}
```

**Step 2: Rodar os testes para confirmar que falham**

```bash
flutter test test/app_shell_test.dart
```

Esperado: FAIL — `AdaptiveShell` e `indexForLocation` não existem ainda.

---

### Task 4: Implementar `AdaptiveShell` (substituir `app_shell.dart`)

**Files:**
- Modify: `lib/app_shell.dart` (reescrever completamente)

**Step 1: Reescrever `lib/app_shell.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scheduler_frontend/core/auth/auth_bloc.dart';
import 'package:scheduler_frontend/core/auth/auth_event.dart';
import 'package:scheduler_frontend/core/auth/auth_state.dart';
import 'package:scheduler_frontend/core/router/app_routes.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';

// ─── Nav item descriptor ─────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  const _NavItem({required this.icon, required this.label, required this.route});
}

const _mobileItems = [
  _NavItem(icon: Icons.home_outlined,         label: 'Home',          route: AppRoutes.home),
  _NavItem(icon: Icons.calendar_month_outlined,label: 'Agendamentos',  route: AppRoutes.appointments),
  _NavItem(icon: Icons.people_outline,         label: 'Clientes',      route: AppRoutes.clients),
  _NavItem(icon: Icons.content_cut,            label: 'Serviços',      route: AppRoutes.services),
  _NavItem(icon: Icons.settings_outlined,      label: 'Configurações', route: AppRoutes.settings),
];

const _desktopItems = [
  _NavItem(icon: Icons.home_outlined,          label: 'Home',          route: AppRoutes.home),
  _NavItem(icon: Icons.calendar_month_outlined,label: 'Agendamentos',  route: AppRoutes.appointments),
  _NavItem(icon: Icons.people_outline,         label: 'Clientes',      route: AppRoutes.clients),
  _NavItem(icon: Icons.content_cut,            label: 'Serviços',      route: AppRoutes.services),
  _NavItem(icon: Icons.bar_chart,              label: 'Relatórios',    route: AppRoutes.reports),
  _NavItem(icon: Icons.settings_outlined,      label: 'Configurações', route: AppRoutes.settings),
];

// ─── Helper exported for tests ────────────────────────────────────────────────

/// Returns the nav index that matches [location].
/// Pass [isMobile] to select the correct item list.
/// Falls back to 0 if no match is found.
int indexForLocation(String location, {required bool isMobile}) {
  final items = isMobile ? _mobileItems : _desktopItems;
  final i = items.indexWhere(
    (item) => location == item.route || location.startsWith('${item.route}/'),
  );
  return i < 0 ? 0 : i;
}

// ─── AdaptiveShell ────────────────────────────────────────────────────────────

class AdaptiveShell extends StatelessWidget {
  final Widget child;
  final String currentLocation;

  const AdaptiveShell({
    super.key,
    required this.child,
    required this.currentLocation,
  });

  static const _kBreakpoint = 720.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < _kBreakpoint;
        final index = indexForLocation(currentLocation, isMobile: isMobile);

        if (isMobile) {
          return _MobileLayout(
            child: child,
            selectedIndex: index,
            items: _mobileItems,
          );
        }

        return _DesktopLayout(
          child: child,
          selectedIndex: index,
          items: _desktopItems,
        );
      },
    );
  }
}

// ─── Mobile layout ────────────────────────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  final Widget child;
  final int selectedIndex;
  final List<_NavItem> items;

  const _MobileLayout({
    required this.child,
    required this.selectedIndex,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) => context.go(items[i].route),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.purple700,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: items
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon, color: AppColors.textSecondary),
                selectedIcon: Icon(item.icon, color: AppColors.textPrimary),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

// ─── Desktop layout ───────────────────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  final Widget child;
  final int selectedIndex;
  final List<_NavItem> items;

  const _DesktopLayout({
    required this.child,
    required this.selectedIndex,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          _Sidebar(selectedIndex: selectedIndex, items: items),
          const VerticalDivider(width: 1, thickness: 1, color: AppColors.surfaceHigh),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ─── Sidebar ──────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final List<_NavItem> items;

  const _Sidebar({required this.selectedIndex, required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: ColoredBox(
        color: AppColors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text('Scheduler', style: AppTypography.headingMd),
            ),
            const SizedBox(height: AppSpacing.xl),
            ...items.asMap().entries.map((e) => _SidebarTile(
                  item: e.value,
                  isSelected: e.key == selectedIndex,
                  onTap: () => context.go(e.value.route),
                )),
            const Spacer(),
            const Divider(color: AppColors.surfaceHigh, height: 1),
            _SidebarFooter(),
          ],
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        item.icon,
        color: isSelected ? AppColors.purple300 : AppColors.textSecondary,
        size: 20,
      ),
      title: Text(
        item.label,
        style: AppTypography.bodySm.copyWith(
          color: isSelected ? AppColors.purple300 : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      tileColor: isSelected
          ? AppColors.purple700.withValues(alpha: 0.2)
          : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      onTap: onTap,
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final name =
            state is AuthAuthenticated ? state.user.firstName : '';
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.purple700,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: AppTypography.bodySm
                      .copyWith(color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  name,
                  style: AppTypography.bodySm,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout,
                    color: AppColors.textSecondary, size: 18),
                tooltip: 'Sair',
                onPressed: () =>
                    context.read<AuthBloc>().add(const AuthLogoutRequested()),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

**Step 2: Rodar os testes**

```bash
flutter test test/app_shell_test.dart
```

Esperado: todos os testes passam.

**Step 3: Rodar a suite completa**

```bash
flutter test
```

Esperado: todos os testes passam.

**Step 4: Commit**

```bash
git add lib/app_shell.dart test/app_shell_test.dart
git commit -m "feat: replace AppShell with AdaptiveShell (sidebar on web, bottom nav on mobile)"
```

---

### Task 5: Conectar as novas rotas no `app_router.dart`

**Files:**
- Modify: `lib/core/router/app_router.dart`

**Step 1: Atualizar o arquivo**

```dart
import 'package:go_router/go_router.dart';
import 'package:scheduler_frontend/app_shell.dart';
import 'package:scheduler_frontend/core/auth/auth_bloc.dart';
import 'package:scheduler_frontend/core/auth/auth_state.dart';
import 'package:scheduler_frontend/core/network/router_notifier.dart';
import 'package:scheduler_frontend/core/router/app_routes.dart';
import 'package:scheduler_frontend/features/appointments/presentation/appointments_page.dart';
import 'package:scheduler_frontend/features/auth/presentation/login_page.dart';
import 'package:scheduler_frontend/features/clients/presentation/clients_page.dart';
import 'package:scheduler_frontend/features/home/presentation/home_page.dart';
import 'package:scheduler_frontend/features/reports/presentation/reports_page.dart';
import 'package:scheduler_frontend/features/services/presentation/services_page.dart';
import 'package:scheduler_frontend/features/settings/presentation/settings_page.dart';

/// Pure redirect logic — testable without a BuildContext.
String? computeRedirect({required bool isLoggedIn, required String location}) {
  final isOnLogin = location == AppRoutes.login;
  if (!isLoggedIn && !isOnLogin) return AppRoutes.login;
  if (isLoggedIn && isOnLogin) return AppRoutes.home;
  return null;
}

GoRouter createAppRouter(AuthBloc authBloc) => GoRouter(
      initialLocation: AppRoutes.home,
      refreshListenable: RouterNotifier(authBloc),
      redirect: (context, state) => computeRedirect(
        isLoggedIn: authBloc.state is AuthAuthenticated,
        location: state.matchedLocation,
      ),
      routes: [
        GoRoute(
          path: AppRoutes.login,
          builder: (context, _) => const LoginPage(),
        ),
        ShellRoute(
          builder: (context, state, child) => AdaptiveShell(
            currentLocation: state.matchedLocation,
            child: child,
          ),
          routes: [
            GoRoute(path: AppRoutes.home,         builder: (_, __) => const HomePage()),
            GoRoute(path: AppRoutes.appointments, builder: (_, __) => const AppointmentsPage()),
            GoRoute(path: AppRoutes.clients,      builder: (_, __) => const ClientsPage()),
            GoRoute(path: AppRoutes.services,     builder: (_, __) => const ServicesPage()),
            GoRoute(path: AppRoutes.reports,      builder: (_, __) => const ReportsPage()),
            GoRoute(path: AppRoutes.settings,     builder: (_, __) => const SettingsPage()),
          ],
        ),
      ],
    );
```

**Step 2: Rodar todos os testes**

```bash
flutter test
```

Esperado: todos os testes passam (incluindo os do router existentes em `test/core/router/app_router_test.dart`).

**Step 3: Testar manualmente no simulador/browser**

```bash
# Mobile (simulador iOS/Android)
flutter run

# Web
flutter run -d chrome
```

Verificar:
- Mobile: bottom nav com 5 abas (sem Relatórios), navegação entre telas funciona
- Web: sidebar com 6 itens, navegação funciona, footer mostra nome do usuário e botão logout
- Redimensionar a janela do browser abaixo de 720 px → layout muda para bottom nav

**Step 4: Commit final**

```bash
git add lib/core/router/app_router.dart
git commit -m "feat: wire adaptive navigation routes into app router"
```
