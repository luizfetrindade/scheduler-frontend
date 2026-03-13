import 'package:equatable/equatable.dart';
import 'package:scheduler_frontend/features/reports/data/reports_model.dart';

sealed class ReportsEvent extends Equatable {
  const ReportsEvent();
  @override
  List<Object?> get props => [];
}

class ReportsLoadRequested extends ReportsEvent {
  final String slug;
  final ReportPeriod period;

  const ReportsLoadRequested({required this.slug, required this.period});

  @override
  List<Object?> get props => [slug, period];
}
