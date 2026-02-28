import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_http/flutter_http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scheduler_frontend/features/appointments/bloc/appointments_bloc.dart';
import 'package:scheduler_frontend/features/appointments/bloc/appointments_event.dart';
import 'package:scheduler_frontend/features/appointments/bloc/appointments_state.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_repository.dart';

class MockAppointmentRepository extends Mock implements AppointmentRepository {}

final _date = DateTime(2026, 2, 28);

// Appointments out of chronological order — bloc must sort by startsAt
final _appt1 = AppointmentModel(
  id: 'a1',
  clientName: 'Alice',
  serviceName: 'Corte',
  startsAt: DateTime(2026, 2, 28, 9, 0),
  endsAt: DateTime(2026, 2, 28, 9, 30),
  status: AppointmentStatus.pending,
);

final _appt2 = AppointmentModel(
  id: 'a2',
  clientName: 'Bob',
  serviceName: 'Barba',
  startsAt: DateTime(2026, 2, 28, 10, 0),
  endsAt: DateTime(2026, 2, 28, 10, 20),
  status: AppointmentStatus.confirmed,
);

void main() {
  late MockAppointmentRepository mockRepo;

  setUp(() {
    mockRepo = MockAppointmentRepository();
    registerFallbackValue(AppointmentStatus.confirmed);
  });

  blocTest<AppointmentsBloc, AppointmentsState>(
    'emits [Loading, Loaded] on success — sorted by startsAt',
    build: () {
      when(() => mockRepo.getAppointments(
                slug: any(named: 'slug'),
                date: any(named: 'date'),
              ))
          .thenAnswer((_) async => Success([_appt2, _appt1])); // reversed on purpose
      return AppointmentsBloc(mockRepo);
    },
    act: (bloc) => bloc.add(AppointmentsLoadRequested(slug: 'salao-a', date: _date)),
    expect: () => [
      const AppointmentsLoading(),
      AppointmentsLoaded([_appt1, _appt2]), // sorted
    ],
  );

  blocTest<AppointmentsBloc, AppointmentsState>(
    'emits [Loading, Loaded] with empty list',
    build: () {
      when(() => mockRepo.getAppointments(
                slug: any(named: 'slug'),
                date: any(named: 'date'),
              ))
          .thenAnswer((_) async => const Success([]));
      return AppointmentsBloc(mockRepo);
    },
    act: (bloc) => bloc.add(AppointmentsLoadRequested(slug: 'salao-a', date: _date)),
    expect: () => [
      const AppointmentsLoading(),
      const AppointmentsLoaded([]),
    ],
  );

  blocTest<AppointmentsBloc, AppointmentsState>(
    'emits [Loading, Error] on network failure',
    build: () {
      when(() => mockRepo.getAppointments(
                slug: any(named: 'slug'),
                date: any(named: 'date'),
              ))
          .thenAnswer((_) async => const HttpFailure(NetworkFailure('no internet')));
      return AppointmentsBloc(mockRepo);
    },
    act: (bloc) => bloc.add(AppointmentsLoadRequested(slug: 'salao-a', date: _date)),
    expect: () => [
      const AppointmentsLoading(),
      const AppointmentsError('Sem conexão com a internet'),
    ],
  );

  blocTest<AppointmentsBloc, AppointmentsState>(
    'emits [Loading, Error] on generic failure',
    build: () {
      when(() => mockRepo.getAppointments(
                slug: any(named: 'slug'),
                date: any(named: 'date'),
              ))
          .thenAnswer((_) async => const HttpFailure(ServerFailure('Internal', statusCode: 500)));
      return AppointmentsBloc(mockRepo);
    },
    act: (bloc) => bloc.add(AppointmentsLoadRequested(slug: 'salao-a', date: _date)),
    expect: () => [
      const AppointmentsLoading(),
      const AppointmentsError('Não foi possível carregar os agendamentos'),
    ],
  );

  blocTest<AppointmentsBloc, AppointmentsState>(
    'optimistically updates status and keeps it on success',
    build: () {
      when(() => mockRepo.updateStatus(
                slug: any(named: 'slug'),
                appointmentId: any(named: 'appointmentId'),
                status: any(named: 'status'),
              ))
          .thenAnswer((_) async => const Success({'status': 'CONFIRMED'}));
      return AppointmentsBloc(mockRepo);
    },
    seed: () => AppointmentsLoaded([_appt1, _appt2]),
    act: (bloc) => bloc.add(const AppointmentStatusChanged(
      slug: 'salao-a',
      appointmentId: 'a1',
      status: AppointmentStatus.confirmed,
    )),
    expect: () => [
      AppointmentsLoaded([
        _appt1.copyWith(status: AppointmentStatus.confirmed),
        _appt2,
      ]),
    ],
  );

  blocTest<AppointmentsBloc, AppointmentsState>(
    'rolls back optimistic update on failure',
    build: () {
      when(() => mockRepo.updateStatus(
                slug: any(named: 'slug'),
                appointmentId: any(named: 'appointmentId'),
                status: any(named: 'status'),
              ))
          .thenAnswer((_) async => const HttpFailure(NetworkFailure('no internet')));
      return AppointmentsBloc(mockRepo);
    },
    seed: () => AppointmentsLoaded([_appt1, _appt2]),
    act: (bloc) => bloc.add(const AppointmentStatusChanged(
      slug: 'salao-a',
      appointmentId: 'a1',
      status: AppointmentStatus.confirmed,
    )),
    expect: () => [
      // optimistic update
      AppointmentsLoaded([
        _appt1.copyWith(status: AppointmentStatus.confirmed),
        _appt2,
      ]),
      // rollback to original
      AppointmentsLoaded([_appt1, _appt2]),
    ],
  );

  blocTest<AppointmentsBloc, AppointmentsState>(
    'ignores AppointmentStatusChanged when state is not Loaded',
    build: () => AppointmentsBloc(mockRepo),
    act: (bloc) => bloc.add(const AppointmentStatusChanged(
      slug: 'salao-a',
      appointmentId: 'a1',
      status: AppointmentStatus.confirmed,
    )),
    expect: () => [],
  );
}
