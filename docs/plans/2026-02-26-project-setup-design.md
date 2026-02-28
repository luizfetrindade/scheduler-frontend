# Flutter Base App Project Setup — Design

**Date:** 2026-02-26
**Status:** Approved

## Summary

Setup inicial do Flutter Base App cobrindo quatro pilares: separação de ambientes via `--dart-define`, roteamento com `go_router` e auth guard, internacionalização pt-BR + en com `flutter_localizations`, e cache em 3 camadas (in-memory + SharedPreferences + Hive).

---

## 1. Ambientes

**Abordagem:** `--dart-define` + `AppConfig`

Sem pacote extra. Variáveis injetadas em build-time, lidas por `String.fromEnvironment`.

### `AppConfig`

```dart
abstract final class AppConfig {
  static const env    = String.fromEnvironment('ENV', defaultValue: 'dev');
  static const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:3000');
  static bool get isDev     => env == 'dev';
  static bool get isStaging => env == 'staging';
  static bool get isProd    => env == 'prod';
}
```

### Makefile

```makefile
run-dev:
    flutter run --dart-define=ENV=dev --dart-define=API_URL=http://localhost:3000

run-staging:
    flutter run --dart-define=ENV=staging --dart-define=API_URL=https://staging-api.gymhero.app

run-prod:
    flutter run --dart-define=ENV=prod --dart-define=API_URL=https://api.gymhero.app

l10n:
    flutter gen-l10n
```

---

## 2. Roteamento

**Pacote:** `go_router ^14.0.0`

### Rotas

| Path | Página | Acesso |
|---|---|---|
| `/login` | `LoginPage` | Pública |
| `/` | `HomePage` | Protegida |
| `/profile` | `ProfilePage` | Protegida |

### Auth Guard

Redirect puro baseado em `AuthService.isAuthenticated`:

- Não autenticado + rota protegida → `/login`
- Autenticado + `/login` → `/`

### Shell Route

`ShellRoute` envolve rotas protegidas para bottom navigation futura. O shell renderiza `AppShell(child: child)`.

### Arquivos

- `lib/core/router/app_router.dart` — instância do `GoRouter`
- `lib/core/router/app_routes.dart` — constantes de path

---

## 3. Internacionalização

**Abordagem:** Flutter oficial — `flutter_localizations` + `intl` + `.arb`

### Configuração (`l10n.yaml`)

```yaml
arb-dir: lib/core/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-dir: lib/core/l10n/generated
```

### Arquivos ARB

- `lib/core/l10n/app_en.arb` — fonte da verdade (inglês)
- `lib/core/l10n/app_pt.arb` — português

### Extensão de conveniência

```dart
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
```

Uso: `context.l10n.homeGreeting`

### Strings iniciais

| Chave | EN | PT |
|---|---|---|
| `appTitle` | Flutter Base App | Flutter Base App |
| `homeGreeting` | Hello, Athlete | Olá, Atleta |
| `homeMyWorkouts` | My Workouts | Meus Treinos |
| `homeTodayWorkout` | Today's Workout | Treino de Hoje |
| `workoutStartButton` | Start Workout | Iniciar Treino |
| `workoutNewButton` | New Workout | Novo Treino |
| `searchHint` | e.g. Chest, Back, Legs... | Ex: Peito, Costas, Pernas... |
| `searchLabel` | Search workout | Buscar treino |
| `loginTitle` | Welcome back | Bem-vindo de volta |
| `loginEmailLabel` | E-mail | E-mail |
| `loginPasswordLabel` | Password | Senha |
| `loginButton` | Sign in | Entrar |

---

## 4. Cache

**Abordagem:** 3 camadas com interface única

### Camadas

| Camada | Pacote | Velocidade | Uso |
|---|---|---|---|
| In-memory | `dart:core` (Map) | < 1ms | Cache HTTP da sessão |
| SharedPreferences | `shared_preferences ^2.3.0` | ~5ms | Primitivos: idioma, `isLoggedIn` |
| Hive | `hive_flutter ^1.1.0` | ~10ms | Objetos estruturados, suporte offline |

### Interface

```dart
abstract interface class CacheService {
  Future<T?> get<T>(String key);
  Future<void> set<T>(String key, T value, {Duration? ttl});
  Future<void> delete(String key);
  Future<void> clear();
}
```

### Fluxo cache-first (Repositories)

```
get(key)
  → in-memory hit?  → retorna
  → Hive hit?       → popula memory → retorna
  → API call        → salva Hive + memory → retorna
```

### TTL

- Dados de API (treinos, exercícios): 24h
- Preferências do usuário: sem expiração
- Dados de sessão (in-memory): até fechar o app

### Arquivos

- `lib/core/cache/cache_service.dart` — interface
- `lib/core/cache/memory_cache_service.dart` — implementação in-memory
- `lib/core/cache/preferences_service.dart` — wrapper SharedPreferences
- `lib/core/cache/hive_cache_service.dart` — implementação Hive (implementa `CacheService`)

---

## Estrutura de Arquivos

```
lib/
├── core/
│   ├── config/
│   │   └── app_config.dart
│   ├── router/
│   │   ├── app_router.dart
│   │   └── app_routes.dart
│   ├── l10n/
│   │   ├── app_en.arb
│   │   ├── app_pt.arb
│   │   └── generated/               # gerado por flutter gen-l10n
│   └── cache/
│       ├── cache_service.dart
│       ├── memory_cache_service.dart
│       ├── preferences_service.dart
│       └── hive_cache_service.dart
├── features/
│   ├── auth/
│   │   └── presentation/
│   │       └── login_page.dart
│   └── home/
│       └── presentation/
│           └── home_page.dart
├── design_system/                   # já existe
└── main.dart
```

## Pacotes Novos

```yaml
dependencies:
  go_router: ^14.0.0
  shared_preferences: ^2.3.0
  hive_flutter: ^1.1.0
  flutter_localizations:
    sdk: flutter
  intl: ^0.20.0
```

## Testes

| Componente | Cobertura |
|---|---|
| `AppConfig` | lê variáveis corretamente; defaults em dev |
| `AppRouter` | redireciona para login quando não autenticado; redireciona para home quando autenticado em `/login` |
| `HiveCacheService` | set/get/delete/clear; respeita TTL |
| `MemoryCacheService` | set/get/delete; TTL expira na sessão |
| `PreferencesService` | get/set primitivos |
