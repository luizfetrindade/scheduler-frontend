import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/features/services/data/service_model.dart';

void main() {
  group('ServiceModel', () {
    final fullJson = {
      'id': 'svc-1',
      'name': 'Corte de cabelo',
      'description': 'Corte masculino',
      'price': 45.0,
      'durationMinutes': 30,
      'isActive': true,
    };

    test('fromJson parses all fields', () {
      final svc = ServiceModel.fromJson(fullJson);
      expect(svc.id, 'svc-1');
      expect(svc.name, 'Corte de cabelo');
      expect(svc.description, 'Corte masculino');
      expect(svc.price, 45.0);
      expect(svc.durationMinutes, 30);
      expect(svc.isActive, true);
    });

    test('fromJson handles optional fields as null', () {
      final json = {
        'id': 'svc-2',
        'name': 'Consulta',
        'isActive': false,
      };
      final svc = ServiceModel.fromJson(json);
      expect(svc.description, isNull);
      expect(svc.price, isNull);
      expect(svc.durationMinutes, isNull);
      expect(svc.isActive, false);
    });

    test('copyWith returns new instance with updated fields', () {
      final svc = ServiceModel.fromJson(fullJson);
      final updated = svc.copyWith(name: 'Barba', isActive: false);
      expect(updated.name, 'Barba');
      expect(updated.isActive, false);
      expect(updated.id, svc.id);
      expect(updated.price, svc.price);
    });
  });
}
