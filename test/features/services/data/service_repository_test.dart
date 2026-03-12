import 'package:flutter_http/flutter_http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scheduler_frontend/core/network/api_client.dart';
import 'package:scheduler_frontend/features/services/data/service_model.dart';
import 'package:scheduler_frontend/features/services/data/service_repository.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockClient;
  late ServiceRepository repo;

  final svc = ServiceModel(
    id: 'svc-1',
    name: 'Corte',
    isActive: true,
  );

  setUp(() {
    mockClient = MockApiClient();
    repo = ServiceRepository(mockClient);
  });

  group('ServiceRepository', () {
    test('getServices calls getList with correct path', () async {
      when(() => mockClient.getList<ServiceModel>(
            any(),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => Success([svc]));

      final result = await repo.getServices(businessId: 'biz-1');
      expect(result, isA<Success<List<ServiceModel>>>());
      verify(() => mockClient.getList<ServiceModel>(
            '/businesses/biz-1/services',
            fromJson: any(named: 'fromJson'),
          )).called(1);
    });

    test('createService calls post with correct path', () async {
      when(() => mockClient.post<ServiceModel>(
            any(),
            fromJson: any(named: 'fromJson'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => Success(svc));

      final result = await repo.createService(
        businessId: 'biz-1',
        name: 'Corte',
        price: 45.0,
        durationMinutes: 30,
      );
      expect(result, isA<Success<ServiceModel>>());
      verify(() => mockClient.post<ServiceModel>(
            '/businesses/biz-1/services',
            fromJson: any(named: 'fromJson'),
            body: any(named: 'body'),
          )).called(1);
    });

    test('updateService calls patch with correct path', () async {
      when(() => mockClient.patch<ServiceModel>(
            any(),
            fromJson: any(named: 'fromJson'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => Success(svc));

      final result = await repo.updateService(
        businessId: 'biz-1',
        serviceId: 'svc-1',
        isActive: false,
      );
      expect(result, isA<Success<ServiceModel>>());
      verify(() => mockClient.patch<ServiceModel>(
            '/businesses/biz-1/services/svc-1',
            fromJson: any(named: 'fromJson'),
            body: any(named: 'body'),
          )).called(1);
    });

    test('createService excludes null optional fields from body', () async {
      Map<String, dynamic>? capturedBody;
      when(() => mockClient.post<ServiceModel>(
            any(),
            fromJson: any(named: 'fromJson'),
            body: any(named: 'body'),
          )).thenAnswer((invocation) async {
        capturedBody = invocation.namedArguments[#body] as Map<String, dynamic>;
        return Success(svc);
      });

      await repo.createService(
        businessId: 'biz-1',
        name: 'Corte',
        // price and durationMinutes intentionally omitted (null)
      );

      expect(capturedBody, containsPair('name', 'Corte'));
      expect(capturedBody, isNot(contains('price')));
      expect(capturedBody, isNot(contains('durationMinutes')));
    });

    test('deleteService calls delete with correct path', () async {
      when(() => mockClient.delete(any()))
          .thenAnswer((_) async => const Success(null));

      final result = await repo.deleteService(
        businessId: 'biz-1',
        serviceId: 'svc-1',
      );
      expect(result, isA<Success<void>>());
      verify(() => mockClient.delete('/businesses/biz-1/services/svc-1'))
          .called(1);
    });
  });
}
