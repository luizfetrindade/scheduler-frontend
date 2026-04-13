# CLAUDE.md — scheduler-frontend

Guia completo para IAs trabalhando neste projeto Flutter.
**Leia este arquivo antes de escrever qualquer linha de código.**

---

## Comandos essenciais

```bash
# Rodar com backend local
make run-dev                     # --dart-define=ENV=dev --dart-define=API_URL=http://localhost:3000

# Rodar em outros ambientes
make run-staging
make run-prod

# Testes
make test                        # flutter test
flutter test test/path/to/foo_test.dart   # arquivo específico
flutter test --reporter=github   # saída limpa para CI

# Linting
make analyze                     # flutter analyze

# Regenerar localização (após editar .arb)
make l10n                        # flutter gen-l10n
```

Configuração via `--dart-define` exclusivamente. Nunca use `.env`.

---

## Mapa da codebase

```
lib/
├── main.dart              # Composição de DI manual + runApp
├── app_shell.dart         # AdaptiveShell: nav lateral (desktop) / bottom bar (mobile)
├── core/
│   ├── auth/              # AuthBloc, AuthRepository, AuthState, RememberMeStorage
│   ├── cache/             # HiveCacheService (persistente), PreferencesService (prefs)
│   ├── config/            # AppConfig — lê API_URL e ENV via dart-define
│   ├── l10n/              # Arquivos .arb e gerados por flutter gen-l10n
│   ├── models/            # UserModel e outros modelos compartilhados
│   ├── network/           # ApiClient, RouterNotifier, WebTokenStorage
│   ├── policy/            # AppPolicy — todas as regras de permissão e nav items
│   ├── router/            # app_router.dart, app_routes.dart, uuid_validator.dart
│   ├── theme/             # ThemeCubit, ThemeState
│   └── utils/
├── design_system/
│   ├── tokens/            # AppColors, AppColorsExtension, AppTypography, AppSpacing,
│   │                      # AppRadius, AppShadows, AppTheme
│   └── components/
│       ├── button/        # BaseButton
│       ├── card/          # BaseCard
│       └── input/         # BaseInputField
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
│   ├── nome_model.dart         # fromJson manual, Equatable
│   └── nome_repository.dart    # chamadas HTTP via ApiClient
└── presentation/
    ├── nome_page.dart
    └── widgets/                # widgets específicos da feature
```

---

## Stack e dependências-chave

| Pacote | Papel |
|---|---|
| `flutter_bloc ^9` | Estado com BLoC explícito (Events + States) |
| `go_router ^14` | Navegação declarativa |
| `flutter_http` (git) | Wrapper sobre Dio — `Result<T>`, `TokenStorage`, `AppFailure` |
| `dio ^5` + `dio_cookie_manager` | HTTP raw para PATCH/DELETE e gestão de cookies |
| `hive_flutter` | Cache local offline-first |
| `flutter_secure_storage` | Tokens de acesso seguros |
| `fl_chart` | Gráficos na tela de Relatórios |
| `intl` | Formatação de datas e moeda (sempre `pt_BR`) |
| `equatable` | Comparação value-equality em estados e modelos |
| `mocktail` + `bloc_test` | Testes — mocks e `blocTest` |
| Lexend | Fonte padrão (pesos 100–900 em assets/fonts/) |

---

## Gerenciamento de estado: BLoC

### Padrão de State (sealed class + Equatable)

```dart
sealed class NomeState extends Equatable {
  const NomeState();
  @override List<Object?> get props => [];
}

class NomeInitial  extends NomeState { const NomeInitial(); }
class NomeLoading  extends NomeState { const NomeLoading(); }
class NomeLoaded   extends NomeState {
  final NomeModel data;
  const NomeLoaded(this.data);
  @override List<Object?> get props => [data];
}
class NomeError    extends NomeState {
  final String message;
  const NomeError(this.message);
  @override List<Object?> get props => [message];
}
```

### Padrão de Event

```dart
sealed class NomeEvent extends Equatable {
  const NomeEvent();
}
class NomeLoadRequested   extends NomeEvent { ... }
class NomeSessionCleared  extends NomeEvent { const NomeSessionCleared(); }
```

### Regra de logout: todo BLoC de feature DEVE ter SessionCleared

Quando `AuthBloc` emite `AuthUnauthenticated`, o `_AppBody` em `main.dart` dispara
`NomeSessionCleared` em todos os BLoCs para zerar dados do usuário anterior.

Ao criar um novo BLoC, adicione o evento ao listener em `main.dart`:

