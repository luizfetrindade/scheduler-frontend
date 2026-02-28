import 'cache_service.dart';

class _Entry {
  final dynamic value;
  final DateTime? expiresAt;

  const _Entry(this.value, this.expiresAt);

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

class MemoryCacheService implements CacheService {
  final _store = <String, _Entry>{};

  /// The caller must use the same [T] on [set] and [get]; a type mismatch will
  /// cause an unchecked [dynamic] cast and throw a [TypeError] at runtime.
  @override
  Future<T?> get<T>(String key) async {
    final entry = _store[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _store.remove(key);
      return null;
    }
    return entry.value as T?;
  }

  @override
  Future<void> set<T>(String key, T value, {Duration? ttl}) async {
    final expiresAt = ttl != null ? DateTime.now().add(ttl) : null;
    _store[key] = _Entry(value, expiresAt);
  }

  @override
  Future<void> delete(String key) async => _store.remove(key);

  @override
  Future<void> clear() async => _store.clear();
}
