import 'package:equatable/equatable.dart';

class ProfessionalRoleModel extends Equatable {
  final String id;
  final String businessId;
  final String name;
  final int? professionalCount;

  const ProfessionalRoleModel({
    required this.id,
    required this.businessId,
    required this.name,
    this.professionalCount,
  });

  factory ProfessionalRoleModel.fromJson(Map<String, dynamic> json) =>
      ProfessionalRoleModel(
        id: json['id'] as String,
        businessId: json['businessId'] as String,
        name: json['name'] as String,
        professionalCount: (json['_count'] as Map<String, dynamic>?)?['professionals'] as int?,
      );

  ProfessionalRoleModel copyWith({
    String? id,
    String? businessId,
    String? name,
    int? professionalCount,
  }) =>
      ProfessionalRoleModel(
        id: id ?? this.id,
        businessId: businessId ?? this.businessId,
        name: name ?? this.name,
        professionalCount: professionalCount ?? this.professionalCount,
      );

  @override
  List<Object?> get props => [id, businessId, name, professionalCount];
}
