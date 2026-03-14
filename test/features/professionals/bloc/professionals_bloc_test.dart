import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_http/flutter_http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professionals_bloc.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professionals_event.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professionals_state.dart';
import 'package:scheduler_frontend/features/professionals/data/professional_model.dart';
import 'package:scheduler_frontend/features/professionals/data/professional_repository.dart';

class MockProfessionalRepository extends Mock implements ProfessionalRepository {}

final _prof1 = ProfessionalModel(
  id: 'p1', businessId: 'b1', name: 'Ana', color: '#4A90E2', isActive: true,
);
final _prof2 = ProfessionalModel(
  id: 'p2', businessId: 'b1', name: 'Carlos', color: '#FF5733', isActive: true,
);

void main() {
  late MockProfessionalRepository repo;

  setUp(() => repo = MockProfessionalRepository());

  group('ProfessionalsLoadRequested', () {
    blocTest<ProfessionalsBloc, ProfessionalsState>(
      'emits Loading then Loaded on success',
      build: () => ProfessionalsBloc(repo),
      setUp: () => when(() => repo.getProfessionals(businessId: 'b1'))
          .thenAnswer((_) async => Success([_prof1, _prof2])),
      act: (bloc) => bloc.add(const ProfessionalsLoadRequested('b1')),
      expect: () => [
        const ProfessionalsLoading(),
        ProfessionalsLoaded([_prof1, _prof2]),
      ],
    );

    blocTest<ProfessionalsBloc, ProfessionalsState>(
      'emits Loading then Error on failure',
      build: () => ProfessionalsBloc(repo),
      setUp: () => when(() => repo.getProfessionals(businessId: 'b1'))
          .thenAnswer((_) async => HttpFailure(const NetworkFailure('no internet'))),
      act: (bloc) => bloc.add(const ProfessionalsLoadRequested('b1')),
      expect: () => [
        const ProfessionalsLoading(),
        isA<ProfessionalsError>(),
      ],
    );
  });

  group('ProfessionalsCreateRequested', () {
    blocTest<ProfessionalsBloc, ProfessionalsState>(
      'emits ActionInProgress then Loaded with new item appended',
      build: () => ProfessionalsBloc(repo),
      seed: () => ProfessionalsLoaded([_prof1]),
      setUp: () => when(() => repo.createProfessional(
            businessId: 'b1',
            name: 'Maria',
            color: '#4A90E2',
          )).thenAnswer((_) async => Success(_prof2.copyWith(name: 'Maria'))),
      act: (bloc) => bloc.add(const ProfessionalsCreateRequested(
        businessId: 'b1',
        name: 'Maria',
      )),
      expect: () => [
        ProfessionalsActionInProgress([_prof1]),
        isA<ProfessionalsLoaded>(),
      ],
    );

    blocTest<ProfessionalsBloc, ProfessionalsState>(
      'emits ActionInProgress then Error on failure, preserving list',
      build: () => ProfessionalsBloc(repo),
      seed: () => ProfessionalsLoaded([_prof1]),
      setUp: () => when(() => repo.createProfessional(
            businessId: 'b1',
            name: 'Maria',
            color: '#4A90E2',
          )).thenAnswer((_) async => HttpFailure(const NetworkFailure('no internet'))),
      act: (bloc) => bloc.add(const ProfessionalsCreateRequested(
        businessId: 'b1',
        name: 'Maria',
      )),
      expect: () => [
        ProfessionalsActionInProgress([_prof1]),
        isA<ProfessionalsError>().having(
          (e) => e.professionals,
          'professionals preserved',
          [_prof1],
        ),
      ],
    );
  });

  group('ProfessionalsUpdateRequested', () {
    blocTest<ProfessionalsBloc, ProfessionalsState>(
      'emits ActionInProgress then Loaded with updated item',
      build: () => ProfessionalsBloc(repo),
      seed: () => ProfessionalsLoaded([_prof1]),
      setUp: () => when(() => repo.updateProfessional(
            businessId: 'b1',
            professionalId: 'p1',
            isActive: false,
          )).thenAnswer((_) async => Success(_prof1.copyWith(isActive: false))),
      act: (bloc) => bloc.add(const ProfessionalsUpdateRequested(
        businessId: 'b1',
        professionalId: 'p1',
        isActive: false,
      )),
      expect: () => [
        ProfessionalsActionInProgress([_prof1]),
        isA<ProfessionalsLoaded>().having(
          (s) => s.professionals.first.isActive,
          'isActive updated',
          false,
        ),
      ],
    );
  });

  group('ProfessionalsDeleteRequested', () {
    blocTest<ProfessionalsBloc, ProfessionalsState>(
      'optimistically removes item, confirms on success',
      build: () => ProfessionalsBloc(repo),
      seed: () => ProfessionalsLoaded([_prof1, _prof2]),
      setUp: () => when(() => repo.deleteProfessional(
            businessId: 'b1',
            professionalId: 'p1',
          )).thenAnswer((_) async => const Success(null)),
      act: (bloc) => bloc.add(const ProfessionalsDeleteRequested(
        businessId: 'b1',
        professionalId: 'p1',
      )),
      expect: () => [
        ProfessionalsActionInProgress([_prof1, _prof2]),
        ProfessionalsLoaded([_prof2]),
      ],
    );

    blocTest<ProfessionalsBloc, ProfessionalsState>(
      'rolls back list on delete failure',
      build: () => ProfessionalsBloc(repo),
      seed: () => ProfessionalsLoaded([_prof1, _prof2]),
      setUp: () => when(() => repo.deleteProfessional(
            businessId: 'b1',
            professionalId: 'p1',
          )).thenAnswer((_) async => HttpFailure(const NetworkFailure('no internet'))),
      act: (bloc) => bloc.add(const ProfessionalsDeleteRequested(
        businessId: 'b1',
        professionalId: 'p1',
      )),
      expect: () => [
        ProfessionalsActionInProgress([_prof1, _prof2]),
        isA<ProfessionalsError>().having(
          (e) => e.professionals,
          'list rolled back',
          [_prof1, _prof2],
        ),
      ],
    );
  });
}
