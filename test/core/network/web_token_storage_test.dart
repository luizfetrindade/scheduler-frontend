import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scheduler_frontend/core/network/web_token_storage.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('WebTokenStorage', () {
    late MockFlutterSecureStorage mockStorage;
    late WebTokenStorage tokenStorage;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      tokenStorage = WebTokenStorage(storage: mockStorage);
    });

    test('saveTokens writes only the access token — refresh token is an httpOnly cookie',
        () async {
      when(() => mockStorage.write(key: 'access_token', value: 'abc'))
          .thenAnswer((_) async {});

      await tokenStorage.saveTokens(accessToken: 'abc', refreshToken: 'ignored');

      verify(() => mockStorage.write(key: 'access_token', value: 'abc')).called(1);
      verifyNever(() => mockStorage.write(key: 'refresh_token', value: any(named: 'value')));
    });

    test('getAccessToken reads access token from secure storage', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => 'abc');

      final result = await tokenStorage.getAccessToken();

      expect(result, 'abc');
    });

    test('getAccessToken returns null when token absent', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);

      final result = await tokenStorage.getAccessToken();

      expect(result, isNull);
    });

    test('getRefreshToken always returns null — refresh token lives in httpOnly cookie',
        () async {
      final result = await tokenStorage.getRefreshToken();
      expect(result, isNull);
    });

    test('clearTokens deletes only the access token', () async {
      when(() => mockStorage.delete(key: 'access_token'))
          .thenAnswer((_) async {});

      await tokenStorage.clearTokens();

      verify(() => mockStorage.delete(key: 'access_token')).called(1);
      verifyNever(() => mockStorage.delete(key: 'refresh_token'));
    });
  });
}
