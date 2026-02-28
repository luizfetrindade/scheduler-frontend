import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scheduler_frontend/core/cache/preferences_service.dart';

void main() {
  group('PreferencesService', () {
    late PreferencesService prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = PreferencesService();
      await prefs.init();
    });

    test('getString returns null for missing key', () {
      expect(prefs.getString('key'), isNull);
    });

    test('setString and getString round-trip', () async {
      await prefs.setString('locale', 'pt');
      expect(prefs.getString('locale'), 'pt');
    });

    test('getBool returns null for missing key', () {
      expect(prefs.getBool('flag'), isNull);
    });

    test('setBool and getBool round-trip', () async {
      await prefs.setBool('isLoggedIn', true);
      expect(prefs.getBool('isLoggedIn'), isTrue);
    });

    test('remove deletes a key', () async {
      await prefs.setString('key', 'value');
      await prefs.remove('key');
      expect(prefs.getString('key'), isNull);
    });

    test('clear removes all keys', () async {
      await prefs.setString('a', '1');
      await prefs.setBool('b', true);
      await prefs.clear();
      expect(prefs.getString('a'), isNull);
      expect(prefs.getBool('b'), isNull);
    });

    test('getInt returns null for missing key', () {
      expect(prefs.getInt('count'), isNull);
    });

    test('setInt and getInt round-trip', () async {
      await prefs.setInt('count', 42);
      expect(prefs.getInt('count'), 42);
    });

    test('getDouble returns null for missing key', () {
      expect(prefs.getDouble('weight'), isNull);
    });

    test('setDouble and getDouble round-trip', () async {
      await prefs.setDouble('weight', 75.5);
      expect(prefs.getDouble('weight'), 75.5);
    });
  });
}
