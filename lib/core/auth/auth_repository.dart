import 'package:flutter_http/flutter_http.dart';
import 'package:scheduler_frontend/core/auth/remember_me_storage.dart';
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
  final RememberMeStorage _rememberMe;

  AuthRepository(this._client, this._rememberMe);

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
    required bool rememberMe,
  }) async {
    final result = await _client.post<Map<String, dynamic>>(
      '/auth/login/totp',
      fromJson: (json) => json,
      body: {'email': email, 'code': code, 'rememberMe': rememberMe},
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

  /// Authenticates a member/staff user with email + password.
  /// Returns a token record on success.
  Future<Result<TokenRecord>> loginWithPassword({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final result = await _client.loginWithPassword(
      email: email,
      password: password,
      rememberMe: rememberMe,
    );
    return switch (result) {
      Success(:final data) => Success((
          accessToken: data['accessToken'] as String,
        )),
      HttpFailure(:final failure) => HttpFailure(failure),
    };
  }

  /// Checks which auth method ('totp' | 'password') the backend requires for
  /// the given email address.
  Future<Result<Map<String, dynamic>>> checkEmail(String email) =>
      _client.checkEmail(email);

  /// Sends a password-reset email to the given address.
  Future<Result<void>> forgotPassword(String email) =>
      _client.forgotPassword(email);

  /// Resets the user's password using the one-time token from the email.
  Future<Result<void>> resetPassword(
    String token,
    String newPassword,
  ) =>
      _client.resetPassword(token, newPassword);

  /// Accepts a staff invite and creates an account with [name] and [password].
  /// Returns a token record so the user can be authenticated immediately.
  Future<Result<TokenRecord>> acceptInvite(
    String token,
    String name,
    String password,
  ) async {
    final result = await _client.acceptInvite(token, name, password);
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

  /// Revokes the server-side session (httpOnly cookie) via POST /auth/logout,
  /// then clears local tokens. Server errors are intentionally ignored so that
  /// local tokens are always cleared and the user is never stuck logged-in.
  Future<void> logout() async {
    await _client.post<void>('/auth/logout', fromJson: (_) {});
    await _client.tokenStorage.clearTokens();
    await _client.clearCookies();
  }

  /// Clears local tokens only (no server call). Prefer [logout] for user
  /// initiated sign-out so the server session is also revoked.
  Future<void> clearTokens() => _client.tokenStorage.clearTokens();

  /// Reads the persisted "Lembrar de mim" state for pre-filling the login UI.
  Future<({String? email, bool enabled})> loadRememberMe() =>
      _rememberMe.load();

  /// Persists the e-mail after a successful login when the box was checked.
  Future<void> saveRememberMe(String email) => _rememberMe.save(email: email);

  /// Clears the persisted e-mail when the box is unchecked on a successful login.
  Future<void> clearRememberMe() => _rememberMe.clear();
}
