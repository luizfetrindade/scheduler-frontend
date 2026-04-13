import 'package:equatable/equatable.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

class ProfileUpdateNameRequested extends ProfileEvent {
  final String name;
  const ProfileUpdateNameRequested(this.name);
  @override
  List<Object?> get props => [name];
}

class ProfileUpdatePhoneRequested extends ProfileEvent {
  final String phone;
  const ProfileUpdatePhoneRequested(this.phone);
  @override
  List<Object?> get props => [phone];
}

class ProfileChangeEmailRequested extends ProfileEvent {
  final String newEmail;
  const ProfileChangeEmailRequested(this.newEmail);
  @override
  List<Object?> get props => [newEmail];
}

class ProfileConfirmEmailChangeRequested extends ProfileEvent {
  final String code;
  const ProfileConfirmEmailChangeRequested(this.code);
  // OTP code excluded from props.
  @override
  List<Object?> get props => [];
}

class ProfileUpdateBusinessNameRequested extends ProfileEvent {
  final String businessId;
  final String name;
  const ProfileUpdateBusinessNameRequested({
    required this.businessId,
    required this.name,
  });
  @override
  List<Object?> get props => [businessId, name];
}

class ProfileReset extends ProfileEvent {
  const ProfileReset();
}
