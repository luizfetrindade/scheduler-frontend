import 'package:flutter_http/flutter_http.dart';
import 'package:scheduler_frontend/core/network/api_client.dart';
import 'package:scheduler_frontend/features/reports/data/reports_model.dart';

class ReportsRepository {
  final ApiClient _client;

  ReportsRepository(this._client);

  Future<Result<ReportsModel>> getReport({
    required String slug,
    required ReportPeriod period,
  }) =>
      _client.get(
        '/b/$slug/reports',
        fromJson: ReportsModel.fromJson,
        queryParams: {'period': period.apiValue},
      );
}
