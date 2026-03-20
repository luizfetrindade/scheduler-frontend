import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_http/flutter_http.dart';
import 'package:mutex/mutex.dart';
import 'package:scheduler_frontend/core/config/app_config.dart';
import 'package:scheduler_frontend/core/network/web_token_storage.dart';

/// Returns an [HttpFailure] carrying a generic, non-revealing [UnknownFailure].
///
/// The raw [error] and [stack] are printed to the debug console for developer
/// diagnostics but are never included in the returned failure message, so that
/// internal paths, class names, and stack traces are not exposed to callers.
///
/// Exposed as a top-level function so that unit tests can exercise the A7 fix
/// without needing a full [ApiClient] instance.
Result<T> apiClientUnknownFailure<T>(Object error, StackTrace stack) {
  debugPrint('ApiClient unexpected error: $error\n$stack');
  return const HttpFailure(UnknownFailure('Erro inesperado. Tente novamente.'));
}

/// Wraps flutter_http's HttpClient and transparently unwraps the backend's
/// response envelope: { "data": <payload>, "meta": { "timestamp": "..." } }.
///
/// All methods pass the unwrapped payload to `fromJson`, so repositories and
/// models never need to know about the envelope structure.
///
/// Also adds PATCH and DELETE support via a raw Dio instance (flutter_http has
/// no patch() or delete()).
///
/// The refresh token is now managed as an httpOnly cookie by the backend.
/// On web, the browser sends it automatically. On mobile, [CookieJar] persists
/// and sends the cookie on every request to /auth/*.
/// Unauthorized responses are handled in AuthBloc by emitting AuthUnauthenticated.
class ApiClient {
  final HttpClient _http;
  final Dio _rawDio;
  final TokenStorage tokenStorage;

  /// M8 — serialises concurrent token reads so that an expiry check is always
  /// based on the latest stored value, preventing race conditions when multiple
  /// requests fire simultaneously.
  final _tokenMutex = Mutex();

  ApiClient._(this._http, this._rawDio, this.tokenStorage);

  factory ApiClient.create() {
    final ts = kIsWeb ? WebTokenStorage() : TokenStorage();
    final http = HttpClient(
      baseUrl: AppConfig.apiUrl,
      tokenStorage: ts,
      refreshEndpoint: '/auth/_no_auto_refresh',
    );
    final rawDio = Dio(BaseOptions(
      baseUrl: AppConfig.apiUrl,
      contentType: 'application/json',
      // A3 — send cookies (including httpOnly refresh_token) cross-origin on web.
      extra: {'withCredentials': true},
    ));
    // A3 — on mobile (iOS/Android), persist and send the httpOnly refresh_token
    // cookie automatically via CookieJar. On web the browser handles this.
    if (!kIsWeb) {
      rawDio.interceptors.add(CookieManager(CookieJar()));
    }
    return ApiClient._(http, rawDio, ts);
  }

  /// Test-only factory that injects a mock [TokenStorage] and a Dio instance
  /// configured with a localhost base URL that will fail fast (no real server
  /// needed for unit tests that only verify token-reading behaviour).
  factory ApiClient.forTest({required TokenStorage tokenStorage}) {
    final http = HttpClient(
      baseUrl: 'http://localhost',
      tokenStorage: tokenStorage,
      refreshEndpoint: '/auth/_no_auto_refresh',
    );
    final rawDio = Dio(BaseOptions(
      baseUrl: 'http://localhost',
      contentType: 'application/json',
      connectTimeout: const Duration(milliseconds: 100),
      receiveTimeout: const Duration(milliseconds: 100),
    ));
    return ApiClient._(http, rawDio, tokenStorage);
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

  /// DELETE via raw Dio. Backend returns 204 No Content — no body to unwrap.
  Future<Result<void>> delete(String path) async {
    try {
      // M8 — token read is serialised through the mutex.
      final token = await _getToken();
      await _rawDio.delete<void>(
        path,
        options: Options(headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );
      return const Success(null);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401) return const HttpFailure(UnauthorizedFailure('Unauthorized'));
      if (code == 404) return const HttpFailure(NotFoundFailure('Not found'));
      final backendMessage = _extractBackendMessage(e);
      return HttpFailure(
          ServerFailure(backendMessage ?? e.message ?? 'Server error', statusCode: code ?? 500));
    } catch (e, stack) {
      // A7 — generic message; raw error is only printed, never returned.
      return apiClientUnknownFailure<void>(e, stack);
    }
  }

  /// PATCH via raw Dio with manual Bearer token injection.
  /// Also unwraps the response envelope.
  Future<Result<T>> patch<T>(
    String path, {
    required T Function(Map<String, dynamic>) fromJson,
    Object? body,
  }) async {
    try {
      // M8 — token read is serialised through the mutex.
      final token = await _getToken();
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
      final backendMessage = _extractBackendMessage(e);
      return HttpFailure(
          ServerFailure(backendMessage ?? e.message ?? 'Server error', statusCode: code ?? 500));
    } catch (e, stack) {
      // A7 — generic message; raw error is only printed, never returned.
      return apiClientUnknownFailure<T>(e, stack);
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// M8 — Serialises token reads through a mutex so that concurrent requests
  /// always see a consistent token value and avoid race conditions on expiry.
  Future<String?> _getToken() => _tokenMutex.protect(
        () => tokenStorage.getAccessToken(),
      );

  /// Extracts the `data` field from the backend response envelope.
  /// Falls back to the raw map if `data` is not present (e.g. in tests).
  Map<String, dynamic> _unwrapObject(Map<String, dynamic> envelope) {
    final data = envelope['data'];
    if (data is Map<String, dynamic>) return data;
    return envelope;
  }

  /// Extracts the human-readable error message from a DioException response.
  /// NestJS returns { "statusCode": N, "message": "...", "error": "..." }.
  String? _extractBackendMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final message = data['message'];
      if (message is String) return message;
    }
    return null;
  }
}
