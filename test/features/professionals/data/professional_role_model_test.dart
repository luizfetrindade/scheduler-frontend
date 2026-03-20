import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/features/professionals/data/professional_role_model.dart';

void main() {
  group('ProfessionalRoleModel.fromJson', () {
    test('parses all fields', () {
      final json = {'id': 'role-1', 'businessId': 'biz-1', 'name': 'Cabeleireira'};
      final model = ProfessionalRoleModel.fromJson(json);
      expect(model.id, 'role-1');
      expect(model.businessId, 'biz-1');
      expect(model.name, 'Cabeleireira');
    });
  });

  group('ProfessionalRoleModel.copyWith', () {
    final base = ProfessionalRoleModel(id: 'r1', businessId: 'b1', name: 'Manicure');

    test('updates name', () {
      expect(base.copyWith(name: 'Manicure Sênior').name, 'Manicure Sênior');
    });

    test('preserves unchanged fields', () {
      final updated = base.copyWith(name: 'New');
      expect(updated.id, 'r1');
      expect(updated.businessId, 'b1');
    });
  });

  group('ProfessionalRoleModel equality', () {
    test('same fields equal', () {
      final a = ProfessionalRoleModel(id: 'r1', businessId: 'b1', name: 'X');
      final b = ProfessionalRoleModel(id: 'r1', businessId: 'b1', name: 'X');
      expect(a, equals(b));
    });
  });

  group('ProfessionalRoleModel.fromJson with professionalCount', () {
    test('parses professionalCount from _count.professionals', () {
      final json = {
        'id': 'r1',
        'businessId': 'b1',
        'name': 'Cabeleireira',
        '_count': {'professionals': 3},
      };
      final model = ProfessionalRoleModel.fromJson(json);
      expect(model.professionalCount, 3);
    });

    test('professionalCount is null when _count absent', () {
      final json = {'id': 'r1', 'businessId': 'b1', 'name': 'Cabeleireira'};
      final model = ProfessionalRoleModel.fromJson(json);
      expect(model.professionalCount, isNull);
    });
  });

  group('ProfessionalRoleModel.copyWith with professionalCount', () {
    test('copies professionalCount', () {
      final base = ProfessionalRoleModel(id: 'r1', businessId: 'b1', name: 'X', professionalCount: 2);
      expect(base.copyWith(professionalCount: 5).professionalCount, 5);
    });
  });
}
