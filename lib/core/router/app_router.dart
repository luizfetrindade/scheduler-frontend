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
import 'package:scheduler_frontend/features/profile/presentation/profile_page.dart';
import 'package:scheduler_frontend/features/settings/presentation/settings_page.dart';

/// Extracts a one-time token from a deep-link or web URI.
///
/// Preference order (most secure first):
/// 1. URL fragment (`#token=VALUE`) — fragment is never sent to servers and
///    never appears in Referer headers, preventing leakage via CDN/proxy logs.
/// 2. Query parameter (`?token=VALUE`) — fallback for existing email links
///    that the backend already sent with the old format.
///
/// Returns an empty string when no token is found.
String extractToken(Uri uri) {
  if (uri.fragment.isNotEmpty) {
    final fragmentParams = Uri.splitQueryString(uri.fragment);
    final token = fragmentParams['token'];
    if (token != null && token.isNotEmpty) return token;
  }
  return uri.queryParameters['token'] ?? '';
}

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
          builder: (_, state) {
            final email = state.uri.queryParameters['email'] ?? '';
            final rememberMe =
                state.uri.queryParameters['rememberMe'] == 'true';
            return TotpLoginPage(email: email, rememberMe: rememberMe);
          },
        ),
        GoRoute(
          path: '/login/password',
          builder: (_, state) {
            final extra = state.extra;
            if (extra is ({String email, bool rememberMe})) {
              return PasswordLoginPage(
                email: extra.email,
                rememberMe: extra.rememberMe,
              );
            }
            return const PasswordLoginPage(email: '', rememberMe: false);
          },
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
          builder: (_, state) =>
              ResetPasswordPage(token: extractToken(state.uri)),
        ),
        GoRoute(
          path: '/accept-invite',
          builder: (_, state) =>
              AcceptInvitePage(token: extractToken(state.uri)),
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
            GoRoute(path: AppRoutes.profile,      builder: (context, _) => const ProfilePage()),
          ],
        ),
      ],
    );
