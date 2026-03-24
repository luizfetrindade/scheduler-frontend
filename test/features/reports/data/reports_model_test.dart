import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/features/reports/data/reports_model.dart';

void main() {
  group('ReportsModel.fromJson', () {
    test('parses clients section', () {
      final json = _fullReportsJson();
      final model = ReportsModel.fromJson(json);
      expect(model.clients.newClients, 43);
      expect(model.clients.atRisk.length, 1);
      expect(model.clients.atRisk.first.name, 'Ana Costa');
    });

    test('parses staff section', () {
      final json = _fullReportsJson();
      final model = ReportsModel.fromJson(json);
      expect(model.staff.length, 1);
      expect(model.staff.first.name, 'Marina R.');
      expect(model.staff.first.completionRate, 0.9);
    });

    test('parses previousFrom and previousTo', () {
      final json = _fullReportsJson();
      final model = ReportsModel.fromJson(json);
      expect(model.previousFrom, '2026-02-01');
      expect(model.previousTo, '2026-02-28');
    });

    test('parses previousCancellationRate', () {
      final model = ReportsModel.fromJson(_fullReportsJson());
      expect(model.appointments.previousCancellationRate, 0.10);
    });
  });
}

Map<String, dynamic> _fullReportsJson() => {
  'period': 'monthly',
  'from': '2026-03-01',
  'to': '2026-03-31',
  'previousFrom': '2026-02-01',
  'previousTo': '2026-02-28',
  'appointments': {
    'total': 147, 'previousTotal': 140,
    'byStatus': {'COMPLETED': 106, 'CANCELLED': 21},
    'cancellationRate': 0.14, 'previousCancellationRate': 0.10,
    'noShowRate': 0.06, 'previousNoShowRate': 0.07,
    'dailySeries': [{'date': '2026-03-01', 'count': 5}],
    'byDayOfWeek': [
      {'day': 0, 'count': 8}, {'day': 1, 'count': 22},
      {'day': 2, 'count': 18}, {'day': 3, 'count': 20},
      {'day': 4, 'count': 25}, {'day': 5, 'count': 34}, {'day': 6, 'count': 20},
    ],
  },
  'revenue': {
    'confirmed': 14900.0, 'previousConfirmed': 13800.0,
    'realized': 12480.0, 'previousRealized': 11550.0,
    'lost': 1240.0, 'previousLost': 980.0,
    'averageTicket': 84.9, 'previousAverageTicket': 78.9,
    'revenueDailySeries': [{'date': '2026-03-01', 'amount': 415.0}],
    'topServices': [{'name': 'Corte + Barba', 'count': 32, 'revenue': 3840.0}],
  },
  'occupancy': {
    'totalSlotsAvailable': 203, 'totalBooked': 138,
    'occupancyRate': 0.68, 'previousOccupancyRate': 0.70,
    'peakHours': [{'hour': 9, 'count': 38}],
  },
  'clients': {
    'total': 114,
    'newClients': 43, 'previousNewClients': 38,
    'returningClients': 71,
    'returnRate': 0.71, 'previousReturnRate': 0.66,
    'averageFrequencyDays': 28,
    'averageTicketPerClient': 109.0, 'previousAverageTicketPerClient': 97.0,
    'atRisk': [
      {
        'id': 'client-1', 'name': 'Ana Costa',
        'lastVisitAt': '2026-01-23T10:00:00.000Z',
        'lastServiceName': 'Coloração',
        'daysSinceLastVisit': 89,
      }
    ],
  },
  'staff': [
    {
      'id': 'staff-1', 'name': 'Marina R.',
      'photoUrl': null, 'roleName': 'Cabeleireira',
      'color': '#3b82f6',
      'appointments': 58, 'revenue': 4920.0, 'completionRate': 0.9,
    }
  ],
};
