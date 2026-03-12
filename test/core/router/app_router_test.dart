import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/core/router/app_router.dart';
import 'package:scheduler_frontend/core/router/app_routes.dart';

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
  });
}
