import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_http/flutter_http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scheduler_frontend/features/services/bloc/services_bloc.dart';
import 'package:scheduler_frontend/features/services/bloc/services_event.dart';
import 'package:scheduler_frontend/features/services/bloc/services_state.dart';
import 'package:scheduler_frontend/features/services/data/service_model.dart';
import 'package:scheduler_frontend/features/services/data/service_repository.dart';

class MockServiceRepository extends Mock implements ServiceRepository {}

final _svc1 = ServiceModel(id: 's1', name: 'Corte', isActive: true);
final _svc2 = ServiceModel(id: 's2', name: 'Barba', isActive: true);

void main() {
  late MockServiceRepository mockRepo;

  setUp(() {
    mockRepo = MockServiceRepository();
  });

  blocTest<ServicesBloc, ServicesState>(
    'emits [Loading, Loaded] on ServicesLoadRequested success',
    build: () {
      when(() => mockRepo.getServices(businessId: any(named: 'businessId')))
          .thenAnswer((_) async => Success([_svc1, _svc2]));
      return ServicesBloc(mockRepo);
    },
    act: (b) => b.add(const ServicesLoadRequested('biz-1')),
    expect: () => [
      const ServicesLoading(),
      ServicesLoaded([_svc1, _svc2]),
    ],
  );

  blocTest<ServicesBloc, ServicesState>(
    'emits [Loading, Error] on ServicesLoadRequested network failure',
    build: () {
      when(() => mockRepo.getServices(businessId: any(named: 'businessId')))
          .thenAnswer((_) async =>
              const HttpFailure(NetworkFailure('no connection')));
      return ServicesBloc(mockRepo);
    },
    act: (b) => b.add(const ServicesLoadRequested('biz-1')),
    expect: () => [
      const ServicesLoading(),
      const ServicesError('Sem conexão com a internet'),
    ],
  );

  blocTest<ServicesBloc, ServicesState>(
    'emits [ActionInProgress, Loaded] on ServiceCreateRequested success — appends to list',
    seed: () => ServicesLoaded([_svc1]),
    build: () {
      when(() => mockRepo.createService(
                businessId: any(named: 'businessId'),
                name: any(named: 'name'),
                description: any(named: 'description'),
                price: any(named: 'price'),
                durationMinutes: any(named: 'durationMinutes'),
              ))
          .thenAnswer((_) async => Success(_svc2));
      return ServicesBloc(mockRepo);
    },
    act: (b) => b.add(const ServiceCreateRequested(
      businessId: 'biz-1',
      name: 'Barba',
    )),
    expect: () => [
      ServicesActionInProgress([_svc1]),
      ServicesLoaded([_svc1, _svc2]),
    ],
  );

  blocTest<ServicesBloc, ServicesState>(
    'emits [ActionInProgress, Loaded] on ServiceDeleteRequested success — removes from list',
    seed: () => ServicesLoaded([_svc1, _svc2]),
    build: () {
      when(() => mockRepo.deleteService(
                businessId: any(named: 'businessId'),
                serviceId: any(named: 'serviceId'),
              ))
          .thenAnswer((_) async => const Success(null));
      return ServicesBloc(mockRepo);
    },
    act: (b) => b.add(const ServiceDeleteRequested(
      businessId: 'biz-1',
      serviceId: 's1',
    )),
    expect: () => [
      ServicesActionInProgress([_svc1, _svc2]),
      ServicesLoaded([_svc2]),
    ],
  );

  blocTest<ServicesBloc, ServicesState>(
    'emits [ActionInProgress, Loaded] on ServiceUpdateRequested — replaces item in list',
    seed: () => ServicesLoaded([_svc1, _svc2]),
    build: () {
      final updated = _svc1.copyWith(isActive: false);
      when(() => mockRepo.updateService(
                businessId: any(named: 'businessId'),
                serviceId: any(named: 'serviceId'),
                name: any(named: 'name'),
                description: any(named: 'description'),
                price: any(named: 'price'),
                durationMinutes: any(named: 'durationMinutes'),
                isActive: any(named: 'isActive'),
              ))
          .thenAnswer((_) async => Success(updated));
      return ServicesBloc(mockRepo);
    },
    act: (b) => b.add(const ServiceUpdateRequested(
      businessId: 'biz-1',
      serviceId: 's1',
      isActive: false,
    )),
    expect: () => [
      ServicesActionInProgress([_svc1, _svc2]),
      predicate<ServicesState>((s) {
        if (s is! ServicesLoaded) return false;
        final s1 = s.services.firstWhere((x) => x.id == 's1');
        return s1.isActive == false && s.services.length == 2;
      }),
    ],
  );

  blocTest<ServicesBloc, ServicesState>(
    'emits [ActionInProgress, Error] on ServiceCreateRequested failure — restores list',
    seed: () => ServicesLoaded([_svc1]),
    build: () {
      when(() => mockRepo.createService(
                businessId: any(named: 'businessId'),
                name: any(named: 'name'),
                description: any(named: 'description'),
                price: any(named: 'price'),
                durationMinutes: any(named: 'durationMinutes'),
              ))
          .thenAnswer((_) async =>
              const HttpFailure(NetworkFailure('no connection')));
      return ServicesBloc(mockRepo);
    },
    act: (b) => b.add(const ServiceCreateRequested(
      businessId: 'biz-1',
      name: 'Barba',
    )),
    expect: () => [
      ServicesActionInProgress([_svc1]),
      ServicesError('Sem conexão com a internet', services: [_svc1]),
    ],
  );
}
