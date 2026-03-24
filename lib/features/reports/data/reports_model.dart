import 'package:equatable/equatable.dart';

enum ReportPeriod { weekly, monthly, quarterly }

extension ReportPeriodX on ReportPeriod {
  String get apiValue => switch (this) {
        ReportPeriod.weekly => 'weekly',
        ReportPeriod.monthly => 'monthly',
        ReportPeriod.quarterly => 'quarterly',
      };

  String get label => switch (this) {
        ReportPeriod.weekly => 'Semanal',
        ReportPeriod.monthly => 'Mensal',
        ReportPeriod.quarterly => 'Trimestral',
      };
}

class DailyPoint extends Equatable {
  final String date;
  final int count;

  const DailyPoint({required this.date, required this.count});

  factory DailyPoint.fromJson(Map<String, dynamic> json) =>
      DailyPoint(date: json['date'] as String, count: json['count'] as int);

  @override
  List<Object?> get props => [date, count];
}

class RevenueDailyPoint extends Equatable {
  final String date;
  final double amount;

  const RevenueDailyPoint({required this.date, required this.amount});

  factory RevenueDailyPoint.fromJson(Map<String, dynamic> json) =>
      RevenueDailyPoint(
        date: json['date'] as String,
        amount: (json['amount'] as num).toDouble(),
      );

  @override
  List<Object?> get props => [date, amount];
}

class DayOfWeekPoint extends Equatable {
  final int day; // 0=dom, 6=sáb
  final int count;

  const DayOfWeekPoint({required this.day, required this.count});

  factory DayOfWeekPoint.fromJson(Map<String, dynamic> json) =>
      DayOfWeekPoint(day: json['day'] as int, count: json['count'] as int);

  @override
  List<Object?> get props => [day, count];
}

class PeakHour extends Equatable {
  final int hour;
  final int count;

  const PeakHour({required this.hour, required this.count});

  factory PeakHour.fromJson(Map<String, dynamic> json) =>
      PeakHour(hour: json['hour'] as int, count: json['count'] as int);

  @override
  List<Object?> get props => [hour, count];
}

class TopService extends Equatable {
  final String name;
  final int count;
  final double revenue;

  const TopService({required this.name, required this.count, required this.revenue});

  factory TopService.fromJson(Map<String, dynamic> json) => TopService(
        name: json['name'] as String,
        count: json['count'] as int,
        revenue: (json['revenue'] as num).toDouble(),
      );

  @override
  List<Object?> get props => [name, count, revenue];
}

class AtRiskClient extends Equatable {
  final String id;
  final String name;
  final String lastVisitAt;
  final String? lastServiceName;
  final int daysSinceLastVisit;

  const AtRiskClient({
    required this.id,
    required this.name,
    required this.lastVisitAt,
    this.lastServiceName,
    required this.daysSinceLastVisit,
  });

  factory AtRiskClient.fromJson(Map<String, dynamic> json) => AtRiskClient(
        id: json['id'] as String,
        name: json['name'] as String,
        lastVisitAt: json['lastVisitAt'] as String,
        lastServiceName: json['lastServiceName'] as String?,
        daysSinceLastVisit: json['daysSinceLastVisit'] as int,
      );

  @override
  List<Object?> get props => [id, name, lastVisitAt, lastServiceName, daysSinceLastVisit];
}

class ClientsReport extends Equatable {
  final int total;
  final int newClients;
  final int previousNewClients;
  final int returningClients;
  final double returnRate;
  final double previousReturnRate;
  final int averageFrequencyDays;
  final double averageTicketPerClient;
  final double previousAverageTicketPerClient;
  final List<AtRiskClient> atRisk;

  const ClientsReport({
    required this.total,
    required this.newClients,
    required this.previousNewClients,
    required this.returningClients,
    required this.returnRate,
    required this.previousReturnRate,
    required this.averageFrequencyDays,
    required this.averageTicketPerClient,
    required this.previousAverageTicketPerClient,
    required this.atRisk,
  });