```dart
BlocListener<AuthBloc, AuthState>(
  listener: (context, state) {
    if (state is AuthUnauthenticated) {
      context.read<NomeBloc>().add(const NomeSessionCleared());
    }
  },
),
```

### Cache in-memory no BLoC

```dart
final Map<ChaveTipo, NomeModel> _cache = {};

// No handler:
final cached = _cache[chave];
if (cached != null && !event.forceRefresh) {
  emit(NomeLoaded(cached));
  return;
}
```

---

## Injeção de dependência

Sem container externo. Tudo criado manualmente em `main()`:

```dart
final apiClient   = await ApiClient.create();
final reportsRepo = ReportsRepository(apiClient);
// ...
runApp(SchedulerApp(reportsRepo: reportsRepo, ...));
```

- BLoCs globais ficam em `MultiBlocProvider` no `SchedulerApp`.
- BLoCs escopados (ex: `ReportsBloc`) são criados com `BlocProvider` dentro da própria página.
- Repositórios que precisam ser lidos dentro de widgets usam `RepositoryProvider`.

---

## Camada de rede: ApiClient

`ApiClient` (`lib/core/network/api_client.dart`) é o único ponto de acesso HTTP.
Nunca chame Dio diretamente de fora de `ApiClient`.

### Envelope do backend

O backend retorna `{ "data": <payload>, "meta": { "timestamp": "..." } }`.
`ApiClient` desencapsula isso automaticamente — repositórios e modelos nunca veem o envelope.

### Métodos disponíveis

```dart
// Objeto único
Future<Result<T>> get(path, {fromJson, queryParams})
Future<Result<T>> post(path, {fromJson, body})
Future<Result<T>> patch(path, {fromJson, body})
Future<Result<void>> delete(path)

// Lista
Future<Result<List<T>>> getList(path, {fromJson, queryParams})

// Negócio autenticado
Future<Result<List<BusinessModel>>> getBusinessesMine()

// Auth helpers diretos
Future<Result<Map<String, dynamic>>> checkEmail(email)
Future<Result<Map<String, dynamic>>> loginWithPassword({email, password, rememberMe})
Future<Result<void>> forgotPassword(email)
Future<Result<void>> resetPassword(token, newPassword)
Future<Result<Map<String, dynamic>>> acceptInvite(token, name, password)
```

### PATCH e DELETE

`flutter_http` não tem `patch()`/`delete()` — `ApiClient` os implementa via Dio raw.
Nunca tente usar `_http.patch()` ou `_http.delete()`.

### getList()

O `getList()` do `flutter_http` **não funciona** com este backend.
Sempre use `ApiClient.getList()`, que extrai `json['data']` corretamente.

### Cookies e refresh

- Mobile: `PersistCookieJar` persiste o `refresh_token` httpOnly em disco.
- Web: o browser gerencia os cookies automaticamente (`withCredentials: true`).
- Refresh automático: ao receber 401, `ApiClient._withRefresh` tenta `POST /auth/refresh`
  uma vez; se falhar, dispara `onAuthExpired` que chama `AuthLogoutRequested`.
- Mutex (`_tokenMutex`) serializa leituras de token — sem race conditions.

### Resultado no repositório

```dart
class NomeRepository {
  final ApiClient _client;
  NomeRepository(this._client);

  Future<Result<NomeModel>> getNome() =>
      _client.get('/endpoint', fromJson: NomeModel.fromJson);
}
```

### Tratamento no BLoC

```dart
final result = await _repository.getNome();
switch (result) {
  case Success(:final data):
    emit(NomeLoaded(data));
  case HttpFailure(:final failure):
    emit(NomeError(_message(failure)));
}
```

### Mapeamento de falhas

```dart
String _message(AppFailure failure) => switch (failure) {
  NetworkFailure()       => 'Sem conexão com a internet',
  UnauthorizedFailure()  => 'Sessão expirada. Faça login novamente.',
  ServerFailure(:final message) => message,
  _                      => 'Erro inesperado. Tente novamente.',
};
```

---

## Modelos de dados

```dart
class NomeModel extends Equatable {
  final String id;
  final String nome;

  const NomeModel({required this.id, required this.nome});

  factory NomeModel.fromJson(Map<String, dynamic> json) => NomeModel(
    id:   json['id']   as String,
    nome: json['nome'] as String,
  );

  @override List<Object?> get props => [id, nome];
}
```

**Nunca use `json_serializable` ou geração de código.** Todos os `fromJson` são manuais.

### copyWith com campos nullable

Use o padrão sentinel:

