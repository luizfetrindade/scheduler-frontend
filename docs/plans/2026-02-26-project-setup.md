# Flutter Base App Project Setup Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Adicionar separação de ambientes via `--dart-define`, roteamento com `go_router` + auth guard, internacionalização pt/en com `.arb`, e cache em 3 camadas (in-memory, SharedPreferences, Hive).

**Architecture:** `AppConfig` lê variáveis de ambiente em build-time. `GoRouter` com `refreshListenable` detecta mudanças de auth e redireciona automaticamente. `CacheService` é uma interface com implementações separadas por camada, inicializadas em `main()` antes de `runApp`.

**Tech Stack:** Flutter/Dart 3.10+, go_router ^14.0.0, hive_flutter ^1.1.0, shared_preferences ^2.3.0, flutter_localizations (SDK), intl ^0.20.0

---

## Task 1: Dependencies + AppConfig + Makefile

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/core/config/app_config.dart`
- Create: `Makefile`
- Create: `test/core/config/app_config_test.dart`

**Step 1: Add packages to `pubspec.yaml`**

Replace the `dependencies` block (keep existing, add new):

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  flutter_http:
    git:
      url: https://github.com/luizfetrindade/flutter-http.git
      ref: v1.0.1
  go_router: ^14.0.0
  shared_preferences: ^2.3.0
  hive_flutter: ^1.1.0
  flutter_localizations:
    sdk: flutter
  intl: ^0.20.0
```

**Step 2: Run pub get**

```bash
cd ~/Flutter Base App && flutter pub get
```

Expected: `Got dependencies!`

**Step 3: Write the failing test**

Create `test/core/config/app_config_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_base_app/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('apiUrl is not empty', () {
      expect(AppConfig.apiUrl, isNotEmpty);
    });

    test('env defaults to dev when no dart-define is set', () {
      expect(AppConfig.env, 'dev');
    });

    test('isDev returns true for default env', () {
      expect(AppConfig.isDev, isTrue);
    });

    test('isStaging returns false for default env', () {
      expect(AppConfig.isStaging, isFalse);
    });

    test('isProd returns false for default env', () {
      expect(AppConfig.isProd, isFalse);
    });
  });
}
```

**Step 4: Run to verify it fails**

```bash
cd ~/Flutter Base App && flutter test test/core/config/app_config_test.dart
```

