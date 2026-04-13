import 'package:equatable/equatable.dart';

sealed class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileIdle extends ProfileState {
  const ProfileIdle();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileNameUpdated extends ProfileState {
  const ProfileNameUpdated();
}

class ProfilePhoneUpdated extends ProfileState {
  const ProfilePhoneUpdated();
}

/// Email change step 1 success: OTP sent to new email address.
class ProfileEmailOtpSent extends ProfileState {
  final String newEmail;
  const ProfileEmailOtpSent(this.newEmail);
  @override
  List<Object?> get props => [newEmail];
}

/// Email change step 2 success: new email persisted.
class ProfileEmailUpdated extends ProfileState {
  const ProfileEmailUpdated();
}

class ProfileBusinessNameUpdated extends ProfileState {
  const ProfileBusinessNameUpdated();
}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);
  @override
  List<Object?> get props => [message];
}
