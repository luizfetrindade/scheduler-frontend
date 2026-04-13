import 'package:flutter_http/flutter_http.dart';
import 'package:scheduler_frontend/core/network/api_client.dart';

class ProfileRepository {
  final ApiClient _client;

  ProfileRepository(this._client);

  Future<Result<void>> updateName(String name) async {
    final result = await _client.updateMyName(name);
    return switch (result) {
      Success() => const Success(null),
      HttpFailure(:final failure) => HttpFailure(failure),
    };
  }

  Future<Result<void>> updatePhone(String phone) async {
    final result = await _client.updateMyPhone(phone);
    return switch (result) {
      Success() => const Success(null),
      HttpFailure(:final failure) => HttpFailure(failure),
    };
  }

  Future<Result<void>> initiateEmailChange(String newEmail) async {
    final result = await _client.initiateEmailChange(newEmail);
    return switch (result) {
      Success() => const Success(null),
      HttpFailure(:final failure) => HttpFailure(failure),
    };
  }

  Future<Result<void>> confirmEmailChange(String code) async {
    final result = await _client.confirmEmailChange(code);
    return switch (result) {
      Success() => const Success(null),
      HttpFailure(:final failure) => HttpFailure(failure),
    };
  }

  Future<Result<void>> updateBusinessName(
      String businessId, String name) async {
    final result = await _client.updateBusinessName(businessId, name);
    return switch (result) {
      Success() => const Success(null),
      HttpFailure(:final failure) => HttpFailure(failure),
    };
  }
}
