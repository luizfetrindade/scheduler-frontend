import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_http/flutter_http.dart';
import 'package:scheduler_frontend/features/profile/bloc/profile_event.dart';
import 'package:scheduler_frontend/features/profile/bloc/profile_state.dart';
import 'package:scheduler_frontend/features/profile/data/profile_repository.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _repository;

  ProfileBloc(this._repository) : super(const ProfileIdle()) {
    on<ProfileUpdateNameRequested>(_onUpdateName);
    on<ProfileUpdatePhoneRequested>(_onUpdatePhone);
    on<ProfileChangeEmailRequested>(_onChangeEmail);
    on<ProfileConfirmEmailChangeRequested>(_onConfirmEmailChange);
    on<ProfileUpdateBusinessNameRequested>(_onUpdateBusinessName);
    on<ProfileReset>((_, emit) => emit(const ProfileIdle()));
  }

  Future<void> _onUpdateName(
    ProfileUpdateNameRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());
    final result = await _repository.updateName(event.name);
    switch (result) {
      case Success():
        emit(const ProfileNameUpdated());
      case HttpFailure(:final failure):
        emit(ProfileError(_message(failure)));
    }
  }

  Future<void> _onUpdatePhone(
    ProfileUpdatePhoneRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());
    final result = await _repository.updatePhone(event.phone);
    switch (result) {
      case Success():
        emit(const ProfilePhoneUpdated());
      case HttpFailure(:final failure):
        emit(ProfileError(_message(failure)));
    }
  }

  Future<void> _onChangeEmail(
    ProfileChangeEmailRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());
    final result = await _repository.initiateEmailChange(event.newEmail);
    switch (result) {
      case Success():
        emit(ProfileEmailOtpSent(event.newEmail));
      case HttpFailure(:final failure):
        emit(ProfileError(_message(failure)));
    }
  }

  Future<void> _onConfirmEmailChange(
    ProfileConfirmEmailChangeRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());
    final result = await _repository.confirmEmailChange(event.code);
    switch (result) {
      case Success():
        emit(const ProfileEmailUpdated());
      case HttpFailure(:final failure):
        emit(ProfileError(_message(failure)));
    }
  }

  Future<void> _onUpdateBusinessName(
    ProfileUpdateBusinessNameRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());
    final result =
        await _repository.updateBusinessName(event.businessId, event.name);
    switch (result) {
      case Success():
        emit(const ProfileBusinessNameUpdated());
      case HttpFailure(:final failure):
        emit(ProfileError(_message(failure)));
    }
  }

  String _message(AppFailure failure) => switch (failure) {
        NetworkFailure() => 'Sem conexão com a internet',
        UnauthorizedFailure() => 'Sessão expirada. Faça login novamente.',
        ServerFailure(:final message) => message,
        _ => 'Erro inesperado. Tente novamente.',
      };
}
