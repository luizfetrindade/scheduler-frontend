import 'package:equatable/equatable.dart';
import 'package:scheduler_frontend/features/reports/data/reports_model.dart';

sealed class ReportsState extends Equatable {
  const ReportsState();
  @override
  List<Object?> get props => [];
}

class ReportsInitial extends ReportsState {
  const ReportsInitial();
}

class ReportsLoading extends ReportsState {
  const ReportsLoading();
}

class ReportsLoaded extends ReportsState {
  final ReportsModel data;
  final ReportPeriod period;

  const ReportsLoaded(this.data, this.period);

  @override
  List<Object?> get props => [data, period];
}

class ReportsError extends ReportsState {
  final String message;
  final ReportPeriod period;
  const ReportsError(this.message, this.period);

  @override
  List<Object?> get props => [message, period];
}
