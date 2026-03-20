import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scheduler_frontend/app_shell.dart';
import 'package:scheduler_frontend/core/auth/auth_bloc.dart';
import 'package:scheduler_frontend/core/auth/auth_state.dart';
import 'package:scheduler_frontend/core/network/router_notifier.dart';
import 'package:scheduler_frontend/core/router/app_routes.dart';
import 'package:scheduler_frontend/features/appointments/presentation/appointments_page.dart';
import 'package:scheduler_frontend/features/auth/presentation/accept_invite_page.dart';
import 'package:scheduler_frontend/features/auth/presentation/forgot_password_page.dart';
import 'package:scheduler_frontend/features/auth/presentation/login_page.dart';
import 'package:scheduler_frontend/features/auth/presentation/password_login_page.dart';
import 'package:scheduler_frontend/features/auth/presentation/register_page.dart';
import 'package:scheduler_frontend/features/auth/presentation/reset_password_page.dart';
import 'package:scheduler_frontend/features/auth/presentation/totp_login_page.dart';
import 'package:scheduler_frontend/features/clients/presentation/clients_page.dart';
import 'package:scheduler_frontend/features/home/presentation/home_page.dart';
import 'package:scheduler_frontend/features/reports/presentation/reports_page.dart';
import 'package:scheduler_frontend/features/professionals/presentation/professional_profile_page.dart';
import 'package:scheduler_frontend/features/professionals/presentation/professionals_page.dart';
import 'package:scheduler_frontend/features/professionals/presentation/roles_management_page.dart';
import 'package:scheduler_frontend/features/services/presentation/services_page.dart';
import 'package:scheduler_frontend/core/router/uuid_validator.dart';
import 'package:scheduler_frontend/features/onboarding/presentation/wizard_page.dart';
import 'package:scheduler_frontend/features/settings/presentation/settings_page.dart';

/// Pure redirect logic — testable without a BuildContext.
String? computeRedirect({required bool isLoggedIn, required String location}) {
  const publicPaths = [
    '/login',
    '/register',
    '/reset-password',
    '/accept-invite',
    '/forgot-password',
  ];
  final isOnPublicRoute = publicPaths.any((p) => location.startsWith(p));
  if (!isLoggedIn && !isOnPublicRoute) return AppRoutes.login;
  if (isLoggedIn && isOnPublicRoute) return AppRoutes.home;
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
        GoRoute(
          path: '/login/totp',
          builder: (_, state) =>
              TotpLoginPage(email: state.extra as String? ?? ''),
        ),
        GoRoute(
          path: '/login/password',
          builder: (_, state) =>
              PasswordLoginPage(email: state.extra as String? ?? ''),
        ),
        GoRoute(
          path: AppRoutes.register,
          builder: (context, _) => const RegisterPage(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, _) => const ForgotPasswordPage(),
        ),
        GoRoute(
          path: '/reset-password',
          builder: (_, state) {
            final token = state.uri.queryParameters['token'] ?? '';
            return ResetPasswordPage(token: token);
          },
        ),
        GoRoute(
          path: '/accept-invite',
          builder: (_, state) {
            final token = state.uri.queryParameters['token'] ?? '';
            return AcceptInvitePage(token: token);
          },
        ),
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (_, __) => const WizardPageWrapper(),
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
            GoRoute(
              path: AppRoutes.professionals,
              builder: (context, _) => const ProfessionalsPage(),
              routes: [
                GoRoute(
                  path: ':id',
                  redirect: (_, state) {
                    final id = state.pathParameters['id'] ?? '';
                    if (!isValidUuid(id)) return AppRoutes.professionals;
                    return null;
                  },
                  builder: (_, state) => ProfessionalProfilePage(
                    professionalId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: AppRoutes.professionalRoles,
              builder: (context, _) => const RolesManagementPage(),
            ),
            GoRoute(path: AppRoutes.reports,      builder: (context, _) => const ReportsPage()),
            GoRoute(path: AppRoutes.settings,     builder: (context, _) => const SettingsPage()),
          ],
        ),
      ],
    );
