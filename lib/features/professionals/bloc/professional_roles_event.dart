import 'package:equatable/equatable.dart';

sealed class ProfessionalRolesEvent extends Equatable {
  const ProfessionalRolesEvent();
  @override
  List<Object?> get props => [];
}

class ProfessionalRolesLoadRequested extends ProfessionalRolesEvent {
  final String businessId;
  const ProfessionalRolesLoadRequested(this.businessId);
  @override
  List<Object?> get props => [businessId];
}

class ProfessionalRolesCreateRequested extends ProfessionalRolesEvent {
  final String businessId;
  final String name;
  const ProfessionalRolesCreateRequested({
    required this.businessId,
    required this.name,
  });
  @override
  List<Object?> get props => [businessId, name];
}

class ProfessionalRolesUpdateRequested extends ProfessionalRolesEvent {
  final String businessId;
  final String roleId;
  final String name;
  const ProfessionalRolesUpdateRequested({
    required this.businessId,
    required this.roleId,
    required this.name,
  });
  @override
  List<Object?> get props => [businessId, roleId, name];
}

class ProfessionalRolesDeleteRequested extends ProfessionalRolesEvent {
  final String businessId;
  final String roleId;
  const ProfessionalRolesDeleteRequested({
    required this.businessId,
    required this.roleId,
  });
  @override
  List<Object?> get props => [businessId, roleId];
}