```dart
static const _sentinel = Object();

NomeModel copyWith({Object? nome = _sentinel}) => NomeModel(
  nome: nome == _sentinel ? this.nome : nome as String?,
);
```

---

## Roteamento

### Constantes em AppRoutes

```dart
abstract final class AppRoutes {
  static const login             = '/login';
  static const register          = '/register';
  static const home              = '/home';
  static const onboarding        = '/onboarding';
  static const appointments      = '/appointments';
  static const clients           = '/clients';
  static const services          = '/services';
  static const professionals     = '/professionals';
  static const professionalRoles = '/professional-roles';
  static const reports           = '/reports';
  static const settings          = '/settings';
}
```

Nunca hardcode strings de rota em widgets. Sempre use `AppRoutes`.

### Rota nova: checklist obrigatório

1. Adicionar constante em `AppRoutes`.
2. Declarar `GoRoute` em `app_router.dart`.
3. Se protegida, inserir dentro do `ShellRoute` do `AdaptiveShell`.
4. Se visível na nav, adicionar em `AppPolicy._buildMobileNav` e/ou `_buildDesktopNav`.

### Redirect de autenticação (testável, sem BuildContext)

```dart
String? computeRedirect({required bool isLoggedIn, required String location})
```

Rotas públicas: `/login`, `/register`, `/reset-password`, `/accept-invite`, `/forgot-password`.

### Deep links com token

```dart
String extractToken(Uri uri)  // fragmento (#token=) tem prioridade sobre query param (?token=)
```

### UUID validation em path params

```dart
if (!isValidUuid(id)) return AppRoutes.professionals;
```

---

## Política de permissões: AppPolicy

```dart
final policy = AppPolicy.from(role, business.maxStaff);
policy.isAdmin           // owner ou manager
policy.isSoloMode        // maxStaff <= 1
policy.canManageTeam     // isAdmin && !isSoloMode
policy.canManageServices // isAdmin
policy.canViewReports    // isAdmin
policy.canViewOtherAppts // isAdmin && !isSoloMode
policy.mobileNavItems    // itens do BottomNavigationBar
policy.desktopNavItems   // itens do NavigationRail (inclui Relatórios)
```

**Relatórios (`/reports`) aparece APENAS no desktop** (`desktopNavItems`).
Nunca adicione `/reports` em `mobileNavItems`.

**Toda validação de permissão de UI passa por `AppPolicy`.**
Nunca compare `role == StaffRole.owner` diretamente em widgets.

---

## Design system

### Cantos: sempre retos

`BorderRadius.zero` em **todos** os componentes — cards, botões, inputs.
Nunca arredonde cantos. Esta é uma decisão de design intencional e definitiva.

### Tokens disponíveis

| Arquivo | Exporta |
|---|---|
| `app_colors.dart` | `AppColors.kCharcoal`, `kLinen`, `kBark`, etc. (paleta base) |
| `app_colors_extension.dart` | `ThemeExtension` com cores semânticas |
| `app_typography.dart` | `AppTypography.displayLg`, `headingMd`, `bodyMd`, etc. |
| `app_spacing.dart` | `AppSpacing.xs/sm/md/lg/xl` |
| `app_radius.dart` | `BorderRadius` padronizados (todos `zero` ou mínimos) |
| `app_shadows.dart` | Sombras padronizadas |
| `app_theme.dart` | `AppTheme.light()` e `AppTheme.dark()` |

### Uso correto de cores

```dart
// Correto — ColorScheme do tema
Theme.of(context).colorScheme.primary
Theme.of(context).colorScheme.surfaceContainerHighest

// Correto — extensão semântica
Theme.of(context).extension<AppColorsExtension>()!.nomeDaCor

// Errado — nunca hardcode
Color(0xFF123456)
Colors.blue.shade400   // aceitável apenas em gráficos/badges com acento visual
```

### Tema dinâmico

`ThemeCubit` gerencia `ThemeMode` e persiste via `PreferencesService`.
O modo é lido em `_AppBodyState.build` através de `BlocBuilder<ThemeCubit, ThemeState>`.

---

## Navegação adaptativa: AdaptiveShell

`AdaptiveShell` usa `LayoutBuilder`:
- **Mobile (`< 600 px`)**: `BottomNavigationBar` com `policy.mobileNavItems`.
- **Desktop (`>= 600 px`)**: `NavigationRail` / `NavigationDrawer` com `policy.desktopNavItems`.

---

## Localização

- **Idioma único: pt-BR.**
- Arquivos ARB: `lib/core/l10n/app_pt.arb` e `app_en.arb`.
- Geração: `make l10n`.
- Formatação de datas e moeda sempre com `intl` e locale `pt_BR`:

