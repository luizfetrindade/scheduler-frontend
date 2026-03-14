import 'package:equatable/equatable.dart';

const _sentinel = Object();

class ProfessionalModel extends Equatable {
  final String id;
  final String businessId;
  final String name;
  final String? photoUrl;
  final String? roleId;
  final String? roleName;
  final String? phone;
  final String? bio;
  final String color;
  final bool isActive;
  final String? linkedUserId;

  const ProfessionalModel({
    required this.id,
    required this.businessId,
    required this.name,
    this.photoUrl,
    this.roleId,
    this.roleName,
    this.phone,
    this.bio,
    this.color = '#4A90E2',
    this.isActive = true,
    this.linkedUserId,
  });

  factory ProfessionalModel.fromJson(Map<String, dynamic> json) =>
      ProfessionalModel(
        id: json['id'] as String,
        businessId: json['businessId'] as String,
        name: json['name'] as String,
        photoUrl: json['photoUrl'] as String?,
        roleId: json['roleId'] as String?,
        roleName: json['roleName'] as String?,
        phone: json['phone'] as String?,
        bio: json['bio'] as String?,
        color: json['color'] as String? ?? '#4A90E2',
        isActive: json['isActive'] as bool? ?? true,
        linkedUserId: json['linkedUserId'] as String?,
      );

  ProfessionalModel copyWith({
    String? name,
    String? color,
    bool? isActive,
    Object? photoUrl = _sentinel,
    Object? roleId = _sentinel,
    Object? roleName = _sentinel,
    Object? phone = _sentinel,
    Object? bio = _sentinel,
    Object? linkedUserId = _sentinel,
  }) =>
      ProfessionalModel(
        id: id,
        businessId: businessId,
        name: name ?? this.name,
        color: color ?? this.color,
        isActive: isActive ?? this.isActive,
        photoUrl: photoUrl == _sentinel ? this.photoUrl : photoUrl as String?,
        roleId: roleId == _sentinel ? this.roleId : roleId as String?,
        roleName: roleName == _sentinel ? this.roleName : roleName as String?,
        phone: phone == _sentinel ? this.phone : phone as String?,
        bio: bio == _sentinel ? this.bio : bio as String?,
        linkedUserId: linkedUserId == _sentinel
            ? this.linkedUserId
            : linkedUserId as String?,
      );

  @override
  List<Object?> get props => [
        id,
        businessId,
        name,
        photoUrl,
        roleId,
        roleName,
        phone,
        bio,
        color,
        isActive,
        linkedUserId,
      ];
}
