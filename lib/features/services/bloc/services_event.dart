import 'package:equatable/equatable.dart';

sealed class ServicesEvent extends Equatable {
  const ServicesEvent();
  @override
  List<Object?> get props => [];
}

class ServicesLoadRequested extends ServicesEvent {
  final String businessId;
  const ServicesLoadRequested(this.businessId);
  @override
  List<Object?> get props => [businessId];
}

class ServiceCreateRequested extends ServicesEvent {
  final String businessId;
  final String name;
  final String? description;
  final double? price;
  final int? durationMinutes;

  const ServiceCreateRequested({
    required this.businessId,
    required this.name,
    this.description,
    this.price,
    this.durationMinutes,
  });

  @override
  List<Object?> get props =>
      [businessId, name, description, price, durationMinutes];
}

class ServiceUpdateRequested extends ServicesEvent {
  final String businessId;
  final String serviceId;
  final String? name;
  final String? description;
  final double? price;
  final int? durationMinutes;
  final bool? isActive;

  const ServiceUpdateRequested({
    required this.businessId,
    required this.serviceId,
    this.name,
    this.description,
    this.price,
    this.durationMinutes,
    this.isActive,
  });

  @override
  List<Object?> get props =>
      [businessId, serviceId, name, description, price, durationMinutes, isActive];
}

class ServiceDeleteRequested extends ServicesEvent {
  final String businessId;
  final String serviceId;

  const ServiceDeleteRequested({
    required this.businessId,
    required this.serviceId,
  });

  @override
  List<Object?> get props => [businessId, serviceId];
}
