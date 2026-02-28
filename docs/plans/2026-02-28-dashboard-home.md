# Dashboard Home Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the scheduler home screen with business selector, today's stats cards, and appointment list with quick actions.

**Architecture:** Three Blocs (AuthBloc, BusinessBloc, AppointmentsBloc) backed by repositories that use the existing `flutter_http` package. `RouterNotifier` bridges `AuthBloc` state to GoRouter's `refreshListenable`. `AppShell` cascades auth → business load → appointments load via `BlocListener`.

**Tech Stack:** Flutter, flutter_bloc ^9, equatable ^2, dio ^5.7 (for PATCH), bloc_test ^10, mocktail ^1, flutter_http (existing), go_router (existing).

---

## Key Context

- **flutter_http** (`lib/flutter_http.dart`) exports `HttpClient`, `TokenStorage`, `Result<T>`, `AppFailure` subtypes. `HttpClient` already injects Bearer token via `AuthInterceptor`. It has `get`, `getList`, `post`, `put`, `delete` — but **no `patch`**, so we add one via raw `dio`.
- **Token refresh mismatch**: `AuthInterceptor` sends `{'refresh_token': ...}` in the body, but the backend expects `x-refresh-token` header. Disable auto-refresh by pointing to a non-existent endpoint; handle `UnauthorizedFailure` in `AuthBloc` by emitting `AuthUnauthenticated`.
- **Backend appointments endpoint** returns appointments with nested `client` and `service` objects.
- **Role-based buttons**: For MVP, show quick-action buttons to all users. Add staff role check in a follow-up task.
- **AppConfig.apiUrl** reads from `--dart-define=API_URL=...`, defaults to `http://localhost:3000`.
- Existing router tests (`test/core/router/app_router_test.dart`) use `AuthService` — update them in Task 8.

---

## Task 1: Add Dependencies

**Files:**
- Modify: `pubspec.yaml`

**Step 1: Add packages**

```yaml
# In dependencies:
  flutter_bloc: ^9.0.0
  equatable: ^2.0.7
  dio: ^5.7.0

# In dev_dependencies:
  bloc_test: ^10.0.0
  mocktail: ^1.0.0
```

**Step 2: Install**

```bash
cd /Users/luizfelipetrindade/Desktop/Scheduler-v1/scheduler-frontend
flutter pub get
```

Expected: `Resolving dependencies... Got dependencies!`

**Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add flutter_bloc, equatable, dio, bloc_test, mocktail"
```

---

## Task 2: UserModel

**Files:**
- Create: `lib/core/models/user_model.dart`
- Create: `test/core/models/user_model_test.dart`

**Step 1: Write the failing test**

```dart
// test/core/models/user_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/core/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 'uuid-1',
        'name': 'João Silva',
        'email': 'joao@example.com',
        'roles': [{'name': 'admin'}],
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'uuid-1');
      expect(user.name, 'João Silva');
      expect(user.email, 'joao@example.com');
      expect(user.roles, ['admin']);
    });

    test('fromJson handles empty roles list', () {
      final json = {
        'id': 'uuid-2',
        'name': 'Maria',
        'email': 'maria@example.com',
        'roles': [],
      };
      final user = UserModel.fromJson(json);
      expect(user.roles, isEmpty);
    });

    test('equality works via Equatable', () {
      const a = UserModel(id: '1', name: 'A', email: 'a@b.com', roles: []);
      const b = UserModel(id: '1', name: 'A', email: 'a@b.com', roles: []);
      expect(a, equals(b));
    });
  });
}
```

**Step 2: Run test — expect failure**

```bash
flutter test test/core/models/user_model_test.dart
```

Expected: `Error: Target of URI doesn't exist 'package:scheduler_frontend/core/models/user_model.dart'`

**Step 3: Implement**

```dart
// lib/core/models/user_model.dart
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final List<String> roles;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.roles,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        roles: (json['roles'] as List<dynamic>? ?? [])
            .map((r) => (r as Map<String, dynamic>)['name'] as String)
            .toList(),
      );

  String get firstName => name.split(' ').first;

  @override
  List<Object?> get props => [id, name, email, roles];
}
```

**Step 4: Run test — expect pass**

```bash
flutter test test/core/models/user_model_test.dart
```

Expected: `All tests passed!`

**Step 5: Commit**

```bash
git add lib/core/models/user_model.dart test/core/models/user_model_test.dart
git commit -m "feat: add UserModel with Equatable"
```

---

## Task 3: BusinessModel

**Files:**
- Create: `lib/features/business/data/business_model.dart`
- Create: `test/features/business/data/business_model_test.dart`

**Step 1: Write the failing test**

```dart
// test/features/business/data/business_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/features/business/data/business_model.dart';

void main() {
  group('BusinessModel', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 'biz-1',
        'slug': 'meu-salao',
        'name': 'Meu Salão',
        'logo': 'https://example.com/logo.png',
        'timezone': 'America/Sao_Paulo',
      };

      final biz = BusinessModel.fromJson(json);

      expect(biz.id, 'biz-1');
      expect(biz.slug, 'meu-salao');
      expect(biz.name, 'Meu Salão');
      expect(biz.logo, 'https://example.com/logo.png');
      expect(biz.timezone, 'America/Sao_Paulo');
    });

    test('fromJson defaults timezone and handles null logo', () {
      final json = {'id': 'x', 'slug': 's', 'name': 'N'};
      final biz = BusinessModel.fromJson(json);
      expect(biz.logo, isNull);
      expect(biz.timezone, 'America/Sao_Paulo');
    });

    test('equality works via Equatable', () {
      const a = BusinessModel(id: '1', slug: 's', name: 'N', logo: null, timezone: 'UTC');
      const b = BusinessModel(id: '1', slug: 's', name: 'N', logo: null, timezone: 'UTC');
      expect(a, equals(b));
    });
  });
}
```

**Step 2: Run test — expect failure**

```bash
flutter test test/features/business/data/business_model_test.dart
```

**Step 3: Implement**

```dart
// lib/features/business/data/business_model.dart
import 'package:equatable/equatable.dart';

class BusinessModel extends Equatable {
  final String id;
  final String slug;
  final String name;
  final String? logo;
  final String timezone;

  const BusinessModel({
    required this.id,
    required this.slug,
    required this.name,
    required this.logo,
    required this.timezone,
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) => BusinessModel(
        id: json['id'] as String,
        slug: json['slug'] as String,
        name: json['name'] as String,
        logo: json['logo'] as String?,
        timezone: json['timezone'] as String? ?? 'America/Sao_Paulo',
      );

  @override
  List<Object?> get props => [id, slug, name, logo, timezone];
}
```

**Step 4: Run test — expect pass**

```bash
flutter test test/features/business/data/business_model_test.dart
```

**Step 5: Commit**

```bash
git add lib/features/business/data/business_model.dart test/features/business/data/business_model_test.dart
git commit -m "feat: add BusinessModel with Equatable"
```

---

## Task 4: AppointmentModel + Enums

**Files:**
- Create: `lib/features/appointments/data/appointment_model.dart`
- Create: `test/features/appointments/data/appointment_model_test.dart`

**Step 1: Write the failing test**

```dart
// test/features/appointments/data/appointment_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';

void main() {
  final sampleJson = {
    'id': 'appt-1',
    'startsAt': '2026-02-28T09:00:00.000Z',
    'endsAt': '2026-02-28T09:30:00.000Z',
    'status': 'PENDING',
    'client': {'name': 'João Silva'},
    'service': {'name': 'Corte', 'durationMinutes': 30},
    'staffId': 'staff-1',
    'notes': null,
  };

  group('AppointmentModel', () {
    test('fromJson parses all fields', () {
      final appt = AppointmentModel.fromJson(sampleJson);
      expect(appt.id, 'appt-1');
      expect(appt.status, AppointmentStatus.pending);
      expect(appt.clientName, 'João Silva');
      expect(appt.serviceName, 'Corte');
      expect(appt.serviceDurationMinutes, 30);
      expect(appt.staffId, 'staff-1');
      expect(appt.notes, isNull);
    });

    test('fromJson handles missing client and service', () {
      final json = {
        'id': 'appt-2',
        'startsAt': '2026-02-28T10:00:00.000Z',
        'endsAt': '2026-02-28T10:30:00.000Z',
        'status': 'CONFIRMED',
      };
      final appt = AppointmentModel.fromJson(json);
      expect(appt.clientName, 'Cliente');
      expect(appt.serviceName, isNull);
      expect(appt.status, AppointmentStatus.confirmed);
    });
  });

  group('AppointmentStatus', () {
    test('fromString maps all values', () {
      expect(AppointmentStatus.fromString('PENDING'), AppointmentStatus.pending);
      expect(AppointmentStatus.fromString('CONFIRMED'), AppointmentStatus.confirmed);
      expect(AppointmentStatus.fromString('CANCELLED'), AppointmentStatus.cancelled);
      expect(AppointmentStatus.fromString('NO_SHOW'), AppointmentStatus.noShow);
      expect(AppointmentStatus.fromString('COMPLETED'), AppointmentStatus.completed);
      expect(AppointmentStatus.fromString('UNKNOWN'), AppointmentStatus.pending);
    });

    test('label returns Portuguese string', () {
      expect(AppointmentStatus.pending.label, 'Pendente');
      expect(AppointmentStatus.confirmed.label, 'Confirmado');
      expect(AppointmentStatus.noShow.label, 'Não compareceu');
    });
  });
}
```

