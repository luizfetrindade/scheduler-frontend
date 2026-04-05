import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/core/router/app_router.dart';
import 'package:scheduler_frontend/core/router/app_routes.dart';

// ignore_for_file: lines_longer_than_80_chars

/// Tests the pure redirect logic extracted from GoRouter.
/// GoRouter + BLoC widget tests are covered by integration/E2E tests.
void main() {
  group('computeRedirect — unauthenticated', () {
    test('redirects to login when on home route', () {
      expect(
        computeRedirect(isLoggedIn: false, location: AppRoutes.home),
        equals(AppRoutes.login),
      );
    });

    test('no redirect when already on login route', () {
      expect(
        computeRedirect(isLoggedIn: false, location: AppRoutes.login),
        isNull,
      );
    });

    test('redirects to login when on unknown route', () {
      expect(
        computeRedirect(isLoggedIn: false, location: '/other'),
        equals(AppRoutes.login),
      );
    });

    test('no redirect when on register route', () {
      expect(
        computeRedirect(isLoggedIn: false, location: AppRoutes.register),
        isNull,
      );
    });
  });

  group('computeRedirect — new public paths (unauthenticated)', () {
    test('no redirect when on /reset-password', () {
      expect(
        computeRedirect(isLoggedIn: false, location: '/reset-password'),
        isNull,
      );
    });

    test('no redirect when on /reset-password with query param', () {
      expect(
        computeRedirect(
            isLoggedIn: false, location: '/reset-password?token=abc'),
        isNull,
      );
    });

    test('no redirect when on /accept-invite', () {
      expect(
        computeRedirect(isLoggedIn: false, location: '/accept-invite'),
        isNull,
      );
    });

    test('no redirect when on /forgot-password', () {
      expect(
        computeRedirect(isLoggedIn: false, location: '/forgot-password'),
        isNull,
      );
    });

    test('no redirect when on /login/totp', () {
      expect(
        computeRedirect(isLoggedIn: false, location: '/login/totp'),
        isNull,
      );
    });

    test('no redirect when on /login/password', () {
      expect(
        computeRedirect(isLoggedIn: false, location: '/login/password'),
        isNull,
      );
    });
  });

  // ─── extractToken ────────────────────────────────────────────────────────────

  group('extractToken — fragment (preferred, safe path)', () {
    test('extracts token from fragment (#token=VALUE)', () {
      final uri = Uri.parse('/reset-password#token=abc123');
      expect(extractToken(uri), equals('abc123'));
    });

    test('extracts invite token from fragment', () {
      final uri = Uri.parse('/accept-invite#token=invite-xyz');
      expect(extractToken(uri), equals('invite-xyz'));
    });

    test('prefers fragment over query parameter when both present', () {
      final uri = Uri.parse('/reset-password?token=query-token#token=fragment-token');
      expect(extractToken(uri), equals('fragment-token'));
    });
  });

  group('extractToken — query param fallback (backward compatibility)', () {
    test('falls back to query parameter when no fragment', () {
      final uri = Uri.parse('/reset-password?token=legacy-token');
      expect(extractToken(uri), equals('legacy-token'));
    });

    test('falls back to query parameter for invite link', () {
      final uri = Uri.parse('/accept-invite?token=legacy-invite');
      expect(extractToken(uri), equals('legacy-invite'));
    });
  });

  group('extractToken — missing token', () {
    test('returns empty string when neither fragment nor query param present', () {
      final uri = Uri.parse('/reset-password');
      expect(extractToken(uri), isEmpty);
    });

    test('returns empty string when fragment has no token key', () {
      final uri = Uri.parse('/reset-password#other=value');
      expect(extractToken(uri), isEmpty);
    });
  });

  group('computeRedirect — authenticated', () {
    test('no redirect when on home route', () {
      expect(
        computeRedirect(isLoggedIn: true, location: AppRoutes.home),
        isNull,
      );
    });

    test('redirects to home when on login route (already authenticated)', () {
      expect(
        computeRedirect(isLoggedIn: true, location: AppRoutes.login),
        equals(AppRoutes.home),
      );
    });

    test('no redirect when on other authenticated route', () {
      expect(
        computeRedirect(isLoggedIn: true, location: '/other'),
        isNull,
      );
    });

    test('redirects to home when on register route (already authenticated)', () {
      expect(
        computeRedirect(isLoggedIn: true, location: AppRoutes.register),
        equals(AppRoutes.home),
      );
    });

    test('redirects to home when on /reset-password (already authenticated)',
        () {
      expect(
        computeRedirect(isLoggedIn: true, location: '/reset-password'),
        equals(AppRoutes.home),
      );
    });

    test('redirects to home when on /accept-invite (already authenticated)',
        () {
      expect(
        computeRedirect(isLoggedIn: true, location: '/accept-invite'),
        equals(AppRoutes.home),
      );
    });

    test('redirects to home when on /forgot-password (already authenticated)',
        () {
      expect(
        computeRedirect(isLoggedIn: true, location: '/forgot-password'),
        equals(AppRoutes.home),
      );
    });
  });
}
