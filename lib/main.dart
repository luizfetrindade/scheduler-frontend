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
import 'package:scheduler_frontend/features/business/data/business_repository.dart';

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

  final authBloc = AuthBloc(authRepo)..add(const AuthUserFetched());

  runApp(SchedulerApp(
    authBloc: authBloc,
    preferences: preferences,
    businessRepo: businessRepo,
    appointmentRepo: appointmentRepo,
  ));
}

class SchedulerApp extends StatelessWidget {
  final AuthBloc authBloc;
  final PreferencesService preferences;
  final BusinessRepository businessRepo;
  final AppointmentRepository appointmentRepo;

  const SchedulerApp({
    super.key,
    required this.authBloc,
    required this.preferences,
    required this.businessRepo,
    required this.appointmentRepo,
  });

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: appointmentRepo,
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: authBloc),
          BlocProvider(create: (_) => ThemeCubit(preferences)),
          BlocProvider(create: (_) => BusinessBloc(businessRepo)),
          BlocProvider(create: (_) => AppointmentsBloc(appointmentRepo)),
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
      builder: (context, themeState) => BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.read<BusinessBloc>().add(const BusinessLoadRequested());
          }
        },
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
