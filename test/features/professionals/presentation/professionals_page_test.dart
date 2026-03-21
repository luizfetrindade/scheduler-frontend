import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scheduler_frontend/core/policy/app_policy.dart';
import 'package:scheduler_frontend/design_system/tokens/app_theme.dart';
import 'package:scheduler_frontend/features/business/bloc/business_bloc.dart';
import 'package:scheduler_frontend/features/business/bloc/business_event.dart';
import 'package:scheduler_frontend/features/business/bloc/business_state.dart';
import 'package:scheduler_frontend/features/business/data/business_model.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_bloc.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_event.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_state.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professionals_bloc.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professionals_event.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professionals_state.dart';
import 'package:scheduler_frontend/features/professionals/data/professional_model.dart';
import 'package:scheduler_frontend/features/professionals/presentation/professionals_page.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockProfessionalsBloc
    extends MockBloc<ProfessionalsEvent, ProfessionalsState>
    implements ProfessionalsBloc {}

class MockProfessionalRolesBloc
    extends MockBloc<ProfessionalRolesEvent, ProfessionalRolesState>
    implements ProfessionalRolesBloc {}

class MockBusinessBloc extends MockBloc<BusinessEvent, BusinessState>
    implements BusinessBloc {}

// ── Fixtures ──────────────────────────────────────────────────────────────────

const _biz = BusinessModel(
  id: 'b1',
  slug: 'my-biz',
  name: 'My Business',
  logo: null,
  timezone: 'America/Sao_Paulo',
);

final _professional = ProfessionalModel(
  id: 'p1',
  businessId: 'b1',
  name: 'Carlos',
  color: '#FF0000',
  isActive: true,
);

BusinessLoaded _bizLoaded(StaffRole role, int maxStaff) => BusinessLoaded(
      businesses: const [_biz],
      active: _biz,
      policy: AppPolicy.from(role, maxStaff),
    );

// ── Test setup ────────────────────────────────────────────────────────────────

void main() {
  late MockProfessionalsBloc professionalsBloc;
  late MockProfessionalRolesBloc rolesBloc;
  late MockBusinessBloc businessBloc;

  setUpAll(() {
    registerFallbackValue(
      const ProfessionalRolesDeleteRequested(
          businessId: 'b1', roleId: 'r1'),
    );
  });

  setUp(() {
    professionalsBloc = MockProfessionalsBloc();
    rolesBloc = MockProfessionalRolesBloc();
    businessBloc = MockBusinessBloc();
    when(() => professionalsBloc.state)
        .thenReturn(const ProfessionalsInitial());
    when(() => rolesBloc.state)
        .thenReturn(const ProfessionalRolesInitial());
    when(() => businessBloc.state).thenReturn(const BusinessInitial());
  });

  // ProfessionalsPage uses context.push / context.go from GoRouter.
  // Wrap with a minimal GoRouter so those calls don't throw.
  Widget buildPage() {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider<ProfessionalsBloc>.value(
                  value: professionalsBloc),
              BlocProvider<ProfessionalRolesBloc>.value(value: rolesBloc),
              BlocProvider<BusinessBloc>.value(value: businessBloc),
            ],
            child: const ProfessionalsPage(),
          ),
        ),
        // Stub route for context.push(AppRoutes.professionalRoles)
        GoRoute(
          path: '/professional-roles',
          builder: (context, state) => const Scaffold(),
        ),
        // Stub route for context.go('/professionals/:id')
        GoRoute(
          path: '/professionals/:id',
          builder: (context, state) => const Scaffold(),
        ),
      ],
    );

    return MaterialApp.router(
      theme: AppTheme.light()
          .copyWith(splashFactory: NoSplash.splashFactory),
      routerConfig: router,
    );
  }

  group('ProfessionalsPage — policy guards', () {
    testWidgets(
        'admin + team policy: "Novo" button and "Gerenciar cargos" icon are visible',
        (tester) async {
      when(() => professionalsBloc.state)
          .thenReturn(ProfessionalsLoaded([_professional]));
      when(() => businessBloc.state)
          .thenReturn(_bizLoaded(StaffRole.owner, 5));

      await tester.pumpWidget(buildPage());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Novo'), findsOneWidget);
      expect(find.byTooltip('Gerenciar cargos'), findsOneWidget);
    });

    testWidgets(
        'member policy: "Novo" button and "Gerenciar cargos" icon are NOT visible',
        (tester) async {
      when(() => professionalsBloc.state)
          .thenReturn(ProfessionalsLoaded([_professional]));
      when(() => businessBloc.state)
          .thenReturn(_bizLoaded(StaffRole.member, 5));

      await tester.pumpWidget(buildPage());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Novo'), findsNothing);
      expect(find.byTooltip('Gerenciar cargos'), findsNothing);
    });
  });
}