**Step 2: Run test — expect failure**

```bash
flutter test test/features/appointments/data/appointment_model_test.dart
```

**Step 3: Implement**

```dart
// lib/features/appointments/data/appointment_model.dart
import 'package:equatable/equatable.dart';

enum AppointmentStatus { pending, confirmed, cancelled, noShow, completed }

extension AppointmentStatusX on AppointmentStatus {
  static AppointmentStatus fromString(String value) => switch (value.toUpperCase()) {
        'CONFIRMED' => AppointmentStatus.confirmed,
        'CANCELLED' => AppointmentStatus.cancelled,
        'NO_SHOW' => AppointmentStatus.noShow,
        'COMPLETED' => AppointmentStatus.completed,
        _ => AppointmentStatus.pending,
      };

  String get label => switch (this) {
        AppointmentStatus.pending => 'Pendente',
        AppointmentStatus.confirmed => 'Confirmado',
        AppointmentStatus.cancelled => 'Cancelado',
        AppointmentStatus.noShow => 'Não compareceu',
        AppointmentStatus.completed => 'Concluído',
      };

  String get apiValue => switch (this) {
        AppointmentStatus.pending => 'PENDING',
        AppointmentStatus.confirmed => 'CONFIRMED',
        AppointmentStatus.cancelled => 'CANCELLED',
        AppointmentStatus.noShow => 'NO_SHOW',
        AppointmentStatus.completed => 'COMPLETED',
      };
}

class AppointmentModel extends Equatable {
  final String id;
  final DateTime startsAt;
  final DateTime endsAt;
  final AppointmentStatus status;
  final String clientName;
  final String? serviceName;
  final int? serviceDurationMinutes;
  final String? staffId;
  final String? notes;

  const AppointmentModel({
    required this.id,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.clientName,
    this.serviceName,
    this.serviceDurationMinutes,
    this.staffId,
    this.notes,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final client = json['client'] as Map<String, dynamic>?;
    final service = json['service'] as Map<String, dynamic>?;
    return AppointmentModel(
      id: json['id'] as String,
      startsAt: DateTime.parse(json['startsAt'] as String),
      endsAt: DateTime.parse(json['endsAt'] as String),
      status: AppointmentStatusX.fromString(json['status'] as String? ?? 'PENDING'),
      clientName: client?['name'] as String? ?? 'Cliente',
      serviceName: service?['name'] as String?,
      serviceDurationMinutes: service?['durationMinutes'] as int?,
      staffId: json['staffId'] as String?,
      notes: json['notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, startsAt, endsAt, status, clientName, serviceName, staffId];
}
```

**Step 4: Run test — expect pass**

```bash
flutter test test/features/appointments/data/appointment_model_test.dart
```

**Step 5: Commit**

```bash
git add lib/features/appointments/data/appointment_model.dart test/features/appointments/data/appointment_model_test.dart
git commit -m "feat: add AppointmentModel with status enum"
```

---

## Task 5: ApiClient + RouterNotifier

**Files:**
- Create: `lib/core/network/api_client.dart`
- Create: `lib/core/network/router_notifier.dart`

No unit tests needed for these infrastructure classes (they wrap external libraries).

**Step 1: Create ApiClient**

```dart
// lib/core/network/api_client.dart
import 'package:dio/dio.dart';
import 'package:flutter_http/flutter_http.dart';
import 'package:scheduler_frontend/core/config/app_config.dart';

/// Wraps flutter_http's HttpClient and adds PATCH support via raw Dio.
/// flutter_http's AuthInterceptor does not match the backend's x-refresh-token
/// header format for token refresh, so we disable auto-refresh here and let
/// AuthBloc handle UnauthorizedFailure by emitting AuthUnauthenticated.
class ApiClient {
  final HttpClient _http;
  final Dio _rawDio;
  final TokenStorage tokenStorage;

  ApiClient._(this._http, this._rawDio, this.tokenStorage);

  factory ApiClient.create() {
    final ts = TokenStorage();
    final http = HttpClient(
      baseUrl: AppConfig.apiUrl,
      tokenStorage: ts,
      // Intentionally wrong endpoint: disables the interceptor's auto-refresh
      // because the interceptor format (JSON body) != backend format (x-refresh-token header).
      // TODO: fix token refresh in flutter_http or implement custom interceptor.
      refreshEndpoint: '/auth/_no_auto_refresh',
    );
    final rawDio = Dio(BaseOptions(
      baseUrl: AppConfig.apiUrl,
      contentType: 'application/json',
    ));
    return ApiClient._(http, rawDio, ts);
  }

  Future<Result<T>> get<T>(
    String path, {
    required T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic>? queryParams,
  }) =>
      _http.get(path, fromJson: fromJson, queryParams: queryParams);

  Future<Result<List<T>>> getList<T>(
    String path, {
    required T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic>? queryParams,
  }) =>
      _http.getList(path, fromJson: fromJson, queryParams: queryParams);

  Future<Result<T>> post<T>(
    String path, {
    required T Function(Map<String, dynamic>) fromJson,
    Object? body,
  }) =>
      _http.post(path, fromJson: fromJson, body: body);

  /// PATCH via raw Dio with manual Bearer token injection.
  /// Used for PATCH /b/:slug/appointments/:id/status.
  Future<Result<T>> patch<T>(
    String path, {
    required T Function(Map<String, dynamic>) fromJson,
    Object? body,
  }) async {
    final token = await tokenStorage.getAccessToken();
    try {
      final response = await _rawDio.patch<Map<String, dynamic>>(
        path,
        data: body,
        options: Options(headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );
      return Success(fromJson(response.data!));
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401) return const HttpFailure(UnauthorizedFailure('Unauthorized'));
      if (code == 404) return const HttpFailure(NotFoundFailure('Not found'));
      return HttpFailure(ServerFailure(e.message ?? 'Server error', statusCode: code ?? 500));
    } catch (e) {
      return HttpFailure(UnknownFailure(e.toString()));
    }
  }
}
```

**Step 2: Create RouterNotifier**

```dart
// lib/core/network/router_notifier.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:scheduler_frontend/core/auth/auth_bloc.dart';

/// Bridges AuthBloc stream to GoRouter's refreshListenable.
class RouterNotifier extends ChangeNotifier {
  late final StreamSubscription<dynamic> _sub;

  RouterNotifier(AuthBloc authBloc) {
    _sub = authBloc.stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
```

**Step 3: Commit**

```bash
git add lib/core/network/
git commit -m "feat: add ApiClient with PATCH support and RouterNotifier"
```

---

## Task 6: AuthRepository

**Files:**
- Create: `lib/core/auth/auth_repository.dart`
- Create: `test/core/auth/auth_repository_test.dart`

**Step 1: Write the failing test**

```dart
// test/core/auth/auth_repository_test.dart
import 'package:flutter_http/flutter_http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scheduler_frontend/core/auth/auth_repository.dart';
import 'package:scheduler_frontend/core/models/user_model.dart';
import 'package:scheduler_frontend/core/network/api_client.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockClient;
  late AuthRepository repo;

  setUp(() {
    mockClient = MockApiClient();
    repo = AuthRepository(mockClient);
  });

  group('AuthRepository.login', () {
    test('returns token record on success', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '/auth/login',
            fromJson: any(named: 'fromJson'),
            body: {'email': 'a@b.com', 'password': '123'},
          )).thenAnswer((_) async => const Success({
            'accessToken': 'acc',
            'refreshToken': 'ref',
          }));

      final result = await repo.login(email: 'a@b.com', password: '123');

      expect(result.isSuccess, isTrue);
      final data = (result as Success).data;
      expect(data.accessToken, 'acc');
      expect(data.refreshToken, 'ref');
    });

    test('returns HttpFailure on error', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '/auth/login',
            fromJson: any(named: 'fromJson'),
            body: any(named: 'body'),
          )).thenAnswer((_) async =>
          const HttpFailure(UnauthorizedFailure('wrong credentials')));

      final result = await repo.login(email: 'x@x.com', password: 'bad');

      expect(result.isFailure, isTrue);
    });
  });

  group('AuthRepository.getMe', () {
    test('returns UserModel on success', () async {
      when(() => mockClient.get<UserModel>(
            '/auth/me',
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => const Success(
            UserModel(id: '1', name: 'João', email: 'j@j.com', roles: []),
          ));

      final result = await repo.getMe();

      expect(result.isSuccess, isTrue);
      expect((result as Success).data.name, 'João');
    });
  });
}
```

