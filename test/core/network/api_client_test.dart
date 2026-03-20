import 'package:flutter_http/flutter_http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scheduler_frontend/core/network/api_client.dart';

class MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  group('ApiClient', () {
    late MockTokenStorage mockTokenStorage;

    setUp(() {
      mockTokenStorage = MockTokenStorage();
    });

    // -------------------------------------------------------------------------
    // Instantiation
    // -------------------------------------------------------------------------

    test('can be instantiated via testable constructor', () {
      final client = ApiClient.forTest(tokenStorage: mockTokenStorage);
      expect(client, isNotNull);
    });

    // -------------------------------------------------------------------------
    // A7 — apiClientUnknownFailure returns generic message (no internals leaked)
    // -------------------------------------------------------------------------

    test(
        'apiClientUnknownFailure<void> returns HttpFailure with generic '
        'message and does not expose internal error details', () {
      final error = Exception('sensitive internal path: /home/user/secret');
      final stack = StackTrace.current;

      final result = apiClientUnknownFailure<void>(error, stack);

      expect(result, isA<HttpFailure<void>>());
      final failure = (result as HttpFailure<void>).failure;
      expect(failure, isA<UnknownFailure>());
      expect(failure.message, 'Erro inesperado. Tente novamente.');
      // Must NOT contain the raw exception string
      expect(failure.message, isNot(contains('sensitive')));
      expect(failure.message, isNot(contains('home/user')));
    });

    test(
        'apiClientUnknownFailure<String> returns HttpFailure with generic '
        'message for typed result', () {
      final error = StateError('internal_state_leak');
      final stack = StackTrace.current;

      final result = apiClientUnknownFailure<String>(error, stack);

      expect(result, isA<HttpFailure<String>>());
      final failure = (result as HttpFailure<String>).failure;
      expect(failure.message, 'Erro inesperado. Tente novamente.');
      expect(failure.message, isNot(contains('internal_state_leak')));
    });

    // -------------------------------------------------------------------------
    // M8 — _getToken delegates to tokenStorage exactly once per call
    // -------------------------------------------------------------------------

    test('delete calls getAccessToken exactly once via _getToken', () async {
      when(() => mockTokenStorage.getAccessToken())
          .thenAnswer((_) async => 'test-token');

      final client = ApiClient.forTest(tokenStorage: mockTokenStorage);

      // delete will fail at the network layer (no real server), but
      // getAccessToken must have been called before the network attempt.
      await client.delete('/test').then((_) {}).catchError((_) {});

      verify(() => mockTokenStorage.getAccessToken()).called(1);
    });

    test('patch calls getAccessToken exactly once via _getToken', () async {
      when(() => mockTokenStorage.getAccessToken())
          .thenAnswer((_) async => 'test-token');

      final client = ApiClient.forTest(tokenStorage: mockTokenStorage);

      await client
          .patch<Map<String, dynamic>>(
            '/test',
            fromJson: (json) => json,
            body: {'key': 'value'},
          )
          .then((_) {})
          .catchError((_) {});

      verify(() => mockTokenStorage.getAccessToken()).called(1);
    });

    // -------------------------------------------------------------------------
    // A7 — generic catch in delete/patch returns safe generic message
    // -------------------------------------------------------------------------

    test(
        'delete returns HttpFailure(UnknownFailure) with generic message '
        'when an unexpected exception is thrown before the Dio call', () async {
      // Arrange: make getAccessToken throw a non-DioException
      when(() => mockTokenStorage.getAccessToken())
          .thenThrow(StateError('unexpected'));

      final client = ApiClient.forTest(tokenStorage: mockTokenStorage);
      final result = await client.delete('/any');

      expect(result, isA<HttpFailure<void>>());
      final failure = (result as HttpFailure<void>).failure;
      expect(failure, isA<UnknownFailure>());
      expect(failure.message, 'Erro inesperado. Tente novamente.');
      // Must not expose the raw StateError message
      expect(failure.message, isNot(contains('unexpected')));
    });

    test(
        'patch returns HttpFailure(UnknownFailure) with generic message '
        'when an unexpected exception is thrown before the Dio call', () async {
      when(() => mockTokenStorage.getAccessToken())
          .thenThrow(StateError('unexpected'));

      final client = ApiClient.forTest(tokenStorage: mockTokenStorage);
      final result = await client.patch<Map<String, dynamic>>(
        '/any',
        fromJson: (json) => json,
      );

      expect(result, isA<HttpFailure<Map<String, dynamic>>>());
      final failure = (result as HttpFailure<Map<String, dynamic>>).failure;
      expect(failure, isA<UnknownFailure>());
      expect(failure.message, 'Erro inesperado. Tente novamente.');
      expect(failure.message, isNot(contains('unexpected')));
    });
  });
}
