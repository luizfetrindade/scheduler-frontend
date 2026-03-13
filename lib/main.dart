import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:scheduler_frontend/core/auth/auth_bloc.dart';
import 'package:scheduler_frontend/core/auth/auth_event.dart';
import 'package:scheduler_frontend/core/auth/auth_repository.dart';
import 'package:scheduler_frontend/core/auth/auth_state.dart';
import 'package:scheduler_frontend/core/cache/hive_cache_service.dart';
import 'package:scheduler_frontend/core/cache/preferences_service.dart';
import 'package:scheduler_frontend/core/l10n/l10n.dart';
import 'package:scheduler_frontend/core/network/api_client.dart';
import 'package:scheduler_frontend/core/router/app_router.dart';
import 'package:scheduler_frontend/core/theme/theme_cubit.dart';
import 'package:scheduler_frontend/core/theme/theme_state.dart';
import 'package:scheduler_frontend/design_system/tokens/app_theme.dart';
import 'package:scheduler_frontend/features/appointments/bloc/appointments_bloc.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_repository.dart';
import 'package:scheduler_frontend/features/business/bloc/business_bloc.dart';
import 'package:scheduler_frontend/features/business/bloc/business_event.dart';
import 'package:scheduler_frontend/features/business/bloc/business_state.dart';
import 'package:scheduler_frontend/features/business/data/business_repository.dart';
import 'package:scheduler_frontend/features/services/bloc/services_bloc.dart';
import 'package:scheduler_frontend/features/services/bloc/services_event.dart';
import 'package:scheduler_frontend/features/reports/data/reports_repository.dart';
import 'package:scheduler_frontend/features/services/data/service_repository.dart';
import 'package:scheduler_frontend/features/clients/bloc/clients_bloc.dart';
import 'package:scheduler_frontend/features/clients/bloc/clients_event.dart';
import 'package:scheduler_frontend/features/clients/data/client_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  await Hive.initFlutter();

  final hiveCache = HiveCacheService();
  await hiveCache.init();

  final preferences = PreferencesService();
  await preferences.init();

  final apiClient = ApiClient.create();
  final authRepo = AuthRepository(apiClient);
  final businessRepo = BusinessRepository(apiClient);
  final appointmentRepo = AppointmentRepository(apiClient);
  final serviceRepo = ServiceRepository(apiClient);
  final clientRepo = ClientRepository(apiClient);
  final reportsRepo = ReportsRepository(apiClient);

  final authBloc = AuthBloc(authRepo)..add(const AuthUserFetched());

  runApp(SchedulerApp(
    authBloc: authBloc,
    preferences: preferences,
    businessRepo: businessRepo,
    appointmentRepo: appointmentRepo,
    serviceRepo: serviceRepo,
    clientRepo: clientRepo,
    reportsRepo: reportsRepo,
  ));
}

class SchedulerApp extends StatelessWidget {
  final AuthBloc authBloc;
  final PreferencesService preferences;
  final BusinessRepository businessRepo;
  final AppointmentRepository appointmentRepo;
  final ServiceRepository serviceRepo;
  final ClientRepository clientRepo;
  final ReportsRepository reportsRepo;

  const SchedulerApp({
    super.key,
    required this.authBloc,
    required this.preferences,
    required this.businessRepo,
    required this.appointmentRepo,
    required this.serviceRepo,
    required this.clientRepo,
    required this.reportsRepo,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: appointmentRepo),
        RepositoryProvider.value(value: reportsRepo),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: authBloc),
          BlocProvider(create: (_) => ThemeCubit(preferences)),
          BlocProvider(create: (_) => BusinessBloc(businessRepo)),
          BlocProvider(create: (_) => AppointmentsBloc(appointmentRepo)),
          BlocProvider(create: (_) => ServicesBloc(serviceRepo)),
          BlocProvider(create: (_) => ClientsBloc(clientRepo)),
        ],
        child: _AppBody(authBloc: authBloc),
      ),
    );
  }
}

class _AppBody extends StatelessWidget {
  final AuthBloc authBloc;
  const _AppBody({required this.authBloc});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) => MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthAuthenticated) {
                context.read<BusinessBloc>().add(const BusinessLoadRequested());
              }
            },
          ),
          BlocListener<BusinessBloc, BusinessState>(
            listener: (context, state) {
              if (state is BusinessLoaded) {
                context
                    .read<ServicesBloc>()
                    .add(ServicesLoadRequested(state.active.id));
              }
            },
          ),
          BlocListener<BusinessBloc, BusinessState>(
            listener: (context, state) {
              if (state is BusinessLoaded) {
                context
                    .read<ClientsBloc>()
                    .add(ClientsLoadRequested(state.active.id));
              }
            },
          ),
        ],
        child: MaterialApp.router(
          title: 'Scheduler',
          debugShowCheckedModeBanner: false,
          routerConfig: createAppRouter(authBloc),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          themeMode: themeState.themeMode,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
        ),
      ),
    );
  }
}