**Step 2: Run test — expect failure**

```bash
flutter test test/core/auth/auth_repository_test.dart
```

**Step 3: Implement**

```dart
// lib/core/auth/auth_repository.dart
import 'package:flutter_http/flutter_http.dart';
import 'package:scheduler_frontend/core/models/user_model.dart';
import 'package:scheduler_frontend/core/network/api_client.dart';

typedef _TokenRecord = ({String accessToken, String refreshToken});

class AuthRepository {
  final ApiClient _client;

  AuthRepository(this._client);

  Future<Result<_TokenRecord>> login({
    required String email,
    required String password,
  }) async {
    final result = await _client.post<Map<String, dynamic>>(
      '/auth/login',
      fromJson: (json) => json,
      body: {'email': email, 'password': password},
    );
    return switch (result) {
      Success(:final data) => Success((
          accessToken: data['accessToken'] as String,
          refreshToken: data['refreshToken'] as String,
        )),
      HttpFailure(:final failure) => HttpFailure(failure),
    };
  }

  Future<Result<UserModel>> getMe() =>
      _client.get('/auth/me', fromJson: UserModel.fromJson);

  Future<void> saveTokens(String accessToken, String refreshToken) =>
      _client.tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

  Future<void> clearTokens() => _client.tokenStorage.clearTokens();
}
```

**Step 4: Run test — expect pass**

```bash
flutter test test/core/auth/auth_repository_test.dart
```

**Step 5: Commit**

```bash
git add lib/core/auth/auth_repository.dart test/core/auth/auth_repository_test.dart
git commit -m "feat: add AuthRepository"
```

---

## Task 7: AuthBloc

**Files:**
- Create: `lib/core/auth/auth_event.dart`
- Create: `lib/core/auth/auth_state.dart`
- Create: `lib/core/auth/auth_bloc.dart`
- Create: `test/core/auth/auth_bloc_test.dart`

**Step 1: Create Events**

```dart
// lib/core/auth/auth_event.dart
import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

/// Dispatched on app startup to check if a stored token is valid.
class AuthUserFetched extends AuthEvent {
  const AuthUserFetched();
}

/// Dispatched when the user submits the login form.
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthLoginRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

/// Dispatched when the user taps logout.
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
```

**Step 2: Create States**

```dart
// lib/core/auth/auth_state.dart
import 'package:equatable/equatable.dart';
import 'package:scheduler_frontend/core/models/user_model.dart';

sealed class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}
```

**Step 3: Create Bloc**

```dart
// lib/core/auth/auth_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_http/flutter_http.dart';
import 'package:scheduler_frontend/core/auth/auth_event.dart';
import 'package:scheduler_frontend/core/auth/auth_repository.dart';
import 'package:scheduler_frontend/core/auth/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;

  AuthBloc(this._repository) : super(const AuthInitial()) {
    on<AuthUserFetched>(_onUserFetched);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onUserFetched(
    AuthUserFetched event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _repository.getMe();
    switch (result) {
      case Success(:final data):
        emit(AuthAuthenticated(data));
      case HttpFailure():
        emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final loginResult = await _repository.login(
      email: event.email,
      password: event.password,
    );
    switch (loginResult) {
      case Success(:final data):
        await _repository.saveTokens(data.accessToken, data.refreshToken);
        final meResult = await _repository.getMe();
        switch (meResult) {
          case Success(:final data):
            emit(AuthAuthenticated(data));
          case HttpFailure(:final failure):
            emit(AuthError(_message(failure)));
        }
      case HttpFailure(:final failure):
        emit(AuthError(_message(failure)));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repository.clearTokens();
    emit(const AuthUnauthenticated());
  }

  String _message(AppFailure failure) => switch (failure) {
        UnauthorizedFailure() => 'Email ou senha incorretos',
        NetworkFailure() => 'Sem conexão com a internet',
        _ => 'Algo deu errado. Tente novamente',
      };
}
```

**Step 4: Write the failing test**

```dart
// test/core/auth/auth_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_http/flutter_http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scheduler_frontend/core/auth/auth_bloc.dart';
import 'package:scheduler_frontend/core/auth/auth_event.dart';
import 'package:scheduler_frontend/core/auth/auth_repository.dart';
import 'package:scheduler_frontend/core/auth/auth_state.dart';
import 'package:scheduler_frontend/core/models/user_model.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

const _user = UserModel(id: '1', name: 'João', email: 'j@j.com', roles: []);

void main() {
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
  });

  group('AuthBloc — AuthUserFetched', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Authenticated] when getMe succeeds',
      build: () {
        when(() => mockRepo.getMe())
            .thenAnswer((_) async => const Success(_user));
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const AuthUserFetched()),
      expect: () => [const AuthLoading(), const AuthAuthenticated(_user)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Unauthenticated] when getMe fails',
      build: () {
        when(() => mockRepo.getMe()).thenAnswer(
            (_) async => const HttpFailure(UnauthorizedFailure('401')));
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const AuthUserFetched()),
      expect: () => [const AuthLoading(), const AuthUnauthenticated()],
    );
  });

  group('AuthBloc — AuthLoginRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Authenticated] on successful login',
      build: () {
        when(() => mockRepo.login(email: 'j@j.com', password: '123'))
            .thenAnswer((_) async => const Success(
                (accessToken: 'acc', refreshToken: 'ref')));
        when(() => mockRepo.saveTokens('acc', 'ref'))
            .thenAnswer((_) async {});
        when(() => mockRepo.getMe())
            .thenAnswer((_) async => const Success(_user));
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(
          const AuthLoginRequested(email: 'j@j.com', password: '123')),
      expect: () => [const AuthLoading(), const AuthAuthenticated(_user)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthError] on wrong credentials',
      build: () {
        when(() => mockRepo.login(email: any(named: 'email'), password: any(named: 'password')))
            .thenAnswer((_) async =>
                const HttpFailure(UnauthorizedFailure('wrong')));
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc
          .add(const AuthLoginRequested(email: 'x@x.com', password: 'bad')),
      expect: () => [
        const AuthLoading(),
        const AuthError('Email ou senha incorretos'),
      ],
    );
  });

  group('AuthBloc — AuthLogoutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Unauthenticated] and clears tokens on logout',
      build: () {
        when(() => mockRepo.clearTokens()).thenAnswer((_) async {});
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const AuthLogoutRequested()),
      expect: () => [const AuthUnauthenticated()],
      verify: (_) => verify(() => mockRepo.clearTokens()).called(1),
    );
  });
}
```

