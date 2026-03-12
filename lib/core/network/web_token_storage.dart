import 'package:flutter_http/flutter_http.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Token storage implementation for Flutter Web.
///
/// flutter_secure_storage uses WebCrypto under the hood and throws
/// [OperationError] in certain browser contexts. SharedPreferences
/// (backed by localStorage on web) is simpler and works reliably for dev.
class WebTokenStorage extends TokenStorage {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  @override
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessKey);
  }

  @override
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshKey);
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_accessKey, accessToken),
      prefs.setString(_refreshKey, refreshToken),
    ]);
  }

  @override
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_accessKey),
      prefs.remove(_refreshKey),
    ]);
  }
}
