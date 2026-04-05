import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/core/auth/remember_me_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RememberMeStorage', () {
    test('load() returns (null, false) when empty', () async {
      final storage = RememberMeStorage();
      final result = await storage.load();
      expect(result.email, isNull);
      expect(result.enabled, isFalse);
    });

    test('save() persists email and sets enabled=true', () async {
      final storage = RememberMeStorage();
      await storage.save(email: 'a@a.com');

      final result = await storage.load();
      expect(result.email, 'a@a.com');
      expect(result.enabled, isTrue);
    });

    test('clear() removes both keys', () async {
      final storage = RememberMeStorage();
      await storage.save(email: 'a@a.com');
      await storage.clear();

      final result = await storage.load();
      expect(result.email, isNull);
      expect(result.enabled, isFalse);
    });

    test('save() overwrites a previously stored email', () async {
      final storage = RememberMeStorage();
      await storage.save(email: 'a@a.com');
      await storage.save(email: 'b@b.com');

      final result = await storage.load();
      expect(result.email, 'b@b.com');
      expect(result.enabled, isTrue);
    });
  });
}