**Step 5: Run test — expect failure (files don't exist yet)**

```bash
flutter test test/core/auth/auth_bloc_test.dart
```

**Step 6: Run test — expect pass (after creating all three files above)**

```bash
flutter test test/core/auth/auth_bloc_test.dart
```

Expected: `All tests passed!`

**Step 7: Commit**

```bash
git add lib/core/auth/ test/core/auth/auth_bloc_test.dart
git commit -m "feat: add AuthBloc with login/logout/fetch-user events"
```

---

## Task 8: Wire AuthBloc into Router, LoginPage, and main.dart

**Files:**
- Modify: `lib/core/router/app_router.dart`
- Modify: `lib/features/auth/presentation/login_page.dart`
- Modify: `lib/main.dart`
- Modify: `test/core/router/app_router_test.dart`
- Delete: `lib/core/auth/auth_service.dart` (replaced by AuthBloc)

**Step 1: Update app_router.dart**

```dart
// lib/core/router/app_router.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scheduler_frontend/app_shell.dart';
import 'package:scheduler_frontend/core/auth/auth_bloc.dart';
import 'package:scheduler_frontend/core/auth/auth_state.dart';
import 'package:scheduler_frontend/core/network/router_notifier.dart';
import 'package:scheduler_frontend/core/router/app_routes.dart';
import 'package:scheduler_frontend/features/auth/presentation/login_page.dart';
import 'package:scheduler_frontend/features/home/presentation/home_page.dart';

GoRouter createAppRouter(AuthBloc authBloc) => GoRouter(
      initialLocation: AppRoutes.home,
      refreshListenable: RouterNotifier(authBloc),
      redirect: (context, state) {
        final isLoggedIn = authBloc.state is AuthAuthenticated;
        final isOnLogin = state.matchedLocation == AppRoutes.login;

        if (!isLoggedIn && !isOnLogin) return AppRoutes.login;
        if (isLoggedIn && isOnLogin) return AppRoutes.home;
        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.login,
          builder: (context, _) => const LoginPage(),
        ),
        ShellRoute(
          builder: (context, _, child) => AppShell(child: child),
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, _) => const HomePage(),
            ),
          ],
        ),
      ],
    );
```

**Step 2: Update LoginPage to use BlocProvider**

```dart
// lib/features/auth/presentation/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scheduler_frontend/core/auth/auth_bloc.dart';
import 'package:scheduler_frontend/core/auth/auth_event.dart';
import 'package:scheduler_frontend/core/auth/auth_state.dart';
import 'package:scheduler_frontend/core/l10n/l10n.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(context.l10n.loginTitle, style: AppTypography.displayLg),
                const SizedBox(height: AppSpacing.xl),
                BaseInputField(
                  label: context.l10n.loginEmailLabel,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                ),
                const SizedBox(height: AppSpacing.md),
                BaseInputField(
                  label: context.l10n.loginPasswordLabel,
                  controller: _passwordController,
                  isPassword: true,
                  prefixIcon: Icons.lock_outlined,
                ),
                const SizedBox(height: AppSpacing.xl),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) => BaseButton(
                    label: context.l10n.loginButton,
                    isLoading: state is AuthLoading,
                    onPressed: state is AuthLoading
                        ? null
                        : () => context.read<AuthBloc>().add(
                              AuthLoginRequested(
                                email: _emailController.text.trim(),
                                password: _passwordController.text,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

> **Note:** `BaseButton` may not have `isLoading` or nullable `onPressed` yet. Check `lib/design_system/components/button/base_button.dart` and add `isLoading` param if missing (add a `CircularProgressIndicator` inside the button when loading).

**Step 3: Update main.dart**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:scheduler_frontend/core/auth/auth_bloc.dart';
import 'package:scheduler_frontend/core/auth/auth_event.dart';
import 'package:scheduler_frontend/core/auth/auth_repository.dart';
import 'package:scheduler_frontend/core/cache/hive_cache_service.dart';
import 'package:scheduler_frontend/core/cache/preferences_service.dart';
import 'package:scheduler_frontend/core/l10n/l10n.dart';
import 'package:scheduler_frontend/core/network/api_client.dart';
import 'package:scheduler_frontend/core/router/app_router.dart';
import 'package:scheduler_frontend/design_system/tokens/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final hiveCache = HiveCacheService();
  await hiveCache.init();

  final preferences = PreferencesService();
  await preferences.init();

  final apiClient = ApiClient.create();
  final authRepo = AuthRepository(apiClient);
  final authBloc = AuthBloc(authRepo)..add(const AuthUserFetched());

  runApp(SchedulerApp(authBloc: authBloc, apiClient: apiClient));
}

class SchedulerApp extends StatelessWidget {
  final AuthBloc authBloc;
  final ApiClient apiClient;

  const SchedulerApp({
    super.key,
    required this.authBloc,
    required this.apiClient,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: authBloc,
      child: MaterialApp.router(
        title: 'Scheduler',
        debugShowCheckedModeBanner: false,
        routerConfig: createAppRouter(authBloc),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.purple500,
            surface: AppColors.surface,
          ),
        ),
      ),
    );
  }
}
```

**Step 4: Update router tests**

Replace the contents of `test/core/router/app_router_test.dart`:

```dart
// test/core/router/app_router_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_http/flutter_http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scheduler_frontend/core/auth/auth_bloc.dart';
import 'package:scheduler_frontend/core/auth/auth_event.dart';
import 'package:scheduler_frontend/core/auth/auth_repository.dart';
import 'package:scheduler_frontend/core/auth/auth_state.dart';
import 'package:scheduler_frontend/core/l10n/l10n.dart';
import 'package:scheduler_frontend/core/models/user_model.dart';
import 'package:scheduler_frontend/core/router/app_router.dart';
import 'package:scheduler_frontend/features/auth/presentation/login_page.dart';
import 'package:scheduler_frontend/features/home/presentation/home_page.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

const _user = UserModel(id: '1', name: 'Test', email: 't@t.com', roles: []);

Widget buildTestApp(AuthBloc authBloc) {
  return BlocProvider.value(
    value: authBloc,
    child: MaterialApp.router(
      routerConfig: createAppRouter(authBloc),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
  });

  group('AppRouter', () {
    testWidgets('redirects to LoginPage when unauthenticated', (tester) async {
      when(() => mockRepo.getMe()).thenAnswer(
          (_) async => const HttpFailure(UnauthorizedFailure('401')));
      final authBloc = AuthBloc(mockRepo)..add(const AuthUserFetched());

      await tester.pumpWidget(buildTestApp(authBloc));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);

      await authBloc.close();
    });

    testWidgets('shows HomePage when authenticated', (tester) async {
      when(() => mockRepo.getMe())
          .thenAnswer((_) async => const Success(_user));
      final authBloc = AuthBloc(mockRepo)..add(const AuthUserFetched());

      await tester.pumpWidget(buildTestApp(authBloc));
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);

      await authBloc.close();
    });

    testWidgets('redirects to home after login', (tester) async {
      when(() => mockRepo.getMe()).thenAnswer(
          (_) async => const HttpFailure(UnauthorizedFailure('401')));
      final authBloc = AuthBloc(mockRepo);

      await tester.pumpWidget(buildTestApp(authBloc));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);

      when(() => mockRepo.getMe())
          .thenAnswer((_) async => const Success(_user));
      authBloc.emit(const AuthAuthenticated(_user));
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);

      await authBloc.close();
    });
  });
}
```

**Step 5: Delete auth_service.dart**

```bash
rm lib/core/auth/auth_service.dart
```

**Step 6: Run all tests**

```bash
flutter test
```

Expected: All tests pass (fix any compile errors before proceeding).

**Step 7: Commit**

```bash
git add -A
git commit -m "feat: wire AuthBloc into router, LoginPage, and main"
```

---

## Task 9: BusinessRepository

**Files:**
- Create: `lib/features/business/data/business_repository.dart`
- Create: `test/features/business/data/business_repository_test.dart`

**Step 1: Write the failing test**

```dart
// test/features/business/data/business_repository_test.dart
import 'package:flutter_http/flutter_http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scheduler_frontend/core/network/api_client.dart';
import 'package:scheduler_frontend/features/business/data/business_model.dart';
import 'package:scheduler_frontend/features/business/data/business_repository.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockClient;
  late BusinessRepository repo;

  setUp(() {
    mockClient = MockApiClient();
    repo = BusinessRepository(mockClient);
  });

  group('BusinessRepository.getBusinesses', () {
    test('returns list of businesses on success', () async {
      when(() => mockClient.getList<BusinessModel>(
            '/businesses',
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => const Success([
            BusinessModel(id: '1', slug: 'biz', name: 'Biz', logo: null, timezone: 'UTC'),
          ]));

      final result = await repo.getBusinesses();

      expect(result.isSuccess, isTrue);
      expect((result as Success).data.length, 1);
    });

    test('returns HttpFailure on network error', () async {
      when(() => mockClient.getList<BusinessModel>(
            '/businesses',
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async =>
          const HttpFailure(NetworkFailure('no internet')));

      final result = await repo.getBusinesses();

      expect(result.isFailure, isTrue);
    });
  });
}
```

**Step 2: Run — expect failure, then implement**

```dart
// lib/features/business/data/business_repository.dart
import 'package:flutter_http/flutter_http.dart';
import 'package:scheduler_frontend/core/network/api_client.dart';
import 'package:scheduler_frontend/features/business/data/business_model.dart';

class BusinessRepository {
  final ApiClient _client;

  BusinessRepository(this._client);

  Future<Result<List<BusinessModel>>> getBusinesses() =>
      _client.getList('/businesses', fromJson: BusinessModel.fromJson);
}
```

**Step 3: Run test — expect pass**

```bash
flutter test test/features/business/data/business_repository_test.dart
```

**Step 4: Commit**

```bash
git add lib/features/business/data/business_repository.dart test/features/business/data/business_repository_test.dart
git commit -m "feat: add BusinessRepository"
```

---

## Task 10: BusinessBloc

**Files:**
- Create: `lib/features/business/bloc/business_event.dart`
- Create: `lib/features/business/bloc/business_state.dart`
- Create: `lib/features/business/bloc/business_bloc.dart`
- Create: `test/features/business/bloc/business_bloc_test.dart`

**Step 1: Create Events**

```dart
// lib/features/business/bloc/business_event.dart
import 'package:equatable/equatable.dart';
import 'package:scheduler_frontend/features/business/data/business_model.dart';

sealed class BusinessEvent extends Equatable {
  const BusinessEvent();
  @override
  List<Object?> get props => [];
}

class BusinessLoadRequested extends BusinessEvent {
  const BusinessLoadRequested();
}

class BusinessSelected extends BusinessEvent {
  final BusinessModel business;
  const BusinessSelected(this.business);
  @override
  List<Object?> get props => [business];
}
```

**Step 2: Create States**

```dart
// lib/features/business/bloc/business_state.dart
import 'package:equatable/equatable.dart';
import 'package:scheduler_frontend/features/business/data/business_model.dart';

sealed class BusinessState extends Equatable {
  const BusinessState();
  @override
  List<Object?> get props => [];
}

class BusinessInitial extends BusinessState {
  const BusinessInitial();
}

class BusinessLoading extends BusinessState {
  const BusinessLoading();
}

class BusinessLoaded extends BusinessState {
  final List<BusinessModel> businesses;
  final BusinessModel active;
  const BusinessLoaded({required this.businesses, required this.active});
  @override
  List<Object?> get props => [businesses, active];
}

class BusinessError extends BusinessState {
  final String message;
  const BusinessError(this.message);
  @override
  List<Object?> get props => [message];
}
```

**Step 3: Create Bloc**

```dart
// lib/features/business/bloc/business_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_http/flutter_http.dart';
import 'package:scheduler_frontend/features/business/bloc/business_event.dart';
import 'package:scheduler_frontend/features/business/bloc/business_state.dart';
import 'package:scheduler_frontend/features/business/data/business_repository.dart';

class BusinessBloc extends Bloc<BusinessEvent, BusinessState> {
  final BusinessRepository _repository;

  BusinessBloc(this._repository) : super(const BusinessInitial()) {
    on<BusinessLoadRequested>(_onLoadRequested);
    on<BusinessSelected>(_onSelected);
  }

  Future<void> _onLoadRequested(
    BusinessLoadRequested event,
    Emitter<BusinessState> emit,
  ) async {
    emit(const BusinessLoading());
    final result = await _repository.getBusinesses();
    switch (result) {
      case Success(:final data) when data.isNotEmpty:
        emit(BusinessLoaded(businesses: data, active: data.first));
      case Success():
        emit(const BusinessError('Nenhum negócio encontrado'));
      case HttpFailure(:final failure):
        emit(BusinessError(_message(failure)));
    }
  }

  void _onSelected(
    BusinessSelected event,
    Emitter<BusinessState> emit,
  ) {
    if (state is BusinessLoaded) {
      final current = state as BusinessLoaded;
      emit(BusinessLoaded(
        businesses: current.businesses,
        active: event.business,
      ));
    }
  }

  String _message(AppFailure failure) => switch (failure) {
        NetworkFailure() => 'Sem conexão com a internet',
        _ => 'Não foi possível carregar os negócios',
      };
}
```

**Step 4: Write and run failing test**

```dart
// test/features/business/bloc/business_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_http/flutter_http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scheduler_frontend/features/business/bloc/business_bloc.dart';
import 'package:scheduler_frontend/features/business/bloc/business_event.dart';
import 'package:scheduler_frontend/features/business/bloc/business_state.dart';
import 'package:scheduler_frontend/features/business/data/business_model.dart';
import 'package:scheduler_frontend/features/business/data/business_repository.dart';

class MockBusinessRepository extends Mock implements BusinessRepository {}

const _biz = BusinessModel(id: '1', slug: 'my-biz', name: 'My Biz', logo: null, timezone: 'UTC');

void main() {
  late MockBusinessRepository mockRepo;

  setUp(() => mockRepo = MockBusinessRepository());

  blocTest<BusinessBloc, BusinessState>(
    'emits [Loading, Loaded] on success',
    build: () {
      when(() => mockRepo.getBusinesses())
          .thenAnswer((_) async => const Success([_biz]));
      return BusinessBloc(mockRepo);
    },
    act: (bloc) => bloc.add(const BusinessLoadRequested()),
    expect: () => [
      const BusinessLoading(),
      const BusinessLoaded(businesses: [_biz], active: _biz),
    ],
  );

  blocTest<BusinessBloc, BusinessState>(
    'emits [Loading, Error] on network failure',
    build: () {
      when(() => mockRepo.getBusinesses()).thenAnswer(
          (_) async => const HttpFailure(NetworkFailure('no internet')));
      return BusinessBloc(mockRepo);
    },
    act: (bloc) => bloc.add(const BusinessLoadRequested()),
    expect: () => [
      const BusinessLoading(),
      const BusinessError('Sem conexão com a internet'),
    ],
  );

  blocTest<BusinessBloc, BusinessState>(
    'changes active business on BusinessSelected',
    build: () {
      when(() => mockRepo.getBusinesses())
          .thenAnswer((_) async => const Success([_biz]));
      return BusinessBloc(mockRepo);
    },
    seed: () => const BusinessLoaded(businesses: [_biz], active: _biz),
    act: (bloc) => bloc.add(const BusinessSelected(_biz)),
    expect: () => [const BusinessLoaded(businesses: [_biz], active: _biz)],
  );
}
```

**Step 5: Run — expect pass**

```bash
flutter test test/features/business/bloc/business_bloc_test.dart
```

**Step 6: Commit**

```bash
git add lib/features/business/bloc/ test/features/business/bloc/
git commit -m "feat: add BusinessBloc"
```

---

## Task 11: AppointmentRepository

**Files:**
- Create: `lib/features/appointments/data/appointment_repository.dart`
- Create: `test/features/appointments/data/appointment_repository_test.dart`

**Step 1: Write the failing test**

```dart
// test/features/appointments/data/appointment_repository_test.dart
import 'package:flutter_http/flutter_http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scheduler_frontend/core/network/api_client.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_repository.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockClient;
  late AppointmentRepository repo;

  setUp(() {
    mockClient = MockApiClient();
    repo = AppointmentRepository(mockClient);
  });

  group('getAppointments', () {
    test('calls correct endpoint with date param', () async {
      when(() => mockClient.getList<AppointmentModel>(
            '/b/my-slug/appointments',
            fromJson: any(named: 'fromJson'),
            queryParams: {'date': '2026-02-28'},
          )).thenAnswer((_) async => const Success([]));

      final result = await repo.getAppointments(
        slug: 'my-slug',
        date: DateTime(2026, 2, 28),
      );

      expect(result.isSuccess, isTrue);
    });
  });

  group('updateStatus', () {
    test('calls PATCH endpoint with status body', () async {
      when(() => mockClient.patch<Map<String, dynamic>>(
            '/b/my-slug/appointments/appt-1/status',
            fromJson: any(named: 'fromJson'),
            body: {'status': 'CONFIRMED'},
          )).thenAnswer((_) async => const Success({}));

      final result = await repo.updateStatus(
        slug: 'my-slug',
        appointmentId: 'appt-1',
        status: AppointmentStatus.confirmed,
      );

      expect(result.isSuccess, isTrue);
    });
  });
}
```

**Step 2: Implement**

```dart
// lib/features/appointments/data/appointment_repository.dart
import 'package:flutter_http/flutter_http.dart';
import 'package:intl/intl.dart';
import 'package:scheduler_frontend/core/network/api_client.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';

class AppointmentRepository {
  final ApiClient _client;

  AppointmentRepository(this._client);

  Future<Result<List<AppointmentModel>>> getAppointments({
    required String slug,
    required DateTime date,
  }) =>
      _client.getList(
        '/b/$slug/appointments',
        fromJson: AppointmentModel.fromJson,
        queryParams: {'date': DateFormat('yyyy-MM-dd').format(date)},
      );

  Future<Result<Map<String, dynamic>>> updateStatus({
    required String slug,
    required String appointmentId,
    required AppointmentStatus status,
  }) =>
      _client.patch(
        '/b/$slug/appointments/$appointmentId/status',
        fromJson: (json) => json,
        body: {'status': status.apiValue},
      );
}
```

**Step 3: Run test — expect pass**

```bash
flutter test test/features/appointments/data/appointment_repository_test.dart
```

**Step 4: Commit**

```bash
git add lib/features/appointments/data/appointment_repository.dart test/features/appointments/data/appointment_repository_test.dart
git commit -m "feat: add AppointmentRepository"
```

---

## Task 12: AppointmentsBloc

**Files:**
- Create: `lib/features/appointments/bloc/appointments_event.dart`
- Create: `lib/features/appointments/bloc/appointments_state.dart`
- Create: `lib/features/appointments/bloc/appointments_bloc.dart`
- Create: `test/features/appointments/bloc/appointments_bloc_test.dart`

**Step 1: Events**

```dart
// lib/features/appointments/bloc/appointments_event.dart
import 'package:equatable/equatable.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';

sealed class AppointmentsEvent extends Equatable {
  const AppointmentsEvent();
  @override
  List<Object?> get props => [];
}

class AppointmentsLoadRequested extends AppointmentsEvent {
  final String slug;
  final DateTime date;
  const AppointmentsLoadRequested({required this.slug, required this.date});
  @override
  List<Object?> get props => [slug, date];
}

class AppointmentStatusChanged extends AppointmentsEvent {
  final String slug;
  final String appointmentId;
  final AppointmentStatus status;
  const AppointmentStatusChanged({
    required this.slug,
    required this.appointmentId,
    required this.status,
  });
  @override
  List<Object?> get props => [slug, appointmentId, status];
}
```

**Step 2: States**

```dart
// lib/features/appointments/bloc/appointments_state.dart
import 'package:equatable/equatable.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';

sealed class AppointmentsState extends Equatable {
  const AppointmentsState();
  @override
  List<Object?> get props => [];
}

class AppointmentsInitial extends AppointmentsState {
  const AppointmentsInitial();
}

class AppointmentsLoading extends AppointmentsState {
  const AppointmentsLoading();
}

class AppointmentsLoaded extends AppointmentsState {
  final List<AppointmentModel> appointments;
  const AppointmentsLoaded(this.appointments);

  int get total => appointments.length;
  int get pending =>
      appointments.where((a) => a.status == AppointmentStatus.pending).length;
  int get confirmed =>
      appointments.where((a) => a.status == AppointmentStatus.confirmed).length;

  @override
  List<Object?> get props => [appointments];
}

class AppointmentsError extends AppointmentsState {
  final String message;
  const AppointmentsError(this.message);
  @override
  List<Object?> get props => [message];
}
```

**Step 3: Bloc**

```dart
// lib/features/appointments/bloc/appointments_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_http/flutter_http.dart';
import 'package:scheduler_frontend/features/appointments/bloc/appointments_event.dart';
import 'package:scheduler_frontend/features/appointments/bloc/appointments_state.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_repository.dart';

class AppointmentsBloc extends Bloc<AppointmentsEvent, AppointmentsState> {
  final AppointmentRepository _repository;

  AppointmentsBloc(this._repository) : super(const AppointmentsInitial()) {
    on<AppointmentsLoadRequested>(_onLoadRequested);
    on<AppointmentStatusChanged>(_onStatusChanged);
  }

  Future<void> _onLoadRequested(
    AppointmentsLoadRequested event,
    Emitter<AppointmentsState> emit,
  ) async {
    emit(const AppointmentsLoading());
    final result = await _repository.getAppointments(
      slug: event.slug,
      date: event.date,
    );
    switch (result) {
      case Success(:final data):
        final sorted = List<AppointmentModel>.from(data)
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
        emit(AppointmentsLoaded(sorted));
      case HttpFailure(:final failure):
        emit(AppointmentsError(_message(failure)));
    }
  }

  Future<void> _onStatusChanged(
    AppointmentStatusChanged event,
    Emitter<AppointmentsState> emit,
  ) async {
    if (state is! AppointmentsLoaded) return;
    final current = state as AppointmentsLoaded;

    // Optimistic update
    final updated = current.appointments
        .map((a) => a.id == event.appointmentId
            ? AppointmentModel(
                id: a.id,
                startsAt: a.startsAt,
                endsAt: a.endsAt,
                status: event.status,
                clientName: a.clientName,
                serviceName: a.serviceName,
                serviceDurationMinutes: a.serviceDurationMinutes,
                staffId: a.staffId,
                notes: a.notes,
              )
            : a)
        .toList();
    emit(AppointmentsLoaded(updated));

    final result = await _repository.updateStatus(
      slug: event.slug,
      appointmentId: event.appointmentId,
      status: event.status,
    );

    // Rollback on failure
    if (result.isFailure) {
      emit(AppointmentsLoaded(current.appointments));
    }
  }

  String _message(AppFailure failure) => switch (failure) {
        NetworkFailure() => 'Sem conexão com a internet',
        _ => 'Não foi possível carregar os agendamentos',
      };
}
```

**Step 4: Write and run test**

```dart
// test/features/appointments/bloc/appointments_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_http/flutter_http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scheduler_frontend/features/appointments/bloc/appointments_bloc.dart';
import 'package:scheduler_frontend/features/appointments/bloc/appointments_event.dart';
import 'package:scheduler_frontend/features/appointments/bloc/appointments_state.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_repository.dart';

class MockAppointmentRepository extends Mock implements AppointmentRepository {}

final _appt = AppointmentModel(
  id: 'a1',
  startsAt: DateTime(2026, 2, 28, 9),
  endsAt: DateTime(2026, 2, 28, 9, 30),
  status: AppointmentStatus.pending,
  clientName: 'João',
);

void main() {
  late MockAppointmentRepository mockRepo;

  setUp(() => mockRepo = MockAppointmentRepository());

  blocTest<AppointmentsBloc, AppointmentsState>(
    'emits [Loading, Loaded] when appointments load succeeds',
    build: () {
      when(() => mockRepo.getAppointments(
                slug: 'my-slug',
                date: any(named: 'date'),
              ))
          .thenAnswer((_) async => Success([_appt]));
      return AppointmentsBloc(mockRepo);
    },
    act: (bloc) => bloc.add(AppointmentsLoadRequested(
      slug: 'my-slug',
      date: DateTime(2026, 2, 28),
    )),
    expect: () => [
      const AppointmentsLoading(),
      AppointmentsLoaded([_appt]),
    ],
  );

  blocTest<AppointmentsBloc, AppointmentsState>(
    'optimistically updates status and rollbacks on failure',
    build: () {
      when(() => mockRepo.updateStatus(
            slug: any(named: 'slug'),
            appointmentId: any(named: 'appointmentId'),
            status: any(named: 'status'),
          )).thenAnswer(
              (_) async => const HttpFailure(NetworkFailure('err')));
      return AppointmentsBloc(mockRepo);
    },
    seed: () => AppointmentsLoaded([_appt]),
    act: (bloc) => bloc.add(AppointmentStatusChanged(
      slug: 'my-slug',
      appointmentId: 'a1',
      status: AppointmentStatus.confirmed,
    )),
    expect: () => [
      // Optimistic
      AppointmentsLoaded([_appt.copyWith(status: AppointmentStatus.confirmed)]),
      // Rollback
      AppointmentsLoaded([_appt]),
    ],
  );
}
```

> **Note:** `_appt.copyWith(...)` requires adding a `copyWith` method to `AppointmentModel`. Add it to the class:
>
> ```dart
> AppointmentModel copyWith({AppointmentStatus? status}) => AppointmentModel(
>       id: id,
>       startsAt: startsAt,
>       endsAt: endsAt,
>       status: status ?? this.status,
>       clientName: clientName,
>       serviceName: serviceName,
>       serviceDurationMinutes: serviceDurationMinutes,
>       staffId: staffId,
>       notes: notes,
>     );
> ```

**Step 5: Run test — expect pass**

```bash
flutter test test/features/appointments/bloc/appointments_bloc_test.dart
```

**Step 6: Commit**

```bash
git add lib/features/appointments/bloc/ test/features/appointments/bloc/
git commit -m "feat: add AppointmentsBloc with optimistic status update"
```

---

## Task 13: AppointmentCard Widget

**Files:**
- Create: `lib/features/home/presentation/widgets/appointment_card.dart`
- Create: `test/features/home/presentation/widgets/appointment_card_test.dart`

**Step 1: Write the failing test**

```dart
// test/features/home/presentation/widgets/appointment_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';
import 'package:scheduler_frontend/features/home/presentation/widgets/appointment_card.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

final _pending = AppointmentModel(
  id: 'a1',
  startsAt: DateTime(2026, 2, 28, 9),
  endsAt: DateTime(2026, 2, 28, 9, 30),
  status: AppointmentStatus.pending,
  clientName: 'João Silva',
  serviceName: 'Corte',
);

void main() {
  testWidgets('shows time, client name, and service', (tester) async {
    await tester.pumpWidget(_wrap(AppointmentCard(
      appointment: _pending,
      onConfirm: null,
      onNoShow: null,
    )));

    expect(find.text('João Silva'), findsOneWidget);
    expect(find.text('Corte'), findsOneWidget);
    expect(find.text('09:00'), findsOneWidget);
    expect(find.text('Pendente'), findsOneWidget);
  });

  testWidgets('shows action buttons when PENDING and callbacks provided',
      (tester) async {
    bool confirmed = false;
    bool noShow = false;

    await tester.pumpWidget(_wrap(AppointmentCard(
      appointment: _pending,
      onConfirm: () => confirmed = true,
      onNoShow: () => noShow = true,
    )));

    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.byIcon(Icons.person_off_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.check));
    expect(confirmed, isTrue);

    await tester.tap(find.byIcon(Icons.person_off_outlined));
    expect(noShow, isTrue);
  });

  testWidgets('hides action buttons when callbacks are null', (tester) async {
    await tester.pumpWidget(_wrap(AppointmentCard(
      appointment: _pending,
      onConfirm: null,
      onNoShow: null,
    )));

    expect(find.byIcon(Icons.check), findsNothing);
  });
}
```

**Step 2: Implement**

```dart
// lib/features/home/presentation/widgets/appointment_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';

class AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback? onConfirm;
  final VoidCallback? onNoShow;

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.onConfirm,
    required this.onNoShow,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(appointment.startsAt.toLocal());
    final showActions =
        appointment.status == AppointmentStatus.pending &&
            (onConfirm != null || onNoShow != null);

    return BaseCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column
          SizedBox(
            width: 52,
            child: Text(timeStr, style: AppTypography.bodySm.copyWith(
              color: AppColors.purple300,
              fontWeight: FontWeight.w600,
            )),
          ),
          const SizedBox(width: AppSpacing.md),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appointment.clientName, style: AppTypography.bodyMd),
                if (appointment.serviceName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    appointment.serviceName!,
                    style: AppTypography.caption,
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                _StatusBadge(status: appointment.status),
              ],
            ),
          ),
          // Actions
          if (showActions)
            Row(
              children: [
                if (onConfirm != null)
                  IconButton(
                    onPressed: onConfirm,
                    icon: const Icon(Icons.check, color: AppColors.success),
                    tooltip: 'Confirmar',
                  ),
                if (onNoShow != null)
                  IconButton(
                    onPressed: onNoShow,
                    icon: const Icon(
                      Icons.person_off_outlined,
                      color: AppColors.textSecondary,
                    ),
                    tooltip: 'Não compareceu',
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final AppointmentStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      AppointmentStatus.pending => AppColors.purple300,
      AppointmentStatus.confirmed => AppColors.success,
      AppointmentStatus.cancelled => AppColors.error,
      AppointmentStatus.noShow => AppColors.textDisabled,
      AppointmentStatus.completed => AppColors.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        status.label,
        style: AppTypography.caption.copyWith(color: color),
      ),
    );
  }
}
```

> **Note:** `AppRadius` may not have an `sm` value. Check `lib/design_system/tokens/app_radius.dart` and use the appropriate token (e.g., `AppRadius.sm` or a constant like `4.0`).

**Step 3: Run test — expect pass**

```bash
flutter test test/features/home/presentation/widgets/appointment_card_test.dart
```

**Step 4: Commit**

```bash
git add lib/features/home/presentation/widgets/appointment_card.dart test/features/home/presentation/widgets/appointment_card_test.dart
git commit -m "feat: add AppointmentCard widget"
```

---

## Task 14: BusinessSelectorHeader Widget

**Files:**
- Create: `lib/features/home/presentation/widgets/business_selector_header.dart`
- Create: `test/features/home/presentation/widgets/business_selector_header_test.dart`

**Step 1: Write the failing test**

```dart
// test/features/home/presentation/widgets/business_selector_header_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/features/business/data/business_model.dart';
import 'package:scheduler_frontend/features/home/presentation/widgets/business_selector_header.dart';

const _biz1 = BusinessModel(id: '1', slug: 's1', name: 'Salão A', logo: null, timezone: 'UTC');
const _biz2 = BusinessModel(id: '2', slug: 's2', name: 'Salão B', logo: null, timezone: 'UTC');

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('shows active business name', (tester) async {
    await tester.pumpWidget(_wrap(BusinessSelectorHeader(
      active: _biz1,
      businesses: [_biz1, _biz2],
      onSelect: (_) {},
      userName: 'João',
    )));

    expect(find.text('Salão A'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
  });

  testWidgets('opens bottom sheet with business list on tap', (tester) async {
    await tester.pumpWidget(_wrap(BusinessSelectorHeader(
      active: _biz1,
      businesses: [_biz1, _biz2],
      onSelect: (_) {},
      userName: 'João',
    )));

    await tester.tap(find.text('Salão A'));
    await tester.pumpAndSettle();

    expect(find.text('Salão B'), findsOneWidget);
  });

  testWidgets('calls onSelect when a different business is tapped',
      (tester) async {
    BusinessModel? selected;

    await tester.pumpWidget(_wrap(BusinessSelectorHeader(
      active: _biz1,
      businesses: [_biz1, _biz2],
      onSelect: (b) => selected = b,
      userName: 'João',
    )));

    await tester.tap(find.text('Salão A'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salão B'));
    await tester.pumpAndSettle();

    expect(selected, equals(_biz2));
  });
}
```

**Step 2: Implement**

```dart
// lib/features/home/presentation/widgets/business_selector_header.dart
import 'package:flutter/material.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/business/data/business_model.dart';

class BusinessSelectorHeader extends StatelessWidget {
  final BusinessModel active;
  final List<BusinessModel> businesses;
  final void Function(BusinessModel) onSelect;
  final String userName;

  const BusinessSelectorHeader({
    super.key,
    required this.active,
    required this.businesses,
    required this.onSelect,
    required this.userName,
  });

  void _openSelector(BuildContext context) {
    showModalBottomSheet<BusinessModel>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ListView(
        shrinkWrap: true,
        children: businesses
            .map((b) => ListTile(
                  title: Text(b.name, style: AppTypography.bodyMd),
                  trailing: b.id == active.id
                      ? const Icon(Icons.check, color: AppColors.purple500)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    if (b.id != active.id) onSelect(b);
                  },
                ))
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: businesses.length > 1 ? () => _openSelector(context) : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(active.name, style: AppTypography.headingMd),
              if (businesses.length > 1) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
        const Spacer(),
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.purple700,
          child: Text(
            userName.isNotEmpty ? userName[0].toUpperCase() : '?',
            style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
```

**Step 3: Run test — expect pass**

```bash
flutter test test/features/home/presentation/widgets/business_selector_header_test.dart
```

**Step 4: Commit**

```bash
git add lib/features/home/presentation/widgets/business_selector_header.dart test/features/home/presentation/widgets/business_selector_header_test.dart
git commit -m "feat: add BusinessSelectorHeader widget"
```

---

## Task 15: GreetingRow + StatsSummaryRow Widgets

**Files:**
- Create: `lib/features/home/presentation/widgets/greeting_row.dart`
- Create: `lib/features/home/presentation/widgets/stats_summary_row.dart`

No tests needed for these pure display widgets.

**Step 1: GreetingRow**

```dart
// lib/features/home/presentation/widgets/greeting_row.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';

class GreetingRow extends StatelessWidget {
  final String firstName;

  const GreetingRow({super.key, required this.firstName});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, d MMM', 'pt_BR').format(DateTime.now());
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$_greeting, $firstName!',
          style: AppTypography.headingMd,
        ),
        Text(dateStr, style: AppTypography.caption),
      ],
    );
  }
}
```

**Step 2: StatsSummaryRow**

```dart
// lib/features/home/presentation/widgets/stats_summary_row.dart
import 'package:flutter/material.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';

class StatsSummaryRow extends StatelessWidget {
  final int total;
  final int pending;
  final int confirmed;

  const StatsSummaryRow({
    super.key,
    required this.total,
    required this.pending,
    required this.confirmed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(value: total, label: 'Total', color: AppColors.textPrimary),
        const SizedBox(width: AppSpacing.md),
        _StatCard(value: pending, label: 'Pendentes', color: AppColors.purple300),
        const SizedBox(width: AppSpacing.md),
        _StatCard(value: confirmed, label: 'Confirmados', color: AppColors.success),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: BaseCard(
        child: Column(
          children: [
            Text(
              '$value',
              style: AppTypography.displayLg.copyWith(color: color),
            ),
            const SizedBox(height: 4),
            Text(label, style: AppTypography.caption, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
```

**Step 3: Commit**

```bash
git add lib/features/home/presentation/widgets/
git commit -m "feat: add GreetingRow and StatsSummaryRow widgets"
```

---

## Task 16: Assemble HomePage

**Files:**
- Modify: `lib/features/home/presentation/home_page.dart`

**Step 1: Replace with bloc-driven implementation**

```dart
// lib/features/home/presentation/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scheduler_frontend/core/auth/auth_bloc.dart';
import 'package:scheduler_frontend/core/auth/auth_state.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/appointments/bloc/appointments_bloc.dart';
import 'package:scheduler_frontend/features/appointments/bloc/appointments_event.dart';
import 'package:scheduler_frontend/features/appointments/bloc/appointments_state.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';
import 'package:scheduler_frontend/features/business/bloc/business_bloc.dart';
import 'package:scheduler_frontend/features/business/bloc/business_event.dart';
import 'package:scheduler_frontend/features/business/bloc/business_state.dart';
import 'package:scheduler_frontend/features/home/presentation/widgets/appointment_card.dart';
import 'package:scheduler_frontend/features/home/presentation/widgets/business_selector_header.dart';
import 'package:scheduler_frontend/features/home/presentation/widgets/greeting_row.dart';
import 'package:scheduler_frontend/features/home/presentation/widgets/stats_summary_row.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocListener<BusinessBloc, BusinessState>(
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
          child: RefreshIndicator(
            onRefresh: () async {
              final bizState = context.read<BusinessBloc>().state;
              if (bizState is BusinessLoaded) {
                context.read<AppointmentsBloc>().add(
                      AppointmentsLoadRequested(
                        slug: bizState.active.slug,
                        date: DateTime.now(),
                      ),
                    );
              }
            },
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildHeader(context),
                      const SizedBox(height: AppSpacing.lg),
                      _buildGreeting(context),
                      const SizedBox(height: AppSpacing.lg),
                      _buildStats(context),
                      const SizedBox(height: AppSpacing.xl),
                      Text('Agendamentos de hoje', style: AppTypography.headingMd),
                      const SizedBox(height: AppSpacing.md),
                      _buildAppointmentList(context),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final userName = authState is AuthAuthenticated
        ? authState.user.firstName
        : '';

    return BlocBuilder<BusinessBloc, BusinessState>(
      builder: (context, state) {
        if (state is! BusinessLoaded) return const SizedBox.shrink();
        return BusinessSelectorHeader(
          active: state.active,
          businesses: state.businesses,
          userName: userName,
          onSelect: (biz) =>
              context.read<BusinessBloc>().add(BusinessSelected(biz)),
        );
      },
    );
  }

  Widget _buildGreeting(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final firstName = authState is AuthAuthenticated
        ? authState.user.firstName
        : '';
    return GreetingRow(firstName: firstName);
  }

  Widget _buildStats(BuildContext context) {
    return BlocBuilder<AppointmentsBloc, AppointmentsState>(
      builder: (context, state) {
        if (state is AppointmentsLoaded) {
          return StatsSummaryRow(
            total: state.total,
            pending: state.pending,
            confirmed: state.confirmed,
          );
        }
        return StatsSummaryRow(total: 0, pending: 0, confirmed: 0);
      },
    );
  }

  Widget _buildAppointmentList(BuildContext context) {
    return BlocBuilder<AppointmentsBloc, AppointmentsState>(
      builder: (context, state) {
        return switch (state) {
          AppointmentsLoading() => const Center(
              child: CircularProgressIndicator(color: AppColors.purple500),
            ),
          AppointmentsLoaded(:final appointments) when appointments.isEmpty =>
            Center(
              child: Text(
                'Nenhum agendamento hoje',
                style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary),
              ),
            ),
          AppointmentsLoaded(:final appointments) => Column(
              children: appointments
                  .map((appt) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: AppointmentCard(
                          appointment: appt,
                          // TODO: show buttons only for OWNER/MANAGER role
                          onConfirm: appt.status == AppointmentStatus.pending
                              ? () => _updateStatus(
                                    context,
                                    appt,
                                    AppointmentStatus.confirmed,
                                  )
                              : null,
                          onNoShow: appt.status == AppointmentStatus.pending
                              ? () => _updateStatus(
                                    context,
                                    appt,
                                    AppointmentStatus.noShow,
                                  )
                              : null,
                        ),
                      ))
                  .toList(),
            ),
          AppointmentsError(:final message) => Center(
              child: Text(message,
                  style: AppTypography.bodySm
                      .copyWith(color: AppColors.error)),
            ),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  void _updateStatus(
    BuildContext context,
    AppointmentModel appt,
    AppointmentStatus newStatus,
  ) {
    final bizState = context.read<BusinessBloc>().state;
    if (bizState is! BusinessLoaded) return;

    context.read<AppointmentsBloc>().add(
          AppointmentStatusChanged(
            slug: bizState.active.slug,
            appointmentId: appt.id,
            status: newStatus,
          ),
        );
  }
}
```

**Step 2: Run all tests**

```bash
flutter test
```

Expected: All tests pass.

**Step 3: Commit**

```bash
git add lib/features/home/presentation/home_page.dart
git commit -m "feat: assemble HomePage with business selector, stats, and appointment list"
```

---

## Task 17: Wire MultiBlocProvider + BlocListener in AppShell

**Files:**
- Modify: `lib/main.dart` (add BusinessBloc + AppointmentsBloc to MultiBlocProvider)
- Modify: `lib/app_shell.dart` (add BlocListener to cascade auth → business load)

**Step 1: Update main.dart — add repositories and blocs**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:scheduler_frontend/core/auth/auth_bloc.dart';
import 'package:scheduler_frontend/core/auth/auth_event.dart';
import 'package:scheduler_frontend/core/auth/auth_repository.dart';
import 'package:scheduler_frontend/core/auth/auth_state.dart';
import 'package:scheduler_frontend/core/cache/hive_cache_service.dart';
import 'package:scheduler_frontend/core/cache/preferences_service.dart';
import 'package:scheduler_frontend/core/l10n/l10n.dart';
import 'package:scheduler_frontend/core/network/api_client.dart';
import 'package:scheduler_frontend/core/router/app_router.dart';
import 'package:scheduler_frontend/design_system/tokens/app_colors.dart';
import 'package:scheduler_frontend/features/appointments/bloc/appointments_bloc.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_repository.dart';
import 'package:scheduler_frontend/features/business/bloc/business_bloc.dart';
import 'package:scheduler_frontend/features/business/bloc/business_event.dart';
import 'package:scheduler_frontend/features/business/data/business_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    businessRepo: businessRepo,
    appointmentRepo: appointmentRepo,
  ));
}