```dart
final fmt  = DateFormat('MMMM yyyy', 'pt_BR');
final curr = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
```

Todas as strings visíveis na UI devem estar nos arquivos ARB.
Nunca hardcode texto em português dentro de widgets.

---

## Testes

### Estrutura

`test/` espelha `lib/`. Cada arquivo `lib/features/x/y.dart` tem seu `test/features/x/y_test.dart`.

### BLoC tests com blocTest

```dart
blocTest<ReportsBloc, ReportsState>(
  'emits [Loading, Loaded] quando sucesso',
  build: () => ReportsBloc(mockRepo),
  act:   (bloc) => bloc.add(ReportsLoadRequested(...)),
  expect: () => [isA<ReportsLoading>(), isA<ReportsLoaded>()],
);
```

### Funções puras — sem mocks

`computeRedirect`, `extractToken`, `computeHealthScore`, `computeSmartAlerts`:
testadas diretamente, sem mocks.

### Gotchas críticos de widget tests

| Problema | Causa | Solução |
|---|---|---|
| `pumpAndSettle` trava | Animação de cursor do `TextField` não termina | Use `pump(Duration)` em vez de `pumpAndSettle` |
| `pumpWidget` com GoRouter + BLoC trava | `RouterNotifier` abre stream subscription | Teste `computeRedirect` diretamente, sem renderizar |
| `AppointmentStatusX.fromString()` | Método em extension, não na enum | Chame via `AppointmentStatusX.fromString()`, não `AppointmentStatus.fromString()` |
| `ServerFailure` com statusCode | Parâmetro nomeado obrigatório | `ServerFailure('msg', statusCode: 500)` |

### Falhas pré-existentes (ignorar)

3 testes em `test/design_system/tokens/app_colors_extension_test.dart` falham por razão
não relacionada às features. Não conserte a menos que o usuário peça explicitamente.

---

## Fluxos de autenticação

O `AuthBloc` gerencia múltiplos fluxos, todos com estados explícitos:

| Fluxo | Estados emitidos |
|---|---|
| Login via TOTP | `Loading` → `AuthLoginOtpSent` → `Loading` → `AuthAuthenticated` |
| Login via senha | `Loading` → `AuthAuthenticated` |
| Registro | `Loading` → `AuthRegisterOtpSent` → `Loading` → `AuthAuthenticated` |
| Accept invite | `Loading` → `AuthInviteOtpSent` → `Loading` → `AuthInviteAccepted` |
| Forgot password | `Loading` → `AuthForgotPasswordSent` |
| Reset password | `Loading` → `AuthPasswordResetSuccess` |
| Logout | `AuthUnauthenticated` (local, sem chamada ao servidor) |
| Token expirado | `ApiClient.onAuthExpired` → `AuthLogoutRequested` → `AuthUnauthenticated` |

O check inicial do usuário (`AuthUserFetched`) é disparado no `main()` antes do `runApp`.

---

## Cascade de carregamento (main.dart)

Quando `AuthAuthenticated` é emitido → `BusinessLoadRequested`.
Quando `BusinessLoaded` é emitido → simultaneamente:
- `ServicesLoadRequested(businessId)`
- `AppointmentsLoadRequested(slug, DateTime.now())`
- `ClientsLoadRequested(businessId)`
- `ProfessionalsLoadRequested(businessId)`
- `ProfessionalRolesLoadRequested(businessId)`
- `WizardBloc.reinitialize(businessId, isSoloMode)`

Quando `AuthUnauthenticated` é emitido → `SessionCleared` em todos os BLoCs acima.

---

## O que nunca fazer

- `setState` para estado de feature — use BLoC.
- Chamar o backend diretamente de widgets — sempre passe por BLoC → Repository → ApiClient.
- `json_serializable` — todos os `fromJson` são manuais.
- Comparar `role == StaffRole.owner` em widgets — use `AppPolicy`.
- Rotas novas sem constante em `AppRoutes`.
- BLoC novo sem `SessionCleared` no listener de logout do `main.dart`.
- `Colors.X` em componentes de layout — use `colorScheme` do tema.
- `BorderRadius` não-zero em cards, botões ou inputs.
- Strings de UI hardcoded em português — use ARB.
- `flutter_http.getList()` — use `ApiClient.getList()`.
- Verificar permissões de role diretamente em widgets — use `AppPolicy`.
- Repositórios com estado interno mutável.
- Usar `pumpAndSettle` em widget tests com `TextField`.
