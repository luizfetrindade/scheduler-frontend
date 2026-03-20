# Services Feature Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implementar a aba de Serviços completa (CRUD) e o seletor de serviço opcional no formulário de agendamento.

**Architecture:** `ServicesBloc` global providenciado em `main.dart`, disparado por `BlocListener<BusinessBloc>` quando o negócio ativo muda. A aba de serviços consome o BLoC para listar, criar, editar, desativar e deletar. O `CreateAppointmentSheet` lê a lista já carregada para o dropdown opcional de serviço, que preenche duração automaticamente.

**Tech Stack:** Flutter/Dart, flutter_bloc ^9, bloc_test, mocktail, flutter_http (ApiClient), Dio (para DELETE via raw Dio).

---

## Task 1: ServiceModel

**Files:**
- Create: `lib/features/services/data/service_model.dart`
- Create: `test/features/services/data/service_model_test.dart`

**Step 1: Escrever o teste que falha**

```dart
// test/features/services/data/service_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/features/services/data/service_model.dart';

void main() {
  group('ServiceModel', () {
    final fullJson = {
      'id': 'svc-1',
      'name': 'Corte de cabelo',
      'description': 'Corte masculino',
      'price': 45.0,
      'durationMinutes': 30,
      'isActive': true,
    };

    test('fromJson parses all fields', () {
      final svc = ServiceModel.fromJson(fullJson);
      expect(svc.id, 'svc-1');
      expect(svc.name, 'Corte de cabelo');
      expect(svc.description, 'Corte masculino');
      expect(svc.price, 45.0);
      expect(svc.durationMinutes, 30);
      expect(svc.isActive, true);
    });

    test('fromJson handles optional fields as null', () {
      final json = {
        'id': 'svc-2',
        'name': 'Consulta',
        'isActive': false,
      };
      final svc = ServiceModel.fromJson(json);
      expect(svc.description, isNull);
      expect(svc.price, isNull);
      expect(svc.durationMinutes, isNull);
      expect(svc.isActive, false);
    });

    test('copyWith returns new instance with updated fields', () {
      final svc = ServiceModel.fromJson(fullJson);
      final updated = svc.copyWith(name: 'Barba', isActive: false);
      expect(updated.name, 'Barba');
      expect(updated.isActive, false);
      expect(updated.id, svc.id); // unchanged
      expect(updated.price, svc.price); // unchanged
    });
  });
}
```

**Step 2: Rodar o teste para confirmar que falha**

```bash
cd /Users/luizfelipetrindade/Desktop/Scheduler-v1/scheduler-frontend
flutter test test/features/services/data/service_model_test.dart
```
Esperado: FAIL — "Target of URI doesn't exist"

**Step 3: Implementar o modelo**

```dart
// lib/features/services/data/service_model.dart
import 'package:equatable/equatable.dart';

class ServiceModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final double? price;
  final int? durationMinutes;
  final bool isActive;

  const ServiceModel({
    required this.id,
    required this.name,
    this.description,
    this.price,
    this.durationMinutes,
    required this.isActive,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) => ServiceModel(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        price: (json['price'] as num?)?.toDouble(),
        durationMinutes: json['durationMinutes'] as int?,
        isActive: json['isActive'] as bool? ?? true,
      );

  ServiceModel copyWith({
    String? name,
    String? description,
    double? price,
    int? durationMinutes,
    bool? isActive,
  }) =>
      ServiceModel(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        price: price ?? this.price,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        isActive: isActive ?? this.isActive,
      );

  @override
  List<Object?> get props => [id, name, description, price, durationMinutes, isActive];
}
```

**Step 4: Rodar o teste para confirmar que passa**

```bash
flutter test test/features/services/data/service_model_test.dart
```
Esperado: PASS (3 testes)

**Step 5: Commit**

```bash
git add lib/features/services/data/service_model.dart test/features/services/data/service_model_test.dart
git commit -m "feat: add ServiceModel with fromJson and copyWith"
```

---

## Task 2: ApiClient.delete + ServiceRepository

**Files:**
- Modify: `lib/core/network/api_client.dart` (adicionar método `delete`)
- Create: `lib/features/services/data/service_repository.dart`
- Create: `test/features/services/data/service_repository_test.dart`

**Step 1: Escrever o teste que falha**

