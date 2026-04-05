import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';
import 'package:scheduler_frontend/features/clients/data/client_model.dart';

void main() {
  group('ClientModel', () {
    final fullJson = {
      'id': 'c-1',
      'name': 'Ana Lima',
      'phone': '11999990000',
      'email': 'ana@test.com',
    };

    test('fromJson parses all fields', () {
      final client = ClientModel.fromJson(fullJson);
      expect(client.id, 'c-1');
      expect(client.name, 'Ana Lima');
      expect(client.phone, '11999990000');
      expect(client.email, 'ana@test.com');
    });

    test('fromJson handles null email', () {
      final json = {'id': 'c-2', 'name': 'Bob', 'phone': '11888880000'};
      final client = ClientModel.fromJson(json);
      expect(client.email, isNull);
    });

    test('fromJson handles null phone (client created via appointment without phone)', () {
      final json = {'id': 'c-3', 'name': 'Carlos', 'phone': null, 'email': null};
      final client = ClientModel.fromJson(json);
      expect(client.phone, isNull);
      expect(client.name, 'Carlos');
    });

    test('copyWith returns new instance with updated fields', () {
      final client = ClientModel.fromJson(fullJson);
      final updated = client.copyWith(name: 'Ana S.', phone: '11000000001');
      expect(updated.name, 'Ana S.');
      expect(updated.phone, '11000000001');
      expect(updated.id, client.id);
      expect(client.name, 'Ana Lima'); // original untouched
    });

    test('copyWith can clear optional email to null', () {
      final client = ClientModel.fromJson(fullJson);
      final cleared = client.copyWith(email: null);
      expect(cleared.email, isNull);
      expect(cleared.id, client.id);
    });

    test('two clients with same data are equal (Equatable)', () {
      final a = ClientModel.fromJson(fullJson);
      final b = ClientModel.fromJson(fullJson);
      expect(a, equals(b));
    });
  });

  group('ClientHistoryItem', () {
    final historyJson = {
      'id': 'appt-1',
      'startsAt': '2026-03-10T14:00:00.000Z',
      'endsAt': '2026-03-10T14:30:00.000Z',
      'status': 'CONFIRMED',
      'service': {'name': 'Corte'},
    };

    test('fromJson parses all fields', () {
      final item = ClientHistoryItem.fromJson(historyJson);
      expect(item.id, 'appt-1');
      expect(item.startsAt, DateTime.parse('2026-03-10T14:00:00.000Z'));
      expect(item.status, AppointmentStatus.confirmed);
      expect(item.serviceName, 'Corte');
    });

    test('fromJson handles null service', () {
      final json = {
        'id': 'appt-2',
        'startsAt': '2026-03-01T09:00:00.000Z',
        'endsAt': '2026-03-01T09:30:00.000Z',
        'status': 'PENDING',
        'service': null,
      };
      final item = ClientHistoryItem.fromJson(json);
      expect(item.serviceName, isNull);
      expect(item.status, AppointmentStatus.pending);
    });

    test('unknown status defaults to pending', () {
      final json = {
        'id': 'appt-3',
        'startsAt': '2026-03-01T09:00:00.000Z',
        'endsAt': '2026-03-01T09:30:00.000Z',
        'status': 'UNKNOWN_STATUS',
        'service': null,
      };
      final item = ClientHistoryItem.fromJson(json);
      expect(item.status, AppointmentStatus.pending);
    });
  });
}
