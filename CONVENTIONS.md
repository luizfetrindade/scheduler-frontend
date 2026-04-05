# Frontend — Guia de Convenções para IA

> Este documento descreve os padrões arquiteturais, convenções de código e decisões de design do frontend Flutter.
> **Toda IA que modificar este projeto deve ler este arquivo antes de escrever qualquer código.**

---

## Stack

| Tecnologia | Papel |
|---|---|
| Flutter (Dart SDK ^3.10) | Framework UI multiplataforma |
| flutter_bloc / bloc | Gerenciamento de estado |
| go_router | Navegação declarativa |
| dio + dio_cookie_manager | HTTP client + cookies |
| flutter_http (lib interna) | Wrapper tipado sobre dio com `Result<T>` |
| hive_flutter | Cache local (offline-first) |
| flutter_secure_storage | Armazenamento seguro (tokens) |
| fl_chart | Gráficos nos relatórios |
| intl | Internacionalização e formatação |
| equatable | Comparação de estados/modelos |
| Lexend | Tipografia padrão (todas as variações de peso) |

---

## Estrutura de Diretórios

```
lib/
├── main.dart                  # Composição de DI: cria repos, BLoCs globais, runApp
├── app_shell.dart             # AdaptiveShell: nav lateral (desktop) + bottom bar (mobile)
├── core/
│   ├── auth/                  # AuthBloc, AuthRepository, RememberMeStorage
│   ├── cache/                 # HiveCacheService, PreferencesService
│   ├── config/                # Constantes de ambiente (API_URL, ENV via --dart-define)
│   ├── l10n/                  # Arquivos ARB e gerados pelo flutter gen-l10n
│   ├── models/                # Modelos compartilhados entre features
│   ├── network/               # ApiClient, RouterNotifier
│   ├── policy/                # AppPolicy (regras de permissão e navegação)
│   ├── router/                # app_router.dart, app_routes.dart, uuid_validator.dart
│   ├── theme/                 # ThemeCubit, ThemeState
│   └── utils/
├── design_system/
│   ├── tokens/                # AppColors, AppTypography, AppSpacing, AppRadius, AppShadows, AppTheme
│   └── components/            # Widgets reutilizáveis do design system
└── features/
    ├── appointments/
    ├── auth/
    ├── business/
    ├── clients/
    ├── home/
    ├── onboarding/
    ├── professionals/
    ├── reports/
    ├── services/
    └── settings/
```

### Estrutura interna de cada feature

```
features/nome_da_feature/
├── bloc/
│   ├── nome_bloc.dart
│   ├── nome_event.dart
│   └── nome_state.dart
├── data/
│   ├── nome_model.dart        # Modelos com fromJson
│   └── nome_repository.dart   # Chamadas HTTP via ApiClient
└── presentation/
    ├── nome_page.dart
    └── widgets/               # Widgets específicos desta feature
```

---

## Gerenciamento de Estado: BLoC

### Convenções de State

Todo BLoC usa `sealed class` para os estados, estendidos de `Equatable`:

```dart
sealed class NomeState extends Equatable {
  const NomeState();
  @override List<Object?> get props => [];
}

class NomeInitial extends NomeState { const NomeInitial(); }
class NomeLoading extends NomeState { const NomeLoading(); }
class NomeLoaded extends NomeState {
  final NomeModel data;
  const NomeLoaded(this.data);
  @override List<Object?> get props => [data];
}
class NomeError extends NomeState {
  final String message;
  const NomeError(this.message);
  @override List<Object?> get props => [message];
}
```

### Convenções de Event

```dart
sealed class NomeEvent extends Equatable {
  const NomeEvent();
}
class NomeLoadRequested extends NomeEvent { ... }
class NomeSessionCleared extends NomeEvent { const NomeSessionCleared(); }
```

### Limpeza de sessão (logout)

**Todo BLoC que carrega dados de um usuário deve implementar `NomeSessionCleared`.**

No `main.dart`, todos os eventos de limpeza são disparados quando `AuthBloc` emite `AuthUnauthenticated`:

```dart
BlocListener<AuthBloc, AuthState>(
  listener: (context, state) {
    if (state is AuthUnauthenticated) {
      context.read<NomeBloc>().add(const NomeSessionCleared());
      // ...demais BLoCs
    }
  },
),
```

> **Regra:** Ao criar um novo BLoC de feature, adicione o `SessionCleared` correspondente no listener do `main.dart`.

### Cache in-memory no BLoC

Quando um BLoC precisa de cache simples (ex: por período, por ID), usa um `Map` interno:

