import 'package:flutter_http/flutter_http.dart';
import 'package:scheduler_frontend/core/models/user_model.dart';
import 'package:scheduler_frontend/core/network/api_client.dart';

/// The refresh token is managed as an httpOnly cookie by the backend.
/// The frontend only stores and sends the short-lived access token.
typedef TokenRecord = ({String accessToken});

/// Returned after a successful registration, before TOTP confirmation.
/// tempToken is short-lived (5 min) and only used to confirm TOTP setup.
typedef TotpSetupRecord = ({
  String qrCodeUrl,
  String secret,
  String tempToken
});

class AuthRepository {
  final ApiClient _client;

  AuthRepository(this._client);

  /// Checks whether the given email is registered.
  /// Returns Success(true) if found, Success(false) if not found (404).
  Future<Result<bool>> verifyEmail({required String email}) async {
    final result = await _client.post<Map<String, dynamic>>(
      '/auth/verify-email',
      fromJson: (json) => json,
      body: {'email': email},
    );
    return switch (result) {
      Success() => const Success(true),
      HttpFailure(:final failure) when failure is NotFoundFailure =>
        const Success(false),
      HttpFailure(:final failure) => HttpFailure(failure),
    };
  }

  /// Verifies the TOTP code for an existing user and returns an access token.
  Future<Result<TokenRecord>> loginWithTotp({
    required String email,
    required String code,
  }) async {
    final result = await _client.post<Map<String, dynamic>>(
      '/auth/login/totp',
      fromJson: (json) => json,
      body: {'email': email, 'code': code},
    );
    return switch (result) {
      Success(:final data) => Success((
          accessToken: data['accessToken'] as String,
        )),
      HttpFailure(:final failure) => HttpFailure(failure),
    };
  }

  /// Creates a new account (no password). Returns TOTP setup data with a
  /// QR code URL, the raw secret, and a short-lived tempToken.
  Future<Result<TotpSetupRecord>> register({
    required String name,
    required String email,
    required String phone,
  }) async {
    final result = await _client.post<Map<String, dynamic>>(
      '/auth/register',
      fromJson: (json) => json,
      body: {'name': name, 'email': email, 'phone': phone},
    );
    return switch (result) {
      Success(:final data) => Success((
          qrCodeUrl: data['qrCodeUrl'] as String,
          secret: data['secret'] as String,
          tempToken: data['tempToken'] as String,
        )),
      HttpFailure(:final failure) => HttpFailure(failure),
    };
  }

  /// Confirms TOTP setup with the first code scanned from Google Authenticator.
  Future<Result<TokenRecord>> confirmTotpSetup({
    required String tempToken,
    required String code,
  }) async {
    final result = await _client.post<Map<String, dynamic>>(
      '/auth/register/confirm-totp',
      fromJson: (json) => json,
      body: {'tempToken': tempToken, 'code': code},
    );
    return switch (result) {
      Success(:final data) => Success((
          accessToken: data['accessToken'] as String,
        )),
      HttpFailure(:final failure) => HttpFailure(failure),
    };
  }

  Future<Result<UserModel>> getMe() =>
      _client.get('/auth/me', fromJson: UserModel.fromJson);

  /// Saves only the access token. The refresh token is an httpOnly cookie
  /// managed automatically by the browser / CookieJar — never stored locally.
  Future<void> saveTokens(String accessToken) =>
      _client.tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: '',
      );

  /// Clears local tokens. The backend clears the httpOnly cookie when
  /// POST /auth/logout is called (handled by Dio's cookie jar on mobile,
  /// or the browser on web).
  Future<void> clearTokens() => _client.tokenStorage.clearTokens();
}
