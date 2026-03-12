import 'package:flutter_http/flutter_http.dart';
import 'package:scheduler_frontend/core/models/user_model.dart';
import 'package:scheduler_frontend/core/network/api_client.dart';

typedef _TokenRecord = ({String accessToken, String refreshToken});

class AuthRepository {
  final ApiClient _client;

  AuthRepository(this._client);

  Future<Result<_TokenRecord>> login({
    required String email,
    required String password,
  }) async {
    final result = await _client.post<Map<String, dynamic>>(
      '/auth/login',
      fromJson: (json) => json,
      body: {'email': email, 'password': password},
    );
    return switch (result) {
      Success(:final data) => Success((
          accessToken: data['accessToken'] as String,
          refreshToken: data['refreshToken'] as String,
        )),
      HttpFailure(:final failure) => HttpFailure(failure),
    };
  }

  Future<Result<_TokenRecord>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final result = await _client.post<Map<String, dynamic>>(
      '/auth/register',
      fromJson: (json) => json,
      body: {'name': name, 'email': email, 'password': password},
    );
    return switch (result) {
      Success(:final data) => Success((
          accessToken: data['accessToken'] as String,
          refreshToken: data['refreshToken'] as String,
        )),
      HttpFailure(:final failure) => HttpFailure(failure),
    };
  }

  Future<Result<UserModel>> getMe() =>
      _client.get('/auth/me', fromJson: UserModel.fromJson);

  Future<void> saveTokens(String accessToken, String refreshToken) =>
      _client.tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

  /// Clears tokens locally. Server-side logout (POST /auth/logout) requires
  /// the x-refresh-token header and returns 204 No Content — handled separately
  /// if needed; for now a local clear is sufficient.
  Future<void> clearTokens() => _client.tokenStorage.clearTokens();
}