```dart
final Map<ChaveDeTipo, Model> _cache = {};

// No handler:
final cached = _cache[chave];
if (cached != null && !event.forceRefresh) {
  emit(NomeLoaded(cached));
  return;
}
```

---

## Injeção de Dependência

### Não há container de DI externo

Todas as dependências são criadas manualmente no `main()` e injetadas via `MultiBlocProvider` / `MultiRepositoryProvider`.

```dart
// main.dart
final apiClient = await ApiClient.create();
final reportsRepo = ReportsRepository(apiClient);

runApp(SchedulerApp(reportsRepo: reportsRepo, ...));
```

### Repositórios no contexto

Repositórios que precisam ser acessados por BLoCs criados dentro de widgets usam `RepositoryProvider`:

```dart
MultiRepositoryProvider(
  providers: [
    RepositoryProvider.value(value: appointmentRepo),
    RepositoryProvider.value(value: reportsRepo),
  ],
  ...
)
```

BLoCs escopados a uma página específica (como `ReportsBloc`) são criados com `BlocProvider` dentro da própria página:

```dart
return BlocProvider(
  create: (ctx) => ReportsBloc(ctx.read<ReportsRepository>())
    ..add(ReportsLoadRequested(...)),
  child: ReportsView(...),
);
```

---

## Camada de Rede: `ApiClient` e `Result<T>`

### `flutter_http` (lib interna)

A lib `flutter_http` (do git) encapsula `dio` e retorna um tipo `Result<T>` selado:

```dart
sealed class Result<T> {}
class Success<T> extends Result<T> { final T data; }
class HttpFailure<T> extends Result<T> { final AppFailure failure; }
```

### Uso no Repository

```dart
class NomeRepository {
  final ApiClient _client;
  NomeRepository(this._client);

  Future<Result<NomeModel>> getNome() =>
      _client.get('/endpoint', fromJson: NomeModel.fromJson);
}
```

### Tratamento no BLoC

Use pattern matching com `switch`:

```dart
final result = await _repository.getNome();
switch (result) {
  case Success(:final data):
    emit(NomeLoaded(data));
  case HttpFailure(:final failure):
    emit(NomeError(_message(failure)));
}
```

### Mapeamento de erros

```dart
String _message(AppFailure failure) => switch (failure) {
  NetworkFailure() => 'Sem conexão com a internet',
  UnauthorizedFailure() => 'Sessão expirada. Faça login novamente.',
  _ => 'Erro inesperado. Tente novamente.',
};
```

---

## Modelos de Dados

### Padrão: `fromJson` + `Equatable`

```dart
class NomeModel extends Equatable {
  final String id;
  final String nome;

  const NomeModel({required this.id, required this.nome});

  factory NomeModel.fromJson(Map<String, dynamic> json) => NomeModel(
    id: json['id'] as String,
    nome: json['nome'] as String,
  );

  @override
  List<Object?> get props => [id, nome];
}
```

> **Regra:** Nunca use `json_serializable` ou geração de código. Todos os `fromJson` são escritos manualmente.

---

## Roteamento: `go_router`

### Rotas declaradas em `app_routes.dart`

```dart
abstract class AppRoutes {
  static const home = '/home';
  static const appointments = '/appointments';
  // ...
}
```

### Shell routes para navegação com AppShell

Todas as rotas protegidas ficam dentro de um `ShellRoute` que renderiza `AdaptiveShell`:

```dart
ShellRoute(
  builder: (context, state, child) => AdaptiveShell(
    currentLocation: state.matchedLocation,
    child: child,
  ),
  routes: [
    GoRoute(path: AppRoutes.home, builder: (_, __) => const HomePage()),
    // ...
  ],
)
```

### Redirecionamento de autenticação

A função `computeRedirect` (testável, sem `BuildContext`) centraliza a lógica:

```dart
String? computeRedirect({required bool isLoggedIn, required String location}) {
  const publicPaths = ['/login', '/register', ...];
  final isOnPublicRoute = publicPaths.any((p) => location.startsWith(p));
  if (!isLoggedIn && !isOnPublicRoute) return AppRoutes.login;
  if (isLoggedIn && isOnPublicRoute) return AppRoutes.home;
  return null;
}
```

### Tokens em deep links

