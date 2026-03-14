import 'package:equatable/equatable.dart';

class ProfessionalRoleModel extends Equatable {
  final String id;
  final String businessId;
  final String name;

  const ProfessionalRoleModel({
    required this.id,
    required this.businessId,
    required this.name,
  });

  factory ProfessionalRoleModel.fromJson(Map<String, dynamic> json) =>
      ProfessionalRoleModel(
        id: json['id'] as String,
        businessId: json['businessId'] as String,
        name: json['name'] as String,
      );

  ProfessionalRoleModel copyWith({String? id, String? businessId, String? name}) =>
      ProfessionalRoleModel(
        id: id ?? this.id,
        businessId: businessId ?? this.businessId,
        name: name ?? this.name,
      );

  @override
  List<Object?> get props => [id, businessId, name];
}
