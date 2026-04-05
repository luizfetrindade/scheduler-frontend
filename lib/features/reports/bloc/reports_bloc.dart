import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_http/flutter_http.dart';
import 'package:scheduler_frontend/features/reports/bloc/reports_event.dart';
import 'package:scheduler_frontend/features/reports/bloc/reports_state.dart';
import 'package:scheduler_frontend/features/reports/data/reports_model.dart';
import 'package:scheduler_frontend/features/reports/data/reports_repository.dart';

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final ReportsRepository _repository;

  /// In-memory cache keyed by period. Cleared on session clear.
  final Map<ReportPeriod, ReportsModel> _cache = {};

  ReportsBloc(this._repository) : super(const ReportsInitial()) {
    on<ReportsSessionCleared>(_onSessionCleared);
    on<ReportsLoadRequested>(_onLoadRequested);
  }

  void _onSessionCleared(
    ReportsSessionCleared event,
    Emitter<ReportsState> emit,
  ) {
    _cache.clear();
    emit(const ReportsInitial());
  }

  Future<void> _onLoadRequested(
    ReportsLoadRequested event,
    Emitter<ReportsState> emit,
  ) async {
    // Return cached data if available and not a forced refresh
    final cached = _cache[event.period];
    if (cached != null && !event.forceRefresh) {
      emit(ReportsLoaded(cached, event.period));
      return;
    }

    emit(const ReportsLoading());

    final result = await _repository.getReport(
      slug: event.slug,
      period: event.period,
    );

    switch (result) {
      case Success(:final data):
        _cache[event.period] = data;
        emit(ReportsLoaded(data, event.period));
      case HttpFailure(:final failure):
        emit(ReportsError(_message(failure), event.period));
    }
  }

  String _message(AppFailure failure) => switch (failure) {
        NetworkFailure() => 'Sem conexão com a internet',
        UnauthorizedFailure() => 'Sessão expirada. Faça login novamente.',
        _ => 'Não foi possível carregar os relatórios',
      };
}
