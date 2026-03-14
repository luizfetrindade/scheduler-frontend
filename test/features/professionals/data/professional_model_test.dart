import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/features/professionals/data/professional_model.dart';

void main() {
  group('ProfessionalModel.fromJson', () {
    test('parses all fields including optional', () {
      final json = {
        'id': 'prof-1',
        'businessId': 'biz-1',
        'name': 'Ana Silva',
        'photoUrl': 'https://example.com/photo.jpg',
        'roleId': 'role-1',
        'roleName': 'Cabeleireira',
        'phone': '+5511999999999',
        'bio': 'Bio da Ana',
        'color': '#FF5733',
        'isActive': true,
        'linkedUserId': 'user-1',
      };
      final model = ProfessionalModel.fromJson(json);
      expect(model.id, 'prof-1');
      expect(model.businessId, 'biz-1');
      expect(model.name, 'Ana Silva');
      expect(model.photoUrl, 'https://example.com/photo.jpg');
      expect(model.roleId, 'role-1');
      expect(model.roleName, 'Cabeleireira');
      expect(model.phone, '+5511999999999');
      expect(model.bio, 'Bio da Ana');
      expect(model.color, '#FF5733');
      expect(model.isActive, true);
      expect(model.linkedUserId, 'user-1');
    });

    test('parses with all optional fields null', () {
      final json = {
        'id': 'prof-2',
        'businessId': 'biz-1',
        'name': 'Carlos',
        'color': '#4A90E2',
        'isActive': false,
      };
      final model = ProfessionalModel.fromJson(json);
      expect(model.photoUrl, isNull);
      expect(model.roleId, isNull);
      expect(model.roleName, isNull);
      expect(model.phone, isNull);
      expect(model.bio, isNull);
      expect(model.linkedUserId, isNull);
      expect(model.isActive, false);
    });

    test('isActive defaults to true when absent', () {
      final json = {'id': 'x', 'businessId': 'b', 'name': 'N', 'color': '#000000'};
      expect(ProfessionalModel.fromJson(json).isActive, true);
    });
  });

  group('ProfessionalModel.copyWith', () {
    final base = ProfessionalModel(
      id: 'prof-1',
      businessId: 'biz-1',
      name: 'Ana',
      color: '#4A90E2',
      isActive: true,
    );

    test('copyWith name preserves other fields', () {
      final updated = base.copyWith(name: 'Ana Maria');
      expect(updated.name, 'Ana Maria');
      expect(updated.id, 'prof-1');
      expect(updated.color, '#4A90E2');
    });

    test('copyWith isActive toggles', () {
      final updated = base.copyWith(isActive: false);
      expect(updated.isActive, false);
    });

    test('sentinel: copyWith without phone keeps existing phone', () {
      final withPhone = base.copyWith(phone: '+5511');
      final updated = withPhone.copyWith(name: 'Changed');
      expect(updated.phone, '+5511');
    });

    test('sentinel: copyWith phone to null clears it', () {
      final withPhone = base.copyWith(phone: '+5511');
      final updated = withPhone.copyWith(phone: null);
      expect(updated.phone, isNull);
    });

    test('sentinel: copyWith roleId to null clears it', () {
      final withRole = base.copyWith(roleId: 'role-1');
      final updated = withRole.copyWith(roleId: null);
      expect(updated.roleId, isNull);
    });

    test('sentinel: copyWith bio to null clears it', () {
      final withBio = base.copyWith(bio: 'Some bio');
      final updated = withBio.copyWith(bio: null);
      expect(updated.bio, isNull);
    });
  });

  group('ProfessionalModel equality', () {
    test('two models with same fields are equal', () {
      final a = ProfessionalModel(id: 'x', businessId: 'b', name: 'N', color: '#000000', isActive: true);
      final b = ProfessionalModel(id: 'x', businessId: 'b', name: 'N', color: '#000000', isActive: true);
      expect(a, equals(b));
    });
  });
}