```dart
// test/features/services/data/service_repository_test.dart
import 'package:flutter_http/flutter_http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scheduler_frontend/core/network/api_client.dart';
import 'package:scheduler_frontend/features/services/data/service_model.dart';
import 'package:scheduler_frontend/features/services/data/service_repository.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockClient;
  late ServiceRepository repo;

  final svc = ServiceModel(
    id: 'svc-1',
    name: 'Corte',
    isActive: true,
  );

  setUp(() {
    mockClient = MockApiClient();
    repo = ServiceRepository(mockClient);
  });

  group('ServiceRepository', () {
    test('getServices calls getList with correct path', () async {
      when(() => mockClient.getList<ServiceModel>(
            any(),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => Success([svc]));

      final result = await repo.getServices(businessId: 'biz-1');
      expect(result, isA<Success<List<ServiceModel>>>());
      verify(() => mockClient.getList<ServiceModel>(
            '/businesses/biz-1/services',
            fromJson: any(named: 'fromJson'),
          )).called(1);
    });

    test('createService calls post with correct body', () async {
      when(() => mockClient.post<ServiceModel>(
            any(),
            fromJson: any(named: 'fromJson'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => Success(svc));

      final result = await repo.createService(
        businessId: 'biz-1',
        name: 'Corte',
        price: 45.0,
        durationMinutes: 30,
      );
      expect(result, isA<Success<ServiceModel>>());
    });

    test('updateService calls patch with correct path and body', () async {
      when(() => mockClient.patch<ServiceModel>(
            any(),
            fromJson: any(named: 'fromJson'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => Success(svc));

      final result = await repo.updateService(
        businessId: 'biz-1',
        serviceId: 'svc-1',
        isActive: false,
      );
      expect(result, isA<Success<ServiceModel>>());
    });

    test('deleteService calls delete with correct path', () async {
      when(() => mockClient.delete(any()))
          .thenAnswer((_) async => const Success(null));

      final result = await repo.deleteService(
        businessId: 'biz-1',
        serviceId: 'svc-1',
      );
      expect(result, isA<Success<void>>());
    });
  });
}
```

**Step 2: Rodar o teste para confirmar que falha**

```bash
flutter test test/features/services/data/service_repository_test.dart
```
Esperado: FAIL

**Step 3: Adicionar `delete` ao ApiClient**

No final da seção "Public API" em `lib/core/network/api_client.dart`, antes do método `patch`, adicionar:

```dart
/// DELETE via raw Dio. Backend returns 204 No Content on success.
Future<Result<void>> delete(String path) async {
  final token = await tokenStorage.getAccessToken();
  try {
    await _rawDio.delete<void>(
      path,
      options: Options(headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      }),
    );
    return const Success(null);
  } on DioException catch (e) {
    final code = e.response?.statusCode;
    if (code == 401) return const HttpFailure(UnauthorizedFailure('Unauthorized'));
    if (code == 404) return const HttpFailure(NotFoundFailure('Not found'));
    return HttpFailure(
        ServerFailure(e.message ?? 'Server error', statusCode: code ?? 500));
  } catch (e) {
    return HttpFailure(UnknownFailure(e.toString()));
  }
}
```

**Step 4: Criar o ServiceRepository**

```dart
// lib/features/services/data/service_repository.dart
import 'package:flutter_http/flutter_http.dart';
import 'package:scheduler_frontend/core/network/api_client.dart';
import 'package:scheduler_frontend/features/services/data/service_model.dart';

class ServiceRepository {
  final ApiClient _client;

  ServiceRepository(this._client);

  Future<Result<List<ServiceModel>>> getServices({
    required String businessId,
  }) =>
      _client.getList(
        '/businesses/$businessId/services',
        fromJson: ServiceModel.fromJson,
      );

  Future<Result<ServiceModel>> createService({
    required String businessId,
    required String name,
    String? description,
    double? price,
    int? durationMinutes,
  }) =>
      _client.post(
        '/businesses/$businessId/services',
        fromJson: ServiceModel.fromJson,
        body: {
          'name': name,
          if (description != null && description.isNotEmpty)
            'description': description,
          if (price != null) 'price': price,
          if (durationMinutes != null) 'durationMinutes': durationMinutes,
        },
      );

  Future<Result<ServiceModel>> updateService({
    required String businessId,
    required String serviceId,
    String? name,
    String? description,
    double? price,
    int? durationMinutes,
    bool? isActive,
  }) =>
      _client.patch(
        '/businesses/$businessId/services/$serviceId',
        fromJson: ServiceModel.fromJson,
        body: {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (price != null) 'price': price,
          if (durationMinutes != null) 'durationMinutes': durationMinutes,
          if (isActive != null) 'isActive': isActive,
        },
      );

  Future<Result<void>> deleteService({
    required String businessId,
    required String serviceId,
  }) =>
      _client.delete('/businesses/$businessId/services/$serviceId');
}
```

**Step 5: Rodar o teste para confirmar que passa**

```bash
flutter test test/features/services/data/service_repository_test.dart
```
Esperado: PASS (4 testes)

**Step 6: Commit**

```bash
git add lib/core/network/api_client.dart \
        lib/features/services/data/service_repository.dart \
        test/features/services/data/service_repository_test.dart
git commit -m "feat: add ApiClient.delete and ServiceRepository"
```

---

## Task 3: ServicesBloc Events e States

**Files:**
- Create: `lib/features/services/bloc/services_event.dart`
- Create: `lib/features/services/bloc/services_state.dart`

**Step 1: Criar os Events**