Use `extractToken(uri)` para extrair o token do fragmento (#) ou query param. O fragmento tem prioridade (não vaza para servidores via Referer).

---

## Política de Navegação e Permissões: `AppPolicy`

`AppPolicy.from(role, maxStaff)` centraliza **todas** as decisões de exibição de UI e acesso:

```dart
final policy = AppPolicy.from(StaffRole.owner, business.maxStaff);
policy.isAdmin           // true p/ owner e manager
policy.isSoloMode        // maxStaff <= 1
policy.canManageTeam     // isAdmin && !isSoloMode
policy.canViewReports    // isAdmin
policy.mobileNavItems    // itens da barra inferior
policy.desktopNavItems   // itens da nav lateral (inclui Relatórios)
```

> **Regra:** Toda validação de permissão de UI deve passar por `AppPolicy`. Nunca verifique `role == StaffRole.owner` diretamente em widgets.

---

## Design System

### Tokens (`lib/design_system/tokens/`)

| Arquivo | Conteúdo |
|---|---|
| `app_colors.dart` | Paleta base (seeds e paletas fixas) |
| `app_colors_extension.dart` | `ThemeExtension` com cores semânticas |
| `app_typography.dart` | Estilos de texto com fonte Lexend |
| `app_spacing.dart` | Constantes de espaçamento (xs, sm, md, lg, xl) |
| `app_radius.dart` | `BorderRadius` padronizados |
| `app_shadows.dart` | Sombras padronizadas |
| `app_theme.dart` | `AppTheme.light()` e `AppTheme.dark()` |

### Uso correto de cores

```dart
// ✅ Correto: use o ColorScheme do tema
Theme.of(context).colorScheme.primary
Theme.of(context).colorScheme.surfaceContainerHighest

// ✅ Correto: use a extensão semântica
Theme.of(context).extension<AppColorsExtension>()!.nomeDaCor

// ❌ Errado: hardcode de cor
Color(0xFF123456)
Colors.blue.shade400  // aceitável apenas em gráficos/badges com acento
```

### Tema dinâmico

`ThemeCubit` gerencia `ThemeMode` e persiste no `PreferencesService`. O modo é lido em `_AppBodyState.build`.

---

## Navegação Adaptativa: `AdaptiveShell`

O `AdaptiveShell` usa `LayoutBuilder` para decidir entre:
- **Mobile** (`< 600px`): `BottomNavigationBar` com os itens de `policy.mobileNavItems`.
- **Desktop** (`>= 600px`): `NavigationRail` ou `NavigationDrawer` com `policy.desktopNavItems`.

> **Regra:** **Relatórios** aparece apenas no desktop. Nunca adicione a rota `/reports` nos `mobileNavItems` dentro de `AppPolicy`.

---

## Localização

- Idioma padrão: **pt-BR**.
- Arquivos ARB em `lib/core/l10n/`.
- Geração: `make l10n` (executa `flutter gen-l10n`).
- Formatação de datas e moeda sempre usa `intl` com locale `pt_BR`:

```dart
final fmt = DateFormat('MMMM yyyy', 'pt_BR');
final curr = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
```

---

## Ambientes e Build

Configuração via `--dart-define` (nunca via arquivo `.env`):

```bash
# Desenvolvimento
make run-dev
# → --dart-define=ENV=dev --dart-define=API_URL=http://localhost:3000

# Staging
make run-staging

# Produção
make run-prod
```

O `ApiClient` lê `API_URL` via `const String.fromEnvironment('API_URL')`.

---

## Testes

- Localizados em `test/`, espelhando a estrutura de `lib/`.
- Usam `bloc_test` e `mocktail`.
- Funções puras (ex: `computeRedirect`, `extractToken`, `computeHealthScore`) têm testes sem mocks.
- BLoCs são testados com `blocTest<NomeBloc, NomeState>`.

```dart
blocTest<ReportsBloc, ReportsState>(
  'emits [Loading, Loaded] quando sucesso',
  build: () => ReportsBloc(mockRepo),
  act: (bloc) => bloc.add(ReportsLoadRequested(...)),
  expect: () => [isA<ReportsLoading>(), isA<ReportsLoaded>()],
);
```

---

## O que NÃO fazer

- ❌ Não use `setState` para estado de feature — use BLoC.
- ❌ Não acesse o backend diretamente de widgets — sempre passe pelo BLoC → Repository.
- ❌ Não hardcode strings de UI — use as constantes de `AppRoutes` e labels vindas do modelo.
- ❌ Não verifique permissões de role diretamente em widgets — use `AppPolicy`.
- ❌ Não crie repositórios com estado interno mutável.
- ❌ Não use `json_serializable` — todos os `fromJson` são manuais.
- ❌ Não adicione rotas novas sem declarar a constante em `AppRoutes`.
- ❌ Não esqueça de adicionar o `SessionCleared` de um BLoC novo no listener de logout do `main.dart`.
- ❌ Não use `Colors.X` diretamente em componentes de layout — use o `ColorScheme` do tema.
