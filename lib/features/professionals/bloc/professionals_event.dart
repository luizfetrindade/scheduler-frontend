import 'package:equatable/equatable.dart';

sealed class ProfessionalsEvent extends Equatable {
  const ProfessionalsEvent();
  @override
  List<Object?> get props => [];
}

/// Emitted on logout to wipe loaded data from memory.
class ProfessionalsSessionCleared extends ProfessionalsEvent {
  const ProfessionalsSessionCleared();
}

class ProfessionalsLoadRequested extends ProfessionalsEvent {
  final String businessId;
  const ProfessionalsLoadRequested(this.businessId);
  @override
  List<Object?> get props => [businessId];
}

class ProfessionalsCreateRequested extends ProfessionalsEvent {
  final String businessId;
  final String name;
  final String? roleId;
  final String? phone;
  final String? bio;
  final String color;

  const ProfessionalsCreateRequested({
    required this.businessId,
    required this.name,
    this.roleId,
    this.phone,
    this.bio,
    this.color = '#4A90E2',
  });

  @override
  List<Object?> get props => [businessId, name, roleId, phone, bio, color];
}

class ProfessionalsUpdateRequested extends ProfessionalsEvent {
  final String businessId;
  final String professionalId;
  final String? name;
  final String? roleId;
  final String? phone;
  final String? bio;
  final String? color;
  final bool? isActive;

  const ProfessionalsUpdateRequested({
    required this.businessId,
    required this.professionalId,
    this.name,
    this.roleId,
    this.phone,
    this.bio,
    this.color,
    this.isActive,
  });

  @override
  List<Object?> get props =>
      [businessId, professionalId, name, roleId, phone, bio, color, isActive];
}

class ProfessionalsDeleteRequested extends ProfessionalsEvent {
  final String businessId;
  final String professionalId;

  const ProfessionalsDeleteRequested({
    required this.businessId,
    required this.professionalId,
  });

  @override
  List<Object?> get props => [businessId, professionalId];
}
