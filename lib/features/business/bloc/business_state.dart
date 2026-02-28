import 'package:equatable/equatable.dart';
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
  const BusinessLoaded({required this.businesses, required this.active});
  @override
  List<Object?> get props => [businesses, active];
}

class BusinessError extends BusinessState {
  final String message;
  const BusinessError(this.message);
  @override
  List<Object?> get props => [message];
}