  factory ClientsReport.fromJson(Map<String, dynamic> json) => ClientsReport(
        total: json['total'] as int,
        newClients: json['newClients'] as int,
        previousNewClients: json['previousNewClients'] as int,
        returningClients: json['returningClients'] as int,
        returnRate: (json['returnRate'] as num).toDouble(),
        previousReturnRate: (json['previousReturnRate'] as num).toDouble(),
        averageFrequencyDays: json['averageFrequencyDays'] as int,
        averageTicketPerClient: (json['averageTicketPerClient'] as num).toDouble(),
        previousAverageTicketPerClient:
            (json['previousAverageTicketPerClient'] as num).toDouble(),
        atRisk: (json['atRisk'] as List<dynamic>)
            .map((e) => AtRiskClient.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [
        total,
        newClients,
        previousNewClients,
        returningClients,
        returnRate,
        previousReturnRate,
        averageFrequencyDays,
        averageTicketPerClient,
        previousAverageTicketPerClient,
        atRisk,
      ];
}

class StaffReport extends Equatable {
  final String id;
  final String name;
  final String? photoUrl;
  final String? roleName;
  final String color;
  final int appointments;
  final double revenue;
  final double completionRate;

  const StaffReport({
    required this.id,
    required this.name,
    this.photoUrl,
    this.roleName,
    required this.color,
    required this.appointments,
    required this.revenue,
    required this.completionRate,
  });

  factory StaffReport.fromJson(Map<String, dynamic> json) => StaffReport(
        id: json['id'] as String,
        name: json['name'] as String,
        photoUrl: json['photoUrl'] as String?,
        roleName: json['roleName'] as String?,
        color: json['color'] as String,
        appointments: json['appointments'] as int,
        revenue: (json['revenue'] as num).toDouble(),
        completionRate: (json['completionRate'] as num).toDouble(),
      );

  @override
  List<Object?> get props => [
        id,
        name,
        photoUrl,
        roleName,
        color,
        appointments,
        revenue,
        completionRate,
      ];
}

class AppointmentsReport extends Equatable {
  final int total;
  final int previousTotal;
  final Map<String, int> byStatus;
  final double cancellationRate;
  final double previousCancellationRate;
  final double noShowRate;
  final double previousNoShowRate;
  final List<DailyPoint> dailySeries;
  final List<DayOfWeekPoint> byDayOfWeek;

  const AppointmentsReport({
    required this.total,
    required this.previousTotal,
    required this.byStatus,
    required this.cancellationRate,
    required this.previousCancellationRate,
    required this.noShowRate,
    required this.previousNoShowRate,
    required this.dailySeries,
    required this.byDayOfWeek,
  });

  factory AppointmentsReport.fromJson(Map<String, dynamic> json) =>
      AppointmentsReport(
        total: json['total'] as int,
        previousTotal: json['previousTotal'] as int,
        byStatus: Map<String, int>.from(
          (json['byStatus'] as Map).map((k, v) => MapEntry(k as String, v as int)),
        ),
        cancellationRate: (json['cancellationRate'] as num).toDouble(),
        previousCancellationRate: (json['previousCancellationRate'] as num).toDouble(),
        noShowRate: (json['noShowRate'] as num).toDouble(),
        previousNoShowRate: (json['previousNoShowRate'] as num).toDouble(),
        dailySeries: (json['dailySeries'] as List)
            .map((e) => DailyPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
        byDayOfWeek: (json['byDayOfWeek'] as List)
            .map((e) => DayOfWeekPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [
        total,
        previousTotal,
        byStatus,
        cancellationRate,
        previousCancellationRate,
        noShowRate,
        previousNoShowRate,
        dailySeries,
        byDayOfWeek,
      ];
}

class RevenueReport extends Equatable {
  final double confirmed;
  final double previousConfirmed;
  final double realized;
  final double previousRealized;
  final double lost;
  final double previousLost;
  final double averageTicket;
  final double previousAverageTicket;
  final List<RevenueDailyPoint> revenueDailySeries;
  final List<TopService> topServices;

  const RevenueReport({
    required this.confirmed,
    required this.previousConfirmed,
    required this.realized,
    required this.previousRealized,
    required this.lost,
    required this.previousLost,
    required this.averageTicket,
    required this.previousAverageTicket,
    required this.revenueDailySeries,
    required this.topServices,
  });

  factory RevenueReport.fromJson(Map<String, dynamic> json) => RevenueReport(
        confirmed: (json['confirmed'] as num).toDouble(),
        previousConfirmed: (json['previousConfirmed'] as num).toDouble(),
        realized: (json['realized'] as num).toDouble(),
        previousRealized: (json['previousRealized'] as num).toDouble(),
        lost: (json['lost'] as num).toDouble(),
        previousLost: (json['previousLost'] as num).toDouble(),
        averageTicket: (json['averageTicket'] as num).toDouble(),
        previousAverageTicket: (json['previousAverageTicket'] as num).toDouble(),
        revenueDailySeries: (json['revenueDailySeries'] as List)
            .map((e) => RevenueDailyPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
        topServices: (json['topServices'] as List)
            .map((e) => TopService.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [
        confirmed,
        previousConfirmed,
        realized,
        previousRealized,
        lost,
        previousLost,
        averageTicket,
        previousAverageTicket,
        revenueDailySeries,
        topServices,
      ];
}

class OccupancyReport extends Equatable {
  final int totalSlotsAvailable;
  final int totalBooked;
  final double occupancyRate;
  final double previousOccupancyRate;
  final List<PeakHour> peakHours;

  const OccupancyReport({
    required this.totalSlotsAvailable,
    required this.totalBooked,
    required this.occupancyRate,
    required this.previousOccupancyRate,
    required this.peakHours,
  });

  factory OccupancyReport.fromJson(Map<String, dynamic> json) => OccupancyReport(
        totalSlotsAvailable: json['totalSlotsAvailable'] as int,
        totalBooked: json['totalBooked'] as int,
        occupancyRate: (json['occupancyRate'] as num).toDouble(),
        previousOccupancyRate: (json['previousOccupancyRate'] as num).toDouble(),
        peakHours: (json['peakHours'] as List)
            .map((e) => PeakHour.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [
        totalSlotsAvailable,
        totalBooked,
        occupancyRate,
        previousOccupancyRate,
        peakHours,
      ];
}

class ReportsModel extends Equatable {
  final String period;
  final String from;
  final String to;
  final String previousFrom;
  final String previousTo;
  final AppointmentsReport appointments;
  final RevenueReport revenue;
  final OccupancyReport occupancy;
  final ClientsReport clients;
  final List<StaffReport> staff;

  const ReportsModel({
    required this.period,
    required this.from,
    required this.to,
    required this.previousFrom,
    required this.previousTo,
    required this.appointments,
    required this.revenue,
    required this.occupancy,
    required this.clients,
    required this.staff,
  });

  factory ReportsModel.fromJson(Map<String, dynamic> json) => ReportsModel(
        period: json['period'] as String,
        from: json['from'] as String,
        to: json['to'] as String,
        previousFrom: json['previousFrom'] as String,
        previousTo: json['previousTo'] as String,
        appointments: AppointmentsReport.fromJson(
            json['appointments'] as Map<String, dynamic>),
        revenue: RevenueReport.fromJson(json['revenue'] as Map<String, dynamic>),
        occupancy:
            OccupancyReport.fromJson(json['occupancy'] as Map<String, dynamic>),
        clients: ClientsReport.fromJson(json['clients'] as Map<String, dynamic>),
        staff: (json['staff'] as List<dynamic>)
            .map((e) => StaffReport.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [
        period,
        from,
        to,
        previousFrom,
        previousTo,
        appointments,
        revenue,
        occupancy,
        clients,
        staff,
      ];
}
