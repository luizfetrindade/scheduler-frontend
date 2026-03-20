import 'package:flutter_http/flutter_http.dart';
import 'package:scheduler_frontend/core/network/api_client.dart';
import 'package:scheduler_frontend/features/business/data/business_model.dart';

class BusinessRepository {
  final ApiClient _client;

  BusinessRepository(this._client);

  Future<Result<List<BusinessModel>>> getBusinesses() =>
      _client.getList('/businesses', fromJson: BusinessModel.fromJson);

  Future<Result<List<BusinessModel>>> getBusinessesMine() =>
      _client.getBusinessesMine();
}
