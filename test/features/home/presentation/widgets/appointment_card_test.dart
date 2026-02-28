import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';
import 'package:scheduler_frontend/features/home/presentation/widgets/appointment_card.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

final _pending = AppointmentModel(
  id: 'a1',
  startsAt: DateTime(2026, 2, 28, 9),
  endsAt: DateTime(2026, 2, 28, 9, 30),
  status: AppointmentStatus.pending,
  clientName: 'João Silva',
  serviceName: 'Corte',
);

final _confirmed = AppointmentModel(
  id: 'a2',
  startsAt: DateTime(2026, 2, 28, 10),
  endsAt: DateTime(2026, 2, 28, 10, 30),
  status: AppointmentStatus.confirmed,
  clientName: 'Maria',
  serviceName: 'Barba',
);

void main() {
  testWidgets('shows time, client name, service, and status badge',
      (tester) async {
    await tester.pumpWidget(_wrap(AppointmentCard(
      appointment: _pending,
      onConfirm: null,
      onNoShow: null,
    )));

    expect(find.text('João Silva'), findsOneWidget);
    expect(find.text('Corte'), findsOneWidget);
    expect(find.text('09:00'), findsOneWidget);
    expect(find.text('Pendente'), findsOneWidget);
  });

  testWidgets('shows action buttons when PENDING and callbacks provided',
      (tester) async {
    bool confirmed = false;
    bool noShow = false;

    await tester.pumpWidget(_wrap(AppointmentCard(
      appointment: _pending,
      onConfirm: () => confirmed = true,
      onNoShow: () => noShow = true,
    )));

    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.byIcon(Icons.person_off_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.check));
    expect(confirmed, isTrue);

    await tester.tap(find.byIcon(Icons.person_off_outlined));
    expect(noShow, isTrue);
  });

  testWidgets('hides action buttons when callbacks are null', (tester) async {
    await tester.pumpWidget(_wrap(AppointmentCard(
      appointment: _pending,
      onConfirm: null,
      onNoShow: null,
    )));

    expect(find.byIcon(Icons.check), findsNothing);
    expect(find.byIcon(Icons.person_off_outlined), findsNothing);
  });

  testWidgets('hides action buttons when status is CONFIRMED', (tester) async {
    await tester.pumpWidget(_wrap(AppointmentCard(
      appointment: _confirmed,
      onConfirm: () {},
      onNoShow: () {},
    )));

    // showActions = false because status != pending
    expect(find.byIcon(Icons.check), findsNothing);
  });
}
