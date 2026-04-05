import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's "Lembrar de mim" choice across app launches.
///
/// Stores only the e-mail — never credentials. Access tokens remain in the
/// existing [TokenStorage]. The e-mail is an identifier, not a secret, so
/// SharedPreferences is sufficient.
class RememberMeStorage {
  static const _kEmailKey = 'remember_me_email';
  static const _kEnabledKey = 'remember_me_enabled';

  /// Reads the persisted state. Returns `(null, false)` if nothing has been
  /// saved or the user previously cleared the preference.
  Future<({String? email, bool enabled})> load() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_kEnabledKey) ?? false;
    final email = enabled ? prefs.getString(_kEmailKey) : null;
    return (email: email, enabled: enabled);
  }

  /// Persists [email] and sets the "enabled" flag to true. Overwrites any
  /// previously stored value.
  Future<void> save({required String email}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kEmailKey, email);
    await prefs.setBool(_kEnabledKey, true);
  }

  /// Removes both keys. Used when the user unchecks the box on a successful
  /// login.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kEmailKey);
    await prefs.remove(_kEnabledKey);
  }
}
