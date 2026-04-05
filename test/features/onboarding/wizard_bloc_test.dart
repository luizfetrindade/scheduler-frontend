import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/features/onboarding/bloc/wizard_bloc.dart';
import 'package:scheduler_frontend/features/onboarding/bloc/wizard_event.dart';
import 'package:scheduler_frontend/features/onboarding/bloc/wizard_state.dart';

WizardBloc _makeSoloBloc({
  bool hasServices = false,
}) =>
    WizardBloc(
      createBusiness: (_) async => 'biz-1',
      hasServices: (_) async => hasServices,
      hasProfessionals: (_) async => false,
      isSoloMode: true,
      businessId: 'biz-1',
    );

WizardBloc _makeTeamBloc({
  bool hasServices = false,
  bool hasProfessionals = false,
}) =>
    WizardBloc(
      createBusiness: (_) async => 'biz-1',
      hasServices: (_) async => hasServices,
      hasProfessionals: (_) async => hasProfessionals,
      isSoloMode: false,
      businessId: 'biz-1',
    );

WizardBloc _makeNoBizBloc({
  Future<String> Function(String)? createBusiness,
  bool hasServices = false,
}) =>
    WizardBloc(
      createBusiness: createBusiness ?? (_) async => 'biz-new',
      hasServices: (_) async => hasServices,
      hasProfessionals: (_) async => false,
      isSoloMode: true,
      businessId: '',
    );

