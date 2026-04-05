import 'package:equatable/equatable.dart';
import 'package:scheduler_frontend/features/reports/data/reports_model.dart';

sealed class ReportsEvent extends Equatable {
  const ReportsEvent();
  @override
  List<Object?> get props => [];
}

/// Emitted on logout to wipe loaded data from memory.
class ReportsSessionCleared extends ReportsEvent {
  const ReportsSessionCleared();
}

class ReportsLoadRequested extends ReportsEvent {
  final String slug;
  final ReportPeriod period;
  final bool forceRefresh;

  const ReportsLoadRequested({
    required this.slug,
    required this.period,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [slug, period, forceRefresh];
}
