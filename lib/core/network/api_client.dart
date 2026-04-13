import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart' show VoidCallback, kIsWeb;
import 'package:flutter_http/flutter_http.dart';
import 'package:mutex/mutex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scheduler_frontend/core/config/app_config.dart';
import 'package:scheduler_frontend/core/network/web_token_storage.dart';
import 'package:scheduler_frontend/features/business/data/business_model.dart';

/// Returns an [HttpFailure] carrying a generic, non-revealing [UnknownFailure].
///
/// The raw [error] and [stack] are printed to the debug console for developer
/// diagnostics but are never included in the returned failure message, so that
/// internal paths, class names, and stack traces are not exposed to callers.
///
/// Exposed as a top-level function so that unit tests can exercise the A7 fix
/// without needing a full [ApiClient] instance.
Result<T> apiClientUnknownFailure<T>(Object error, StackTrace stack) {
  print('ApiClient unexpected error: $error\n$stack');
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
  final Dio _rawDio;
  final TokenStorage tokenStorage;

  /// The persisted cookie jar used on mobile to store the httpOnly refresh
  /// token. Null on web (the browser manages cookies natively).
  /// Exposed so that [clearCookies] can wipe refresh tokens on logout.
  final CookieJar? _cookieJar;

  /// M8 — serialises concurrent token reads so that an expiry check is always
  /// based on the latest stored value, preventing race conditions when multiple
  /// requests fire simultaneously.
  final _tokenMutex = Mutex();

  /// Called when a 401 response cannot be recovered by refreshing the token.
  /// Typically wired to trigger [AuthLogoutRequested] so the user is redirected
  /// to the login screen instead of seeing misleading "no permission" errors.
  VoidCallback? onAuthExpired;

  ApiClient._(this._rawDio, this.tokenStorage, [this._cookieJar]);

  /// Creates a production [ApiClient].
  ///
  /// On mobile (iOS/Android) the httpOnly refresh_token cookie is persisted to
  /// disk via [PersistCookieJar] so that the user stays logged in across app
  /// restarts. [getApplicationDocumentsDirectory] is called once to obtain a
  /// stable, app-private directory that survives process kills.
  ///
  /// On web the browser manages cookies automatically; no jar is needed.
  static Future<ApiClient> create() async {
    final ts = kIsWeb ? WebTokenStorage() : TokenStorage();
    final validatedUrl = AppConfig.validatedApiUrl;
    final rawDio = Dio(BaseOptions(
      baseUrl: validatedUrl,
      contentType: 'application/json',
      // A3 — send cookies (including httpOnly refresh_token) cross-origin on web.
      extra: {'withCredentials': true},
    ));
    if (!kIsWeb) {
      // HIGH-02 fix: PersistCookieJar writes the httpOnly refresh_token to the
      // app's documents directory so it survives process kills. The in-memory
      // CookieJar() it replaces lost the cookie on every cold start, forcing
      // the user to log in again after closing the app.
      final dir = await getApplicationDocumentsDirectory();
      final cookieJar = PersistCookieJar(
        storage: FileStorage('${dir.path}/.cookies/'),
      );
      rawDio.interceptors.add(CookieManager(cookieJar));
      return ApiClient._(rawDio, ts, cookieJar);
    }
    return ApiClient._(rawDio, ts);
  }

  /// Test-only factory that injects a mock [TokenStorage] and a Dio instance
  /// configured with a localhost base URL that will fail fast (no real server
  /// needed for unit tests that only verify token-reading behaviour).
  factory ApiClient.forTest({required TokenStorage tokenStorage}) {
    final rawDio = Dio(BaseOptions(
      baseUrl: 'http://localhost',
      contentType: 'application/json',
      connectTimeout: const Duration(milliseconds: 100),
      receiveTimeout: const Duration(milliseconds: 100),
    ));
    return ApiClient._(rawDio, tokenStorage);
  }

  // ---------------------------------------------------------------------------
  // Public API — mirrors HttpClient but unwraps { data, meta } envelope.
  // Every authenticated method is wrapped with [_withRefresh] so that an
  // expired access token triggers a transparent refresh + retry cycle.
  // ---------------------------------------------------------------------------

  Future<Result<T>> get<T>(
    String path, {
    required T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic>? queryParams,
  }) =>
      _withRefresh(
        () => _getInner(path, fromJson: fromJson, queryParams: queryParams),
        path: path,
      );

  /// Backend returns { "data": [...], "meta": {...} } — NOT a raw array.
  /// flutter_http's getList() expects a raw array, so we use get<List<T>>
  /// with a custom fromJson that extracts json['data'] as a list.
  Future<Result<List<T>>> getList<T>(
    String path, {
    required T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic>? queryParams,
  }) =>
      _withRefresh(
        () => _getListInner(path, fromJson: fromJson, queryParams: queryParams),
        path: path,
      );

  /// Fetches the list of businesses for the authenticated user from
  /// `/businesses/mine`. Unwraps the backend's `{ "data": [...] }` envelope.
  Future<Result<List<BusinessModel>>> getBusinessesMine() =>
      _withRefresh(
        () => _getListInner('/businesses/mine', fromJson: BusinessModel.fromJson),
        path: '/businesses/mine',
      );

  Future<Result<T>> post<T>(
    String path, {
    required T Function(Map<String, dynamic>) fromJson,
    Object? body,
  }) =>
      _withRefresh(
        () => _postInner(path, fromJson: fromJson, body: body),
        path: path,
      );

  Future<Result<T>> _postInner<T>(
    String path, {
    required T Function(Map<String, dynamic>) fromJson,
    Object? body,
  }) async {
    try {
      final token = await _getToken();
      final response = await _rawDio.post<Map<String, dynamic>>(
        path,
        data: body,
        options: Options(headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );
      final data = response.data;
      if (data == null) return Success(fromJson({}));
      return Success(fromJson(_unwrapObject(data)));
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401) return const HttpFailure(UnauthorizedFailure('Não autorizado'));
      if (code == 404) return const HttpFailure(NotFoundFailure('Recurso não encontrado'));
      final backendMessage = _extractBackendMessage(e);
      return HttpFailure(
          ServerFailure(backendMessage ?? e.message ?? 'Erro no servidor', statusCode: code ?? 500));
    } catch (e, stack) {
      return apiClientUnknownFailure<T>(e, stack);
    }
  }

  /// POST /auth/check-email — returns { authMethod: 'totp' | 'password' }
  Future<Result<Map<String, dynamic>>> checkEmail(String email) =>
      post<Map<String, dynamic>>(
        '/auth/check-email',
        fromJson: (json) => json,
        body: {'email': email},
      );

  /// POST /auth/login — returns { accessToken }
  Future<Result<Map<String, dynamic>>> loginWithPassword({
    required String email,
    required String password,
    required bool rememberMe,
  }) =>
      post<Map<String, dynamic>>(
        '/auth/login',
        fromJson: (json) => json,
        body: {
          'email': email,
          'password': password,
          'rememberMe': rememberMe,
        },
      );

  /// POST /auth/forgot-password — 204 No Content
  Future<Result<void>> forgotPassword(String email) =>
      post<void>(
        '/auth/forgot-password',
        fromJson: (_) {},
        body: {'email': email},
      );

  /// POST /auth/reset-password — 204 No Content
  Future<Result<void>> resetPassword(String token, String newPassword) =>
      post<void>(
        '/auth/reset-password',
        fromJson: (_) {},
        body: {'token': token, 'newPassword': newPassword},
      );

  /// POST /auth/accept-invite — returns { accessToken }
  Future<Result<Map<String, dynamic>>> acceptInvite(String token, String name, String password) =>
      post<Map<String, dynamic>>(
        '/auth/accept-invite',
        fromJson: (json) => json,
        body: {'token': token, 'name': name, 'password': password},
      );

  /// GET via raw Dio with manual Bearer token injection.
  /// Consistent with _postInner / _patchInner / _deleteInner so that the token
  /// is always read from tokenStorage at request time (avoids flutter_http
  /// caching issues on web where IndexedDB reads may not be reflected
  /// immediately in the flutter_http internal state).
  Future<Result<T>> _getInner<T>(
    String path, {
    required T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final token = await _getToken();
      final response = await _rawDio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParams,
        options: Options(headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );
      final data = response.data;
      if (data == null) return Success(fromJson({}));
      return Success(fromJson(_unwrapObject(data)));
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401) return const HttpFailure(UnauthorizedFailure('Não autorizado'));
      if (code == 404) return const HttpFailure(NotFoundFailure('Recurso não encontrado'));
      final backendMessage = _extractBackendMessage(e);
      return HttpFailure(
          ServerFailure(backendMessage ?? e.message ?? 'Erro no servidor', statusCode: code ?? 500));
    } catch (e, stack) {
      return apiClientUnknownFailure<T>(e, stack);
    }
  }

  /// GET list via raw Dio with manual Bearer token injection.
  /// Extracts json['data'] as a list from the backend envelope.
  Future<Result<List<T>>> _getListInner<T>(
    String path, {
    required T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final token = await _getToken();
      final response = await _rawDio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParams,
        options: Options(headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );
      final envelope = response.data;
      if (envelope == null) return const Success([]);
      final list = (envelope['data'] as List<dynamic>);
      return Success(list.map((item) => fromJson(item as Map<String, dynamic>)).toList());
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401) return const HttpFailure(UnauthorizedFailure('Não autorizado'));
      if (code == 404) return const HttpFailure(NotFoundFailure('Recurso não encontrado'));
      final backendMessage = _extractBackendMessage(e);
      return HttpFailure(
          ServerFailure(backendMessage ?? e.message ?? 'Erro no servidor', statusCode: code ?? 500));
    } catch (e, stack) {
      return apiClientUnknownFailure<List<T>>(e, stack);
    }
  }

  /// DELETE via raw Dio. Backend returns 204 No Content — no body to unwrap.
  Future<Result<void>> delete(String path) =>
      _withRefresh(() => _deleteInner(path), path: path);

  Future<Result<void>> _deleteInner(String path) async {
    try {
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
      if (code == 401) return const HttpFailure(UnauthorizedFailure('Não autorizado'));
      if (code == 404) return const HttpFailure(NotFoundFailure('Recurso não encontrado'));
      final backendMessage = _extractBackendMessage(e);
      return HttpFailure(
          ServerFailure(backendMessage ?? e.message ?? 'Erro no servidor', statusCode: code ?? 500));
    } catch (e, stack) {
      return apiClientUnknownFailure<void>(e, stack);
    }
  }

  /// PATCH via raw Dio with manual Bearer token injection.
  /// Also unwraps the response envelope.
  Future<Result<T>> patch<T>(
    String path, {
    required T Function(Map<String, dynamic>) fromJson,
    Object? body,
  }) =>
      _withRefresh(
        () => _patchInner(path, fromJson: fromJson, body: body),
        path: path,
      );

  Future<Result<T>> _patchInner<T>(
    String path, {
    required T Function(Map<String, dynamic>) fromJson,
    Object? body,
  }) async {
    try {
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
      if (code == 401) return const HttpFailure(UnauthorizedFailure('Não autorizado'));
      if (code == 404) return const HttpFailure(NotFoundFailure('Recurso não encontrado'));
      final backendMessage = _extractBackendMessage(e);
      return HttpFailure(
          ServerFailure(backendMessage ?? e.message ?? 'Erro no servidor', statusCode: code ?? 500));
    } catch (e, stack) {
      return apiClientUnknownFailure<T>(e, stack);
    }
  }

  /// POST /auth/logout — does NOT go through [_withRefresh] to avoid re-entrant
  /// logout loops. If the server returns 401 (already unauthenticated), we
  /// ignore the error and proceed with local cleanup.
  Future<void> logoutDirect() async {
    try {
      final token = await _getToken();
      await _rawDio.post<void>(
        '/auth/logout',
        options: Options(headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );
    } catch (_) {
      // Ignore server errors — always clear local state.
    }
  }

  /// HIGH-03 fix: wipes persisted cookies (including the httpOnly refresh
  /// token) from disk. Must be called on logout so that a subsequent user on
  /// the same device cannot reuse the previous session's refresh cookie.
  /// No-op on web where the browser manages cookie lifecycle.
  Future<void> clearCookies() async {
    await _cookieJar?.deleteAll();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// M8 — Serialises token reads through a mutex so that concurrent requests
  /// always see a consistent token value and avoid race conditions on expiry.
  Future<String?> _getToken() => _tokenMutex.protect(
        () => tokenStorage.getAccessToken(),
      );

  /// Attempts to refresh the access token by calling POST /auth/refresh.
  /// The refresh token is sent as an httpOnly cookie automatically
  /// (CookieManager on mobile, browser withCredentials on web).
  /// Returns true if a new access token was obtained and saved.
  Future<bool> _tryRefreshToken() async {
    try {
      final response = await _rawDio.post<Map<String, dynamic>>(
        '/auth/refresh',
      );
      final envelope = response.data;
      if (envelope == null) return false;
      // Backend wraps response: { "data": { "accessToken": "..." } }
      final data = envelope['data'];
      final accessToken = (data is Map<String, dynamic>)
          ? data['accessToken'] as String?
          : null;
      if (accessToken == null) return false;
      await tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: '',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Executes [call]. If it returns [UnauthorizedFailure], attempts a single
  /// token refresh (serialised via [_tokenMutex] to prevent concurrent
  /// refresh storms) and retries the original call once.
  ///
  /// When the refresh itself fails (e.g. refresh token expired), fires
  /// [onAuthExpired] so that the auth layer can log the user out instead of
  /// letting feature BLoCs show misleading "no permission" errors.
  ///
  /// [path] is used to skip the refresh cycle for auth endpoints — those
  /// are unauthenticated by design and should never trigger [onAuthExpired].
  Future<Result<T>> _withRefresh<T>(
    Future<Result<T>> Function() call, {
    String path = '',
  }) async {
    final result = await call();
    if (result case HttpFailure(:final failure)
        when failure is UnauthorizedFailure) {
      // Never attempt to refresh or fire onAuthExpired for /auth/* endpoints.
      // They are public routes and a 401 there means a bad request, not an
      // expired session — triggering logout here would create an infinite loop.
      if (path.startsWith('/auth/')) return result;
      final refreshed =
          await _tokenMutex.protect(() => _tryRefreshToken());
      if (refreshed) return call();
      onAuthExpired?.call();
    }
    return result;
  }

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
