import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/core/cache/memory_cache_service.dart';

void main() {
  late MemoryCacheService cache;

  setUp(() => cache = MemoryCacheService());

  group('MemoryCacheService', () {
    test('returns null for missing key', () async {
      expect(await cache.get<String>('missing'), isNull);
    });

    test('stores and retrieves a string', () async {
      await cache.set<String>('key', 'value');
      expect(await cache.get<String>('key'), 'value');
    });

    test('stores and retrieves an int', () async {
      await cache.set<int>('count', 42);
      expect(await cache.get<int>('count'), 42);
    });

    test('delete removes a key', () async {
      await cache.set<String>('key', 'value');
      await cache.delete('key');
      expect(await cache.get<String>('key'), isNull);
    });

    test('clear removes all keys', () async {
      await cache.set<String>('a', '1');
      await cache.set<String>('b', '2');
      await cache.clear();
      expect(await cache.get<String>('a'), isNull);
      expect(await cache.get<String>('b'), isNull);
    });

    test('expired entry returns null', () async {
      await cache.set<String>('key', 'value', ttl: const Duration(milliseconds: 1));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(await cache.get<String>('key'), isNull);
    });

    test('type mismatch throws TypeError at runtime', () async {
      await cache.set<int>('key', 42);
      await expectLater(cache.get<String>('key'), throwsA(isA<TypeError>()));
    });

    test('non-expired entry is still available', () async {
      await cache.set<String>('key', 'value', ttl: const Duration(hours: 1));
      expect(await cache.get<String>('key'), 'value');
    });
  });
}