```dart
// lib/features/services/bloc/services_event.dart
import 'package:equatable/equatable.dart';

sealed class ServicesEvent extends Equatable {
  const ServicesEvent();
  @override
  List<Object?> get props => [];
}

class ServicesLoadRequested extends ServicesEvent {
  final String businessId;
  const ServicesLoadRequested(this.businessId);
  @override
  List<Object?> get props => [businessId];
}

class ServiceCreateRequested extends ServicesEvent {
  final String businessId;
  final String name;
  final String? description;
  final double? price;
  final int? durationMinutes;

  const ServiceCreateRequested({
    required this.businessId,
    required this.name,
    this.description,
    this.price,
    this.durationMinutes,
  });

  @override
  List<Object?> get props =>
      [businessId, name, description, price, durationMinutes];
}

class ServiceUpdateRequested extends ServicesEvent {
  final String businessId;
  final String serviceId;
  final String? name;
  final String? description;
  final double? price;
  final int? durationMinutes;
  final bool? isActive;

  const ServiceUpdateRequested({
    required this.businessId,
    required this.serviceId,
    this.name,
    this.description,
    this.price,
    this.durationMinutes,
    this.isActive,
  });

  @override
  List<Object?> get props =>
      [businessId, serviceId, name, description, price, durationMinutes, isActive];
}

class ServiceDeleteRequested extends ServicesEvent {
  final String businessId;
  final String serviceId;

  const ServiceDeleteRequested({
    required this.businessId,
    required this.serviceId,
  });

  @override
  List<Object?> get props => [businessId, serviceId];
}
```

**Step 2: Criar os States**

```dart
// lib/features/services/bloc/services_state.dart
import 'package:equatable/equatable.dart';
import 'package:scheduler_frontend/features/services/data/service_model.dart';

sealed class ServicesState extends Equatable {
  const ServicesState();
  @override
  List<Object?> get props => [];
}

class ServicesInitial extends ServicesState {
  const ServicesInitial();
}

class ServicesLoading extends ServicesState {
  const ServicesLoading();
}

class ServicesLoaded extends ServicesState {
  final List<ServiceModel> services;
  const ServicesLoaded(this.services);
  @override
  List<Object?> get props => [services];
}

/// Used during create/update/delete — mantém a lista visível
class ServicesActionInProgress extends ServicesState {
  final List<ServiceModel> services;
  const ServicesActionInProgress(this.services);
  @override
  List<Object?> get props => [services];
}

class ServicesError extends ServicesState {
  final String message;
  final List<ServiceModel> services;
  const ServicesError(this.message, {this.services = const []});
  @override
  List<Object?> get props => [message, services];
}
```

**Step 3: Commit**

```bash
git add lib/features/services/bloc/services_event.dart \
        lib/features/services/bloc/services_state.dart
git commit -m "feat: add ServicesBloc events and states"
```

---

## Task 4: ServicesBloc

**Files:**
- Create: `lib/features/services/bloc/services_bloc.dart`
- Create: `test/features/services/bloc/services_bloc_test.dart`

**Step 1: Escrever os testes que falham**

```dart
// test/features/services/bloc/services_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_http/flutter_http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scheduler_frontend/features/services/bloc/services_bloc.dart';
import 'package:scheduler_frontend/features/services/bloc/services_event.dart';
import 'package:scheduler_frontend/features/services/bloc/services_state.dart';
import 'package:scheduler_frontend/features/services/data/service_model.dart';
import 'package:scheduler_frontend/features/services/data/service_repository.dart';

class MockServiceRepository extends Mock implements ServiceRepository {}

final _svc1 = ServiceModel(id: 's1', name: 'Corte', isActive: true);
final _svc2 = ServiceModel(id: 's2', name: 'Barba', isActive: true);

void main() {
  late MockServiceRepository mockRepo;

  setUp(() {
    mockRepo = MockServiceRepository();
  });

  blocTest<ServicesBloc, ServicesState>(
    'emits [Loading, Loaded] on ServicesLoadRequested success',
    build: () {
      when(() => mockRepo.getServices(businessId: any(named: 'businessId')))
          .thenAnswer((_) async => Success([_svc1, _svc2]));
      return ServicesBloc(mockRepo);
    },
    act: (b) => b.add(const ServicesLoadRequested('biz-1')),
    expect: () => [
      const ServicesLoading(),
      ServicesLoaded([_svc1, _svc2]),
    ],
  );

  blocTest<ServicesBloc, ServicesState>(
    'emits [Loading, Error] on ServicesLoadRequested failure',
    build: () {
      when(() => mockRepo.getServices(businessId: any(named: 'businessId')))
          .thenAnswer((_) async =>
              const HttpFailure(NetworkFailure('no connection')));
      return ServicesBloc(mockRepo);
    },
    act: (b) => b.add(const ServicesLoadRequested('biz-1')),
    expect: () => [
      const ServicesLoading(),
      const ServicesError('Sem conexão com a internet'),
    ],
  );

  blocTest<ServicesBloc, ServicesState>(
    'emits [ActionInProgress, Loaded] on ServiceCreateRequested success',
    seed: () => ServicesLoaded([_svc1]),
    build: () {
      when(() => mockRepo.createService(
                businessId: any(named: 'businessId'),
                name: any(named: 'name'),
                description: any(named: 'description'),
                price: any(named: 'price'),
                durationMinutes: any(named: 'durationMinutes'),
              ))
          .thenAnswer((_) async => Success(_svc2));
      return ServicesBloc(mockRepo);
    },
    act: (b) => b.add(const ServiceCreateRequested(
      businessId: 'biz-1',
      name: 'Barba',
    )),
    expect: () => [
      ServicesActionInProgress([_svc1]),
      ServicesLoaded([_svc1, _svc2]),
    ],
  );

  blocTest<ServicesBloc, ServicesState>(
    'emits [ActionInProgress, Loaded] on ServiceDeleteRequested success — removes from list',
    seed: () => ServicesLoaded([_svc1, _svc2]),
    build: () {
      when(() => mockRepo.deleteService(
                businessId: any(named: 'businessId'),
                serviceId: any(named: 'serviceId'),
              ))
          .thenAnswer((_) async => const Success(null));
      return ServicesBloc(mockRepo);
    },
    act: (b) => b.add(const ServiceDeleteRequested(
      businessId: 'biz-1',
      serviceId: 's1',
    )),
    expect: () => [
      ServicesActionInProgress([_svc1, _svc2]),
      ServicesLoaded([_svc2]),
    ],
  );

  blocTest<ServicesBloc, ServicesState>(
    'emits [ActionInProgress, Loaded] on ServiceUpdateRequested — updates in list',
    seed: () => ServicesLoaded([_svc1, _svc2]),
    build: () {
      final updated = _svc1.copyWith(isActive: false);
      when(() => mockRepo.updateService(
                businessId: any(named: 'businessId'),
                serviceId: any(named: 'serviceId'),
                isActive: any(named: 'isActive'),
              ))
          .thenAnswer((_) async => Success(updated));
      return ServicesBloc(mockRepo);
    },
    act: (b) => b.add(const ServiceUpdateRequested(
      businessId: 'biz-1',
      serviceId: 's1',
      isActive: false,
    )),
    expect: () => [
      ServicesActionInProgress([_svc1, _svc2]),
      isA<ServicesLoaded>(),
    ],
  );
}
```

