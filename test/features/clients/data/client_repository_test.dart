import 'package:flutter_http/flutter_http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scheduler_frontend/core/network/api_client.dart';
import 'package:scheduler_frontend/features/clients/data/client_model.dart';
import 'package:scheduler_frontend/features/clients/data/client_repository.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockClient;
  late ClientRepository repo;

  final client = const ClientModel(id: 'c-1', name: 'Ana', phone: '11999990000');

  setUp(() {
    mockClient = MockApiClient();
    repo = ClientRepository(mockClient);
  });

  group('ClientRepository', () {
    test('getClients calls getList with correct path', () async {
      when(() => mockClient.getList<ClientModel>(
            any(),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => Success([client]));

      final result = await repo.getClients(businessId: 'biz-1');
      expect(result, isA<Success<List<ClientModel>>>());
      verify(() => mockClient.getList<ClientModel>(
            '/businesses/biz-1/clients',
            fromJson: any(named: 'fromJson'),
          )).called(1);
    });

    test('createClient calls post with correct path and required fields', () async {
      Map<String, dynamic>? capturedBody;
      when(() => mockClient.post<ClientModel>(
            any(),
            fromJson: any(named: 'fromJson'),
            body: any(named: 'body'),
          )).thenAnswer((inv) async {
        capturedBody = inv.namedArguments[#body] as Map<String, dynamic>;
        return Success(client);
      });

      await repo.createClient(businessId: 'biz-1', name: 'Ana', phone: '11999990000');
      expect(capturedBody, containsPair('name', 'Ana'));
      expect(capturedBody, containsPair('phone', '11999990000'));
      expect(capturedBody, isNot(contains('email')));
    });

    test('createClient includes email when provided', () async {
      Map<String, dynamic>? capturedBody;
      when(() => mockClient.post<ClientModel>(
            any(),
            fromJson: any(named: 'fromJson'),
            body: any(named: 'body'),
          )).thenAnswer((inv) async {
        capturedBody = inv.namedArguments[#body] as Map<String, dynamic>;
        return Success(client);
      });

      await repo.createClient(
        businessId: 'biz-1',
        name: 'Ana',
        phone: '11999990000',
        email: 'ana@test.com',
      );
      expect(capturedBody, containsPair('email', 'ana@test.com'));
    });

    test('updateClient calls patch with correct path', () async {
      when(() => mockClient.patch<ClientModel>(
            any(),
            fromJson: any(named: 'fromJson'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => Success(client));

      final result = await repo.updateClient(
        businessId: 'biz-1',
        clientId: 'c-1',
        name: 'Ana Updated',
        phone: '11000000001',
      );
      expect(result, isA<Success<ClientModel>>());
      verify(() => mockClient.patch<ClientModel>(
            '/businesses/biz-1/clients/c-1',
            fromJson: any(named: 'fromJson'),
            body: any(named: 'body'),
          )).called(1);
    });

    test('deleteClient calls delete with correct path', () async {
      when(() => mockClient.delete(any()))
          .thenAnswer((_) async => const Success(null));

      final result = await repo.deleteClient(businessId: 'biz-1', clientId: 'c-1');
      expect(result, isA<Success<void>>());
      verify(() => mockClient.delete('/businesses/biz-1/clients/c-1')).called(1);
    });

    test('getClientHistory calls getList with correct path', () async {
      when(() => mockClient.getList<ClientHistoryItem>(
            any(),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => const Success([]));

      final result = await repo.getClientHistory(businessId: 'biz-1', clientId: 'c-1');
      expect(result, isA<Success<List<ClientHistoryItem>>>());
      verify(() => mockClient.getList<ClientHistoryItem>(
            '/businesses/biz-1/clients/c-1/appointments',
            fromJson: any(named: 'fromJson'),
          )).called(1);
    });
  });
}