Expected: FAIL — import error (file doesn't exist yet).

**Step 5: Create `lib/core/config/app_config.dart`**

```dart
abstract final class AppConfig {
  static const env = String.fromEnvironment('ENV', defaultValue: 'dev');
  static const apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000',
  );

  static bool get isDev => env == 'dev';
  static bool get isStaging => env == 'staging';
  static bool get isProd => env == 'prod';
}
```

**Step 6: Run test to verify it passes**

```bash
cd ~/Flutter Base App && flutter test test/core/config/app_config_test.dart
```

Expected: All 5 tests PASS.

**Step 7: Create `Makefile` na raiz do projeto**

```makefile
.PHONY: run-dev run-staging run-prod l10n test analyze

run-dev:
	flutter run \
		--dart-define=ENV=dev \
		--dart-define=API_URL=http://localhost:3000

run-staging:
	flutter run \
		--dart-define=ENV=staging \
		--dart-define=API_URL=https://staging-api.gymhero.app

run-prod:
	flutter run \
		--dart-define=ENV=prod \
		--dart-define=API_URL=https://api.gymhero.app

l10n:
	flutter gen-l10n

test:
	flutter test

analyze:
	flutter analyze
```

**Step 8: Commit**

```bash
cd ~/Flutter Base App
git add pubspec.yaml pubspec.lock lib/core/config/app_config.dart Makefile test/core/config/app_config_test.dart
git commit -m "feat: add dependencies, AppConfig env setup and Makefile"
```

---

## Task 2: Cache — Interface + MemoryCacheService

**Files:**
- Create: `lib/core/cache/cache_service.dart`
- Create: `lib/core/cache/memory_cache_service.dart`
- Create: `test/core/cache/memory_cache_service_test.dart`

**Step 1: Write the failing test**

Create `test/core/cache/memory_cache_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_base_app/core/cache/memory_cache_service.dart';

void main() {
  late MemoryCacheService cache;

  setUp(() => cache = MemoryCacheService());

  group('MemoryCacheService', () {
    test('returns null for missing key', () async {
      expect(await cache.get<String>('missing'), isNull);
    });

    test('stores and retrieves a value', () async {
      await cache.set<String>('key', 'value');
      expect(await cache.get<String>('key'), 'value');
    });

    test('stores and retrieves an int', () async {
      await cache.set<int>('count', 42);
      expect(await cache.get<int>('count'), 42);
    });

    test('delete removes a key', () async {
      await cache.set<String>('key', 'value');
      await cache.delete('key');
      expect(await cache.get<String>('key'), isNull);
    });

    test('clear removes all keys', () async {
      await cache.set<String>('a', '1');
      await cache.set<String>('b', '2');
      await cache.clear();
      expect(await cache.get<String>('a'), isNull);
      expect(await cache.get<String>('b'), isNull);
    });

    test('expired entry returns null', () async {
      await cache.set<String>('key', 'value', ttl: const Duration(milliseconds: 1));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(await cache.get<String>('key'), isNull);
    });

    test('non-expired entry is still available', () async {
      await cache.set<String>('key', 'value', ttl: const Duration(hours: 1));
      expect(await cache.get<String>('key'), 'value');
    });
  });
}
```

**Step 2: Run to verify it fails**

```bash
cd ~/Flutter Base App && flutter test test/core/cache/memory_cache_service_test.dart
```

Expected: FAIL — import error.

**Step 3: Create `lib/core/cache/cache_service.dart`**

```dart
abstract interface class CacheService {
  Future<T?> get<T>(String key);
  Future<void> set<T>(String key, T value, {Duration? ttl});
  Future<void> delete(String key);
  Future<void> clear();
}
```

**Step 4: Create `lib/core/cache/memory_cache_service.dart`**

```dart
import 'cache_service.dart';

class _Entry {
  final dynamic value;
  final DateTime? expiresAt;

  const _Entry(this.value, this.expiresAt);

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

class MemoryCacheService implements CacheService {
  final _store = <String, _Entry>{};

  @override
  Future<T?> get<T>(String key) async {
    final entry = _store[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _store.remove(key);
      return null;
    }
    return entry.value as T?;
  }

  @override
  Future<void> set<T>(String key, T value, {Duration? ttl}) async {
    final expiresAt = ttl != null ? DateTime.now().add(ttl) : null;
    _store[key] = _Entry(value, expiresAt);
  }

  @override
  Future<void> delete(String key) async => _store.remove(key);

  @override
  Future<void> clear() async => _store.clear();
}
```

**Step 5: Run tests**

```bash
cd ~/Flutter Base App && flutter test test/core/cache/memory_cache_service_test.dart
```

Expected: All 7 tests PASS.

**Step 6: Commit**

```bash
cd ~/Flutter Base App
git add lib/core/cache/ test/core/cache/memory_cache_service_test.dart
git commit -m "feat: add CacheService interface and MemoryCacheService"
```

---

## Task 3: Cache — PreferencesService

**Files:**
- Create: `lib/core/cache/preferences_service.dart`
- Create: `test/core/cache/preferences_service_test.dart`

**Step 1: Write the failing test**

Create `test/core/cache/preferences_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_base_app/core/cache/preferences_service.dart';

void main() {
  late PreferencesService prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = PreferencesService();
    await prefs.init();
  });

  group('PreferencesService', () {
    test('getString returns null for missing key', () {
      expect(prefs.getString('key'), isNull);
    });

    test('setString and getString round-trip', () async {
      await prefs.setString('locale', 'pt');
      expect(prefs.getString('locale'), 'pt');
    });

    test('getBool returns null for missing key', () {
      expect(prefs.getBool('flag'), isNull);
    });

    test('setBool and getBool round-trip', () async {
      await prefs.setBool('isLoggedIn', true);
      expect(prefs.getBool('isLoggedIn'), isTrue);
    });

    test('remove deletes a key', () async {
      await prefs.setString('key', 'value');
      await prefs.remove('key');
      expect(prefs.getString('key'), isNull);
    });

    test('clear removes all keys', () async {
      await prefs.setString('a', '1');
      await prefs.setBool('b', true);
      await prefs.clear();
      expect(prefs.getString('a'), isNull);
      expect(prefs.getBool('b'), isNull);
    });
  });
}
```

**Step 2: Run to verify it fails**

```bash
cd ~/Flutter Base App && flutter test test/core/cache/preferences_service_test.dart
```

Expected: FAIL — import error.

**Step 3: Create `lib/core/cache/preferences_service.dart`**

```dart
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String? getString(String key) => _prefs.getString(key);
  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);

  bool? getBool(String key) => _prefs.getBool(key);
  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);

  int? getInt(String key) => _prefs.getInt(key);
  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);

  double? getDouble(String key) => _prefs.getDouble(key);
  Future<bool> setDouble(String key, double value) =>
      _prefs.setDouble(key, value);

  Future<bool> remove(String key) => _prefs.remove(key);
  Future<bool> clear() => _prefs.clear();
}
```

**Step 4: Run tests**

```bash
cd ~/Flutter Base App && flutter test test/core/cache/preferences_service_test.dart
```

Expected: All 6 tests PASS.

**Step 5: Commit**

```bash
cd ~/Flutter Base App
git add lib/core/cache/preferences_service.dart test/core/cache/preferences_service_test.dart
git commit -m "feat: add PreferencesService wrapping SharedPreferences"
```

---

## Task 4: Cache — HiveCacheService

**Files:**
- Create: `lib/core/cache/hive_cache_service.dart`
- Create: `test/core/cache/hive_cache_service_test.dart`

**Step 1: Write the failing test**

Create `test/core/cache/hive_cache_service_test.dart`:

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_base_app/core/cache/hive_cache_service.dart';

void main() {
  late HiveCacheService cache;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    cache = HiveCacheService();
    await cache.init();
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('HiveCacheService', () {
    test('returns null for missing key', () async {
      expect(await cache.get<String>('missing'), isNull);
    });

    test('stores and retrieves a string', () async {
      await cache.set<String>('key', 'hello');
      expect(await cache.get<String>('key'), 'hello');
    });

    test('stores and retrieves an int', () async {
      await cache.set<int>('count', 7);
      expect(await cache.get<int>('count'), 7);
    });

    test('delete removes a key', () async {
      await cache.set<String>('key', 'value');
      await cache.delete('key');
      expect(await cache.get<String>('key'), isNull);
    });

    test('clear removes all keys', () async {
      await cache.set<String>('a', '1');
      await cache.set<String>('b', '2');
      await cache.clear();
      expect(await cache.get<String>('a'), isNull);
      expect(await cache.get<String>('b'), isNull);
    });

    test('expired entry returns null', () async {
      await cache.set<String>(
        'key',
        'value',
        ttl: const Duration(milliseconds: 1),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(await cache.get<String>('key'), isNull);
    });

    test('non-expired entry is still available', () async {
      await cache.set<String>('key', 'value', ttl: const Duration(hours: 24));
      expect(await cache.get<String>('key'), 'value');
    });
  });
}
```

**Step 2: Run to verify it fails**

```bash
cd ~/Flutter Base App && flutter test test/core/cache/hive_cache_service_test.dart
```

Expected: FAIL — import error.

**Step 3: Create `lib/core/cache/hive_cache_service.dart`**

```dart
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'cache_service.dart';

class HiveCacheService implements CacheService {
  static const _boxName = 'app_cache';
  late Box<String> _box;

  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  @override
  Future<T?> get<T>(String key) async {
    final raw = _box.get(key);
    if (raw == null) return null;

    final entry = jsonDecode(raw) as Map<String, dynamic>;
    final expiresAt = entry['expiresAt'] as int?;

    if (expiresAt != null &&
        DateTime.now().millisecondsSinceEpoch > expiresAt) {
      await _box.delete(key);
      return null;
    }

    return entry['value'] as T?;
  }

  @override
  Future<void> set<T>(String key, T value, {Duration? ttl}) async {
    final expiresAt = ttl != null
        ? DateTime.now().add(ttl).millisecondsSinceEpoch
        : null;

    final encoded = jsonEncode({'value': value, 'expiresAt': expiresAt});
    await _box.put(key, encoded);
  }

  @override
  Future<void> delete(String key) => _box.delete(key);

  @override
  Future<void> clear() async => _box.clear();
}
```

**Step 4: Run tests**

```bash
cd ~/Flutter Base App && flutter test test/core/cache/hive_cache_service_test.dart
```

Expected: All 7 tests PASS.

**Step 5: Commit**

```bash
cd ~/Flutter Base App
git add lib/core/cache/hive_cache_service.dart test/core/cache/hive_cache_service_test.dart
git commit -m "feat: add HiveCacheService with TTL support"
```

---

## Task 5: Internacionalização (i18n)

**Files:**
- Create: `l10n.yaml`
- Create: `lib/core/l10n/app_en.arb`
- Create: `lib/core/l10n/app_pt.arb`
- Create: `lib/core/l10n/l10n.dart`

> Tokens são gerados — sem testes unitários. Verificação: `flutter gen-l10n` sem erros + `flutter analyze` limpo.

**Step 1: Create `l10n.yaml` na raiz do projeto**

```yaml
arb-dir: lib/core/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-dir: lib/core/l10n/generated
nullable-getter: false
```

**Step 2: Create `lib/core/l10n/app_en.arb`**

```json
{
  "@@locale": "en",
  "appTitle": "Flutter Base App",
  "@appTitle": { "description": "The app name" },

  "homeGreeting": "Hello, Athlete",
  "@homeGreeting": { "description": "Greeting on home screen" },

  "homeMyWorkouts": "My Workouts",
  "@homeMyWorkouts": { "description": "Section title for workouts list" },

  "homeTodayWorkout": "Today's Workout",
  "@homeTodayWorkout": { "description": "Section title for today's workout" },

  "workoutStartButton": "Start Workout",
  "@workoutStartButton": { "description": "Button to start a workout" },

  "workoutNewButton": "New Workout",
  "@workoutNewButton": { "description": "Button to create a new workout" },

  "searchLabel": "Search workout",
  "@searchLabel": { "description": "Label for search input" },

  "searchHint": "e.g. Chest, Back, Legs...",
  "@searchHint": { "description": "Hint for search input" },

  "loginTitle": "Welcome back",
  "@loginTitle": { "description": "Title on login screen" },

  "loginEmailLabel": "E-mail",
  "@loginEmailLabel": { "description": "Label for email input" },

  "loginPasswordLabel": "Password",
  "@loginPasswordLabel": { "description": "Label for password input" },

  "loginButton": "Sign in",
  "@loginButton": { "description": "Login submit button" }
}
```

**Step 3: Create `lib/core/l10n/app_pt.arb`**

```json
{
  "@@locale": "pt",
  "appTitle": "Flutter Base App",
  "homeGreeting": "Olá, Atleta",
  "homeMyWorkouts": "Meus Treinos",
  "homeTodayWorkout": "Treino de Hoje",
  "workoutStartButton": "Iniciar Treino",
  "workoutNewButton": "Novo Treino",
  "searchLabel": "Buscar treino",
  "searchHint": "Ex: Peito, Costas, Pernas...",
  "loginTitle": "Bem-vindo de volta",
  "loginEmailLabel": "E-mail",
  "loginPasswordLabel": "Senha",
  "loginButton": "Entrar"
}
```

**Step 4: Run `flutter gen-l10n`**

```bash
cd ~/Flutter Base App && flutter gen-l10n
```

Expected: No errors. Files generated in `lib/core/l10n/generated/`.

**Step 5: Create `lib/core/l10n/l10n.dart` — extensão de conveniência**

```dart
import 'package:flutter/widgets.dart';
import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
```

**Step 6: Add generated directory to `.gitignore` and verify analyze**

Add to `.gitignore`:
```
# Generated l10n
lib/core/l10n/generated/
```

Run:
```bash
cd ~/Flutter Base App && flutter analyze
```

Expected: `No issues found!`

**Step 7: Commit**

```bash
cd ~/Flutter Base App
git add l10n.yaml lib/core/l10n/ .gitignore
git commit -m "feat: add i18n with pt and en ARB files and AppLocalizations extension"
```

---

## Task 6: Router + AuthService + Pages

**Files:**
- Create: `lib/core/router/app_routes.dart`
- Create: `lib/core/router/app_router.dart`
- Create: `lib/core/auth/auth_service.dart`
- Create: `lib/features/auth/presentation/login_page.dart`
- Create: `lib/features/home/presentation/home_page.dart` (mover de `lib/main.dart`)
- Create: `lib/app_shell.dart`
- Create: `test/core/router/app_router_test.dart`

**Step 1: Create `lib/core/router/app_routes.dart`**

```dart
abstract final class AppRoutes {
  static const login = '/login';
  static const home = '/';
  static const profile = '/profile';
}
```

**Step 2: Create `lib/core/auth/auth_service.dart`**

```dart
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;

  void login() {
    _isAuthenticated = true;
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }
}
```

**Step 3: Create `lib/app_shell.dart`**

```dart
import 'package:flutter/material.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}
```

**Step 4: Move `HomePage` to `lib/features/home/presentation/home_page.dart`**

Cut the classes `HomePage`, `_HomePageState`, `_Header`, `_TodayWorkoutCard`, `_StatChip`, `_WorkoutCard` from `lib/main.dart` and paste into the new file:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_base_app/core/l10n/l10n.dart';
import 'package:flutter_base_app/design_system/base_design_system.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(),
              const SizedBox(height: AppSpacing.xl),
              BaseInputField(
                label: context.l10n.searchLabel,
                hint: context.l10n.searchHint,
                controller: _searchController,
                prefixIcon: Icons.search_outlined,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(context.l10n.homeTodayWorkout, style: AppTypography.headingMd),
              const SizedBox(height: AppSpacing.md),
              const _TodayWorkoutCard(),
              const SizedBox(height: AppSpacing.xl),
              Text(context.l10n.homeMyWorkouts, style: AppTypography.headingMd),
              const SizedBox(height: AppSpacing.md),
              _WorkoutCard(
                name: 'Treino A — Peito',
                muscles: 'Peitoral · Ombro · Tríceps',
                exercises: 6,
                onTap: () {},
              ),
              const SizedBox(height: AppSpacing.md),
              _WorkoutCard(
                name: 'Treino B — Costas',
                muscles: 'Costas · Bíceps · Antebraço',
                exercises: 5,
                onTap: () {},
              ),
              const SizedBox(height: AppSpacing.md),
              _WorkoutCard(
                name: 'Treino C — Pernas',
                muscles: 'Quadríceps · Posterior · Glúteo',
                exercises: 7,
                onTap: () {},
              ),
              const SizedBox(height: AppSpacing.xl),
              BaseButton(
                label: context.l10n.workoutNewButton,
                onPressed: () {},
                variant: BaseButtonVariant.secondary,
                prefixIcon: Icons.add,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.homeGreeting, style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.xs),
            Text(context.l10n.appTitle, style: AppTypography.displayLg),
          ],
        ),
        BaseCard(
          padding: AppSpacing.sm,
          onTap: () {},
          child: const Icon(Icons.person_outline, color: AppColors.purple500, size: 24),
        ),
      ],
    );
  }
}

class _TodayWorkoutCard extends StatelessWidget {
  const _TodayWorkoutCard();

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      elevated: true,
      onTap: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: AppColors.purple500, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Text('Treino A — Peito', style: AppTypography.headingMd),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('Peitoral · Ombro · Tríceps', style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _StatChip(icon: Icons.fitness_center_outlined, label: '6 exercícios'),
              const SizedBox(width: AppSpacing.md),
              _StatChip(icon: Icons.timer_outlined, label: '~45 min'),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          BaseButton(
            label: context.l10n.workoutStartButton,
            onPressed: () {},
            prefixIcon: Icons.play_arrow_rounded,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 14),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final String name;
  final String muscles;
  final int exercises;
  final VoidCallback onTap;

  const _WorkoutCard({
    required this.name,
    required this.muscles,
    required this.exercises,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTypography.bodyMd),
                const SizedBox(height: AppSpacing.xs),
                Text(muscles, style: AppTypography.caption),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$exercises', style: AppTypography.headingMd.copyWith(color: AppColors.purple500)),
              Text('exercícios', style: AppTypography.caption),
            ],
          ),
        ],
      ),
    );
  }
}
```

**Step 5: Create `lib/features/auth/presentation/login_page.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_base_app/core/auth/auth_service.dart';
import 'package:flutter_base_app/core/l10n/l10n.dart';
import 'package:flutter_base_app/core/router/app_routes.dart';
import 'package:flutter_base_app/design_system/base_design_system.dart';

class LoginPage extends StatelessWidget {
  final AuthService authService;
  const LoginPage({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
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
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: AppSpacing.md),
              BaseInputField(
                label: context.l10n.loginPasswordLabel,
                isPassword: true,
                prefixIcon: Icons.lock_outlined,
              ),
              const SizedBox(height: AppSpacing.xl),
              BaseButton(
                label: context.l10n.loginButton,
                onPressed: () {
                  authService.login();
                  context.go(AppRoutes.home);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Step 6: Write the failing test**

Create `test/core/router/app_router_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_base_app/core/auth/auth_service.dart';
import 'package:flutter_base_app/core/l10n/l10n.dart';
import 'package:flutter_base_app/core/router/app_router.dart';
import 'package:flutter_base_app/features/auth/presentation/login_page.dart';
import 'package:flutter_base_app/features/home/presentation/home_page.dart';

Widget buildTestApp(AuthService authService) {
  return MaterialApp.router(
    routerConfig: createAppRouter(authService),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
}

void main() {
  group('AppRouter', () {
    testWidgets('redirects to LoginPage when not authenticated', (tester) async {
      final auth = AuthService();
      await tester.pumpWidget(buildTestApp(auth));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
    });

    testWidgets('shows HomePage when authenticated', (tester) async {
      final auth = AuthService()..login();
      await tester.pumpWidget(buildTestApp(auth));
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
    });

    testWidgets('redirects from login to home after login()', (tester) async {
      final auth = AuthService();
      await tester.pumpWidget(buildTestApp(auth));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);

      auth.login();
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
    });
  });
}
```

**Step 7: Run to verify it fails**

```bash
cd ~/Flutter Base App && flutter test test/core/router/app_router_test.dart
```

Expected: FAIL — import error.

**Step 8: Create `lib/core/router/app_router.dart`**

```dart
import 'package:go_router/go_router.dart';
import 'package:flutter_base_app/app_shell.dart';
import 'package:flutter_base_app/core/auth/auth_service.dart';
import 'package:flutter_base_app/core/router/app_routes.dart';
import 'package:flutter_base_app/features/auth/presentation/login_page.dart';
import 'package:flutter_base_app/features/home/presentation/home_page.dart';

GoRouter createAppRouter(AuthService authService) => GoRouter(
      initialLocation: AppRoutes.home,
      refreshListenable: authService,
      redirect: (context, state) {
        final isLoggedIn = authService.isAuthenticated;
        final isOnLogin = state.matchedLocation == AppRoutes.login;

        if (!isLoggedIn && !isOnLogin) return AppRoutes.login;
        if (isLoggedIn && isOnLogin) return AppRoutes.home;
        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.login,
          builder: (_, __) => LoginPage(authService: authService),
        ),
        ShellRoute(
          builder: (_, __, child) => AppShell(child: child),
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (_, __) => const HomePage(),
            ),
          ],
        ),
      ],
    );