**Step 2: Rodar o teste para confirmar que falha**

```bash
flutter test test/features/services/bloc/services_bloc_test.dart
```
Esperado: FAIL

**Step 3: Implementar o ServicesBloc**

```dart
// lib/features/services/bloc/services_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_http/flutter_http.dart';
import 'package:scheduler_frontend/features/services/bloc/services_event.dart';
import 'package:scheduler_frontend/features/services/bloc/services_state.dart';
import 'package:scheduler_frontend/features/services/data/service_model.dart';
import 'package:scheduler_frontend/features/services/data/service_repository.dart';

class ServicesBloc extends Bloc<ServicesEvent, ServicesState> {
  final ServiceRepository _repository;

  ServicesBloc(this._repository) : super(const ServicesInitial()) {
    on<ServicesLoadRequested>(_onLoad);
    on<ServiceCreateRequested>(_onCreate);
    on<ServiceUpdateRequested>(_onUpdate);
    on<ServiceDeleteRequested>(_onDelete);
  }

  List<ServiceModel> get _currentList => switch (state) {
        ServicesLoaded(:final services) => services,
        ServicesActionInProgress(:final services) => services,
        ServicesError(:final services) => services,
        _ => const [],
      };

  Future<void> _onLoad(
    ServicesLoadRequested event,
    Emitter<ServicesState> emit,
  ) async {
    emit(const ServicesLoading());
    final result = await _repository.getServices(businessId: event.businessId);
    switch (result) {
      case Success(:final data):
        emit(ServicesLoaded(data));
      case HttpFailure(:final failure):
        emit(ServicesError(_message(failure)));
    }
  }

  Future<void> _onCreate(
    ServiceCreateRequested event,
    Emitter<ServicesState> emit,
  ) async {
    final current = _currentList;
    emit(ServicesActionInProgress(current));

    final result = await _repository.createService(
      businessId: event.businessId,
      name: event.name,
      description: event.description,
      price: event.price,
      durationMinutes: event.durationMinutes,
    );

    switch (result) {
      case Success(:final data):
        emit(ServicesLoaded([...current, data]));
      case HttpFailure(:final failure):
        emit(ServicesError(_mutationMessage(failure), services: current));
    }
  }

  Future<void> _onUpdate(
    ServiceUpdateRequested event,
    Emitter<ServicesState> emit,
  ) async {
    final current = _currentList;
    emit(ServicesActionInProgress(current));

    final result = await _repository.updateService(
      businessId: event.businessId,
      serviceId: event.serviceId,
      name: event.name,
      description: event.description,
      price: event.price,
      durationMinutes: event.durationMinutes,
      isActive: event.isActive,
    );

    switch (result) {
      case Success(:final data):
        final updated = current
            .map((s) => s.id == data.id ? data : s)
            .toList();
        emit(ServicesLoaded(updated));
      case HttpFailure(:final failure):
        emit(ServicesError(_mutationMessage(failure), services: current));
    }
  }

  Future<void> _onDelete(
    ServiceDeleteRequested event,
    Emitter<ServicesState> emit,
  ) async {
    final current = _currentList;
    emit(ServicesActionInProgress(current));

    final result = await _repository.deleteService(
      businessId: event.businessId,
      serviceId: event.serviceId,
    );

    switch (result) {
      case Success():
        final updated =
            current.where((s) => s.id != event.serviceId).toList();
        emit(ServicesLoaded(updated));
      case HttpFailure(:final failure):
        emit(ServicesError(_mutationMessage(failure), services: current));
    }
  }

  String _message(AppFailure failure) => switch (failure) {
        NetworkFailure() => 'Sem conexão com a internet',
        _ => 'Não foi possível carregar os serviços',
      };

  String _mutationMessage(AppFailure failure) => switch (failure) {
        NetworkFailure() => 'Sem conexão com a internet',
        _ => 'Não foi possível completar a ação. Tente novamente.',
      };
}
```

