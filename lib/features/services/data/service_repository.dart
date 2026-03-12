import 'package:flutter_http/flutter_http.dart';
import 'package:scheduler_frontend/core/network/api_client.dart';
import 'package:scheduler_frontend/features/services/data/service_model.dart';

class ServiceRepository {
  final ApiClient _client;

  ServiceRepository(this._client);

  Future<Result<List<ServiceModel>>> getServices({
    required String businessId,
  }) =>
      _client.getList(
        '/businesses/$businessId/services',
        fromJson: ServiceModel.fromJson,
      );

  Future<Result<ServiceModel>> createService({
    required String businessId,
    required String name,
    String? description,
    double? price,
    int? durationMinutes,
  }) =>
      _client.post(
        '/businesses/$businessId/services',
        fromJson: ServiceModel.fromJson,
        body: {
          'name': name,
          if (description != null && description.isNotEmpty)
            'description': description,
          if (price != null) 'price': price,
          if (durationMinutes != null) 'durationMinutes': durationMinutes,
        },
      );

  Future<Result<ServiceModel>> updateService({
    required String businessId,
    required String serviceId,
    String? name,
    String? description,
    double? price,
    int? durationMinutes,
    bool? isActive,
  }) =>
      _client.patch(
        '/businesses/$businessId/services/$serviceId',
        fromJson: ServiceModel.fromJson,
        body: {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (price != null) 'price': price,
          if (durationMinutes != null) 'durationMinutes': durationMinutes,
          if (isActive != null) 'isActive': isActive,
        },
      );

  Future<Result<void>> deleteService({
    required String businessId,
    required String serviceId,
  }) =>
      _client.delete('/businesses/$businessId/services/$serviceId');
}
