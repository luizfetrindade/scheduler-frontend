import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/core/auth/auth_state.dart';

void main() {
  group('AuthRegisterOtpSent', () {
    test('equality is based on email', () {
      const a = AuthRegisterOtpSent('a@a.com');
      const b = AuthRegisterOtpSent('a@a.com');
      const c = AuthRegisterOtpSent('b@b.com');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('AuthLoginOtpSent', () {
    test('equality is based on email', () {
      const a = AuthLoginOtpSent(email: 'a@a.com');
      const b = AuthLoginOtpSent(email: 'a@a.com');
      const c = AuthLoginOtpSent(email: 'b@b.com');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
