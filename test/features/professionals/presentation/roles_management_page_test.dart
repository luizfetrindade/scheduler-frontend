import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scheduler_frontend/design_system/tokens/app_theme.dart';
import 'package:scheduler_frontend/features/business/bloc/business_bloc.dart';
import 'package:scheduler_frontend/features/business/bloc/business_event.dart';
import 'package:scheduler_frontend/features/business/bloc/business_state.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_bloc.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_event.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_state.dart';
import 'package:scheduler_frontend/features/business/data/business_model.dart';
import 'package:scheduler_frontend/features/professionals/data/professional_role_model.dart';
import 'package:scheduler_frontend/features/professionals/presentation/roles_management_page.dart';

class MockProfessionalRolesBloc
    extends MockBloc<ProfessionalRolesEvent, ProfessionalRolesState>
    implements ProfessionalRolesBloc {}

class MockBusinessBloc extends MockBloc<BusinessEvent, BusinessState>
    implements BusinessBloc {}

void main() {
  late MockProfessionalRolesBloc rolesBloc;
  late MockBusinessBloc businessBloc;

  setUpAll(() {
    // ProfessionalRolesEvent is sealed — register concrete instances as fallbacks
    registerFallbackValue(const ProfessionalRolesDeleteRequested(businessId: 'b1', roleId: 'r1'));
  });

  setUp(() {
    rolesBloc = MockProfessionalRolesBloc();
    businessBloc = MockBusinessBloc();
    when(() => rolesBloc.state).thenReturn(const ProfessionalRolesInitial());
    when(() => businessBloc.state).thenReturn(const BusinessInitial());
  });

  Widget buildPage() => MaterialApp(
        // Override splashFactory to avoid ink_sparkle shader error in test environment
        theme: AppTheme.light().copyWith(splashFactory: NoSplash.splashFactory),
        home: MultiBlocProvider(
          providers: [
            BlocProvider<ProfessionalRolesBloc>.value(value: rolesBloc),
            BlocProvider<BusinessBloc>.value(value: businessBloc),
          ],
          child: const RolesManagementPage(),
        ),
      );

  final role1 = ProfessionalRoleModel(
    id: 'r1', businessId: 'b1', name: 'Cabeleireira', professionalCount: 2,
  );
  final role2 = ProfessionalRoleModel(
    id: 'r2', businessId: 'b1', name: 'Manicure', professionalCount: 0,
  );

  testWidgets('renders role list with names and counts', (tester) async {
    when(() => rolesBloc.state).thenReturn(ProfessionalRolesLoaded([role1, role2]));

    await tester.pumpWidget(buildPage());
    await tester.pump();

    expect(find.text('Cabeleireira'), findsOneWidget);
    expect(find.text('Manicure'), findsOneWidget);
    expect(find.text('2 profissional(is)'), findsOneWidget);
    expect(find.text('0 profissional(is)'), findsOneWidget);
  });

  testWidgets('renders empty state when list is empty', (tester) async {
    when(() => rolesBloc.state).thenReturn(const ProfessionalRolesLoaded([]));

    await tester.pumpWidget(buildPage());
    await tester.pump();

    expect(find.textContaining('Nenhum cargo cadastrado'), findsOneWidget);
  });

  testWidgets('delete button shows confirmation dialog when count > 0', (tester) async {
    when(() => rolesBloc.state).thenReturn(ProfessionalRolesLoaded([role1]));

    await tester.pumpWidget(buildPage());
    await tester.pump();

    await tester.tap(find.byKey(const Key('delete-r1')));
    await tester.pump();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('profissional'), findsWidgets);
  });

  testWidgets('delete fires immediately when count == 0 (no dialog)', (tester) async {
    when(() => rolesBloc.state).thenReturn(ProfessionalRolesLoaded([role2]));
    when(() => businessBloc.state).thenReturn(
      BusinessLoaded(
        businesses: const [],
        active: const BusinessModel(
          id: 'b1', slug: 'my-biz', name: 'My Business',
          logo: null, timezone: 'America/Sao_Paulo',
        ),
      ),
    );

    await tester.pumpWidget(buildPage());
    await tester.pump();

    await tester.tap(find.byKey(const Key('delete-r2')));
    await tester.pump();

    expect(find.byType(AlertDialog), findsNothing);
    verify(() => rolesBloc.add(any(that: isA<ProfessionalRolesDeleteRequested>()))).called(1);
  });
}