**Step 4: Rodar os testes para confirmar que passam**

```bash
flutter test test/features/services/bloc/services_bloc_test.dart
```
Esperado: PASS (5 testes)

**Step 5: Commit**

```bash
git add lib/features/services/bloc/services_bloc.dart \
        test/features/services/bloc/services_bloc_test.dart
git commit -m "feat: implement ServicesBloc with CRUD operations"
```

---

## Task 5: Wiring no main.dart

**Files:**
- Modify: `lib/main.dart`

**Contexto:** Adicionar `ServiceRepository` e `ServicesBloc` ao setup global. Quando `BusinessBloc` emite `BusinessLoaded`, disparar `ServicesLoadRequested` com o `business.id` ativo.

**Step 1: Modificar main.dart**

No `main()`, após `final appointmentRepo = AppointmentRepository(apiClient);`:

```dart
final serviceRepo = ServiceRepository(apiClient);
```

E adicionar `serviceRepo` ao `SchedulerApp`:

```dart
runApp(SchedulerApp(
  authBloc: authBloc,
  businessRepo: businessRepo,
  appointmentRepo: appointmentRepo,
  serviceRepo: serviceRepo,        // novo
));
```

No `SchedulerApp`, adicionar campo e parâmetro:

```dart
final ServiceRepository serviceRepo;

const SchedulerApp({
  super.key,
  required this.authBloc,
  required this.businessRepo,
  required this.appointmentRepo,
  required this.serviceRepo,      // novo
});
```

No `build` do `SchedulerApp`, adicionar ao `MultiBlocProvider`:

```dart
BlocProvider(create: (_) => ServicesBloc(serviceRepo)),
```

No `_AppBody.build`, o `BlocListener<AuthBloc>` que dispara `BusinessLoadRequested` permanece. **Adicionar** um `BlocListener<BusinessBloc>` para disparar serviços quando o negócio ativo muda. Trocar `BlocListener` por `MultiBlocListener`:

```dart
// Dentro de _AppBody.build(), substituir o BlocListener simples por:
return MultiBlocListener(
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
  ],
  child: MaterialApp.router( /* ... igual ao atual */ ),
);
```

Adicionar os imports necessários:
```dart
import 'package:scheduler_frontend/features/services/bloc/services_bloc.dart';
import 'package:scheduler_frontend/features/services/bloc/services_event.dart';
import 'package:scheduler_frontend/features/services/data/service_repository.dart';
```

**Step 2: Verificar que o app compila**

```bash
flutter analyze
```
Esperado: sem erros

**Step 3: Commit**

```bash
git add lib/main.dart
git commit -m "feat: wire ServicesBloc globally, trigger on business change"
```

---

## Task 6: ServiceCard Widget

**Files:**
- Create: `lib/features/services/presentation/widgets/service_card.dart`

**Contexto:** Card que exibe nome, preço, duração, badge "Inativo" se `isActive == false`. Ações: editar (ícone), menu popup com "Desativar"/"Reativar" e "Excluir".

**Step 1: Implementar o widget**

```dart
// lib/features/services/presentation/widgets/service_card.dart
import 'package:flutter/material.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/services/data/service_model.dart';

class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  const ServiceCard({
    super.key,
    required this.service,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: service.isActive ? 1.0 : 0.5,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.surfaceHigh),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        service.name,
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (!service.isActive) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceHigh,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            'Inativo',
                            style: AppTypography.bodyXs.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  _buildSubtitle(),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              color: AppColors.textSecondary,
              onPressed: onEdit,
              tooltip: 'Editar',
            ),
            PopupMenuButton<_ServiceAction>(
              icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textSecondary),
              color: AppColors.surface,
              onSelected: (action) {
                if (action == _ServiceAction.toggleActive) onToggleActive();
                if (action == _ServiceAction.delete) onDelete();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: _ServiceAction.toggleActive,
                  child: Text(
                    service.isActive ? 'Desativar' : 'Reativar',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: _ServiceAction.delete,
                  child: Text(
                    'Excluir',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    final parts = <String>[];
    if (service.price != null) {
      parts.add('R\$ ${service.price!.toStringAsFixed(2).replaceAll('.', ',')}');
    }
    if (service.durationMinutes != null) {
      parts.add(_formatDuration(service.durationMinutes!));
    }
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      parts.join(' · '),
      style: AppTypography.bodyXs.copyWith(color: AppColors.textSecondary),
    );
  }

  static String _formatDuration(int min) {
    if (min < 60) return '${min}min';
    if (min % 60 == 0) return '${min ~/ 60}h';
    return '${min ~/ 60}h ${min % 60}min';
  }
}

enum _ServiceAction { toggleActive, delete }
```

