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
            GoRoute(path: AppRoutes.home,         builder: (context, _) => const HomePage()),
            GoRoute(path: AppRoutes.appointments, builder: (context, _) => const AppointmentsPage()),
            GoRoute(path: AppRoutes.clients,      builder: (context, _) => const ClientsPage()),
            GoRoute(path: AppRoutes.services,     builder: (context, _) => const ServicesPage()),
            GoRoute(path: AppRoutes.reports,      builder: (context, _) => const ReportsPage()),
            GoRoute(path: AppRoutes.settings,     builder: (context, _) => const SettingsPage()),
          ],
        ),
      ],
    );
