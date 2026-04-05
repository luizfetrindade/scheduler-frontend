import 'package:flutter/material.dart';
import 'package:flutter_http/flutter_http.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:scheduler_frontend/core/auth/auth_bloc.dart';
import 'package:scheduler_frontend/core/auth/auth_event.dart';
import 'package:scheduler_frontend/core/auth/auth_repository.dart';
import 'package:scheduler_frontend/core/auth/remember_me_storage.dart';
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
import 'package:scheduler_frontend/features/appointments/bloc/appointments_event.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_repository.dart';
import 'package:scheduler_frontend/features/appointments/presentation/attendance_prompt_watcher.dart';
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
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_bloc.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_event.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professionals_bloc.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professionals_event.dart';
import 'package:scheduler_frontend/features/professionals/data/professional_repository.dart';
import 'package:scheduler_frontend/features/onboarding/bloc/wizard_bloc.dart';
import 'package:scheduler_frontend/features/professionals/data/professional_roles_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  await Hive.initFlutter();

  final hiveCache = HiveCacheService();
  await hiveCache.init();

  final preferences = PreferencesService();
  await preferences.init();

  final apiClient = await ApiClient.create();
  final authRepo = AuthRepository(apiClient, RememberMeStorage());
  final businessRepo = BusinessRepository(apiClient);
  final appointmentRepo = AppointmentRepository(apiClient);
  final serviceRepo = ServiceRepository(apiClient);
  final clientRepo = ClientRepository(apiClient);
  final reportsRepo = ReportsRepository(apiClient);
  final professionalRepo = ProfessionalRepository(apiClient);
  final professionalRolesRepo = ProfessionalRolesRepository(apiClient);

  final authBloc = AuthBloc(authRepo)..add(const AuthUserFetched());

  // When the access token expires and the refresh token is also invalid,
  // automatically log the user out instead of showing "no permission" errors.
  apiClient.onAuthExpired = () => authBloc.add(const AuthLogoutRequested());

  runApp(SchedulerApp(
    authBloc: authBloc,
    preferences: preferences,
    businessRepo: businessRepo,
    appointmentRepo: appointmentRepo,
    serviceRepo: serviceRepo,
    clientRepo: clientRepo,
    reportsRepo: reportsRepo,
    professionalRepo: professionalRepo,
    professionalRolesRepo: professionalRolesRepo,
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
  final ProfessionalRepository professionalRepo;
  final ProfessionalRolesRepository professionalRolesRepo;

  const SchedulerApp({
    super.key,
    required this.authBloc,
    required this.preferences,
    required this.businessRepo,
    required this.appointmentRepo,
    required this.serviceRepo,
    required this.clientRepo,
    required this.reportsRepo,
    required this.professionalRepo,
    required this.professionalRolesRepo,
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
          BlocProvider(create: (_) => ProfessionalsBloc(professionalRepo)),
          BlocProvider(create: (_) => ProfessionalRolesBloc(professionalRolesRepo)),
          BlocProvider(
            create: (context) => WizardBloc(
              createBusiness: (name) async {
                final result = await businessRepo.createBusiness(name: name);
                if (result case Success(:final data)) {
                  context
                      .read<BusinessBloc>()
                      .add(const BusinessLoadRequested());
                  return data.id;
                }
                throw (result as HttpFailure).failure;
              },
              hasServices: (bizId) async {
                final result = await serviceRepo.getServices(businessId: bizId);
                return switch (result) {
                  Success(:final data) => data.isNotEmpty,
                  _ => false,
                };
              },
              hasProfessionals: (bizId) async {
                final result = await professionalRepo.getProfessionals(
                  businessId: bizId,
                );
                return switch (result) {
                  Success(:final data) => data.isNotEmpty,
                  _ => false,
                };
              },
              isSoloMode: true,
              businessId: '',
            ),
          ),
        ],
        child: _AppBody(authBloc: authBloc),
      ),
    );
  }
}

class _AppBody extends StatefulWidget {
  final AuthBloc authBloc;
  const _AppBody({required this.authBloc});

  @override
  State<_AppBody> createState() => _AppBodyState();
}

class _AppBodyState extends State<_AppBody> {
  late final GoRouter _router = createAppRouter(widget.authBloc);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

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
          // HIGH-05 fix: wipe all BLoC state on logout so that a subsequent
          // login on the same device never sees the previous user's data.
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthUnauthenticated) {
                context.read<BusinessBloc>().add(const BusinessSessionCleared());
                context.read<AppointmentsBloc>().add(const AppointmentsSessionCleared());
                context.read<ServicesBloc>().add(const ServicesSessionCleared());
                context.read<ClientsBloc>().add(const ClientsSessionCleared());
                context.read<ProfessionalsBloc>().add(const ProfessionalsSessionCleared());
                context.read<ProfessionalRolesBloc>().add(const ProfessionalRolesSessionCleared());
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
                context.read<AppointmentsBloc>().add(
                      AppointmentsLoadRequested(
                        slug: state.active.slug,
                        date: DateTime.now(),
                      ),
                    );
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
          BlocListener<BusinessBloc, BusinessState>(
            listener: (context, state) {
              if (state is BusinessLoaded) {
                context
                    .read<ProfessionalsBloc>()
                    .add(ProfessionalsLoadRequested(state.active.id));
              }
            },
          ),
          BlocListener<BusinessBloc, BusinessState>(
            listener: (context, state) {
              if (state is BusinessLoaded) {
                context
                    .read<ProfessionalRolesBloc>()
                    .add(ProfessionalRolesLoadRequested(state.active.id));
              }
            },
          ),
          BlocListener<BusinessBloc, BusinessState>(
            listener: (context, state) {
              if (state is BusinessLoaded) {
                context.read<WizardBloc>().reinitialize(
                      businessId: state.active.id,
                      isSoloMode: state.policy.isSoloMode,
                    );
              }
            },
          ),
        ],
        child: MaterialApp.router(
          title: 'Scheduler',
          debugShowCheckedModeBanner: false,
          routerConfig: _router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          themeMode: themeState.themeMode,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          builder: (context, child) => AttendancePromptWatcher(
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