**Step 2: Verificar que compila**

```bash
flutter analyze lib/features/services/presentation/widgets/service_card.dart
```

**Step 3: Commit**

```bash
git add lib/features/services/presentation/widgets/service_card.dart
git commit -m "feat: add ServiceCard widget with edit, deactivate, delete actions"
```

---

## Task 7: ServiceFormSheet

**Files:**
- Create: `lib/features/services/presentation/widgets/service_form_sheet.dart`

**Contexto:** BottomSheet reutilizável para criar e editar serviços. Recebe `ServiceModel? initial` — se não nulo, pré-preenche para edição.

**Step 1: Implementar o widget**

```dart
// lib/features/services/presentation/widgets/service_form_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/business/bloc/business_bloc.dart';
import 'package:scheduler_frontend/features/business/bloc/business_state.dart';
import 'package:scheduler_frontend/features/services/bloc/services_bloc.dart';
import 'package:scheduler_frontend/features/services/bloc/services_event.dart';
import 'package:scheduler_frontend/features/services/bloc/services_state.dart';
import 'package:scheduler_frontend/features/services/data/service_model.dart';

class ServiceFormSheet extends StatefulWidget {
  /// Se não nulo, modo edição.
  final ServiceModel? initial;

  const ServiceFormSheet({super.key, this.initial});

  @override
  State<ServiceFormSheet> createState() => _ServiceFormSheetState();
}

class _ServiceFormSheetState extends State<ServiceFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _durationCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initial?.name ?? '');
    _priceCtrl = TextEditingController(
      text: widget.initial?.price?.toStringAsFixed(2) ?? '',
    );
    _durationCtrl = TextEditingController(
      text: widget.initial?.durationMinutes?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.initial != null;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ServicesBloc, ServicesState>(
      listener: (context, state) {
        if (state is ServicesLoaded || state is ServicesError) {
          Navigator.of(context).pop();
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isEditing ? 'Editar Serviço' : 'Novo Serviço',
                  style: AppTypography.headingMd.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: _inputDecoration('Nome do serviço'),
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 2) {
                      return 'Nome deve ter pelo menos 2 caracteres';
                    }
                    if (v.trim().length > 100) {
                      return 'Nome deve ter no máximo 100 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _priceCtrl,
                  decoration: _inputDecoration('Preço (opcional)'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final parsed =
                        double.tryParse(v.trim().replaceAll(',', '.'));
                    if (parsed == null || parsed <= 0) {
                      return 'Preço inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _durationCtrl,
                  decoration: _inputDecoration('Duração em minutos (opcional)'),
                  keyboardType: TextInputType.number,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final mins = int.tryParse(v.trim());
                    if (mins == null || mins < 5 || mins > 480) {
                      return 'Duração deve ser entre 5 e 480 minutos';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                BlocBuilder<ServicesBloc, ServicesState>(
                  builder: (context, state) {
                    final isLoading = state is ServicesActionInProgress;
                    return ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple500,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_isEditing ? 'Salvar' : 'Criar Serviço'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final businessState = context.read<BusinessBloc>().state;
    if (businessState is! BusinessLoaded) return;
    final businessId = businessState.active.id;

    final name = _nameCtrl.text.trim();
    final price = _priceCtrl.text.trim().isEmpty
        ? null
        : double.tryParse(_priceCtrl.text.trim().replaceAll(',', '.'));
    final duration = _durationCtrl.text.trim().isEmpty
        ? null
        : int.tryParse(_durationCtrl.text.trim());

    if (_isEditing) {
      context.read<ServicesBloc>().add(ServiceUpdateRequested(
            businessId: businessId,
            serviceId: widget.initial!.id,
            name: name,
            price: price,
            durationMinutes: duration,
          ));
    } else {
      context.read<ServicesBloc>().add(ServiceCreateRequested(
            businessId: businessId,
            name: name,
            price: price,
            durationMinutes: duration,
          ));
    }
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle:
            AppTypography.bodySm.copyWith(color: AppColors.textSecondary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.surfaceHigh),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.purple500),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        filled: true,
        fillColor: AppColors.surface,
      );
}
```

**Step 2: Verificar que compila**

```bash
flutter analyze lib/features/services/presentation/widgets/service_form_sheet.dart
```

**Step 3: Commit**

```bash
git add lib/features/services/presentation/widgets/service_form_sheet.dart
git commit -m "feat: add ServiceFormSheet for create and edit"
```

---

## Task 8: ServicesPage

**Files:**
- Modify: `lib/features/services/presentation/services_page.dart` (substituir placeholder)

**Step 1: Implementar a página**

