import 'package:flutter_http/flutter_http.dart';
import 'package:scheduler_frontend/core/network/api_client.dart';
import 'package:scheduler_frontend/features/professionals/data/professional_role_model.dart';

class ProfessionalRolesRepository {
  final ApiClient _client;

  ProfessionalRolesRepository(this._client);

  Future<Result<List<ProfessionalRoleModel>>> getRoles({
    required String businessId,
  }) =>
      _client.getList(
        '/businesses/$businessId/professional-roles',
        fromJson: ProfessionalRoleModel.fromJson,
      );

  Future<Result<ProfessionalRoleModel>> createRole({
    required String businessId,
    required String name,
  }) =>
      _client.post(
        '/businesses/$businessId/professional-roles',
        fromJson: ProfessionalRoleModel.fromJson,
        body: {'name': name},
      );

  Future<Result<ProfessionalRoleModel>> updateRole({
    required String businessId,
    required String roleId,
    required String name,
  }) =>
      _client.patch(
        '/businesses/$businessId/professional-roles/$roleId',
        fromJson: ProfessionalRoleModel.fromJson,
        body: {'name': name},
      );

  Future<Result<void>> deleteRole({
    required String businessId,
    required String roleId,
  }) =>
      _client.delete('/businesses/$businessId/professional-roles/$roleId');
}
