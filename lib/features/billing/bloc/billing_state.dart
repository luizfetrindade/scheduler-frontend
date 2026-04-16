import 'package:equatable/equatable.dart';

sealed class BillingState extends Equatable {
  const BillingState();
  @override
  List<Object?> get props => [];
}

class BillingInitial extends BillingState {
  const BillingInitial();
}

class BillingLoading extends BillingState {
  const BillingLoading();
}

/// Checkout URL is ready — the UI should open this URL then reset the bloc.
class BillingCheckoutReady extends BillingState {
  final String url;
  const BillingCheckoutReady(this.url);
  @override
  List<Object?> get props => [url];
}

/// Subscription was cancelled successfully.
class BillingSubscriptionCancelled extends BillingState {
  const BillingSubscriptionCancelled();
}

class BillingError extends BillingState {
  final String message;
  const BillingError(this.message);
  @override
  List<Object?> get props => [message];
}