```dart
// lib/features/services/presentation/services_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/business/bloc/business_bloc.dart';
import 'package:scheduler_frontend/features/business/bloc/business_state.dart';
import 'package:scheduler_frontend/features/services/bloc/services_bloc.dart';
import 'package:scheduler_frontend/features/services/bloc/services_event.dart';
import 'package:scheduler_frontend/features/services/bloc/services_state.dart';
import 'package:scheduler_frontend/features/services/data/service_model.dart';
import 'package:scheduler_frontend/features/services/presentation/widgets/service_card.dart';
import 'package:scheduler_frontend/features/services/presentation/widgets/service_form_sheet.dart';

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Serviços',
          style: AppTypography.headingMd.copyWith(color: AppColors.textPrimary),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.purple500,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(context, initial: null),
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<ServicesBloc, ServicesState>(
        listener: (context, state) {
          if (state is ServicesError && state.services.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ServicesLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.purple500),
            );
          }

          final services = switch (state) {
            ServicesLoaded(:final services) => services,
            ServicesActionInProgress(:final services) => services,
            ServicesError(:final services) => services,
            _ => <ServiceModel>[],
          };

          if (services.isEmpty && state is! ServicesLoading) {
            return _buildEmptyState(context);
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: services.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) {
              final svc = services[i];
              return ServiceCard(
                service: svc,
                onEdit: () => _openForm(context, initial: svc),
                onToggleActive: () =>
                    _toggleActive(context, svc),
                onDelete: () => _confirmDelete(context, svc),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cut_outlined,
              size: 48, color: AppColors.textDisabled),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Nenhum serviço cadastrado',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => _openForm(context, initial: null),
            child: Text(
              'Adicionar serviço',
              style: AppTypography.bodySm.copyWith(
                color: AppColors.purple500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openForm(BuildContext context, {required ServiceModel? initial}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<ServicesBloc>()),
          BlocProvider.value(value: context.read<BusinessBloc>()),
        ],
        child: ServiceFormSheet(initial: initial),
      ),
    );
  }

  void _toggleActive(BuildContext context, ServiceModel svc) {
    final businessState = context.read<BusinessBloc>().state;
    if (businessState is! BusinessLoaded) return;

    context.read<ServicesBloc>().add(ServiceUpdateRequested(
          businessId: businessState.active.id,
          serviceId: svc.id,
          isActive: !svc.isActive,
        ));
  }

  Future<void> _confirmDelete(BuildContext context, ServiceModel svc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Excluir serviço',
          style: AppTypography.headingSm.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'Tem certeza que deseja excluir "${svc.name}"? Esta ação não pode ser desfeita.',
          style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancelar',
              style: AppTypography.bodySm.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Excluir',
              style: AppTypography.bodySm.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final businessState = context.read<BusinessBloc>().state;
      if (businessState is! BusinessLoaded) return;

      context.read<ServicesBloc>().add(ServiceDeleteRequested(
            businessId: businessState.active.id,
            serviceId: svc.id,
          ));
    }
  }
}
```

**Step 2: Verificar que compila**

```bash
flutter analyze lib/features/services/
```

**Step 3: Commit**

```bash
git add lib/features/services/presentation/services_page.dart
git commit -m "feat: implement ServicesPage with list, empty state, CRUD actions"
```

---

## Task 9: serviceId no Agendamento

**Files:**
- Modify: `lib/features/appointments/bloc/schedule_event.dart`
- Modify: `lib/features/appointments/data/appointment_repository.dart`
- Modify: `lib/features/appointments/bloc/schedule_bloc.dart`

**Contexto:** Adicionar `serviceId: String?` ao evento de criação de agendamento e passar para o repositório.

**Step 1: Adicionar `serviceId` ao `ScheduleAppointmentCreateRequested`**

Em `lib/features/appointments/bloc/schedule_event.dart`, na classe `ScheduleAppointmentCreateRequested`:

```dart
// Adicionar o campo:
final String? serviceId;

// Atualizar o construtor:
const ScheduleAppointmentCreateRequested({
  required this.clientName,
  required this.clientEmail,
  required this.startsAt,
  this.durationMinutes = 60,
  this.notes,
  this.recurrenceRule,
  this.serviceId,           // novo
});

// Atualizar props:
@override
List<Object?> get props =>
    [clientName, clientEmail, startsAt, durationMinutes, notes, recurrenceRule, serviceId];
```

**Step 2: Adicionar `serviceId` ao `AppointmentRepository.createAppointment`**

Em `lib/features/appointments/data/appointment_repository.dart`:

```dart
Future<Result<AppointmentModel>> createAppointment({
  required String slug,
  required String clientName,
  required String clientEmail,
  required DateTime startsAt,
  int durationMinutes = 60,
  String? notes,
  String? recurrenceRule,
  String? serviceId,           // novo parâmetro
}) =>
    _client.post(
      '/b/$slug/appointments',
      fromJson: AppointmentModel.fromJson,
      body: {
        'startsAt': startsAt.toUtc().toIso8601String(),
        'durationMinutes': durationMinutes,
        'clientName': clientName,
        'clientEmail': clientEmail,
        'bookedBy': 'BUSINESS',
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (recurrenceRule != null) 'recurrenceRule': recurrenceRule,
        if (serviceId != null) 'serviceId': serviceId,    // novo
      },
    );
```

