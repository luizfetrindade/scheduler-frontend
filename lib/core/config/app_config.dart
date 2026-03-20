/// Validates that [url] uses HTTPS when running in production.
///
/// Exposed at the top level (not inside the class) so it can be tested
/// independently of compile-time `String.fromEnvironment` values.
///
/// - In prod ([isProd] == true): throws [StateError] if [url] does not start
///   with `https://`.
/// - In dev / staging: returns [url] unchanged (HTTP is acceptable for
///   local development).
String validateApiUrl(String url, {required bool isProd}) {
  if (isProd && !url.startsWith('https://')) {
    throw StateError(
      'API_URL must use HTTPS in production. Got: $url. '
      'Pass --dart-define=API_URL=https://your-api.com when building.',
    );
  }
  return url;
}

abstract final class AppConfig {
  static const String env = String.fromEnvironment('ENV', defaultValue: 'dev');
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000',
  );

  static bool get isDev => env == 'dev';
  static bool get isStaging => env == 'staging';
  static bool get isProd => env == 'prod';

  /// Returns [apiUrl] after asserting it uses HTTPS in production builds.
  ///
  /// Prefer this over [apiUrl] in all new repository and client code.
  /// Throws [StateError] if the app is built for production but [apiUrl]
  /// does not start with `https://`.
  static String get validatedApiUrl => validateApiUrl(apiUrl, isProd: isProd);
}
