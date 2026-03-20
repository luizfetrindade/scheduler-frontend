import 'package:flutter_http/flutter_http.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Token storage implementation for Flutter Web.
///
/// Uses [FlutterSecureStorage] (WebCrypto + IndexedDB) for the access token.
///
/// The refresh token is no longer stored locally — it is managed as an httpOnly
/// cookie by the backend and sent automatically by the browser on every request
/// to `/auth/*`. Passing an empty string to [saveTokens] is intentional.
class WebTokenStorage extends TokenStorage {
  WebTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              webOptions: WebOptions(
                dbName: 'scheduler_secure_storage',
                publicKey: 'scheduler_auth_key',
              ),
            );

  static const _accessKey = 'access_token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> getAccessToken() => _storage.read(key: _accessKey);

  /// Refresh token is managed as httpOnly cookie — always returns null.
  @override
  Future<String?> getRefreshToken() async => null;

  /// Only persists [accessToken]. The [refreshToken] param is kept for
  /// interface compatibility but is intentionally ignored — the refresh token
  /// lives exclusively in the httpOnly cookie set by the backend.
  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) =>
      _storage.write(key: _accessKey, value: accessToken);

  @override
  Future<void> clearTokens() => _storage.delete(key: _accessKey);
}
