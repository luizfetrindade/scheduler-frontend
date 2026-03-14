import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_http/flutter_http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_bloc.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_event.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_state.dart';
import 'package:scheduler_frontend/features/professionals/data/professional_role_model.dart';
import 'package:scheduler_frontend/features/professionals/data/professional_roles_repository.dart';

class MockProfessionalRolesRepository extends Mock
    implements ProfessionalRolesRepository {}

final _role1 =
    ProfessionalRoleModel(id: 'r1', businessId: 'b1', name: 'Cabeleireira');
final _role2 =
    ProfessionalRoleModel(id: 'r2', businessId: 'b1', name: 'Manicure');

void main() {
  late MockProfessionalRolesRepository repo;

  setUp(() => repo = MockProfessionalRolesRepository());

  group('ProfessionalRolesLoadRequested', () {
    blocTest<ProfessionalRolesBloc, ProfessionalRolesState>(
      'emits Loading then Loaded on success',
      build: () => ProfessionalRolesBloc(repo),
      setUp: () => when(() => repo.getRoles(businessId: 'b1'))
          .thenAnswer((_) async => Success([_role1, _role2])),
      act: (bloc) => bloc.add(const ProfessionalRolesLoadRequested('b1')),
      expect: () => [
        const ProfessionalRolesLoading(),
        ProfessionalRolesLoaded([_role1, _role2]),
      ],
    );

    blocTest<ProfessionalRolesBloc, ProfessionalRolesState>(
      'emits Loading then Error on failure',
      build: () => ProfessionalRolesBloc(repo),
      setUp: () => when(() => repo.getRoles(businessId: 'b1'))
          .thenAnswer(
              (_) async => HttpFailure(const NetworkFailure('no internet'))),
      act: (bloc) => bloc.add(const ProfessionalRolesLoadRequested('b1')),
      expect: () => [
        const ProfessionalRolesLoading(),
        isA<ProfessionalRolesError>(),
      ],
    );
  });

  group('ProfessionalRolesCreateRequested', () {
    blocTest<ProfessionalRolesBloc, ProfessionalRolesState>(
      'emits ActionInProgress then Loaded with new item appended',
      build: () => ProfessionalRolesBloc(repo),
      seed: () => ProfessionalRolesLoaded([_role1]),
      setUp: () => when(() => repo.createRole(
            businessId: 'b1',
            name: 'Esteticista',
          )).thenAnswer((_) async => Success(
            ProfessionalRoleModel(
                id: 'r3', businessId: 'b1', name: 'Esteticista'),
          )),
      act: (bloc) => bloc.add(const ProfessionalRolesCreateRequested(
        businessId: 'b1',
        name: 'Esteticista',
      )),
      expect: () => [
        ProfessionalRolesActionInProgress([_role1]),
        isA<ProfessionalRolesLoaded>().having(
          (s) => s.roles.length,
          'list length increased',
          2,
        ),
      ],
    );

    blocTest<ProfessionalRolesBloc, ProfessionalRolesState>(
      'emits ActionInProgress then Error on failure, preserving list',
      build: () => ProfessionalRolesBloc(repo),
      seed: () => ProfessionalRolesLoaded([_role1]),
      setUp: () => when(() => repo.createRole(
            businessId: 'b1',
            name: 'Esteticista',
          )).thenAnswer(
              (_) async => HttpFailure(const NetworkFailure('error'))),
      act: (bloc) => bloc.add(const ProfessionalRolesCreateRequested(
        businessId: 'b1',
        name: 'Esteticista',
      )),
      expect: () => [
        ProfessionalRolesActionInProgress([_role1]),
        isA<ProfessionalRolesError>().having(
          (e) => e.roles,
          'roles preserved',
          [_role1],
        ),
      ],
    );
  });

  group('ProfessionalRolesUpdateRequested', () {
    blocTest<ProfessionalRolesBloc, ProfessionalRolesState>(
      'emits ActionInProgress then Loaded with updated item',
      build: () => ProfessionalRolesBloc(repo),
      seed: () => ProfessionalRolesLoaded([_role1]),
      setUp: () => when(() => repo.updateRole(
            businessId: 'b1',
            roleId: 'r1',
            name: 'Cabeleireira Sênior',
          )).thenAnswer(
              (_) async => Success(_role1.copyWith(name: 'Cabeleireira Sênior'))),
      act: (bloc) => bloc.add(const ProfessionalRolesUpdateRequested(
        businessId: 'b1',
        roleId: 'r1',
        name: 'Cabeleireira Sênior',
      )),
      expect: () => [
        ProfessionalRolesActionInProgress([_role1]),
        isA<ProfessionalRolesLoaded>().having(
          (s) => s.roles.first.name,
          'role name updated',
          'Cabeleireira Sênior',
        ),
      ],
    );
  });

  group('ProfessionalRolesDeleteRequested', () {
    blocTest<ProfessionalRolesBloc, ProfessionalRolesState>(
      'optimistically removes item, confirms on success',
      build: () => ProfessionalRolesBloc(repo),
      seed: () => ProfessionalRolesLoaded([_role1, _role2]),
      setUp: () => when(() => repo.deleteRole(
            businessId: 'b1',
            roleId: 'r1',
          )).thenAnswer((_) async => const Success(null)),
      act: (bloc) => bloc.add(const ProfessionalRolesDeleteRequested(
        businessId: 'b1',
        roleId: 'r1',
      )),
      expect: () => [
        ProfessionalRolesActionInProgress([_role1, _role2]),
        ProfessionalRolesLoaded([_role2]),
      ],
    );

    blocTest<ProfessionalRolesBloc, ProfessionalRolesState>(
      'rolls back list on delete failure',
      build: () => ProfessionalRolesBloc(repo),
      seed: () => ProfessionalRolesLoaded([_role1, _role2]),
      setUp: () => when(() => repo.deleteRole(
            businessId: 'b1',
            roleId: 'r1',
          )).thenAnswer(
              (_) async => HttpFailure(const NetworkFailure('error'))),
      act: (bloc) => bloc.add(const ProfessionalRolesDeleteRequested(
        businessId: 'b1',
        roleId: 'r1',
      )),
      expect: () => [
        ProfessionalRolesActionInProgress([_role1, _role2]),
        isA<ProfessionalRolesError>().having(
          (e) => e.roles,
          'list rolled back',
          [_role1, _role2],
        ),
      ],
    );
  });
}
