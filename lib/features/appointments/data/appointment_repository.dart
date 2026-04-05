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
    required DateTime startsAt,
    int durationMinutes = 60,
    String? notes,
    String? recurrenceRule,
    String? serviceId,
    AppointmentStatus? status,
  }) =>
      _client.post(
        '/b/$slug/appointments',
        fromJson: AppointmentModel.fromJson,
        body: {
          'startsAt': startsAt.toUtc().toIso8601String(),
          'durationMinutes': durationMinutes,
          'clientName': clientName,
          'bookedBy': 'BUSINESS',
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          if (recurrenceRule != null) 'recurrenceRule': recurrenceRule,
          if (serviceId != null) 'serviceId': serviceId,
          if (status != null) 'status': status.apiValue,
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

  /// PATCH /b/:slug/appointments/:id
  Future<Result<AppointmentModel>> updateAppointment({
    required String slug,
    required String appointmentId,
    String? clientName,
    DateTime? startsAt,
    int? durationMinutes,
    String? notes,
    String? serviceId,
    bool clearNotes = false,
    bool clearService = false,
  }) =>
      _client.patch(
        '/b/$slug/appointments/$appointmentId',
        fromJson: AppointmentModel.fromJson,
        body: {
          if (clientName != null) 'clientName': clientName,
          if (startsAt != null) 'startsAt': startsAt.toUtc().toIso8601String(),
          if (durationMinutes != null) 'durationMinutes': durationMinutes,
          if (clearNotes) 'notes': null else if (notes != null) 'notes': notes,
          if (clearService) 'serviceId': null else if (serviceId != null) 'serviceId': serviceId,
        },
      );

  /// PATCH /b/:slug/appointments/:id/update-future
  Future<Result<Map<String, dynamic>>> updateFutureAppointments({
    required String slug,
    required String appointmentId,
    String? clientName,
    DateTime? startsAt,
    int? durationMinutes,
    String? notes,
    String? serviceId,
    bool clearNotes = false,
    bool clearService = false,
  }) =>
      _client.patch(
        '/b/$slug/appointments/$appointmentId/update-future',
        fromJson: (json) => json,
        body: {
          if (clientName != null) 'clientName': clientName,
          if (startsAt != null) 'startsAt': startsAt.toUtc().toIso8601String(),
          if (durationMinutes != null) 'durationMinutes': durationMinutes,
          if (clearNotes) 'notes': null else if (notes != null) 'notes': notes,
          if (clearService) 'serviceId': null else if (serviceId != null) 'serviceId': serviceId,
        },
      );
}
