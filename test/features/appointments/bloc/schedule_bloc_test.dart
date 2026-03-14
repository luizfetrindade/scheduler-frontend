import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_http/flutter_http.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scheduler_frontend/features/appointments/bloc/schedule_bloc.dart';
import 'package:scheduler_frontend/features/appointments/bloc/schedule_event.dart';
import 'package:scheduler_frontend/features/appointments/bloc/schedule_state.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_repository.dart';
import 'package:test/test.dart';

class MockAppointmentRepository extends Mock implements AppointmentRepository {}

AppointmentModel _makeAppointment({
  required String id,
  String? staffId,
  DateTime? startsAt,
}) =>
    AppointmentModel(
      id: id,
      startsAt: startsAt ?? DateTime(2024, 1, 15, 9, 0),
      endsAt: (startsAt ?? DateTime(2024, 1, 15, 9, 0)).add(const Duration(hours: 1)),
      status: AppointmentStatus.confirmed,
      clientName: 'Test Client',
      staffId: staffId,
    );

void main() {
  late MockAppointmentRepository mockRepo;
  final testDate = DateTime(2024, 1, 15);

  setUp(() {
    mockRepo = MockAppointmentRepository();
  });

  group('ScheduleBloc - ScheduleFilterByProfessional', () {
    final apptAlice = _makeAppointment(id: '1', staffId: 'alice');
    final apptBob = _makeAppointment(id: '2', staffId: 'bob');
    final apptNoStaff = _makeAppointment(id: '3', staffId: null);

    final allAppointments = [apptAlice, apptBob, apptNoStaff];
    final dateKey = '2024-01-15';

    test('ScheduleFilterByProfessional props contains professionalId', () {
      const event = ScheduleFilterByProfessional('alice');
      expect(event.props, equals(['alice']));

      const eventNull = ScheduleFilterByProfessional(null);
      expect(eventNull.props, equals([null]));
    });

    blocTest<ScheduleBloc, ScheduleState>(
      'filters appointmentsByDate by staffId when state is ScheduleLoaded',
      build: () {
        when(
          () => mockRepo.getAppointments(slug: any(named: 'slug'), date: any(named: 'date')),
        ).thenAnswer((_) async => Success(allAppointments));
        return ScheduleBloc(mockRepo);
      },
      act: (bloc) async {
        bloc.add(ScheduleInitialized(slug: 'test-slug', date: testDate));
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const ScheduleFilterByProfessional('alice'));
      },
      skip: 2, // skip ScheduleLoading and ScheduleLoaded
      expect: () => [
        isA<ScheduleLoaded>().having(
          (s) => s.appointmentsByDate[dateKey],
          'filtered appointments',
          [apptAlice],
        ).having(
          (s) => s.activeProfessionalFilter,
          'activeProfessionalFilter',
          'alice',
        ).having(
          (s) => s.allAppointmentsByDate[dateKey],
          'allAppointmentsByDate preserved',
          allAppointments,
        ),
      ],
    );

    blocTest<ScheduleBloc, ScheduleState>(
      'restores full list when ScheduleFilterByProfessional(null) is dispatched',
      build: () {
        when(
          () => mockRepo.getAppointments(slug: any(named: 'slug'), date: any(named: 'date')),
        ).thenAnswer((_) async => Success(allAppointments));
        return ScheduleBloc(mockRepo);
      },
      act: (bloc) async {
        bloc.add(ScheduleInitialized(slug: 'test-slug', date: testDate));
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const ScheduleFilterByProfessional('alice'));
        await Future.delayed(const Duration(milliseconds: 10));
        bloc.add(const ScheduleFilterByProfessional(null));
      },
      skip: 3, // skip ScheduleLoading, initial ScheduleLoaded, filtered ScheduleLoaded
      expect: () => [
        isA<ScheduleLoaded>().having(
          (s) => s.appointmentsByDate[dateKey],
          'restored appointments',
          allAppointments,
        ).having(
          (s) => s.activeProfessionalFilter,
          'activeProfessionalFilter cleared',
          null,
        ),
      ],
    );

    // When ScheduleFilterByProfessional is dispatched during loading,
    // the _pendingProfessionalFilter is stored and consumed by _loadDay
    // when the async await resumes — so only 2 states are emitted:
    // ScheduleLoading → ScheduleLoaded(filtered). No intermediate unfiltered state.
    blocTest<ScheduleBloc, ScheduleState>(
      'pending filter stored during loading is applied at load completion (single filtered emit)',
      build: () {
        when(
          () => mockRepo.getAppointments(slug: any(named: 'slug'), date: any(named: 'date')),
        ).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return Success(allAppointments);
        });
        return ScheduleBloc(mockRepo);
      },
      act: (bloc) async {
        bloc.add(ScheduleInitialized(slug: 'test-slug', date: testDate));
        // Dispatch filter during the async load (stored as pending, consumed at load completion)
        await Future.delayed(const Duration(milliseconds: 10));
        bloc.add(const ScheduleFilterByProfessional('bob'));
      },
      wait: const Duration(milliseconds: 200),
      // States: ScheduleLoading, ScheduleLoaded(filtered)
      skip: 1, // skip ScheduleLoading
      expect: () => [
        isA<ScheduleLoaded>().having(
          (s) => s.appointmentsByDate[dateKey],
          'filtered at load — only bob',
          [apptBob],
        ).having(
          (s) => s.activeProfessionalFilter,
          'activeProfessionalFilter is bob',
          'bob',
        ).having(
          (s) => s.allAppointmentsByDate[dateKey],
          'allAppointmentsByDate contains all',
          allAppointments,
        ),
      ],
    );
  });
}
