import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:scheduler_frontend/core/cache/hive_cache_service.dart';

void main() {
  late HiveCacheService cache;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    cache = HiveCacheService();
    await cache.init();
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('HiveCacheService', () {
    test('returns null for missing key', () async {
      expect(await cache.get<String>('missing'), isNull);
    });

    test('stores and retrieves a string', () async {
      await cache.set<String>('key', 'hello');
      expect(await cache.get<String>('key'), 'hello');
    });

    test('stores and retrieves an int', () async {
      await cache.set<int>('count', 7);
      expect(await cache.get<int>('count'), 7);
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
      await cache.set<String>(
        'key',
        'value',
        ttl: const Duration(milliseconds: 1),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(await cache.get<String>('key'), isNull);
    });

    test('non-expired entry is still available', () async {
      await cache.set<String>('key', 'value', ttl: const Duration(hours: 24));
      expect(await cache.get<String>('key'), 'value');
    });
  });
}
