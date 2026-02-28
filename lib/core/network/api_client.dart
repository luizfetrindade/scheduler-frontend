import 'package:dio/dio.dart';
import 'package:flutter_http/flutter_http.dart';
import 'package:scheduler_frontend/core/config/app_config.dart';

/// Wraps flutter_http's HttpClient and transparently unwraps the backend's
/// response envelope: { "data": <payload>, "meta": { "timestamp": "..." } }.
///
/// All methods pass the unwrapped payload to `fromJson`, so repositories and
/// models never need to know about the envelope structure.
///
/// Also adds PATCH support via a raw Dio instance (flutter_http has no patch()).
///
/// Token auto-refresh is disabled (the interceptor in flutter_http sends the
/// refresh token as a JSON body, but the backend expects x-refresh-token header).
/// Unauthorized responses are handled in AuthBloc by emitting AuthUnauthenticated.
class ApiClient {
  final HttpClient _http;
  final Dio _rawDio;
  final TokenStorage tokenStorage;

  ApiClient._(this._http, this._rawDio, this.tokenStorage);

  factory ApiClient.create() {
    final ts = TokenStorage();
    final http = HttpClient(
      baseUrl: AppConfig.apiUrl,
      tokenStorage: ts,
      // Points to a non-existent endpoint to disable the interceptor's
      // auto-refresh (its format doesn't match our backend's x-refresh-token).
      refreshEndpoint: '/auth/_no_auto_refresh',
    );
    final rawDio = Dio(BaseOptions(
      baseUrl: AppConfig.apiUrl,
      contentType: 'application/json',
    ));
    return ApiClient._(http, rawDio, ts);
  }

  // ---------------------------------------------------------------------------
  // Public API — mirrors HttpClient but unwraps { data, meta } envelope
  // ---------------------------------------------------------------------------

  Future<Result<T>> get<T>(
    String path, {
    required T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic>? queryParams,
  }) =>
      _http.get(
        path,
        fromJson: (envelope) => fromJson(_unwrapObject(envelope)),
        queryParams: queryParams,
      );

  /// Backend returns { "data": [...], "meta": {...} } — NOT a raw array.
  /// flutter_http's getList() expects a raw array, so we use get<List<T>>
  /// with a custom fromJson that extracts json['data'] as a list.
  Future<Result<List<T>>> getList<T>(
    String path, {
    required T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic>? queryParams,
  }) =>
      _http.get<List<T>>(
        path,
        fromJson: (envelope) {
          final list = (envelope['data'] as List<dynamic>);
          return list
              .map((item) => fromJson(item as Map<String, dynamic>))
              .toList();
        },
        queryParams: queryParams,
      );

  Future<Result<T>> post<T>(
    String path, {
    required T Function(Map<String, dynamic>) fromJson,
    Object? body,
  }) =>
      _http.post(
        path,
        fromJson: (envelope) => fromJson(_unwrapObject(envelope)),
        body: body,
      );

  /// PATCH via raw Dio with manual Bearer token injection.
  /// Also unwraps the response envelope.
  Future<Result<T>> patch<T>(
    String path, {
    required T Function(Map<String, dynamic>) fromJson,
    Object? body,
  }) async {
    final token = await tokenStorage.getAccessToken();
    try {
      final response = await _rawDio.patch<Map<String, dynamic>>(
        path,
        data: body,
        options: Options(headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );
      return Success(fromJson(_unwrapObject(response.data!)));
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401) return const HttpFailure(UnauthorizedFailure('Unauthorized'));
      if (code == 404) return const HttpFailure(NotFoundFailure('Not found'));
      return HttpFailure(
          ServerFailure(e.message ?? 'Server error', statusCode: code ?? 500));
    } catch (e) {
      return HttpFailure(UnknownFailure(e.toString()));
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Extracts the `data` field from the backend response envelope.
  /// Falls back to the raw map if `data` is not present (e.g. in tests).
  Map<String, dynamic> _unwrapObject(Map<String, dynamic> envelope) {
    final data = envelope['data'];
    if (data is Map<String, dynamic>) return data;
    return envelope;
  }
}
