import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scheduler_frontend/features/appointments/bloc/schedule_bloc.dart';
import 'package:scheduler_frontend/features/appointments/bloc/schedule_event.dart';
import 'package:scheduler_frontend/features/appointments/bloc/schedule_state.dart';
import 'package:scheduler_frontend/features/professionals/data/professional_model.dart';
import 'package:scheduler_frontend/features/professionals/presentation/widgets/professional_filter_chips.dart';

class MockScheduleBloc extends MockBloc<ScheduleEvent, ScheduleState> implements ScheduleBloc {}

void main() {
  setUpAll(() {
    registerFallbackValue(const ScheduleFilterByProfessional(null));
  });

  final professionals = [
    ProfessionalModel(id: 'p1', businessId: 'b1', name: 'Ana', color: '#4A90E2', isActive: true),
    ProfessionalModel(id: 'p2', businessId: 'b1', name: 'Carlos', color: '#FF5733', isActive: true),
  ];

  Widget buildChips(MockScheduleBloc scheduleBloc) => MaterialApp(
        home: Scaffold(
          body: BlocProvider<ScheduleBloc>.value(
            value: scheduleBloc,
            child: ProfessionalFilterChips(professionals: professionals),
          ),
        ),
      );

  testWidgets('renders Todos chip and one chip per professional', (tester) async {
    final bloc = MockScheduleBloc();
    when(() => bloc.state).thenReturn(const ScheduleInitial());
    await tester.pumpWidget(buildChips(bloc));
    await tester.pump();
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Carlos'), findsOneWidget);
  });

  testWidgets('tapping a professional chip dispatches ScheduleFilterByProfessional with id', (tester) async {
    final bloc = MockScheduleBloc();
    when(() => bloc.state).thenReturn(const ScheduleInitial());
    await tester.pumpWidget(buildChips(bloc));
    await tester.pump();
    await tester.tap(find.text('Ana'));
    await tester.pump();
    verify(() => bloc.add(const ScheduleFilterByProfessional('p1'))).called(1);
  });

  testWidgets('tapping Todos dispatches ScheduleFilterByProfessional with null', (tester) async {
    final bloc = MockScheduleBloc();
    when(() => bloc.state).thenReturn(const ScheduleInitial());
    await tester.pumpWidget(buildChips(bloc));
    await tester.pump();
    await tester.tap(find.text('Todos'));
    await tester.pump();
    verify(() => bloc.add(const ScheduleFilterByProfessional(null))).called(1);
  });
}
