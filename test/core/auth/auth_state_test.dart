import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/core/auth/auth_state.dart';

void main() {
  group('AuthTotpSetupReady — sensitive fields must not leak', () {
    const state = AuthTotpSetupReady(
      qrCodeUrl: 'otpauth://totp/Scheduler:a@a.com',
      secret: 'SENSITIVE_SECRET',
      tempToken: 'SENSITIVE_TOKEN',
    );

    test('secret is not in props', () {
      expect(state.props, isNot(contains('SENSITIVE_SECRET')));
    });

    test('tempToken is not in props', () {
      expect(state.props, isNot(contains('SENSITIVE_TOKEN')));
    });

    test('toString() does not contain secret', () {
      expect(state.toString(), isNot(contains('SENSITIVE_SECRET')));
    });

    test('toString() does not contain tempToken', () {
      expect(state.toString(), isNot(contains('SENSITIVE_TOKEN')));
    });

    test('equality is based on qrCodeUrl only', () {
      const other = AuthTotpSetupReady(
        qrCodeUrl: 'otpauth://totp/Scheduler:a@a.com',
        secret: 'DIFFERENT_SECRET',
        tempToken: 'DIFFERENT_TOKEN',
      );
      expect(state, equals(other));
    });
  });
}
