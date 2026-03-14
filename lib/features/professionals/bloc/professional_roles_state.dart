import 'package:equatable/equatable.dart';
import 'package:scheduler_frontend/features/professionals/data/professional_role_model.dart';

sealed class ProfessionalRolesState extends Equatable {
  const ProfessionalRolesState();
  @override
  List<Object?> get props => [];
}

class ProfessionalRolesInitial extends ProfessionalRolesState {
  const ProfessionalRolesInitial();
}

class ProfessionalRolesLoading extends ProfessionalRolesState {
  const ProfessionalRolesLoading();
}

class ProfessionalRolesLoaded extends ProfessionalRolesState {
  final List<ProfessionalRoleModel> roles;
  const ProfessionalRolesLoaded(this.roles);
  @override
  List<Object?> get props => [roles];
}

/// Keeps list visible during create/update/delete to avoid UI flicker.
class ProfessionalRolesActionInProgress extends ProfessionalRolesState {
  final List<ProfessionalRoleModel> roles;
  const ProfessionalRolesActionInProgress(this.roles);
  @override
  List<Object?> get props => [roles];
}

class ProfessionalRolesError extends ProfessionalRolesState {
  final String message;
  final List<ProfessionalRoleModel> roles;
  const ProfessionalRolesError(this.message, {this.roles = const []});
  @override
  List<Object?> get props => [message, roles];
}
