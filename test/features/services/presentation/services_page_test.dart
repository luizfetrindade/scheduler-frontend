import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scheduler_frontend/core/policy/app_policy.dart';
import 'package:scheduler_frontend/design_system/tokens/app_theme.dart';
import 'package:scheduler_frontend/features/business/bloc/business_bloc.dart';
import 'package:scheduler_frontend/features/business/bloc/business_event.dart';
import 'package:scheduler_frontend/features/business/bloc/business_state.dart';
import 'package:scheduler_frontend/features/business/data/business_model.dart';
import 'package:scheduler_frontend/features/services/bloc/services_bloc.dart';
import 'package:scheduler_frontend/features/services/bloc/services_event.dart';
import 'package:scheduler_frontend/features/services/bloc/services_state.dart';
import 'package:scheduler_frontend/features/services/data/service_model.dart';
import 'package:scheduler_frontend/features/services/presentation/services_page.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockServicesBloc extends MockBloc<ServicesEvent, ServicesState>
    implements ServicesBloc {}

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

final _service = ServiceModel(id: 's1', name: 'Corte', isActive: true);

BusinessLoaded _bizLoaded(StaffRole role, int maxStaff) => BusinessLoaded(
      businesses: const [_biz],
      active: _biz,
      policy: AppPolicy.from(role, maxStaff),
    );

// ── Test setup ────────────────────────────────────────────────────────────────

void main() {
  late MockServicesBloc servicesBloc;
  late MockBusinessBloc businessBloc;

  setUp(() {
    servicesBloc = MockServicesBloc();
    businessBloc = MockBusinessBloc();
    when(() => servicesBloc.state).thenReturn(const ServicesInitial());
    when(() => businessBloc.state).thenReturn(const BusinessInitial());
  });

  Widget buildPage() => MaterialApp(
        theme: AppTheme.light()
            .copyWith(splashFactory: NoSplash.splashFactory),
        home: MultiBlocProvider(
          providers: [
            BlocProvider<ServicesBloc>.value(value: servicesBloc),
            BlocProvider<BusinessBloc>.value(value: businessBloc),
          ],
          child: const ServicesPage(),
        ),
      );

  group('ServicesPage — "Novo serviço" button visibility', () {
    testWidgets(
        'admin policy: "Novo serviço" button is visible when services are loaded',
        (tester) async {
      when(() => servicesBloc.state)
          .thenReturn(ServicesLoaded([_service]));
      when(() => businessBloc.state)
          .thenReturn(_bizLoaded(StaffRole.owner, 5));

      await tester.pumpWidget(buildPage());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Novo serviço'), findsOneWidget);
    });

    testWidgets(
        'member policy: "Novo serviço" button is NOT visible when services are loaded',
        (tester) async {
      when(() => servicesBloc.state)
          .thenReturn(ServicesLoaded([_service]));
      when(() => businessBloc.state)
          .thenReturn(_bizLoaded(StaffRole.member, 5));

      await tester.pumpWidget(buildPage());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Novo serviço'), findsNothing);
    });

    testWidgets(
        'member policy + empty services: "Adicionar serviço" CTA button is NOT visible',
        (tester) async {
      when(() => servicesBloc.state)
          .thenReturn(const ServicesLoaded([]));
      when(() => businessBloc.state)
          .thenReturn(_bizLoaded(StaffRole.member, 5));

      await tester.pumpWidget(buildPage());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Adicionar serviço'), findsNothing);
    });
  });
}
