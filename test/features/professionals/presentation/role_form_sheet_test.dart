import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scheduler_frontend/features/business/bloc/business_bloc.dart';
import 'package:scheduler_frontend/features/business/bloc/business_event.dart';
import 'package:scheduler_frontend/features/business/bloc/business_state.dart';
import 'package:scheduler_frontend/features/business/data/business_model.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_bloc.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_event.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_state.dart';
import 'package:scheduler_frontend/features/professionals/data/professional_role_model.dart';
import 'package:scheduler_frontend/features/professionals/presentation/widgets/role_form_sheet.dart';
import 'package:scheduler_frontend/design_system/tokens/app_theme.dart';

class MockProfessionalRolesBloc
    extends MockBloc<ProfessionalRolesEvent, ProfessionalRolesState>
    implements ProfessionalRolesBloc {}

class MockBusinessBloc extends MockBloc<BusinessEvent, BusinessState>
    implements BusinessBloc {}

void main() {
  late MockProfessionalRolesBloc rolesBloc;
  late MockBusinessBloc businessBloc;

  setUpAll(() {
    registerFallbackValue(const ProfessionalRolesCreateRequested(
      businessId: 'b1',
      name: 'Test',
    ));
    registerFallbackValue(const ProfessionalRolesUpdateRequested(
      businessId: 'b1',
      roleId: 'r1',
      name: 'Test',
    ));
  });

  setUp(() {
    rolesBloc = MockProfessionalRolesBloc();
    businessBloc = MockBusinessBloc();
    when(() => rolesBloc.state).thenReturn(const ProfessionalRolesInitial());
    when(() => businessBloc.state).thenReturn(const BusinessInitial());
  });

  Widget buildSheet({ProfessionalRoleModel? role}) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider<ProfessionalRolesBloc>.value(value: rolesBloc),
              BlocProvider<BusinessBloc>.value(value: businessBloc),
            ],
            child: RoleFormSheet(role: role),
          ),
        ),
      );

  testWidgets('shows Novo Cargo title in create mode', (tester) async {
    await tester.pumpWidget(buildSheet());
    await tester.pump();
    expect(find.text('Novo Cargo'), findsOneWidget);
  });

  testWidgets('shows Editar Cargo title in edit mode', (tester) async {
    final role = ProfessionalRoleModel(id: 'r1', businessId: 'b1', name: 'Manicure');
    await tester.pumpWidget(buildSheet(role: role));
    await tester.pump();
    expect(find.text('Editar Cargo'), findsOneWidget);
  });

  testWidgets('submit with empty name shows validation error', (tester) async {
    await tester.pumpWidget(buildSheet());
    await tester.pump();

    await tester.tap(find.text('Salvar'));
    await tester.pump();

    expect(find.text('Nome é obrigatório'), findsOneWidget);
    verifyNever(() => rolesBloc.add(any()));
  });

  testWidgets('valid create dispatches ProfessionalRolesCreateRequested', (tester) async {
    when(() => rolesBloc.state).thenReturn(const ProfessionalRolesLoaded([]));
    when(() => businessBloc.state).thenReturn(
      BusinessLoaded(
        businesses: const [],
        active: const BusinessModel(
          id: 'b1', slug: 'my-biz', name: 'My Business',
          logo: null, timezone: 'America/Sao_Paulo',
        ),
      ),
    );

    await tester.pumpWidget(buildSheet());
    await tester.pump();

    await tester.enterText(find.byType(TextFormField), 'Esteticista');
    await tester.pump();

    await tester.tap(find.text('Salvar'));
    await tester.pump();

    verify(() => rolesBloc.add(any(that: isA<ProfessionalRolesCreateRequested>()))).called(1);
  });

  testWidgets('valid edit dispatches ProfessionalRolesUpdateRequested', (tester) async {
    final role = ProfessionalRoleModel(id: 'r1', businessId: 'b1', name: 'Manicure');
    when(() => rolesBloc.state).thenReturn(const ProfessionalRolesLoaded([]));
    when(() => businessBloc.state).thenReturn(
      BusinessLoaded(
        businesses: const [],
        active: const BusinessModel(
          id: 'b1', slug: 'my-biz', name: 'My Business',
          logo: null, timezone: 'America/Sao_Paulo',
        ),
      ),
    );

    await tester.pumpWidget(buildSheet(role: role));
    await tester.pump();

    await tester.enterText(find.byType(TextFormField), 'Manicure Editado');
    await tester.pump();
    await tester.tap(find.text('Salvar'));
    await tester.pump();

    verify(() => rolesBloc.add(any(that: isA<ProfessionalRolesUpdateRequested>()))).called(1);
  });

  testWidgets('sheet does not close on initial Loaded state (wasSubmitting guard)', (tester) async {
    when(() => rolesBloc.state).thenReturn(const ProfessionalRolesLoaded([]));
    when(() => rolesBloc.stream)
        .thenAnswer((_) => Stream.value(const ProfessionalRolesLoaded([])));

    await tester.pumpWidget(buildSheet());
    await tester.pump();
    await tester.pump();

    // Sheet should still be in the tree — not closed
    expect(find.byType(RoleFormSheet), findsOneWidget);
  });
}
