import 'package:equatable/equatable.dart';

sealed class BillingEvent extends Equatable {
  const BillingEvent();
  @override
  List<Object?> get props => [];
}

class BillingCheckoutRequested extends BillingEvent {
  final String slug;
  final String planName;
  const BillingCheckoutRequested({required this.slug, required this.planName});
  @override
  List<Object?> get props => [slug, planName];
}

class BillingCancelRequested extends BillingEvent {
  final String slug;
  const BillingCancelRequested({required this.slug});
  @override
  List<Object?> get props => [slug];
}

class BillingSessionCleared extends BillingEvent {
  const BillingSessionCleared();
}
