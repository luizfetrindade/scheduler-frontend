import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scheduler_frontend/design_system/tokens/app_theme.dart';
import 'package:scheduler_frontend/features/appointments/bloc/schedule_bloc.dart';
import 'package:scheduler_frontend/features/appointments/bloc/schedule_event.dart';
import 'package:scheduler_frontend/features/appointments/bloc/schedule_state.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';
import 'package:scheduler_frontend/features/appointments/presentation/widgets/appointment_detail_sheet.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockScheduleBloc extends MockBloc<ScheduleEvent, ScheduleState>
    implements ScheduleBloc {}

// ── Fixtures ──────────────────────────────────────────────────────────────────

final _pendingAppointment = AppointmentModel(
  id: 'a1',
  clientName: 'Alice',
  serviceName: 'Corte',
  startsAt: DateTime(2026, 3, 20, 9, 0),
  endsAt: DateTime(2026, 3, 20, 9, 30),
  status: AppointmentStatus.pending,
);

final _cancelledAppointment = AppointmentModel(
  id: 'a2',
  clientName: 'Bob',
  serviceName: 'Barba',
  startsAt: DateTime(2026, 3, 20, 10, 0),
  endsAt: DateTime(2026, 3, 20, 10, 30),
  status: AppointmentStatus.cancelled,
);

// ── Test setup ────────────────────────────────────────────────────────────────

void main() {
  late MockScheduleBloc scheduleBloc;

  setUp(() {
    scheduleBloc = MockScheduleBloc();
    when(() => scheduleBloc.state).thenReturn(const ScheduleInitial());
  });

  Widget buildSheet({
    required AppointmentModel appointment,
    required bool canModify,
  }) =>
      MaterialApp(
        theme: AppTheme.light()
            .copyWith(splashFactory: NoSplash.splashFactory),
        home: Scaffold(
          body: BlocProvider<ScheduleBloc>.value(
            value: scheduleBloc,
            child: AppointmentDetailSheet(
              appointment: appointment,
              canModify: canModify,
            ),
          ),
        ),
      );

  group('AppointmentDetailSheet — "Cancelar Agendamento" button visibility', () {
    testWidgets(
        'canModify: true + PENDING → "Cancelar Agendamento" button IS visible',
        (tester) async {
      await tester.pumpWidget(buildSheet(
        appointment: _pendingAppointment,
        canModify: true,
      ));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Cancelar Agendamento'), findsOneWidget);
    });

    testWidgets(
        'canModify: false + PENDING → "Cancelar Agendamento" button NOT visible',
        (tester) async {
      await tester.pumpWidget(buildSheet(
        appointment: _pendingAppointment,
        canModify: false,
      ));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Cancelar Agendamento'), findsNothing);
    });

    testWidgets(
        'canModify: true + CANCELLED → "Cancelar Agendamento" NOT visible (already cancelled)',
        (tester) async {
      await tester.pumpWidget(buildSheet(
        appointment: _cancelledAppointment,
        canModify: true,
      ));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Cancelar Agendamento'), findsNothing);
    });
  });
}
