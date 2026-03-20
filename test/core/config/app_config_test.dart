import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/core/config/app_config.dart';

// NOTE: AppConfig values are compile-time constants (String.fromEnvironment).
// The tests below only cover the default (dev) environment.
// To test staging/prod environments run:
//   flutter test --dart-define=ENV=staging
//   flutter test --dart-define=ENV=prod
// See the Makefile targets test-staging and test-prod.

void main() {
  group('AppConfig', () {
    test('apiUrl defaults to localhost:3000', () {
      expect(AppConfig.apiUrl, 'http://localhost:3000');
    });

    test('env defaults to dev when no dart-define is set', () {
      expect(AppConfig.env, 'dev');
    });

    test('isDev returns true for default env', () {
      expect(AppConfig.isDev, isTrue);
    });

    test('isStaging returns false for default env', () {
      expect(AppConfig.isStaging, isFalse);
    });

    test('isProd returns false for default env', () {
      expect(AppConfig.isProd, isFalse);
    });
  });

  group('validateApiUrl', () {
    test('returns URL unchanged in dev (HTTP allowed)', () {
      expect(
        validateApiUrl('http://localhost:3000', isProd: false),
        'http://localhost:3000',
      );
    });

    test('returns HTTPS URL unchanged in prod', () {
      expect(
        validateApiUrl('https://api.example.com', isProd: true),
        'https://api.example.com',
      );
    });

    test('throws StateError for HTTP URL in prod', () {
      expect(
        () => validateApiUrl('http://api.example.com', isProd: true),
        throwsA(isA<StateError>()),
      );
    });

    test('throws StateError for localhost HTTP in prod', () {
      expect(
        () => validateApiUrl('http://localhost:3000', isProd: true),
        throwsA(isA<StateError>()),
      );
    });

    test('StateError message contains the bad URL', () {
      expect(
        () => validateApiUrl('http://api.example.com', isProd: true),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('http://api.example.com'),
          ),
        ),
      );
    });
  });
}
