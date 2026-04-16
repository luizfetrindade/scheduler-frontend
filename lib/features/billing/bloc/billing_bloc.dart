import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_http/flutter_http.dart';
import 'package:scheduler_frontend/features/billing/bloc/billing_event.dart';
import 'package:scheduler_frontend/features/billing/bloc/billing_state.dart';
import 'package:scheduler_frontend/features/billing/data/billing_repository.dart';

class BillingBloc extends Bloc<BillingEvent, BillingState> {
  final BillingRepository _repository;

  BillingBloc(this._repository) : super(const BillingInitial()) {
    on<BillingCheckoutRequested>(_onCheckoutRequested);
    on<BillingCancelRequested>(_onCancelRequested);
    on<BillingSessionCleared>((_, emit) => emit(const BillingInitial()));
  }

  Future<void> _onCheckoutRequested(
    BillingCheckoutRequested event,
    Emitter<BillingState> emit,
  ) async {
    emit(const BillingLoading());
    final result = await _repository.createCheckout(
      slug: event.slug,
      planName: event.planName,
    );
    switch (result) {
      case Success(:final data):
        emit(BillingCheckoutReady(data));
      case HttpFailure(:final failure):
        emit(BillingError(_message(failure)));
    }
  }

  Future<void> _onCancelRequested(
    BillingCancelRequested event,
    Emitter<BillingState> emit,
  ) async {
    emit(const BillingLoading());
    final result = await _repository.cancelSubscription(slug: event.slug);
    switch (result) {
      case Success():
        emit(const BillingSubscriptionCancelled());
      case HttpFailure(:final failure):
        emit(BillingError(_message(failure)));
    }
  }

  String _message(AppFailure failure) => switch (failure) {
        NetworkFailure() => 'Sem conexão com a internet',
        UnauthorizedFailure() => 'Você não tem permissão para esta ação',
        ServerFailure(:final message) => message,
        _ => 'Erro inesperado. Tente novamente.',
      };
}
