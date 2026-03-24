import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scheduler_frontend/design_system/tokens/app_theme.dart';
import 'package:scheduler_frontend/features/reports/bloc/reports_bloc.dart';
import 'package:scheduler_frontend/features/reports/bloc/reports_event.dart';
import 'package:scheduler_frontend/features/reports/bloc/reports_state.dart';
import 'package:scheduler_frontend/features/reports/data/reports_model.dart';
import 'package:scheduler_frontend/features/reports/presentation/reports_page.dart';

class MockReportsBloc extends MockBloc<ReportsEvent, ReportsState>
    implements ReportsBloc {}

void main() {
  late MockReportsBloc mockBloc;

  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });

  setUp(() {
    mockBloc = MockReportsBloc();
  });

  Widget buildPage() => MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: BlocProvider<ReportsBloc>.value(
          value: mockBloc,
          child: const ReportsView(slug: 'my-salon'),
        ),
      );

  testWidgets('shows TabBar with 5 tabs when ReportsLoaded',
      (tester) async {
    when(() => mockBloc.state)
        .thenReturn(ReportsLoaded(_fakeModel(), ReportPeriod.monthly));
    await tester.pumpWidget(buildPage());
    await tester.pump();
    expect(find.text('Geral'), findsOneWidget);
    expect(find.text('Financeiro'), findsOneWidget);
    expect(find.text('Clientes'), findsOneWidget);
    expect(find.byType(TabBar), findsOneWidget);
  });

  testWidgets('shows CircularProgressIndicator during loading, no TabBar',
      (tester) async {
    when(() => mockBloc.state).thenReturn(const ReportsLoading());
    await tester.pumpWidget(buildPage());
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(TabBar), findsNothing);
  });

  testWidgets('shows SnackBar on ReportsError', (tester) async {
    whenListen(
      mockBloc,
      Stream.fromIterable([
        const ReportsLoading(),
        ReportsError('Erro ao carregar relatórios', ReportPeriod.monthly),
      ]),
      initialState: const ReportsLoading(),
    );
    await tester.pumpWidget(buildPage());
    await tester.pump();
    await tester.pump();
    expect(find.text('Erro ao carregar relatórios'), findsOneWidget);
  });
}

ReportsModel _fakeModel() => ReportsModel.fromJson({
      'period': 'monthly',
      'from': '2026-03-01',
      'to': '2026-03-31',
      'previousFrom': '2026-02-01',
      'previousTo': '2026-02-28',
      'appointments': {
        'total': 0,
        'previousTotal': 0,
        'byStatus': <String, dynamic>{},
        'cancellationRate': 0.0,
        'previousCancellationRate': 0.0,
        'noShowRate': 0.0,
        'previousNoShowRate': 0.0,
        'dailySeries': <dynamic>[],
        'byDayOfWeek': <dynamic>[],
      },
      'revenue': {
        'confirmed': 0.0,
        'previousConfirmed': 0.0,
        'realized': 0.0,
        'previousRealized': 0.0,
        'lost': 0.0,
        'previousLost': 0.0,
        'averageTicket': 0.0,
        'previousAverageTicket': 0.0,
        'revenueDailySeries': <dynamic>[],
        'topServices': <dynamic>[],
      },
      'occupancy': {
        'totalSlotsAvailable': 0,
        'totalBooked': 0,
        'occupancyRate': 0.0,
        'previousOccupancyRate': 0.0,
        'peakHours': <dynamic>[],
      },
      'clients': {
        'total': 0,
        'newClients': 0,
        'previousNewClients': 0,
        'returningClients': 0,
        'returnRate': 0.0,
        'previousReturnRate': 0.0,
        'averageFrequencyDays': 0,
        'averageTicketPerClient': 0.0,
        'previousAverageTicketPerClient': 0.0,
        'atRisk': <dynamic>[],
      },
      'staff': <dynamic>[],
    });
