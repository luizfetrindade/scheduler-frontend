import 'package:equatable/equatable.dart';
import 'package:scheduler_frontend/features/services/data/service_model.dart';

sealed class ServicesState extends Equatable {
  const ServicesState();
  @override
  List<Object?> get props => [];
}

class ServicesInitial extends ServicesState {
  const ServicesInitial();
}

class ServicesLoading extends ServicesState {
  const ServicesLoading();
}

class ServicesLoaded extends ServicesState {
  final List<ServiceModel> services;
  const ServicesLoaded(this.services);
  @override
  List<Object?> get props => [services];
}

/// Used during create/update/delete — keeps list visible while action is in progress
class ServicesActionInProgress extends ServicesState {
  final List<ServiceModel> services;
  const ServicesActionInProgress(this.services);
  @override
  List<Object?> get props => [services];
}

class ServicesError extends ServicesState {
  final String message;
  final List<ServiceModel> services;
  const ServicesError(this.message, {this.services = const []});
  @override
  List<Object?> get props => [message, services];
}
