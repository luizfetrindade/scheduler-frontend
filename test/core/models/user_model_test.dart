import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/core/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 'uuid-1',
        'name': 'João Silva',
        'email': 'joao@example.com',
        'roles': [
          {'id': 'r1', 'name': 'admin'},
        ],
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'uuid-1');
      expect(user.name, 'João Silva');
      expect(user.email, 'joao@example.com');
      expect(user.roles, ['admin']);
    });

    test('fromJson handles empty roles list', () {
      final json = {
        'id': 'uuid-2',
        'name': 'Maria',
        'email': 'maria@example.com',
        'roles': <dynamic>[],
      };
      final user = UserModel.fromJson(json);
      expect(user.roles, isEmpty);
    });

    test('firstName returns first word of name', () {
      const user = UserModel(id: '1', name: 'João Silva', email: 'j@j.com', roles: []);
      expect(user.firstName, 'João');
    });

    test('equality works via Equatable', () {
      const a = UserModel(id: '1', name: 'A', email: 'a@b.com', roles: []);
      const b = UserModel(id: '1', name: 'A', email: 'a@b.com', roles: []);
      expect(a, equals(b));
    });
  });
}
