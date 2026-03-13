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

class AppointmentsReport extends Equatable {
  final int total;
  final Map<String, int> byStatus;
  final double cancellationRate;
  final double noShowRate;
  final List<DailyPoint> dailySeries;

  const AppointmentsReport({
    required this.total,
    required this.byStatus,
    required this.cancellationRate,
    required this.noShowRate,
    required this.dailySeries,
  });

  factory AppointmentsReport.fromJson(Map<String, dynamic> json) =>
      AppointmentsReport(
        total: json['total'] as int,
        byStatus: Map<String, int>.from(
          (json['byStatus'] as Map).map((k, v) => MapEntry(k as String, v as int)),
        ),
        cancellationRate: (json['cancellationRate'] as num).toDouble(),
        noShowRate: (json['noShowRate'] as num).toDouble(),
        dailySeries: (json['dailySeries'] as List)
            .map((e) => DailyPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [total, byStatus, cancellationRate, noShowRate, dailySeries];
}

class RevenueReport extends Equatable {
  final double confirmed;
  final double realized;
  final double lost;
  final List<TopService> topServices;

  const RevenueReport({
    required this.confirmed,
    required this.realized,
    required this.lost,
    required this.topServices,
  });

  factory RevenueReport.fromJson(Map<String, dynamic> json) => RevenueReport(
        confirmed: (json['confirmed'] as num).toDouble(),
        realized: (json['realized'] as num).toDouble(),
        lost: (json['lost'] as num).toDouble(),
        topServices: (json['topServices'] as List)
            .map((e) => TopService.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [confirmed, realized, lost, topServices];
}

class OccupancyReport extends Equatable {
  final int totalSlotsAvailable;
  final int totalBooked;
  final double occupancyRate;
  final List<PeakHour> peakHours;

  const OccupancyReport({
    required this.totalSlotsAvailable,
    required this.totalBooked,
    required this.occupancyRate,
    required this.peakHours,
  });

  factory OccupancyReport.fromJson(Map<String, dynamic> json) => OccupancyReport(
        totalSlotsAvailable: json['totalSlotsAvailable'] as int,
        totalBooked: json['totalBooked'] as int,
        occupancyRate: (json['occupancyRate'] as num).toDouble(),
        peakHours: (json['peakHours'] as List)
            .map((e) => PeakHour.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [totalSlotsAvailable, totalBooked, occupancyRate, peakHours];
}

class ReportsModel extends Equatable {
  final String period;
  final String from;
  final String to;
  final AppointmentsReport appointments;
  final RevenueReport revenue;
  final OccupancyReport occupancy;

  const ReportsModel({
    required this.period,
    required this.from,
    required this.to,
    required this.appointments,
    required this.revenue,
    required this.occupancy,
  });

  factory ReportsModel.fromJson(Map<String, dynamic> json) => ReportsModel(
        period: json['period'] as String,
        from: json['from'] as String,
        to: json['to'] as String,
        appointments: AppointmentsReport.fromJson(
            json['appointments'] as Map<String, dynamic>),
        revenue: RevenueReport.fromJson(json['revenue'] as Map<String, dynamic>),
        occupancy:
            OccupancyReport.fromJson(json['occupancy'] as Map<String, dynamic>),
      );

  @override
  List<Object?> get props => [period, from, to, appointments, revenue, occupancy];
}
