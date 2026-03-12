import 'package:equatable/equatable.dart';

class ServiceModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final double? price;
  final int? durationMinutes;
  final bool isActive;

  const ServiceModel({
    required this.id,
    required this.name,
    this.description,
    this.price,
    this.durationMinutes,
    required this.isActive,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) => ServiceModel(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        price: (json['price'] as num?)?.toDouble(),
        durationMinutes: json['durationMinutes'] as int?,
        isActive: json['isActive'] as bool? ?? true,
      );

  ServiceModel copyWith({
    String? name,
    String? description,
    double? price,
    int? durationMinutes,
    bool? isActive,
  }) =>
      ServiceModel(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        price: price ?? this.price,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        isActive: isActive ?? this.isActive,
      );

  @override
  List<Object?> get props => [id, name, description, price, durationMinutes, isActive];
}
