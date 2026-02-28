import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';

void main() {
  final sampleJson = {
    'id': 'appt-1',
    'startsAt': '2026-02-28T09:00:00.000Z',
    'endsAt': '2026-02-28T09:30:00.000Z',
    'status': 'PENDING',
    'client': {'id': 'c1', 'name': 'João Silva', 'email': 'j@j.com'},
    'service': {'id': 's1', 'name': 'Corte', 'durationMinutes': 30},
    'staffId': 'staff-1',
    'notes': null,
  };

  group('AppointmentModel', () {
    test('fromJson parses all fields', () {
      final appt = AppointmentModel.fromJson(sampleJson);
      expect(appt.id, 'appt-1');
      expect(appt.status, AppointmentStatus.pending);
      expect(appt.clientName, 'João Silva');
      expect(appt.serviceName, 'Corte');
      expect(appt.serviceDurationMinutes, 30);
      expect(appt.staffId, 'staff-1');
      expect(appt.notes, isNull);
    });

    test('fromJson handles missing client and service', () {
      final json = {
        'id': 'appt-2',
        'startsAt': '2026-02-28T10:00:00.000Z',
        'endsAt': '2026-02-28T10:30:00.000Z',
        'status': 'CONFIRMED',
      };
      final appt = AppointmentModel.fromJson(json);
      expect(appt.clientName, 'Cliente');
      expect(appt.serviceName, isNull);
      expect(appt.status, AppointmentStatus.confirmed);
    });

    test('copyWith changes only the specified field', () {
      final appt = AppointmentModel.fromJson(sampleJson);
      final copy = appt.copyWith(status: AppointmentStatus.confirmed);
      expect(copy.status, AppointmentStatus.confirmed);
      expect(copy.id, appt.id);
      expect(copy.clientName, appt.clientName);
    });
  });

  group('AppointmentStatus', () {
    test('fromString maps all values', () {
      expect(AppointmentStatusX.fromString('PENDING'), AppointmentStatus.pending);
      expect(AppointmentStatusX.fromString('CONFIRMED'), AppointmentStatus.confirmed);
      expect(AppointmentStatusX.fromString('CANCELLED'), AppointmentStatus.cancelled);
      expect(AppointmentStatusX.fromString('NO_SHOW'), AppointmentStatus.noShow);
      expect(AppointmentStatusX.fromString('COMPLETED'), AppointmentStatus.completed);
      expect(AppointmentStatusX.fromString('UNKNOWN'), AppointmentStatus.pending);
    });

    test('label returns Portuguese string', () {
      expect(AppointmentStatus.pending.label, 'Pendente');
      expect(AppointmentStatus.confirmed.label, 'Confirmado');
      expect(AppointmentStatus.noShow.label, 'Não compareceu');
    });

    test('apiValue returns uppercase backend string', () {
      expect(AppointmentStatus.confirmed.apiValue, 'CONFIRMED');
      expect(AppointmentStatus.noShow.apiValue, 'NO_SHOW');
    });
  });
}
