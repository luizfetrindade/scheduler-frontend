import 'package:flutter_http/flutter_http.dart';
import 'package:scheduler_frontend/core/network/api_client.dart';
import 'package:scheduler_frontend/features/professionals/data/professional_model.dart';

class ProfessionalRepository {
  final ApiClient _client;

  ProfessionalRepository(this._client);

  Future<Result<List<ProfessionalModel>>> getProfessionals({
    required String businessId,
  }) =>
      _client.getList(
        '/businesses/$businessId/professionals',
        fromJson: ProfessionalModel.fromJson,
      );

  Future<Result<ProfessionalModel>> createProfessional({
    required String businessId,
    required String name,
    String? roleId,
    String? phone,
    String? bio,
    String color = '#4A90E2',
  }) =>
      _client.post(
        '/businesses/$businessId/professionals',
        fromJson: ProfessionalModel.fromJson,
        body: {
          'name': name,
          'color': color,
          if (roleId != null) 'roleId': roleId,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (bio != null && bio.isNotEmpty) 'bio': bio,
        },
      );

  Future<Result<ProfessionalModel>> updateProfessional({
    required String businessId,
    required String professionalId,
    String? name,
    String? roleId,
    String? phone,
    String? bio,
    String? color,
    bool? isActive,
  }) {
    if (color != null && !RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(color)) {
      return Future.value(
        HttpFailure(UnknownFailure('Cor inválida. Use o formato #RRGGBB.')),
      );
    }
    return _client.patch(
      '/businesses/$businessId/professionals/$professionalId',
      fromJson: ProfessionalModel.fromJson,
      body: {
        if (name != null) 'name': name,
        if (roleId != null) 'roleId': roleId,
        if (phone != null) 'phone': phone,
        if (bio != null) 'bio': bio,
        if (color != null) 'color': color,
        if (isActive != null) 'isActive': isActive,
      },
    );
  }

  Future<Result<void>> deleteProfessional({
    required String businessId,
    required String professionalId,
  }) =>
      _client.delete('/businesses/$businessId/professionals/$professionalId');
}
