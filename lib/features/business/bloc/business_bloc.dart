import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_http/flutter_http.dart';
import 'package:scheduler_frontend/core/policy/app_policy.dart';
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
    final result = await _repository.getBusinessesMine();
    switch (result) {
      case Success(:final data) when data.isNotEmpty:
        final active = data.first;
        final policy = AppPolicy.from(active.myStaffRole, active.planMaxStaff);
        emit(BusinessLoaded(businesses: data, active: active, policy: policy));
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
      final active = event.business;
      final policy = AppPolicy.from(active.myStaffRole, active.planMaxStaff);
      emit(BusinessLoaded(businesses: businesses, active: active, policy: policy));
    }
  }

  String _message(AppFailure failure) => switch (failure) {
        NetworkFailure() => 'Sem conexão com a internet',
        _ => 'Não foi possível carregar os negócios',
      };
}