**Step 3: Passar `serviceId` no ScheduleBloc**

Em `lib/features/appointments/bloc/schedule_bloc.dart`, no método `_onCreateRequested`:

```dart
final result = await _repository.createAppointment(
  slug: _slug,
  clientName: event.clientName,
  clientEmail: event.clientEmail,
  startsAt: event.startsAt,
  durationMinutes: event.durationMinutes,
  notes: event.notes,
  recurrenceRule: event.recurrenceRule,
  serviceId: event.serviceId,    // novo
);
```

**Step 4: Verificar que compila e testes existentes passam**

```bash
flutter analyze
flutter test test/features/appointments/
```
Esperado: PASS (testes existentes sem regressão)

**Step 5: Commit**

```bash
git add lib/features/appointments/bloc/schedule_event.dart \
        lib/features/appointments/data/appointment_repository.dart \
        lib/features/appointments/bloc/schedule_bloc.dart
git commit -m "feat: add optional serviceId to appointment creation"
```

---

## Task 10: Service Dropdown no CreateAppointmentSheet

**Files:**
- Modify: `lib/features/appointments/presentation/widgets/create_appointment_sheet.dart`

**Contexto:** Adicionar dropdown "Serviço (opcional)" acima do campo de nome do cliente. Ao selecionar, preenche duração automaticamente. Ao limpar, volta duração ao padrão (60 min).

**Step 1: Adicionar state e lógica ao `_CreateAppointmentSheetState`**

No topo do state, adicionar:
```dart
String? _selectedServiceId;
```

**Step 2: Adicionar o widget `_buildServiceSelector` e inseri-lo no `build`**

Inserir `_buildServiceSelector()` + `const SizedBox(height: AppSpacing.md)` **antes** do campo de nome do cliente.

```dart
Widget _buildServiceSelector() {
  return BlocBuilder<ServicesBloc, ServicesState>(
    builder: (context, state) {
      final services = switch (state) {
        ServicesLoaded(:final services) => services.where((s) => s.isActive).toList(),
        _ => <ServiceModel>[],
      };

      if (services.isEmpty) return const SizedBox.shrink();

      final selectedService = services
          .where((s) => s.id == _selectedServiceId)
          .firstOrNull;

      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.surfaceHigh),
        ),
        child: Row(
          children: [
            Icon(Icons.design_services_outlined,
                size: 18, color: AppColors.purple500),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Serviço',
              style: AppTypography.bodySm.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            DropdownButton<String?>(
              value: _selectedServiceId,
              underline: const SizedBox.shrink(),
              dropdownColor: AppColors.surface,
              hint: Text(
                'Opcional',
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.textDisabled,
                ),
              ),
              style: AppTypography.bodySm.copyWith(
                color: AppColors.textPrimary,
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(
                    'Nenhum',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                ...services.map((s) => DropdownMenuItem<String?>(
                      value: s.id,
                      child: Text(s.name),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedServiceId = value;
                  if (value == null) {
                    _durationMinutes = 60;
                    _isCustomDuration = false;
                  } else {
                    final svc = services.firstWhere((s) => s.id == value);
                    if (svc.durationMinutes != null) {
                      _durationMinutes = svc.durationMinutes!;
                      _isCustomDuration = false;
                    }
                  }
                });
              },
            ),
            if (selectedService != null && selectedService.price != null)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.xs),
                child: Text(
                  'R\$ ${selectedService.price!.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: AppTypography.bodyXs.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}
```

**Step 3: Passar `serviceId` no `_submit`**

No método `_submit`, atualizar o `ScheduleAppointmentCreateRequested`:

```dart
context.read<ScheduleBloc>().add(
  ScheduleAppointmentCreateRequested(
    clientName: _nameController.text.trim(),
    clientEmail: _emailController.text.trim(),
    startsAt: _selectedDateTime,
    durationMinutes: duration,
    notes: _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim(),
    recurrenceRule: _recurrenceRule,
    serviceId: _selectedServiceId,    // novo
  ),
);
```

**Step 4: Adicionar imports necessários**

```dart
import 'package:scheduler_frontend/features/services/bloc/services_bloc.dart';
import 'package:scheduler_frontend/features/services/bloc/services_state.dart';
import 'package:scheduler_frontend/features/services/data/service_model.dart';
```

**Step 5: Verificar que compila e testes existentes passam**

```bash
flutter analyze
flutter test
```
Esperado: PASS (todos os testes passando)

**Step 6: Commit final**

```bash
git add lib/features/appointments/presentation/widgets/create_appointment_sheet.dart
git commit -m "feat: add optional service selector to appointment form with auto-fill duration"
```

---

## Verificação Final

```bash
flutter analyze
flutter test --reporter=github
```

Todos os testes devem passar. A aba de Serviços deve:
- Listar serviços do negócio ativo
- Permitir criar, editar, desativar/reativar e deletar serviços
- O formulário de agendamento deve exibir dropdown de serviços ativos com preenchimento automático de duração
