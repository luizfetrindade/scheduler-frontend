import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/features/business/data/business_model.dart';

void main() {
  group('BusinessModel', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 'biz-1',
        'slug': 'meu-salao',
        'name': 'Meu Salão',
        'logo': 'https://example.com/logo.png',
        'timezone': 'America/Sao_Paulo',
        'planId': 'plan-1',
        'plan': {'name': 'FREE'},
      };

      final biz = BusinessModel.fromJson(json);

      expect(biz.id, 'biz-1');
      expect(biz.slug, 'meu-salao');
      expect(biz.name, 'Meu Salão');
      expect(biz.logo, 'https://example.com/logo.png');
      expect(biz.timezone, 'America/Sao_Paulo');
    });

    test('fromJson defaults timezone and handles null logo', () {
      final json = {'id': 'x', 'slug': 's', 'name': 'N'};
      final biz = BusinessModel.fromJson(json);
      expect(biz.logo, isNull);
      expect(biz.timezone, 'America/Sao_Paulo');
    });

    test('equality works via Equatable', () {
      const a = BusinessModel(id: '1', slug: 's', name: 'N', logo: null, timezone: 'UTC');
      const b = BusinessModel(id: '1', slug: 's', name: 'N', logo: null, timezone: 'UTC');
      expect(a, equals(b));
    });
  });
}
