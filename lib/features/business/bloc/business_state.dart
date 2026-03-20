import 'package:equatable/equatable.dart';
import 'package:scheduler_frontend/core/policy/app_policy.dart';
import 'package:scheduler_frontend/features/business/data/business_model.dart';

sealed class BusinessState extends Equatable {
  const BusinessState();
  @override
  List<Object?> get props => [];
}

class BusinessInitial extends BusinessState {
  const BusinessInitial();
}

class BusinessLoading extends BusinessState {
  const BusinessLoading();
}

class BusinessLoaded extends BusinessState {
  final List<BusinessModel> businesses;
  final BusinessModel active;
  final AppPolicy policy;

  const BusinessLoaded({
    required this.businesses,
    required this.active,
    required this.policy,
  });

  @override
  List<Object?> get props => [businesses, active, policy];
}

class BusinessError extends BusinessState {
  final String message;
  const BusinessError(this.message);
  @override
  List<Object?> get props => [message];
}
