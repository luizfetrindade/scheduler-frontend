import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/features/reports/data/reports_model.dart';
import 'package:scheduler_frontend/features/reports/utils/smart_alerts.dart';

void main() {
  group('buildAlerts', () {
    test('generates high alert when cancellationRate > 0.15', () {
      final model = _makeModel(cancellationRate: 0.16);
      final alerts = buildAlerts(model);
      expect(alerts.any((a) => a.severity == AlertSeverity.high), isTrue);
    });

    test('no newClients alert when previousNewClients is 0', () {
      final model = _makeModel(previousNewClients: 0, newClients: 10);
      final alerts = buildAlerts(model);
      expect(alerts.any((a) => a.message.contains('clientes novos')), isFalse);
    });

    test('top service alert only when topServices is not empty and realized > 0', () {
      final modelEmpty = _makeModel(topServices: [], realized: 0);
      expect(buildAlerts(modelEmpty).any((a) => a.message.contains('serviço')), isFalse);

      final modelFull = _makeModel(
        topServices: [const TopService(name: 'Corte', count: 32, revenue: 3840)],
        realized: 12480,
      );
      expect(buildAlerts(modelFull).any((a) => a.severity == AlertSeverity.positive), isTrue);
    });

    test('alerts are ordered high → medium → positive', () {
      final model = _makeModel(
        cancellationRate: 0.20,
        atRisk: List.generate(12, (i) => AtRiskClient(
          id: 'c$i', name: 'Cliente $i', lastVisitAt: '2026-01-01T00:00:00Z',
          daysSinceLastVisit: 70,
        )),
        realized: 12480,
        revenueDelta: 0.15,
      );
      final alerts = buildAlerts(model);
      final severities = alerts.map((a) => a.severity.index).toList();
      expect(severities, orderedEquals(severities.toList()..sort()));
    });
  });
}

/// Builds a [ReportsModel] from sensible defaults, with optional overrides.
///
/// [revenueDelta] is a convenience parameter: when provided, it sets
/// [previousRealized] such that `(realized - previousRealized) / previousRealized == revenueDelta`.
/// This allows tests to drive the revenue growth alert without manually computing previousRealized.
ReportsModel _makeModel({
  double cancellationRate = 0.14,
  double previousCancellationRate = 0.10,
  int newClients = 43,
  int previousNewClients = 38,
  List<AtRiskClient>? atRisk,
  List<TopService>? topServices,
  double realized = 12480.0,
  double? revenueDelta,
}) {
  // Compute previousRealized from revenueDelta when provided.
  // revenueDelta = (realized - previousRealized) / previousRealized
  // => previousRealized = realized / (1 + revenueDelta)
  final double previousRealized = revenueDelta != null && revenueDelta != 0.0
      ? realized / (1.0 + revenueDelta)
      : 11550.0;

  final effectiveAtRisk = atRisk ??
      [
        const AtRiskClient(
          id: 'client-1',
          name: 'Ana Costa',
          lastVisitAt: '2026-01-23T10:00:00.000Z',
          lastServiceName: 'Coloração',
          daysSinceLastVisit: 89,
        )
      ];

  final effectiveTopServices = topServices ??
      [const TopService(name: 'Corte + Barba', count: 32, revenue: 3840.0)];

  return ReportsModel(
    period: 'monthly',
    from: '2026-03-01',
    to: '2026-03-31',
    previousFrom: '2026-02-01',
    previousTo: '2026-02-28',
    appointments: AppointmentsReport(
      total: 147,
      previousTotal: 140,
      byStatus: const {'COMPLETED': 106, 'CANCELLED': 21},
      cancellationRate: cancellationRate,
      previousCancellationRate: previousCancellationRate,
      noShowRate: 0.06,
      previousNoShowRate: 0.07,
      dailySeries: const [DailyPoint(date: '2026-03-01', count: 5)],
      byDayOfWeek: const [
        DayOfWeekPoint(day: 0, count: 8),
        DayOfWeekPoint(day: 1, count: 22),
        DayOfWeekPoint(day: 2, count: 18),
        DayOfWeekPoint(day: 3, count: 20),
        DayOfWeekPoint(day: 4, count: 25),
        DayOfWeekPoint(day: 5, count: 34),
        DayOfWeekPoint(day: 6, count: 20),
      ],
    ),
    revenue: RevenueReport(
      confirmed: 14900.0,
      previousConfirmed: 13800.0,
      realized: realized,
      previousRealized: previousRealized,
      lost: 1240.0,
      previousLost: 980.0,
      averageTicket: 84.9,
      previousAverageTicket: 78.9,
      revenueDailySeries: const [
        RevenueDailyPoint(date: '2026-03-01', amount: 415.0)
      ],
      topServices: effectiveTopServices,
    ),
    occupancy: const OccupancyReport(
      totalSlotsAvailable: 203,
      totalBooked: 138,
      occupancyRate: 0.68,
      previousOccupancyRate: 0.70,
      peakHours: [PeakHour(hour: 9, count: 38)],
    ),
    clients: ClientsReport(
      total: 114,
      newClients: newClients,
      previousNewClients: previousNewClients,
      returningClients: 71,
      returnRate: 0.71,
      previousReturnRate: 0.66,
      averageFrequencyDays: 28,
      averageTicketPerClient: 109.0,
      previousAverageTicketPerClient: 97.0,
      atRisk: effectiveAtRisk,
    ),
    staff: const [
      StaffReport(
        id: 'staff-1',
        name: 'Marina R.',
        photoUrl: null,
        roleName: 'Cabeleireira',
        color: '#3b82f6',
        appointments: 58,
        revenue: 4920.0,
        completionRate: 0.9,
      )
    ],
  );
}