void main() {
  // ─── Initial state ──────────────────────────────────────────────────────────

  test('WizardBloc initial state is WizardInitial', () {
    final bloc = _makeSoloBloc();
    expect(bloc.state, const WizardInitial());
    bloc.close();
  });

  // ─── WizardCheckRequested — solo mode ───────────────────────────────────────

  group('WizardCheckRequested — solo mode', () {
    blocTest<WizardBloc, WizardState>(
      'emits [WizardLoading, WizardLoaded] with only servicos step',
      build: () => _makeSoloBloc(hasServices: false),
      act: (bloc) => bloc.add(const WizardCheckRequested()),
      expect: () => [
        const WizardLoading(),
        isA<WizardLoaded>().having(
          (s) => s.steps.keys.toSet(),
          'step keys',
          {WizardStep.servicos},
        ),
      ],
    );

    blocTest<WizardBloc, WizardState>(
      'solo mode does not include equipe step',
      build: () => _makeSoloBloc(hasServices: true),
      act: (bloc) => bloc.add(const WizardCheckRequested()),
      expect: () => [
        const WizardLoading(),
        isA<WizardLoaded>().having(
          (s) => s.steps.containsKey(WizardStep.equipe),
          'has equipe key',
          false,
        ),
      ],
    );
  });

  // ─── WizardCheckRequested — team mode ───────────────────────────────────────

  group('WizardCheckRequested — team mode', () {
    blocTest<WizardBloc, WizardState>(
      'emits [WizardLoading, WizardLoaded] with servicos and equipe steps',
      build: () => _makeTeamBloc(hasServices: false, hasProfessionals: false),
      act: (bloc) => bloc.add(const WizardCheckRequested()),
      expect: () => [
        const WizardLoading(),
        isA<WizardLoaded>().having(
          (s) => s.steps.keys.toSet(),
          'step keys',
          {WizardStep.servicos, WizardStep.equipe},
        ),
      ],
    );
  });

  // ─── Step completeness ───────────────────────────────────────────────────────

  group('Step completeness', () {
    blocTest<WizardBloc, WizardState>(
      'servicos.isComplete is true when hasServices returns true',
      build: () => _makeSoloBloc(hasServices: true),
      act: (bloc) => bloc.add(const WizardCheckRequested()),
      expect: () => [
        const WizardLoading(),
        isA<WizardLoaded>().having(
          (s) => s.steps[WizardStep.servicos]!.isComplete,
          'servicos.isComplete',
          true,
        ),
      ],
    );

    blocTest<WizardBloc, WizardState>(
      'servicos.isComplete is false when hasServices returns false',
      build: () => _makeSoloBloc(hasServices: false),
      act: (bloc) => bloc.add(const WizardCheckRequested()),
      expect: () => [
        const WizardLoading(),
        isA<WizardLoaded>().having(
          (s) => s.steps[WizardStep.servicos]!.isComplete,
          'servicos.isComplete',
          false,
        ),
      ],
    );

    blocTest<WizardBloc, WizardState>(
      'equipe.isComplete is true when hasProfessionals returns true (team mode)',
      build: () => _makeTeamBloc(hasServices: true, hasProfessionals: true),
      act: (bloc) => bloc.add(const WizardCheckRequested()),
      expect: () => [
        const WizardLoading(),
        isA<WizardLoaded>().having(
          (s) => s.steps[WizardStep.equipe]!.isComplete,
          'equipe.isComplete',
          true,
        ),
      ],
    );

    blocTest<WizardBloc, WizardState>(
      'equipe.isComplete is false when hasProfessionals returns false (team mode)',
      build: () => _makeTeamBloc(hasServices: true, hasProfessionals: false),
      act: (bloc) => bloc.add(const WizardCheckRequested()),
      expect: () => [
        const WizardLoading(),
        isA<WizardLoaded>().having(
          (s) => s.steps[WizardStep.equipe]!.isComplete,
          'equipe.isComplete',
          false,
        ),
      ],
    );
  });

  // ─── isAllComplete ───────────────────────────────────────────────────────────

  group('WizardLoaded.isAllComplete', () {
    blocTest<WizardBloc, WizardState>(
      'isAllComplete is true when all steps are complete (solo)',
      build: () => _makeSoloBloc(hasServices: true),
      act: (bloc) => bloc.add(const WizardCheckRequested()),
      expect: () => [
        const WizardLoading(),
        isA<WizardLoaded>().having(
          (s) => s.isAllComplete,
          'isAllComplete',
          true,
        ),
      ],
    );

    blocTest<WizardBloc, WizardState>(
      'isAllComplete is false when any step is incomplete (solo)',
      build: () => _makeSoloBloc(hasServices: false),
      act: (bloc) => bloc.add(const WizardCheckRequested()),
      expect: () => [
        const WizardLoading(),
        isA<WizardLoaded>().having(
          (s) => s.isAllComplete,
          'isAllComplete',
          false,
        ),
      ],
    );

    blocTest<WizardBloc, WizardState>(
      'isAllComplete is true when all team steps are complete',
      build: () => _makeTeamBloc(hasServices: true, hasProfessionals: true),
      act: (bloc) => bloc.add(const WizardCheckRequested()),
      expect: () => [
        const WizardLoading(),
        isA<WizardLoaded>().having(
          (s) => s.isAllComplete,
          'isAllComplete',
          true,
        ),
      ],
    );

    blocTest<WizardBloc, WizardState>(
      'isAllComplete is false when equipe step is incomplete (team mode)',
      build: () => _makeTeamBloc(hasServices: true, hasProfessionals: false),
      act: (bloc) => bloc.add(const WizardCheckRequested()),
      expect: () => [
        const WizardLoading(),
        isA<WizardLoaded>().having(
          (s) => s.isAllComplete,
          'isAllComplete',
          false,
        ),
      ],
    );
  });

  // ─── WizardStepCompleted ─────────────────────────────────────────────────────

  group('WizardStepCompleted', () {
    blocTest<WizardBloc, WizardState>(
      'WizardStepCompleted triggers a new WizardCheckRequested '
      'and emits [WizardLoading, WizardLoaded]',
      build: () => _makeSoloBloc(hasServices: true),
      act: (bloc) => bloc.add(const WizardStepCompleted(WizardStep.servicos)),
      expect: () => [
        const WizardLoading(),
        isA<WizardLoaded>(),
      ],
    );
  });

  // ─── WizardStepSkipped ───────────────────────────────────────────────────────

  group('WizardStepSkipped', () {
    blocTest<WizardBloc, WizardState>(
      'WizardStepSkipped emits nothing (no state change)',
      build: () => _makeSoloBloc(),
      act: (bloc) => bloc.add(const WizardStepSkipped(WizardStep.servicos)),
      expect: () => [],
    );
  });

  // ─── Error handling ──────────────────────────────────────────────────────────

  group('Error handling', () {
    blocTest<WizardBloc, WizardState>(
      'emits [WizardLoading, WizardError] when hasServices throws',
      build: () => WizardBloc(
        createBusiness: (_) async => 'biz-1',
        hasServices: (_) async => throw Exception('network error'),
        hasProfessionals: (_) async => false,
        isSoloMode: true,
        businessId: 'biz-1',
      ),
      act: (bloc) => bloc.add(const WizardCheckRequested()),
      expect: () => [
        const WizardLoading(),
        const WizardError('Algo deu errado. Tente novamente.'),
      ],
    );

    blocTest<WizardBloc, WizardState>(
      'emits [WizardLoading, WizardError] when hasProfessionals throws (team mode)',
      build: () => WizardBloc(
        createBusiness: (_) async => 'biz-1',
        hasServices: (_) async => true,
        hasProfessionals: (_) async => throw Exception('network error'),
        isSoloMode: false,
        businessId: 'biz-1',
      ),
      act: (bloc) => bloc.add(const WizardCheckRequested()),
      expect: () => [
        const WizardLoading(),
        const WizardError('Algo deu errado. Tente novamente.'),
      ],
    );
  });

  // ─── No-business state (empty businessId) ────────────────────────────────────

  group('WizardCheckRequested — no business', () {
    blocTest<WizardBloc, WizardState>(
      'emits [WizardLoading, WizardLoaded] with only negocios step when businessId is empty',
      build: () => _makeNoBizBloc(),
      act: (bloc) => bloc.add(const WizardCheckRequested()),
      expect: () => [
        const WizardLoading(),
        isA<WizardLoaded>().having(
          (s) => s.steps.keys.toSet(),
          'step keys',
          {WizardStep.negocios},
        ),
      ],
    );

    blocTest<WizardBloc, WizardState>(
      'negocios step is incomplete when businessId is empty',
      build: () => _makeNoBizBloc(),
      act: (bloc) => bloc.add(const WizardCheckRequested()),
      expect: () => [
        const WizardLoading(),
        isA<WizardLoaded>().having(
          (s) => s.steps[WizardStep.negocios]!.isComplete,
          'negocios.isComplete',
          false,
        ),
      ],
    );

    blocTest<WizardBloc, WizardState>(
      'does NOT call hasServices when businessId is empty',
      build: () {
        var called = false;
        return WizardBloc(
          createBusiness: (_) async => 'biz-new',
          hasServices: (_) async {
            called = true;
            return false;
          },
          hasProfessionals: (_) async => false,
          isSoloMode: true,
          businessId: '',
        );
      },
      act: (bloc) => bloc.add(const WizardCheckRequested()),
      verify: (bloc) {
        final state = bloc.state as WizardLoaded;
        expect(state.steps.containsKey(WizardStep.negocios), isTrue);
      },
    );
  });

  // ─── WizardBusinessSubmitted ─────────────────────────────────────────────────

  group('WizardBusinessSubmitted', () {
    blocTest<WizardBloc, WizardState>(
      'calls createBusiness and then emits WizardLoaded with servicos step',
      build: () => _makeNoBizBloc(hasServices: false),
      act: (bloc) =>
          bloc.add(const WizardBusinessSubmitted(name: 'Meu Salão')),
      expect: () => [
        const WizardLoading(),
        isA<WizardLoaded>().having(
          (s) => s.steps.keys.toSet(),
          'step keys',
          {WizardStep.servicos},
        ),
      ],
    );

    blocTest<WizardBloc, WizardState>(
      'emits [WizardLoading, WizardError] when createBusiness throws',
      build: () => _makeNoBizBloc(
        createBusiness: (_) async => throw Exception('server error'),
      ),
      act: (bloc) =>
          bloc.add(const WizardBusinessSubmitted(name: 'Meu Salão')),
      expect: () => [
        const WizardLoading(),
        const WizardError('Algo deu errado. Tente novamente.'),
      ],
    );
  });
}
