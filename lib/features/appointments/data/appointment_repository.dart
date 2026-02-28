import 'package:flutter_http/flutter_http.dart';
import 'package:intl/intl.dart';
import 'package:scheduler_frontend/core/network/api_client.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';

class AppointmentRepository {
  final ApiClient _client;

  AppointmentRepository(this._client);

  Future<Result<List<AppointmentModel>>> getAppointments({
    required String slug,
    required DateTime date,
  }) =>
      _client.getList(
        '/b/$slug/appointments',
        fromJson: AppointmentModel.fromJson,
        queryParams: {'date': DateFormat('yyyy-MM-dd').format(date)},
      );

  /// PATCH /b/:slug/appointments/:id/status
  /// Accepted status values: CONFIRMED, COMPLETED, NO_SHOW
  Future<Result<Map<String, dynamic>>> updateStatus({
    required String slug,
    required String appointmentId,
    required AppointmentStatus status,
  }) =>
      _client.patch(
        '/b/$slug/appointments/$appointmentId/status',
        fromJson: (json) => json,
        body: {'status': status.apiValue},
      );
}
