import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'cache_service.dart';

class HiveCacheService implements CacheService {
  static const _boxName = 'app_cache';
  late Box<String> _box;

  /// Must be called once before any other method. Typically called in [main].
  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  /// The caller must use the same [T] on [set] and [get].
  /// Note: values are stored as JSON, so [T] must be a JSON-primitive type
  /// (String, int, double, bool). Callers retrieving [List] or [Map] values
  /// will receive [List<dynamic>] / [Map<String, dynamic>] regardless of [T].
  @override
  Future<T?> get<T>(String key) async {
    final raw = _box.get(key);
    if (raw == null) return null;

    final Map<String, dynamic> entry;
    try {
      entry = jsonDecode(raw) as Map<String, dynamic>;
    } on FormatException {
      await _box.delete(key);
      return null;
    }
    final expiresAt = entry['expiresAt'] as int?;

    if (expiresAt != null &&
        DateTime.now().millisecondsSinceEpoch > expiresAt) {
      await _box.delete(key);
      return null;
    }

    return entry['value'] as T?;
  }

  @override
  Future<void> set<T>(String key, T value, {Duration? ttl}) async {
    final expiresAt = ttl != null
        ? DateTime.now().add(ttl).millisecondsSinceEpoch
        : null;

    final encoded = jsonEncode({'value': value, 'expiresAt': expiresAt});
    await _box.put(key, encoded);
  }

  @override
  Future<void> delete(String key) => _box.delete(key);

  @override
  Future<void> clear() => _box.clear();
}
