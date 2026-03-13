import 'package:flutter_http/flutter_http.dart';
import 'package:scheduler_frontend/core/network/api_client.dart';
import 'package:scheduler_frontend/features/clients/data/client_model.dart';

class ClientRepository {
  final ApiClient _client;

  ClientRepository(this._client);

  Future<Result<List<ClientModel>>> getClients({
    required String businessId,
  }) =>
      _client.getList(
        '/businesses/$businessId/clients',
        fromJson: ClientModel.fromJson,
      );

  Future<Result<ClientModel>> createClient({
    required String businessId,
    required String name,
    required String phone,
    String? email,
  }) =>
      _client.post(
        '/businesses/$businessId/clients',
        fromJson: ClientModel.fromJson,
        body: {
          'name': name,
          'phone': phone,
          if (email != null && email.isNotEmpty) 'email': email,
        },
      );

  Future<Result<ClientModel>> updateClient({
    required String businessId,
    required String clientId,
    required String name,
    required String phone,
    String? email,
  }) =>
      _client.patch(
        '/businesses/$businessId/clients/$clientId',
        fromJson: ClientModel.fromJson,
        body: {
          'name': name,
          'phone': phone,
          if (email != null && email.isNotEmpty) 'email': email,
        },
      );

  Future<Result<void>> deleteClient({
    required String businessId,
    required String clientId,
  }) =>
      _client.delete('/businesses/$businessId/clients/$clientId');

  Future<Result<List<ClientHistoryItem>>> getClientHistory({
    required String businessId,
    required String clientId,
  }) =>
      _client.getList(
        '/businesses/$businessId/clients/$clientId/appointments',
        fromJson: ClientHistoryItem.fromJson,
      );
}
