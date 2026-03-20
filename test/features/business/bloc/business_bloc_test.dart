import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_http/flutter_http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scheduler_frontend/core/policy/app_policy.dart';
import 'package:scheduler_frontend/features/business/bloc/business_bloc.dart';
import 'package:scheduler_frontend/features/business/bloc/business_event.dart';
import 'package:scheduler_frontend/features/business/bloc/business_state.dart';
import 'package:scheduler_frontend/features/business/data/business_model.dart';
import 'package:scheduler_frontend/features/business/data/business_repository.dart';

class MockBusinessRepository extends Mock implements BusinessRepository {}

const _biz1 = BusinessModel(
    id: '1', slug: 'salao-a', name: 'Salão A', logo: null, timezone: 'UTC');
const _biz2 = BusinessModel(
    id: '2', slug: 'salao-b', name: 'Salão B', logo: null, timezone: 'UTC');
const _bizOwnerMulti = BusinessModel(
    id: '3',
    slug: 'salao-c',
    name: 'Salão C',
    logo: null,
    timezone: 'UTC',
    myStaffRole: StaffRole.owner,
    planMaxStaff: 5);

void main() {
  late MockBusinessRepository mockRepo;

  setUp(() => mockRepo = MockBusinessRepository());

  blocTest<BusinessBloc, BusinessState>(
    'LoadRequested calls getBusinessesMine and derives AppPolicy',
    build: () {
      when(() => mockRepo.getBusinessesMine())
          .thenAnswer((_) async => const Success([_bizOwnerMulti]));
      return BusinessBloc(mockRepo);
    },
    act: (bloc) => bloc.add(const BusinessLoadRequested()),
    expect: () => [
      isA<BusinessLoading>(),
      isA<BusinessLoaded>()
          .having((s) => s.policy.isSoloMode, 'isSoloMode', isFalse),
    ],
  );

  blocTest<BusinessBloc, BusinessState>(
    'emits [Loading, Loaded] on success — first business is active',
    build: () {
      when(() => mockRepo.getBusinessesMine())
          .thenAnswer((_) async => const Success([_biz1, _biz2]));
      return BusinessBloc(mockRepo);
    },
    act: (bloc) => bloc.add(const BusinessLoadRequested()),
    expect: () => [
      isA<BusinessLoading>(),
      isA<BusinessLoaded>()
          .having((s) => s.businesses, 'businesses', [_biz1, _biz2])
          .having((s) => s.active, 'active', _biz1),
    ],
  );

  blocTest<BusinessBloc, BusinessState>(
    'emits [Loading, Error] when list is empty',
    build: () {
      when(() => mockRepo.getBusinessesMine())
          .thenAnswer((_) async => const Success([]));
      return BusinessBloc(mockRepo);
    },
    act: (bloc) => bloc.add(const BusinessLoadRequested()),
    expect: () => [
      const BusinessLoading(),
      const BusinessError('Nenhum negócio encontrado'),
    ],
  );

  blocTest<BusinessBloc, BusinessState>(
    'emits [Loading, Error] on network failure',
    build: () {
      when(() => mockRepo.getBusinessesMine()).thenAnswer(
          (_) async => const HttpFailure(NetworkFailure('no internet')));
      return BusinessBloc(mockRepo);
    },
    act: (bloc) => bloc.add(const BusinessLoadRequested()),
    expect: () => [
      const BusinessLoading(),
      const BusinessError('Sem conexão com a internet'),
    ],
  );

  blocTest<BusinessBloc, BusinessState>(
    'updates active business on BusinessSelected',
    build: () => BusinessBloc(mockRepo),
    seed: () => BusinessLoaded(
      businesses: const [_biz1, _biz2],
      active: _biz1,
      policy: AppPolicy.from(_biz1.myStaffRole, _biz1.planMaxStaff),
    ),
    act: (bloc) => bloc.add(const BusinessSelected(_biz2)),
    expect: () => [
      isA<BusinessLoaded>()
          .having((s) => s.businesses, 'businesses', [_biz1, _biz2])
          .having((s) => s.active, 'active', _biz2),
    ],
  );
}
