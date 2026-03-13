import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_http/flutter_http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';
import 'package:scheduler_frontend/features/clients/bloc/clients_bloc.dart';
import 'package:scheduler_frontend/features/clients/bloc/clients_event.dart';
import 'package:scheduler_frontend/features/clients/bloc/clients_state.dart';
import 'package:scheduler_frontend/features/clients/data/client_model.dart';
import 'package:scheduler_frontend/features/clients/data/client_repository.dart';

class MockClientRepository extends Mock implements ClientRepository {}

final _c1 = const ClientModel(id: 'c1', name: 'Ana', phone: '11111111111');
final _c2 = const ClientModel(id: 'c2', name: 'Bob', phone: '22222222222');
final _histItem = ClientHistoryItem(
  id: 'a1',
  startsAt: DateTime(2026, 3, 1),
  endsAt: DateTime(2026, 3, 1, 1),
  status: AppointmentStatus.confirmed,
);

void main() {
  late MockClientRepository mockRepo;

  setUp(() {
    mockRepo = MockClientRepository();
  });

  // ── Load ─────────────────────────────────────────────────────────────────

  blocTest<ClientsBloc, ClientsState>(
    'emits [Loading, Loaded] on ClientsLoadRequested success',
    build: () {
      when(() => mockRepo.getClients(businessId: any(named: 'businessId')))
          .thenAnswer((_) async => Success([_c1, _c2]));
      return ClientsBloc(mockRepo);
    },
    act: (b) => b.add(const ClientsLoadRequested('biz-1')),
    expect: () => [
      const ClientsLoading(),
      ClientsLoaded([_c1, _c2]),
    ],
  );

  blocTest<ClientsBloc, ClientsState>(
    'emits [Loading, Error] on ClientsLoadRequested network failure',
    build: () {
      when(() => mockRepo.getClients(businessId: any(named: 'businessId')))
          .thenAnswer((_) async => const HttpFailure(NetworkFailure('no connection')));
      return ClientsBloc(mockRepo);
    },
    act: (b) => b.add(const ClientsLoadRequested('biz-1')),
    expect: () => [
      const ClientsLoading(),
      const ClientsError('Sem conexão com a internet'),
    ],
  );

  // ── Create ───────────────────────────────────────────────────────────────

  blocTest<ClientsBloc, ClientsState>(
    'emits [ActionInProgress, Loaded] on ClientCreateRequested success — appends to list and preserves history',
    seed: () => ClientsLoaded([_c1], history: {'c1': [_histItem]}),
    build: () {
      when(() => mockRepo.createClient(
                businessId: any(named: 'businessId'),
                name: any(named: 'name'),
                phone: any(named: 'phone'),
                email: any(named: 'email'),
              ))
          .thenAnswer((_) async => Success(_c2));
      return ClientsBloc(mockRepo);
    },
    act: (b) => b.add(const ClientCreateRequested(
      businessId: 'biz-1',
      name: 'Bob',
      phone: '22222222222',
    )),
    expect: () => [
      ClientsActionInProgress([_c1], history: {'c1': [_histItem]}),
      predicate<ClientsState>((s) {
        if (s is! ClientsLoaded) return false;
        // History cache must be preserved after create
        return s.clients.length == 2 && s.history.containsKey('c1');
      }),
    ],
  );

  blocTest<ClientsBloc, ClientsState>(
    'emits [ActionInProgress, Error] on ClientCreateRequested failure — restores list',
    seed: () => ClientsLoaded([_c1]),
    build: () {
      when(() => mockRepo.createClient(
                businessId: any(named: 'businessId'),
                name: any(named: 'name'),
                phone: any(named: 'phone'),
                email: any(named: 'email'),
              ))
          .thenAnswer((_) async => const HttpFailure(NetworkFailure('no connection')));
      return ClientsBloc(mockRepo);
    },
    act: (b) => b.add(const ClientCreateRequested(
      businessId: 'biz-1',
      name: 'Bob',
      phone: '22222222222',
    )),
    expect: () => [
      ClientsActionInProgress([_c1]),
      ClientsError('Sem conexão com a internet', clients: [_c1]),
    ],
  );

  // ── Update ───────────────────────────────────────────────────────────────

  blocTest<ClientsBloc, ClientsState>(
    'emits [ActionInProgress, Loaded] on ClientUpdateRequested — replaces item',
    seed: () => ClientsLoaded([_c1, _c2]),
    build: () {
      final updated = _c1.copyWith(name: 'Ana Updated');
      when(() => mockRepo.updateClient(
                businessId: any(named: 'businessId'),
                clientId: any(named: 'clientId'),
                name: any(named: 'name'),
                phone: any(named: 'phone'),
                email: any(named: 'email'),
              ))
          .thenAnswer((_) async => Success(updated));
      return ClientsBloc(mockRepo);
    },
    act: (b) => b.add(const ClientUpdateRequested(
      businessId: 'biz-1',
      clientId: 'c1',
      name: 'Ana Updated',
      phone: '11111111111',
    )),
    expect: () => [
      ClientsActionInProgress([_c1, _c2]),
      predicate<ClientsState>((s) {
        if (s is! ClientsLoaded) return false;
        final c1 = s.clients.firstWhere((x) => x.id == 'c1');
        return c1.name == 'Ana Updated' && s.clients.length == 2;
      }),
    ],
  );

  // ── Delete ───────────────────────────────────────────────────────────────

  blocTest<ClientsBloc, ClientsState>(
    'emits [ActionInProgress, Loaded] on ClientDeleteRequested — removes from list',
    seed: () => ClientsLoaded([_c1, _c2]),
    build: () {
      when(() => mockRepo.deleteClient(
                businessId: any(named: 'businessId'),
                clientId: any(named: 'clientId'),
              ))
          .thenAnswer((_) async => const Success(null));
      return ClientsBloc(mockRepo);
    },
    act: (b) => b.add(const ClientDeleteRequested(
      businessId: 'biz-1',
      clientId: 'c1',
    )),
    expect: () => [
      ClientsActionInProgress([_c1, _c2]),
      ClientsLoaded([_c2]),
    ],
  );

  blocTest<ClientsBloc, ClientsState>(
    'emits [ActionInProgress, Error] on ClientDeleteRequested failure — restores list',
    seed: () => ClientsLoaded([_c1, _c2]),
    build: () {
      when(() => mockRepo.deleteClient(
                businessId: any(named: 'businessId'),
                clientId: any(named: 'clientId'),
              ))
          .thenAnswer((_) async => const HttpFailure(NetworkFailure('no connection')));
      return ClientsBloc(mockRepo);
    },
    act: (b) => b.add(const ClientDeleteRequested(
      businessId: 'biz-1',
      clientId: 'c1',
    )),
    expect: () => [
      ClientsActionInProgress([_c1, _c2]),
      ClientsError('Sem conexão com a internet', clients: [_c1, _c2]),
    ],
  );

  // ── History ──────────────────────────────────────────────────────────────

  blocTest<ClientsBloc, ClientsState>(
    'emits Loaded with history merged when ClientHistoryLoadRequested — first load',
    seed: () => ClientsLoaded([_c1, _c2]),
    build: () {
      when(() => mockRepo.getClientHistory(
                businessId: any(named: 'businessId'),
                clientId: any(named: 'clientId'),
              ))
          .thenAnswer((_) async => Success([_histItem]));
      return ClientsBloc(mockRepo);
    },
    act: (b) => b.add(const ClientHistoryLoadRequested(
      businessId: 'biz-1',
      clientId: 'c1',
    )),
    expect: () => [
      predicate<ClientsState>((s) {
        if (s is! ClientsLoaded) return false;
        return s.history.containsKey('c1') &&
            s.history['c1']!.length == 1;
      }),
    ],
  );

  blocTest<ClientsBloc, ClientsState>(
    'does NOT fetch history when clientId already cached',
    seed: () => ClientsLoaded([_c1], history: {'c1': [_histItem]}),
    build: () => ClientsBloc(mockRepo),
    act: (b) => b.add(const ClientHistoryLoadRequested(
      businessId: 'biz-1',
      clientId: 'c1',
    )),
    expect: () => [], // no state change
    verify: (_) => verifyNever(() => mockRepo.getClientHistory(
          businessId: any(named: 'businessId'),
          clientId: any(named: 'clientId'),
        )),
  );

  blocTest<ClientsBloc, ClientsState>(
    'caches empty history list and does not re-fetch',
    seed: () => ClientsLoaded([_c1]),
    build: () {
      when(() => mockRepo.getClientHistory(
                businessId: any(named: 'businessId'),
                clientId: any(named: 'clientId'),
              ))
          .thenAnswer((_) async => const Success([]));
      return ClientsBloc(mockRepo);
    },
    act: (b) async {
      b.add(const ClientHistoryLoadRequested(businessId: 'biz-1', clientId: 'c1'));
      await Future<void>.delayed(Duration.zero);
      b.add(const ClientHistoryLoadRequested(businessId: 'biz-1', clientId: 'c1'));
    },
    verify: (_) => verify(() => mockRepo.getClientHistory(
          businessId: any(named: 'businessId'),
          clientId: any(named: 'clientId'),
        )).called(1), // fetched only once
  );
}
