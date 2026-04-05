import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scheduler_frontend/core/policy/app_policy.dart';
import 'package:scheduler_frontend/design_system/tokens/app_theme.dart';
import 'package:scheduler_frontend/features/appointments/bloc/appointments_bloc.dart';
import 'package:scheduler_frontend/features/appointments/bloc/appointments_event.dart';
import 'package:scheduler_frontend/features/appointments/bloc/appointments_state.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_repository.dart';
import 'package:scheduler_frontend/features/business/bloc/business_bloc.dart';
import 'package:scheduler_frontend/features/business/bloc/business_event.dart';
import 'package:scheduler_frontend/features/business/bloc/business_state.dart';
import 'package:scheduler_frontend/features/business/data/business_model.dart';
import 'package:scheduler_frontend/features/home/presentation/widgets/personal_appointments_list.dart';
import 'package:scheduler_frontend/features/home/presentation/widgets/team_appointments_list.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professionals_bloc.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professionals_event.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professionals_state.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockBusinessBloc extends MockBloc<BusinessEvent, BusinessState>
    implements BusinessBloc {}

class MockAppointmentsBloc
    extends MockBloc<AppointmentsEvent, AppointmentsState>
    implements AppointmentsBloc {}

class MockProfessionalsBloc
    extends MockBloc<ProfessionalsEvent, ProfessionalsState>
    implements ProfessionalsBloc {}

class MockAppointmentRepository extends Mock implements AppointmentRepository {}

// ── Helpers ───────────────────────────────────────────────────────────────────

final _business = BusinessModel(
  id: 'b1',
  slug: 'my-biz',
  name: 'My Biz',
  logo: null,
  timezone: 'America/Sao_Paulo',
  myStaffRole: StaffRole.owner,
  planMaxStaff: 5,
);

BusinessLoaded _loadedState({required bool canViewOtherAppts}) {
  final role = canViewOtherAppts ? StaffRole.owner : StaffRole.member;
  final maxStaff = canViewOtherAppts ? 5 : 1;
  return BusinessLoaded(
    businesses: [_business],
    active: _business,
    policy: AppPolicy.from(role, maxStaff),
  );
}

/// Minimal widget that reproduces the _buildAppointmentList logic from HomePage.
Widget _buildSubject({
  required MockBusinessBloc businessBloc,
  required MockAppointmentsBloc appointmentsBloc,
  required MockProfessionalsBloc professionalsBloc,
  required MockAppointmentRepository appointmentRepo,
}) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: MultiBlocProvider(
        providers: [
          BlocProvider<BusinessBloc>.value(value: businessBloc),
          BlocProvider<AppointmentsBloc>.value(value: appointmentsBloc),
          BlocProvider<ProfessionalsBloc>.value(value: professionalsBloc),
          RepositoryProvider<AppointmentRepository>.value(
            value: appointmentRepo,
          ),
        ],
        child: BlocBuilder<BusinessBloc, BusinessState>(
          builder: (context, businessState) {
            if (businessState is! BusinessLoaded) {
              return const SizedBox.shrink();
            }
            return businessState.policy.canViewOtherAppts
                ? const TeamAppointmentsList()
                : const PersonalAppointmentsList();
          },
        ),
      ),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    registerFallbackValue(
      AppointmentsLoadRequested(slug: 'slug', date: DateTime.now()),
    );
  });

  late MockBusinessBloc businessBloc;
  late MockAppointmentsBloc appointmentsBloc;
  late MockProfessionalsBloc professionalsBloc;
  late MockAppointmentRepository appointmentRepo;

  setUp(() {
    businessBloc = MockBusinessBloc();
    appointmentsBloc = MockAppointmentsBloc();
    professionalsBloc = MockProfessionalsBloc();
    appointmentRepo = MockAppointmentRepository();

    when(() => appointmentsBloc.state)
        .thenReturn(const AppointmentsInitial());
    when(() => professionalsBloc.state)
        .thenReturn(const ProfessionalsInitial());
  });

  Widget buildWidget() => _buildSubject(
        businessBloc: businessBloc,
        appointmentsBloc: appointmentsBloc,
        professionalsBloc: professionalsBloc,
        appointmentRepo: appointmentRepo,
      );

  group('_buildAppointmentList persona selection', () {
    testWidgets(
        'renders TeamAppointmentsList when canViewOtherAppts is true',
        (tester) async {
      when(() => businessBloc.state)
          .thenReturn(_loadedState(canViewOtherAppts: true));

      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(TeamAppointmentsList), findsOneWidget);
      expect(find.byType(PersonalAppointmentsList), findsNothing);
    });

    testWidgets(
        'renders PersonalAppointmentsList when canViewOtherAppts is false',
        (tester) async {
      when(() => businessBloc.state)
          .thenReturn(_loadedState(canViewOtherAppts: false));

      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(PersonalAppointmentsList), findsOneWidget);
      expect(find.byType(TeamAppointmentsList), findsNothing);
    });

    testWidgets(
        'renders nothing when BusinessState is not BusinessLoaded',
        (tester) async {
      when(() => businessBloc.state).thenReturn(const BusinessLoading());

      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(TeamAppointmentsList), findsNothing);
      expect(find.byType(PersonalAppointmentsList), findsNothing);
    });
  });

  group('PersonalAppointmentsList', () {
    Widget buildPersonal() => MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider<BusinessBloc>.value(value: businessBloc),
                BlocProvider<AppointmentsBloc>.value(value: appointmentsBloc),
              ],
              child: const PersonalAppointmentsList(),
            ),
          ),
        );

    testWidgets('shows loading indicator when AppointmentsLoading',
        (tester) async {
      when(() => businessBloc.state)
          .thenReturn(_loadedState(canViewOtherAppts: false));
      when(() => appointmentsBloc.state)
          .thenReturn(const AppointmentsLoading());

      await tester.pumpWidget(buildPersonal());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when appointments list is empty',
        (tester) async {
      when(() => businessBloc.state)
          .thenReturn(_loadedState(canViewOtherAppts: false));
      when(() => appointmentsBloc.state)
          .thenReturn(const AppointmentsLoaded([]));

      await tester.pumpWidget(buildPersonal());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Sem agendamentos hoje'), findsOneWidget);
    });

    testWidgets('shows error message on AppointmentsError', (tester) async {
      when(() => businessBloc.state)
          .thenReturn(_loadedState(canViewOtherAppts: false));
      when(() => appointmentsBloc.state)
          .thenReturn(const AppointmentsError('Erro ao carregar'));

      await tester.pumpWidget(buildPersonal());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Erro ao carregar'), findsOneWidget);
    });

    testWidgets('shows appointment cards when appointments loaded',
        (tester) async {
      final appt = AppointmentModel(
        id: 'a1',
        startsAt: DateTime(2026, 3, 20, 9),
        endsAt: DateTime(2026, 3, 20, 9, 30),
        status: AppointmentStatus.pending,
        clientName: 'Ana Lima',
        serviceName: 'Corte',
      );
      when(() => businessBloc.state)
          .thenReturn(_loadedState(canViewOtherAppts: false));
      when(() => appointmentsBloc.state)
          .thenReturn(AppointmentsLoaded([appt]));

      await tester.pumpWidget(buildPersonal());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Ana Lima'), findsOneWidget);
    });
  });
}
