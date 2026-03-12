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

  /// POST /b/:slug/appointments
  Future<Result<AppointmentModel>> createAppointment({
    required String slug,
    required String clientName,
    required String clientEmail,
    required DateTime startsAt,
    int durationMinutes = 60,
    String? notes,
    String? recurrenceRule,
  }) =>
      _client.post(
        '/b/$slug/appointments',
        fromJson: AppointmentModel.fromJson,
        body: {
          'startsAt': startsAt.toUtc().toIso8601String(),
          'durationMinutes': durationMinutes,
          'clientName': clientName,
          'clientEmail': clientEmail,
          'bookedBy': 'BUSINESS',
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          if (recurrenceRule != null) 'recurrenceRule': recurrenceRule,
        },
      );

  /// POST /b/:slug/appointments/blocks
  Future<Result<AppointmentModel>> createBlock({
    required String slug,
    required DateTime startsAt,
    required int durationMinutes,
    String? title,
    String? notes,
    String? staffId,
    String? recurrenceRule,
  }) =>
      _client.post(
        '/b/$slug/appointments/blocks',
        fromJson: AppointmentModel.fromJson,
        body: {
          'startsAt': startsAt.toUtc().toIso8601String(),
          'durationMinutes': durationMinutes,
          if (title != null && title.isNotEmpty) 'title': title,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          if (staffId != null) 'staffId': staffId,
          if (recurrenceRule != null) 'recurrenceRule': recurrenceRule,
        },
      );

  /// PATCH /b/:slug/appointments/:id/cancel
  Future<Result<Map<String, dynamic>>> cancelAppointment({
    required String slug,
    required String appointmentId,
  }) =>
      _client.patch(
        '/b/$slug/appointments/$appointmentId/cancel',
        fromJson: (json) => json,
      );

  /// PATCH /b/:slug/appointments/:id/cancel-future
  Future<Result<Map<String, dynamic>>> cancelFutureOccurrences({
    required String slug,
    required String appointmentId,
  }) =>
      _client.patch(
        '/b/$slug/appointments/$appointmentId/cancel-future',
        fromJson: (json) => json,
      );
}
