import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/core/policy/app_policy.dart';
import 'package:scheduler_frontend/features/business/data/business_model.dart';

void main() {
  group('AppPolicy', () {
    test('OWNER with maxStaff=1 → isSoloMode=true, isAdmin=true, no team nav', () {
      final policy = AppPolicy.from(StaffRole.owner, 1);
      expect(policy.isSoloMode, isTrue);
      expect(policy.isAdmin, isTrue);
      expect(policy.canManageTeam, isFalse);
      expect(policy.mobileNavItems.any((n) => n.label == 'Equipe'), isFalse);
      expect(policy.mobileNavItems.any((n) => n.label == 'Profissionais'), isFalse);
    });

    test('OWNER with maxStaff=5 → isSoloMode=false, canManageTeam=true', () {
      final policy = AppPolicy.from(StaffRole.owner, 5);
      expect(policy.isSoloMode, isFalse);
      expect(policy.canManageTeam, isTrue);
      expect(policy.mobileNavItems.any((n) => n.label == 'Equipe'), isTrue);
    });

    test('MEMBER → isAdmin=false, no team management nav', () {
      final policy = AppPolicy.from(StaffRole.member, 5);
      expect(policy.isAdmin, isFalse);
      expect(policy.canManageTeam, isFalse);
      expect(policy.canManageServices, isFalse);
      expect(policy.mobileNavItems.any((n) => n.label == 'Conta'), isTrue);
      expect(policy.mobileNavItems.any((n) => n.label == 'Equipe'), isFalse);
    });

    test('MANAGER with maxStaff=3 → isAdmin=true, canManageTeam=true', () {
      final policy = AppPolicy.from(StaffRole.manager, 3);
      expect(policy.isAdmin, isTrue);
      expect(policy.canManageTeam, isTrue);
    });

    test('Desktop nav includes Relatórios for admins', () {
      final policy = AppPolicy.from(StaffRole.owner, 5);
      expect(policy.desktopNavItems.any((n) => n.label == 'Relatórios'), isTrue);
      expect(policy.mobileNavItems.any((n) => n.label == 'Relatórios'), isFalse);
    });
  });

  group('BusinessModel fromJson', () {
    test('parses myStaffRole and planMaxStaff from JSON', () {
      final json = {
        'id': 'biz-1',
        'name': 'Test Business',
        'slug': 'test-biz',
        'phone': '11999999999',
        'logo': null,
        'timezone': 'America/Sao_Paulo',
        'myStaffRole': 'OWNER',
        'plan': {'name': 'Team', 'maxStaff': 5},
      };
      final model = BusinessModel.fromJson(json);
      expect(model.myStaffRole, StaffRole.owner);
      expect(model.planMaxStaff, 5);
    });

    test('defaults to owner and maxStaff=1 when fields absent', () {
      final json = {
        'id': 'biz-1',
        'name': 'Test Business',
        'slug': 'test-biz',
        'phone': '11999999999',
        'logo': null,
        'timezone': 'America/Sao_Paulo',
      };
      final model = BusinessModel.fromJson(json);
      expect(model.myStaffRole, StaffRole.owner);
      expect(model.planMaxStaff, 1);
    });
  });
}
