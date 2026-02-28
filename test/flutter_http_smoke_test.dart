import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_http/flutter_http.dart';

void main() {
  group('flutter_http smoke test', () {
    test('TokenStorage can be instantiated', () {
      final storage = TokenStorage();
      expect(storage, isNotNull);
    });

    test('AppFailure subtypes are accessible', () {
      const NetworkFailure network = NetworkFailure('no internet');
      const UnauthorizedFailure unauthorized = UnauthorizedFailure('401');
      const NotFoundFailure notFound = NotFoundFailure('404');
      const ServerFailure server = ServerFailure('500', statusCode: 500);
      const ParseFailure parse = ParseFailure('bad json');
      const UnknownFailure unknown = UnknownFailure('?');

      expect(network.message, 'no internet');
      expect(unauthorized.message, '401');
      expect(notFound.message, '404');
      expect(server.statusCode, 500);
      expect(parse.message, 'bad json');
      expect(unknown.message, '?');
    });

    test('Result<T> Success and HttpFailure are accessible', () {
      const Result<int> success = Success(42);
      final Result<int> failure = HttpFailure(const NetworkFailure('err'));

      expect(success.isSuccess, isTrue);
      expect(failure.isFailure, isTrue);
    });

    test('switch on Result is exhaustive', () {
      const Result<String> result = Success('gym');
      final value = switch (result) {
        Success(:final data) => data,
        HttpFailure() => 'fail',
      };
      expect(value, 'gym');
    });

    test('switch on AppFailure is exhaustive', () {
      const AppFailure failure = ServerFailure('error', statusCode: 503);
      final label = switch (failure) {
        NetworkFailure() => 'network',
        UnauthorizedFailure() => 'unauthorized',
        NotFoundFailure() => 'not_found',
        ServerFailure(:final statusCode) => 'server_$statusCode',
        ParseFailure() => 'parse',
        UnknownFailure() => 'unknown',
      };
      expect(label, 'server_503');
    });
  });
}
