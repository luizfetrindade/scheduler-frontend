import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_http/flutter_http.dart';
import 'package:scheduler_frontend/features/business/bloc/business_event.dart';
import 'package:scheduler_frontend/features/business/bloc/business_state.dart';
import 'package:scheduler_frontend/features/business/data/business_repository.dart';

class BusinessBloc extends Bloc<BusinessEvent, BusinessState> {
  final BusinessRepository _repository;

  BusinessBloc(this._repository) : super(const BusinessInitial()) {
    on<BusinessLoadRequested>(_onLoadRequested);
    on<BusinessSelected>(_onSelected);
  }

  Future<void> _onLoadRequested(
    BusinessLoadRequested event,
    Emitter<BusinessState> emit,
  ) async {
    emit(const BusinessLoading());
    final result = await _repository.getBusinesses();
    switch (result) {
      case Success(:final data) when data.isNotEmpty:
        emit(BusinessLoaded(businesses: data, active: data.first));
      case Success():
        emit(const BusinessError('Nenhum negócio encontrado'));
      case HttpFailure(:final failure):
        emit(BusinessError(_message(failure)));
    }
  }

  void _onSelected(
    BusinessSelected event,
    Emitter<BusinessState> emit,
  ) {
    if (state case BusinessLoaded(:final businesses)) {
      emit(BusinessLoaded(businesses: businesses, active: event.business));
    }
  }

  String _message(AppFailure failure) => switch (failure) {
        NetworkFailure() => 'Sem conexão com a internet',
        _ => 'Não foi possível carregar os negócios',
      };
}
