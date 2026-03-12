import 'package:equatable/equatable.dart';

enum RecurrenceFrequency { daily, weekly, monthly }

enum WeekDay { mo, tu, we, th, fr, sa, su }

extension WeekDayX on WeekDay {
  String get rruleValue => switch (this) {
        WeekDay.mo => 'MO',
        WeekDay.tu => 'TU',
        WeekDay.we => 'WE',
        WeekDay.th => 'TH',
        WeekDay.fr => 'FR',
        WeekDay.sa => 'SA',
        WeekDay.su => 'SU',
      };

  String get shortLabel => switch (this) {
        WeekDay.mo => 'Seg',
        WeekDay.tu => 'Ter',
        WeekDay.we => 'Qua',
        WeekDay.th => 'Qui',
        WeekDay.fr => 'Sex',
        WeekDay.sa => 'Sáb',
        WeekDay.su => 'Dom',
      };
}

class RecurrenceConfig extends Equatable {
  final RecurrenceFrequency frequency;
  final int interval;
  final List<WeekDay>? byWeekDay;
  final DateTime? until;
  final int? count;

  const RecurrenceConfig({
    required this.frequency,
    this.interval = 1,
    this.byWeekDay,
    this.until,
    this.count,
  });

  @override
  List<Object?> get props => [frequency, interval, byWeekDay, until, count];
}

String buildRRule(RecurrenceConfig config) {
  final parts = <String>[];

  final freq = switch (config.frequency) {
    RecurrenceFrequency.daily => 'DAILY',
    RecurrenceFrequency.weekly => 'WEEKLY',
    RecurrenceFrequency.monthly => 'MONTHLY',
  };
  parts.add('FREQ=$freq');

  if (config.interval > 1) {
    parts.add('INTERVAL=${config.interval}');
  }

  if (config.byWeekDay != null && config.byWeekDay!.isNotEmpty) {
    final days = config.byWeekDay!.map((d) => d.rruleValue).join(',');
    parts.add('BYDAY=$days');
  }

  if (config.count != null) {
    parts.add('COUNT=${config.count}');
  } else if (config.until != null) {
    final u = config.until!.toUtc();
    final formatted = '${u.year.toString().padLeft(4, '0')}'
        '${u.month.toString().padLeft(2, '0')}'
        '${u.day.toString().padLeft(2, '0')}'
        'T235959Z';
    parts.add('UNTIL=$formatted');
  }

  return parts.join(';');
}

String describeRRule(String rrule) {
  final params = <String, String>{};
  for (final part in rrule.split(';')) {
    final kv = part.split('=');
    if (kv.length == 2) params[kv[0]] = kv[1];
  }

  final freq = params['FREQ'] ?? 'WEEKLY';
  final interval = int.tryParse(params['INTERVAL'] ?? '1') ?? 1;

  final freqLabel = switch (freq) {
    'DAILY' => interval == 1 ? 'Todo dia' : 'A cada $interval dias',
    'WEEKLY' => interval == 1 ? 'Toda semana' : 'A cada $interval semanas',
    'MONTHLY' => interval == 1 ? 'Todo mês' : 'A cada $interval meses',
    _ => freq,
  };

  final parts = <String>[freqLabel];

  if (params.containsKey('BYDAY')) {
    final dayMap = {
      'MO': 'Seg', 'TU': 'Ter', 'WE': 'Qua', 'TH': 'Qui',
      'FR': 'Sex', 'SA': 'Sáb', 'SU': 'Dom',
    };
    final days = params['BYDAY']!.split(',').map((d) => dayMap[d] ?? d).join(', ');
    parts.add(days);
  }

  if (params.containsKey('COUNT')) {
    parts.add('${params['COUNT']} vezes');
  } else if (params.containsKey('UNTIL')) {
    final raw = params['UNTIL']!;
    if (raw.length >= 8) {
      final year = raw.substring(0, 4);
      final month = raw.substring(4, 6);
      final day = raw.substring(6, 8);
      parts.add('até $day/$month/$year');
    }
  }

  return parts.join(', ');
}
