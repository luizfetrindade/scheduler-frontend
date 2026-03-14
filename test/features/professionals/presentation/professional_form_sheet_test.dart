import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_bloc.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_event.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_state.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professionals_bloc.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professionals_event.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professionals_state.dart';
import 'package:scheduler_frontend/design_system/tokens/app_theme.dart';
import 'package:scheduler_frontend/features/professionals/data/professional_model.dart';
import 'package:scheduler_frontend/features/professionals/presentation/widgets/professional_form_sheet.dart';

class MockProfessionalsBloc
    extends MockBloc<ProfessionalsEvent, ProfessionalsState>
    implements ProfessionalsBloc {}

class MockProfessionalRolesBloc
    extends MockBloc<ProfessionalRolesEvent, ProfessionalRolesState>
    implements ProfessionalRolesBloc {}

void main() {
  late MockProfessionalsBloc profsBloc;
  late MockProfessionalRolesBloc rolesBloc;

  setUpAll(() {
    registerFallbackValue(const ProfessionalsCreateRequested(
      businessId: 'b1',
      name: 'Test',
    ));
    registerFallbackValue(const ProfessionalsUpdateRequested(
      businessId: 'b1',
      professionalId: 'p1',
    ));
  });

  setUp(() {
    profsBloc = MockProfessionalsBloc();
    rolesBloc = MockProfessionalRolesBloc();
    when(() => profsBloc.state).thenReturn(const ProfessionalsInitial());
    when(() => rolesBloc.state).thenReturn(const ProfessionalRolesInitial());
  });

  Widget buildSheet({ProfessionalModel? professional}) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider<ProfessionalsBloc>.value(value: profsBloc),
              BlocProvider<ProfessionalRolesBloc>.value(value: rolesBloc),
            ],
            child: ProfessionalFormSheet(professional: professional),
          ),
        ),
      );

  testWidgets('renders form fields in create mode', (tester) async {
    await tester.pumpWidget(buildSheet());
    await tester.pump();
    expect(find.byType(TextFormField), findsWidgets);
    expect(find.byType(ProfessionalFormSheet), findsOneWidget);
  });

  testWidgets('shows Novo Profissional title in create mode', (tester) async {
    await tester.pumpWidget(buildSheet());
    await tester.pump();
    expect(find.text('Novo Profissional'), findsOneWidget);
  });

  testWidgets('shows Editar Profissional title in edit mode', (tester) async {
    final prof = ProfessionalModel(
      id: 'p1',
      businessId: 'b1',
      name: 'Ana',
      color: '#4A90E2',
      isActive: true,
    );
    await tester.pumpWidget(buildSheet(professional: prof));
    await tester.pump();
    expect(find.text('Editar Profissional'), findsOneWidget);
  });

  testWidgets('pre-fills name field in edit mode', (tester) async {
    final prof = ProfessionalModel(
      id: 'p1',
      businessId: 'b1',
      name: 'Ana Silva',
      color: '#4A90E2',
      isActive: true,
    );
    await tester.pumpWidget(buildSheet(professional: prof));
    await tester.pump();
    expect(find.text('Ana Silva'), findsOneWidget);
  });

  testWidgets('submit with empty name shows validation error', (tester) async {
    await tester.pumpWidget(buildSheet());
    await tester.pump();

    final btn = find.byType(ElevatedButton);
    await tester.tap(btn);
    await tester.pump();

    expect(find.text('Nome é obrigatório'), findsOneWidget);
    verifyNever(() => profsBloc.add(any()));
  });

  testWidgets('sheet stays open on ProfessionalsError', (tester) async {
    final errorStream = Stream<ProfessionalsState>.fromIterable([
      const ProfessionalsError('Erro de rede'),
    ]);
    when(() => profsBloc.stream).thenAnswer((_) => errorStream);

    await tester.pumpWidget(buildSheet());
    await tester.pump();
    await tester.pump();

    // Sheet still visible (not popped)
    expect(find.byType(ProfessionalFormSheet), findsOneWidget);
  });
}
