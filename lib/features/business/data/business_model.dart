import 'package:equatable/equatable.dart';

enum StaffRole { owner, manager, member }

extension StaffRoleX on StaffRole {
  static StaffRole fromString(String value) => switch (value.toUpperCase()) {
        'OWNER' => StaffRole.owner,
        'MANAGER' => StaffRole.manager,
        _ => StaffRole.member,
      };
}

class BusinessModel extends Equatable {
  final String id;
  final String slug;
  final String name;
  final String? logo;
  final String timezone;
  final StaffRole myStaffRole;
  final int planMaxStaff;

  const BusinessModel({
    required this.id,
    required this.slug,
    required this.name,
    required this.logo,
    required this.timezone,
    this.myStaffRole = StaffRole.owner,
    this.planMaxStaff = 1,
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) => BusinessModel(
        id: json['id'] as String,
        slug: json['slug'] as String,
        name: json['name'] as String,
        logo: json['logo'] as String?,
        timezone: json['timezone'] as String? ?? 'America/Sao_Paulo',
        myStaffRole: StaffRoleX.fromString(
          json['myStaffRole'] as String? ?? 'OWNER',
        ),
        planMaxStaff:
            (json['plan'] as Map<String, dynamic>?)?['maxStaff'] as int? ?? 1,
      );

  BusinessModel copyWith({
    String? id,
    String? slug,
    String? name,
    String? logo,
    String? timezone,
    StaffRole? myStaffRole,
    int? planMaxStaff,
  }) =>
      BusinessModel(
        id: id ?? this.id,
        slug: slug ?? this.slug,
        name: name ?? this.name,
        logo: logo ?? this.logo,
        timezone: timezone ?? this.timezone,
        myStaffRole: myStaffRole ?? this.myStaffRole,
        planMaxStaff: planMaxStaff ?? this.planMaxStaff,
      );

  @override
  List<Object?> get props => [id, slug, name, logo, timezone, myStaffRole, planMaxStaff];
}
