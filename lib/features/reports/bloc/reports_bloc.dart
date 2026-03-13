import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_http/flutter_http.dart';
import 'package:scheduler_frontend/features/reports/bloc/reports_event.dart';
import 'package:scheduler_frontend/features/reports/bloc/reports_state.dart';
import 'package:scheduler_frontend/features/reports/data/reports_repository.dart';

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final ReportsRepository _repository;

  ReportsBloc(this._repository) : super(const ReportsInitial()) {
    on<ReportsLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    ReportsLoadRequested event,
    Emitter<ReportsState> emit,
  ) async {
    emit(const ReportsLoading());

    final result = await _repository.getReport(
      slug: event.slug,
      period: event.period,
    );

    switch (result) {
      case Success(:final data):
        emit(ReportsLoaded(data, event.period));
      case HttpFailure(:final failure):
        emit(ReportsError(_message(failure), event.period));
    }
  }

  String _message(AppFailure failure) => switch (failure) {
        NetworkFailure() => 'Sem conexão com a internet',
        UnauthorizedFailure() => 'Você não tem permissão para ver relatórios',
        _ => 'Não foi possível carregar os relatórios',
      };
}