```

**Step 9: Run tests**

```bash
cd ~/Flutter Base App && flutter test test/core/router/app_router_test.dart
```

Expected: All 3 tests PASS.

**Step 10: Commit**

```bash
cd ~/Flutter Base App
git add lib/core/router/ lib/core/auth/ lib/app_shell.dart lib/features/ test/core/router/
git commit -m "feat: add GoRouter with auth guard, AuthService, LoginPage and HomePage"
```

---

## Task 7: Wire everything in main.dart

**Files:**
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`

**Step 1: Replace `lib/main.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_base_app/core/auth/auth_service.dart';
import 'package:flutter_base_app/core/cache/hive_cache_service.dart';
import 'package:flutter_base_app/core/cache/preferences_service.dart';
import 'package:flutter_base_app/core/l10n/l10n.dart';
import 'package:flutter_base_app/core/router/app_router.dart';
import 'package:flutter_base_app/design_system/tokens/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  final hiveCache = HiveCacheService();
  await hiveCache.init();

  final preferences = PreferencesService();
  await preferences.init();

  final authService = AuthService();

  runApp(Flutter Base AppApp(authService: authService));
}

class Flutter Base AppApp extends StatelessWidget {
  final AuthService authService;

  const Flutter Base AppApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Base App',
      debugShowCheckedModeBanner: false,
      routerConfig: createAppRouter(authService),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.purple500,
          surface: AppColors.surface,
        ),
      ),
    );
  }
}
```

**Step 2: Update `test/widget_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_base_app/core/auth/auth_service.dart';
import 'package:flutter_base_app/core/l10n/l10n.dart';
import 'package:flutter_base_app/core/router/app_router.dart';

void main() {
  testWidgets('Flutter Base AppApp smoke test — unauthenticated shows login', (tester) async {
    final auth = AuthService();
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: createAppRouter(auth),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bem-vindo de volta'), findsOneWidget);
  });
}
```

**Step 3: Run full test suite**

```bash
cd ~/Flutter Base App && flutter test
```

Expected: All tests PASS.

**Step 4: Run flutter analyze**

```bash
cd ~/Flutter Base App && flutter analyze
```

Expected: `No issues found!`

**Step 5: Commit**

```bash
cd ~/Flutter Base App
git add lib/main.dart test/widget_test.dart
git commit -m "feat: wire router, i18n, Hive and SharedPreferences in main.dart"
```
