import 'package:flutter_http/flutter_http.dart';
import 'package:scheduler_frontend/core/auth/remember_me_storage.dart';
import 'package:scheduler_frontend/core/models/user_model.dart';
import 'package:scheduler_frontend/core/network/api_client.dart';

typedef TokenRecord = ({String accessToken});

class AuthRepository {
  final ApiClient _client;
  final RememberMeStorage _rememberMe;

  AuthRepository(this._client, this._rememberMe);

  /// Step 1 of registration: creates a pending account and sends OTP to email.
  Future<Result<void>> register({
    required String name,
    required String email,
    required String phone,
  }) =>
      _client.post<void>(
        '/auth/register',
        fromJson: (_) {},
        body: {'name': name, 'email': email, 'phone': phone},
      );

  /// Step 2 of registration: confirms OTP code and activates the account.
  Future<Result<TokenRecord>> registerConfirm({
    required String email,
    required String code,
  }) async {
    final result = await _client.post<Map<String, dynamic>>(
      '/auth/register/confirm',
      fromJson: (json) => json,
      body: {'email': email, 'code': code},
    );
    return switch (result) {
      Success(:final data) => Success((accessToken: data['accessToken'] as String)),
      HttpFailure(:final failure) => HttpFailure(failure),
    };
  }

  /// Step 1 of login: sends OTP to the user's email.
  Future<Result<void>> loginInitiate({required String email}) =>
      _client.post<void>(
        '/auth/login',
        fromJson: (_) {},
        body: {'email': email},
      );

  /// Step 2 of login: verifies OTP and returns an access token.
  Future<Result<TokenRecord>> loginConfirm({
    required String email,
    required String code,
    required bool rememberMe,
  }) async {
    final result = await _client.post<Map<String, dynamic>>(
      '/auth/login/confirm',
      fromJson: (json) => json,
      body: {'email': email, 'code': code, 'rememberMe': rememberMe},
    );
    return switch (result) {
      Success(:final data) => Success((accessToken: data['accessToken'] as String)),
      HttpFailure(:final failure) => HttpFailure(failure),
    };
  }

  /// Step 1 of accept-invite: validates invite token and sends OTP to invite email.
  Future<Result<void>> acceptInviteInitiate({
    required String token,
    required String name,
  }) =>
      _client.post<void>(
        '/auth/accept-invite',
        fromJson: (_) {},
        body: {'token': token, 'name': name},
      );

  /// Step 2 of accept-invite: confirms OTP and activates the account.
  Future<Result<TokenRecord>> acceptInviteConfirm({
    required String token,
    required String code,
  }) async {
    final result = await _client.post<Map<String, dynamic>>(
      '/auth/accept-invite/confirm',
      fromJson: (json) => json,
      body: {'token': token, 'code': code},
    );
    return switch (result) {
      Success(:final data) => Success((accessToken: data['accessToken'] as String)),
      HttpFailure(:final failure) => HttpFailure(failure),
    };
  }

  /// Sends a password-reset email to the given address.
  Future<Result<void>> forgotPassword(String email) =>
      _client.forgotPassword(email);

  /// Resets the user's password using the one-time token from the email.
  Future<Result<void>> resetPassword(String token, String newPassword) =>
      _client.resetPassword(token, newPassword);

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
  /// then clears local tokens.
  Future<void> logout() async {
    await _client.post<void>('/auth/logout', fromJson: (_) {});
    await _client.tokenStorage.clearTokens();
    await _client.clearCookies();
  }

  Future<void> clearTokens() => _client.tokenStorage.clearTokens();

  Future<({String? email, bool enabled})> loadRememberMe() =>
      _rememberMe.load();

  Future<void> saveRememberMe(String email) => _rememberMe.save(email: email);

  Future<void> clearRememberMe() => _rememberMe.clear();
}