class SchedulerApp extends StatelessWidget {
  final AuthBloc authBloc;
  final BusinessRepository businessRepo;
  final AppointmentRepository appointmentRepo;

  const SchedulerApp({
    super.key,
    required this.authBloc,
    required this.businessRepo,
    required this.appointmentRepo,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: authBloc),
        BlocProvider(create: (_) => BusinessBloc(businessRepo)),
        BlocProvider(create: (_) => AppointmentsBloc(appointmentRepo)),
      ],
      child: _AppBody(authBloc: authBloc),
    );
  }
}

class _AppBody extends StatelessWidget {
  final AuthBloc authBloc;
  const _AppBody({required this.authBloc});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
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
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.purple500,
            surface: AppColors.surface,
          ),
        ),
      ),
    );
  }
}
```

**Step 2: Run all tests**

```bash
flutter test
```

Expected: All tests pass.

**Step 3: Run on device/simulator**

```bash
flutter run --dart-define=API_URL=http://localhost:3000
```

Verify:
- App starts on login screen (no stored token)
- Login with valid credentials → home screen appears
- Business selector shows in header
- Appointments for today load and display
- Confirm/No-show buttons update status optimistically

**Step 4: Final commit**

```bash
git add lib/main.dart lib/app_shell.dart
git commit -m "feat: wire MultiBlocProvider and auth→business cascade in main"
```

---

## Post-Implementation Checklist

- [ ] All 17 tasks committed
- [ ] `flutter test` passes with zero errors
- [ ] App runs on simulator with real backend
- [ ] No references to deleted `auth_service.dart` remain
- [ ] `BaseButton` updated with `isLoading` param if needed (Task 8 note)
- [ ] `AppRadius.sm` token exists or fallback used in `AppointmentCard` (Task 13 note)
- [ ] `intl` date formatting with `pt_BR` locale initialized in `main()` (add `await initializeDateFormatting('pt_BR', null)` before `runApp`)
