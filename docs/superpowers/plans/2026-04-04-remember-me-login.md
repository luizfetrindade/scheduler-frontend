# Remember Me — Login — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a "Lembrar de mim" checkbox to the login flow that pre-fills the e-mail on the next launch and extends the refresh-token session from 7 to 30 days when checked.

**Architecture:** Full-stack change. Frontend adds a local `RememberMeStorage` (SharedPreferences wrapper), a checkbox on the e-mail screen, and carries the flag through to the TOTP/password step via `GoRouter` `extra`. Backend DTOs accept `rememberMe`, and `generateTokens` selects a TTL (7d short / 30d long) applied to both the Redis refresh record and the `Set-Cookie` `maxAge`.

**Tech Stack:** Flutter (flutter_bloc, go_router, shared_preferences, mocktail, bloc_test), NestJS 11 with Zod validation, Prisma, Redis.

**Spec:** `docs/superpowers/specs/2026-04-04-remember-me-login-design.md`

---

## Reference — key existing files

**Frontend** (`scheduler-frontend/`):
- `lib/core/auth/auth_bloc.dart` — handlers for `AuthTotpLoginSubmitted` (line 58) and `AuthPasswordLoginRequested` (line 159).
- `lib/core/auth/auth_event.dart` — `AuthTotpLoginSubmitted` (line 23), `AuthPasswordLoginRequested` (line 72).
- `lib/core/auth/auth_repository.dart` — `loginWithTotp` (line 39), `loginWithPassword` (line 98).
- `lib/core/network/api_client.dart` — `loginWithPassword` helper (line 185). NOTE: the current route string there is `/auth/login/password`, but the backend only serves `/auth/login`. As part of Task 9 we replace this helper with a raw `post` to the correct path `/auth/login`.
- `lib/features/auth/presentation/login_page.dart` — step 1 e-mail screen. `_EmailStep` at line 279 is where the checkbox goes.
- `lib/features/auth/presentation/totp_login_page.dart` — step 2 TOTP. Dispatches event at line 31.
- `lib/features/auth/presentation/password_login_page.dart` — step 2 password. Dispatches event at line 32.
- `lib/core/router/app_router.dart` — `/login/totp` (line 72) and `/login/password` (line 77) read `state.extra as String`.
- `lib/core/l10n/app_pt.arb`, `lib/core/l10n/app_en.arb` — l10n source files; run `make l10n` after edit.
- `test/core/auth/auth_bloc_test.dart` — existing bloc tests to extend.

**Backend** (`scheduler-backend/`):
- `src/modules/auth/auth.controller.ts` — `loginTotp` (line 232), `login` (line 262). `setRefreshCookie` helper at line 334 with hard-coded `REFRESH_COOKIE_MAX_AGE_MS = 604_800 * 1_000` (line 43).
- `src/modules/auth/auth.service.ts` — `loginTotp` (line 133), `login` (line 156), `generateTokens` (line 378) reads TTL from `jwt.refreshExpiresIn`.
- `src/modules/auth/dto/totp-login.dto.ts`, `src/modules/auth/dto/login.dto.ts` — Zod schemas.
- `src/config/` — config factory where `jwt.refreshExpiresIn` is declared.

---

## File structure

**New files**
- `scheduler-frontend/lib/core/auth/remember_me_storage.dart`
- `scheduler-frontend/test/core/auth/remember_me_storage_test.dart`

**Modified files — frontend**
- `lib/core/auth/auth_event.dart`
- `lib/core/auth/auth_bloc.dart`
- `lib/core/auth/auth_repository.dart`
- `lib/core/network/api_client.dart`
- `lib/features/auth/presentation/login_page.dart`
- `lib/features/auth/presentation/totp_login_page.dart`
- `lib/features/auth/presentation/password_login_page.dart`
- `lib/core/router/app_router.dart`
- `lib/core/l10n/app_pt.arb`
- `lib/core/l10n/app_en.arb`
- `test/core/auth/auth_bloc_test.dart`
- `main.dart` — inject `RememberMeStorage` into `AuthRepository`.

**Modified files — backend**
- `src/modules/auth/dto/totp-login.dto.ts`
- `src/modules/auth/dto/login.dto.ts`
- `src/modules/auth/auth.service.ts`
- `src/modules/auth/auth.controller.ts`
- `src/modules/auth/auth.service.spec.ts`
- `src/modules/auth/auth.controller.spec.ts`
- `src/config/jwt.config.ts` (or wherever `jwt.refreshExpiresIn` lives) — add `refreshExpiresInLong`.
- `.env.example`

---

## Implementation order

Backend first so the API accepts `rememberMe` before the frontend starts sending it. Frontend then layers on from the data layer (storage → repository → bloc → UI).

---

## Task 1: Backend — DTOs accept `rememberMe`

**Files:**
- Modify: `scheduler-backend/src/modules/auth/dto/totp-login.dto.ts`
- Modify: `scheduler-backend/src/modules/auth/dto/login.dto.ts`

- [ ] **Step 1: Update `totp-login.dto.ts`**

```ts
import { z } from 'zod';

export const TotpLoginSchema = z.object({
  email: z.string().email(),
  code: z.string().length(6),
  rememberMe: z.boolean().optional().default(false),
});

export type TotpLoginDto = z.infer<typeof TotpLoginSchema>;
```

- [ ] **Step 2: Update `login.dto.ts`**

```ts
import { z } from 'zod';

export const LoginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
  rememberMe: z.boolean().optional().default(false),
});

export type LoginDto = z.infer<typeof LoginSchema>;
```

- [ ] **Step 3: Run DTO compilation check**

```bash
cd scheduler-backend && npx tsc --noEmit
```

Expected: no errors. `rememberMe` is now a typed, defaulted field on both DTOs.

- [ ] **Step 4: Commit**

```bash
cd scheduler-backend
git add src/modules/auth/dto/totp-login.dto.ts src/modules/auth/dto/login.dto.ts
git commit -m "feat(auth): accept rememberMe flag in login DTOs"
```

---

## Task 2: Backend — Config for long refresh TTL

**Files:**
- Modify: `scheduler-backend/.env.example`
- Modify: `scheduler-backend/src/config/jwt.config.ts` (or whichever config file declares `refreshExpiresIn`)

- [ ] **Step 1: Locate the current `refreshExpiresIn` declaration**

```bash
cd scheduler-backend && grep -rn "refreshExpiresIn" src/config/
```

Expected: one or two hits pointing at a `registerAs('jwt', ...)` factory. Open that file.

- [ ] **Step 2: Add a second TTL field**

In the same factory, next to the existing `refreshExpiresIn`, add:

```ts
// Short session = default when rememberMe is false.
refreshExpiresIn: parseInt(process.env.REFRESH_TOKEN_TTL_SHORT ?? '604800', 10), // 7 days in seconds
// Long session = applied when rememberMe is true.
refreshExpiresInLong: parseInt(process.env.REFRESH_TOKEN_TTL_LONG ?? '2592000', 10), // 30 days in seconds
```

If the existing factory already uses a different var name (e.g. `JWT_REFRESH_EXPIRES_IN`), keep that name for `refreshExpiresIn` and **add** the two new env vars alongside. Do not rename existing keys.

- [ ] **Step 3: Update `.env.example`**

Append:

```env
# Refresh token TTLs in seconds. Short applies to normal logins; long
# applies when the user checks "Lembrar de mim" on the login screen.
REFRESH_TOKEN_TTL_SHORT=604800
REFRESH_TOKEN_TTL_LONG=2592000
```

- [ ] **Step 4: Type check**

```bash
cd scheduler-backend && npx tsc --noEmit
```

Expected: no errors.

- [ ] **Step 5: Commit**

```bash
cd scheduler-backend
git add src/config/ .env.example
git commit -m "feat(auth): add REFRESH_TOKEN_TTL_LONG config"
```

---

## Task 3: Backend — `generateTokens` picks TTL from flag

**Files:**
- Modify: `scheduler-backend/src/modules/auth/auth.service.ts`
- Modify: `scheduler-backend/src/modules/auth/auth.service.spec.ts`

- [ ] **Step 1: Write the failing spec**

Open `auth.service.spec.ts` and add a new `describe` block. Match the style of the existing specs in that file (look at how `loginTotp` / `login` are currently tested and reuse the same `beforeEach` setup and mocks).

```ts
describe('generateTokens (rememberMe TTL)', () => {
  it('uses short TTL when rememberMe is false', async () => {
    // Arrange: mock config to return 604800 for refreshExpiresIn
    //   and 2592000 for refreshExpiresInLong.
    // Mock redis.set, prisma.user.findUnique, etc. the same way the existing
    // loginTotp spec does.

    // Act
    const result = await service.login({
      email: 'u@u.com',
      password: 'pw',
      rememberMe: false,
    });

    // Assert: redis.set was called with ttl = 604800
    expect(redisService.set).toHaveBeenCalledWith(
      expect.stringMatching(/^refresh:/),
      '1',
      604800,
    );
    expect(result.refreshTtlSeconds).toBe(604800);
  });

  it('uses long TTL when rememberMe is true', async () => {
    const result = await service.login({
      email: 'u@u.com',
      password: 'pw',
      rememberMe: true,
    });

    expect(redisService.set).toHaveBeenCalledWith(
      expect.stringMatching(/^refresh:/),
      '1',
      2592000,
    );
    expect(result.refreshTtlSeconds).toBe(2592000);
  });
});
```

- [ ] **Step 2: Run the spec to verify it fails**

```bash
cd scheduler-backend && npx jest src/modules/auth/auth.service.spec.ts -t "rememberMe TTL"
```

Expected: FAIL — `refreshTtlSeconds` is not yet returned by `generateTokens`.

- [ ] **Step 3: Update `generateTokens` to accept a TTL and return it**

In `auth.service.ts`, replace the current `generateTokens` (line ~378) with:

```ts
private async generateTokens(
  userId: string,
  email: string,
  roles: string[],
  rememberMe: boolean = false,
) {
  const tokenId = randomUUID();
  const ttl = rememberMe
    ? this.configService.get<number>('jwt.refreshExpiresInLong')!
    : this.configService.get<number>('jwt.refreshExpiresIn')!;

  const accessToken = this.jwtService.sign({ sub: userId, email, roles });

  const refreshToken = `${userId}:${tokenId}`;
  await this.redis.set(`refresh:${userId}:${tokenId}`, '1', ttl);

  return { accessToken, refreshToken, refreshTtlSeconds: ttl };
}
```

- [ ] **Step 4: Forward `rememberMe` from `login` and `loginTotp`**

In the same file, update both methods to pass `dto.rememberMe` through:

```ts
async loginTotp(dto: TotpLoginDto) {
  // ... existing validation ...
  const roleNames = user.roles.map((r) => r.name);
  return this.generateTokens(user.id, user.email, roleNames, dto.rememberMe);
}

async login(dto: LoginDto) {
  // ... existing validation ...
  const roleNames = user.roles.map((r) => r.name);
  return this.generateTokens(user.id, user.email, roleNames, dto.rememberMe);
}
```

Do **not** add `rememberMe` to `confirmTotpSetup`, `acceptInvite`, or `refresh` — those are out of scope (spec §Non-goals). They keep using the default (short TTL).

- [ ] **Step 5: Run the spec to verify it passes**

```bash
cd scheduler-backend && npx jest src/modules/auth/auth.service.spec.ts -t "rememberMe TTL"
```

Expected: PASS.

- [ ] **Step 6: Run the full auth service test file to check for regressions**

```bash
cd scheduler-backend && npx jest src/modules/auth/auth.service.spec.ts
```

Expected: all existing tests still pass. Any existing tests that assert the shape of the `generateTokens` return will need to tolerate the new `refreshTtlSeconds` field — if a test uses a strict equality check on the return object, loosen it to only assert the fields it cares about.

- [ ] **Step 7: Commit**

```bash
cd scheduler-backend
git add src/modules/auth/auth.service.ts src/modules/auth/auth.service.spec.ts
git commit -m "feat(auth): select refresh TTL from rememberMe flag"
```

---

## Task 4: Backend — Controller sets cookie `maxAge` dynamically

**Files:**
- Modify: `scheduler-backend/src/modules/auth/auth.controller.ts`
- Modify: `scheduler-backend/src/modules/auth/auth.controller.spec.ts`

- [ ] **Step 1: Write the failing spec**

Open `auth.controller.spec.ts`. Add:

```ts
describe('login rememberMe cookie', () => {
  it('sets maxAge to 30 days when rememberMe is true', async () => {
    const mockRes = {
      cookie: jest.fn(),
    } as unknown as Response;

    jest.spyOn(authService, 'login').mockResolvedValue({
      accessToken: 'a',
      refreshToken: 'u:t',
      refreshTtlSeconds: 2592000,
    });

    await controller.login(
      { email: 'u@u.com', password: 'pw', rememberMe: true },
      mockRes,
    );

    expect(mockRes.cookie).toHaveBeenCalledWith(
      'refresh_token',
      'u:t',
      expect.objectContaining({ maxAge: 2592000 * 1000 }),
    );
  });

  it('sets maxAge to 7 days when rememberMe is false', async () => {
    const mockRes = { cookie: jest.fn() } as unknown as Response;

    jest.spyOn(authService, 'login').mockResolvedValue({
      accessToken: 'a',
      refreshToken: 'u:t',
      refreshTtlSeconds: 604800,
    });

    await controller.login(
      { email: 'u@u.com', password: 'pw', rememberMe: false },
      mockRes,
    );

    expect(mockRes.cookie).toHaveBeenCalledWith(
      'refresh_token',
      'u:t',
      expect.objectContaining({ maxAge: 604800 * 1000 }),
    );
  });
});
```

Mirror the existing `auth.controller.spec.ts` setup (imports, `beforeEach`, module compile) — reuse that scaffolding. If the existing controller spec uses a different pattern for mocking `authService`, follow that pattern.

- [ ] **Step 2: Run the spec to verify it fails**

```bash
cd scheduler-backend && npx jest src/modules/auth/auth.controller.spec.ts -t "rememberMe cookie"
```

Expected: FAIL — `setRefreshCookie` currently ignores TTL.

- [ ] **Step 3: Refactor `setRefreshCookie` to take a TTL**

In `auth.controller.ts`, replace the constant and helper:

```ts
// Delete the old constant:
// const REFRESH_COOKIE_MAX_AGE_MS = 604_800 * 1_000;

// Replace setRefreshCookie:
private setRefreshCookie(
  res: Response,
  token: string,
  ttlSeconds: number,
): void {
  const isProduction = process.env.NODE_ENV === 'production';
  res.cookie(REFRESH_COOKIE, token, {
    httpOnly: true,
    secure: isProduction,
    sameSite: 'strict',
    maxAge: ttlSeconds * 1000,
    path: '/auth',
  });
}
```

- [ ] **Step 4: Update all call sites of `setRefreshCookie`**

There are four existing call sites: `confirmTotpSetup`, `loginTotp`, `login`, `acceptInvite`, `refresh`. Each now passes the `refreshTtlSeconds` returned by the service.

`login` (pattern for the rest):

```ts
async login(
  @Body(new ZodValidationPipe(LoginSchema)) dto: LoginDto,
  @Res({ passthrough: true }) res: Response,
) {
  const { accessToken, refreshToken, refreshTtlSeconds } =
    await this.authService.login(dto);
  this.setRefreshCookie(res, refreshToken, refreshTtlSeconds);
  return { accessToken };
}
```

Repeat for `loginTotp`, `confirmTotpSetup`, `acceptInvite`, and `refresh` — each destructures `refreshTtlSeconds` from the service call and passes it as the third argument. For the three out-of-scope flows (`confirmTotpSetup`, `acceptInvite`, `refresh`), the service still calls `generateTokens` without a `rememberMe` arg, so `refreshTtlSeconds` will be the short-TTL value — that preserves current behaviour.

- [ ] **Step 5: Run the spec to verify it passes**

```bash
cd scheduler-backend && npx jest src/modules/auth/auth.controller.spec.ts
```

Expected: all tests pass, including the two new ones.

- [ ] **Step 6: Run the full backend test suite**

```bash
cd scheduler-backend && npm test
```

Expected: green.

- [ ] **Step 7: Commit**

```bash
cd scheduler-backend
git add src/modules/auth/auth.controller.ts src/modules/auth/auth.controller.spec.ts
git commit -m "feat(auth): dynamic refresh cookie maxAge from rememberMe"
```

---

## Task 5: Backend — E2E coverage

**Files:**
- Modify: `scheduler-backend/test/auth.e2e-spec.ts` (or the existing e2e file covering auth)

- [ ] **Step 1: Locate the existing auth e2e file**

```bash
cd scheduler-backend && ls test/ && grep -l "login" test/*.e2e-spec.ts
```

Pick the file that already exercises `/auth/login`. If none exists, skip this task and add a TODO in the final commit — but based on CLAUDE.md (`npm run test:e2e`), one should exist.

- [ ] **Step 2: Add two assertions**

Add a new `describe('POST /auth/login with rememberMe')` block. Use `request(app.getHttpServer()).post('/auth/login').send({ ... })` matching the file's existing style. Assert that the `Set-Cookie` header for `refresh_token` contains `Max-Age=2592000` when `rememberMe: true` is sent, and `Max-Age=604800` when `rememberMe: false` or omitted.

```ts
it('sets Max-Age=2592000 on refresh cookie when rememberMe is true', async () => {
  const res = await request(app.getHttpServer())
    .post('/auth/login')
    .send({ email: 'seeded@user.com', password: 'seededpw', rememberMe: true })
    .expect(200);

  const cookies = res.headers['set-cookie'] as unknown as string[];
  const refreshCookie = cookies.find((c) => c.startsWith('refresh_token='));
  expect(refreshCookie).toMatch(/Max-Age=2592000/);
});

it('sets Max-Age=604800 on refresh cookie when rememberMe is false', async () => {
  const res = await request(app.getHttpServer())
    .post('/auth/login')
    .send({ email: 'seeded@user.com', password: 'seededpw', rememberMe: false })
    .expect(200);

  const cookies = res.headers['set-cookie'] as unknown as string[];
  const refreshCookie = cookies.find((c) => c.startsWith('refresh_token='));
  expect(refreshCookie).toMatch(/Max-Age=604800/);
});
```

Reuse whatever seeded-user credentials the existing e2e login test already uses — do not invent new fixtures.

- [ ] **Step 3: Run e2e**

```bash
cd scheduler-backend && npm run test:e2e -- --testNamePattern="rememberMe"
```

Expected: PASS. If the full e2e suite needs infra (Postgres/Redis), follow the existing `npm run docker:infra` flow from CLAUDE.md.

- [ ] **Step 4: Commit**

```bash
cd scheduler-backend
git add test/auth.e2e-spec.ts
git commit -m "test(auth): e2e coverage for rememberMe cookie maxAge"
```

---

## Task 6: Frontend — `RememberMeStorage`

**Files:**
- Create: `scheduler-frontend/lib/core/auth/remember_me_storage.dart`
- Create: `scheduler-frontend/test/core/auth/remember_me_storage_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/core/auth/remember_me_storage_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/core/auth/remember_me_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RememberMeStorage', () {
    test('load() returns (null, false) when empty', () async {
      final storage = RememberMeStorage();
      final result = await storage.load();
      expect(result.email, isNull);
      expect(result.enabled, isFalse);
    });

    test('save() persists email and sets enabled=true', () async {
      final storage = RememberMeStorage();
      await storage.save(email: 'a@a.com');

      final result = await storage.load();
      expect(result.email, 'a@a.com');
      expect(result.enabled, isTrue);
    });

    test('clear() removes both keys', () async {
      final storage = RememberMeStorage();
      await storage.save(email: 'a@a.com');
      await storage.clear();

      final result = await storage.load();
      expect(result.email, isNull);
      expect(result.enabled, isFalse);
    });

    test('save() overwrites a previously stored email', () async {
      final storage = RememberMeStorage();
      await storage.save(email: 'a@a.com');
      await storage.save(email: 'b@b.com');

      final result = await storage.load();
      expect(result.email, 'b@b.com');
      expect(result.enabled, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd scheduler-frontend && flutter test test/core/auth/remember_me_storage_test.dart
```

Expected: FAIL — file not found.

- [ ] **Step 3: Implement `RememberMeStorage`**

Create `lib/core/auth/remember_me_storage.dart`:

```dart
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's "Lembrar de mim" choice across app launches.
///
/// Stores only the e-mail — never credentials. Access tokens remain in the
/// existing [TokenStorage]. The e-mail is an identifier, not a secret, so
/// SharedPreferences is sufficient.
class RememberMeStorage {
  static const _kEmailKey = 'remember_me_email';
  static const _kEnabledKey = 'remember_me_enabled';

  /// Reads the persisted state. Returns `(null, false)` if nothing has been
  /// saved or the user previously cleared the preference.
  Future<({String? email, bool enabled})> load() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_kEnabledKey) ?? false;
    final email = enabled ? prefs.getString(_kEmailKey) : null;
    return (email: email, enabled: enabled);
  }

  /// Persists [email] and sets the "enabled" flag to true. Overwrites any
  /// previously stored value.
  Future<void> save({required String email}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kEmailKey, email);
    await prefs.setBool(_kEnabledKey, true);
  }

  /// Removes both keys. Used when the user unchecks the box on a successful
  /// login.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kEmailKey);
    await prefs.remove(_kEnabledKey);
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
cd scheduler-frontend && flutter test test/core/auth/remember_me_storage_test.dart
```

Expected: all 4 tests PASS.

- [ ] **Step 5: Commit**

```bash
cd scheduler-frontend
git add lib/core/auth/remember_me_storage.dart test/core/auth/remember_me_storage_test.dart
git commit -m "feat(auth): add RememberMeStorage for local email persistence"
```

---

## Task 7: Frontend — `AuthEvent` gains `rememberMe`

**Files:**
- Modify: `scheduler-frontend/lib/core/auth/auth_event.dart`

This task only updates event data classes — it does not add new behaviour. Tests come in Task 9 together with the bloc changes (bloc tests exercise events).

- [ ] **Step 1: Add `rememberMe` to `AuthTotpLoginSubmitted`**

In `lib/core/auth/auth_event.dart`, replace the existing class (line 23) with:

```dart
/// Step 2 of login: submit the 6-digit TOTP code from Google Authenticator.
class AuthTotpLoginSubmitted extends AuthEvent {
  final String email;
  final String code;
  final bool rememberMe;
  const AuthTotpLoginSubmitted({
    required this.email,
    required this.code,
    required this.rememberMe,
  });
  @override
  // TOTP code excluded from props — Equatable serialises props in toString(),
  // which leaks into debug logs and crash reporters.
  List<Object?> get props => [email, rememberMe];
}
```

- [ ] **Step 2: Add `rememberMe` to `AuthPasswordLoginRequested`**

Replace the class at line 72:

```dart
/// Login with email + password (for staff/member personas).
class AuthPasswordLoginRequested extends AuthEvent {
  final String email;
  final String password;
  final bool rememberMe;
  const AuthPasswordLoginRequested({
    required this.email,
    required this.password,
    required this.rememberMe,
  });
  @override
  // Password excluded — must not appear in Equatable's toString() output.
  List<Object?> get props => [email, rememberMe];
}
```

- [ ] **Step 3: Run analyzer to find compile errors from new required field**

```bash
cd scheduler-frontend && flutter analyze lib/
```

Expected: errors at every call site that constructs these events without `rememberMe`. They will be fixed in Tasks 10 and 11. Do not commit yet — this task's change is coupled to Task 8's compile fixes in the bloc.

---

## Task 8: Frontend — `AuthRepository` accepts `rememberMe` + delegates storage

**Files:**
- Modify: `scheduler-frontend/lib/core/auth/auth_repository.dart`
- Modify: `scheduler-frontend/lib/core/network/api_client.dart`

- [ ] **Step 1: Replace `AuthRepository` constructor and login methods**

In `lib/core/auth/auth_repository.dart`, update imports and the class so it owns a `RememberMeStorage`, and propagate `rememberMe` into the two login methods:

```dart
import 'package:flutter_http/flutter_http.dart';
import 'package:scheduler_frontend/core/auth/remember_me_storage.dart';
import 'package:scheduler_frontend/core/models/user_model.dart';
import 'package:scheduler_frontend/core/network/api_client.dart';

typedef TokenRecord = ({String accessToken});

typedef TotpSetupRecord = ({
  String qrCodeUrl,
  String secret,
  String tempToken
});

class AuthRepository {
  final ApiClient _client;
  final RememberMeStorage _rememberMe;

  AuthRepository(this._client, this._rememberMe);

  // ... verifyEmail unchanged ...

  Future<Result<TokenRecord>> loginWithTotp({
    required String email,
    required String code,
    required bool rememberMe,
  }) async {
    final result = await _client.post<Map<String, dynamic>>(
      '/auth/login/totp',
      fromJson: (json) => json,
      body: {'email': email, 'code': code, 'rememberMe': rememberMe},
    );
    return switch (result) {
      Success(:final data) => Success((
          accessToken: data['accessToken'] as String,
        )),
      HttpFailure(:final failure) => HttpFailure(failure),
    };
  }

  Future<Result<TokenRecord>> loginWithPassword({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final result = await _client.loginWithPassword(
      email: email,
      password: password,
      rememberMe: rememberMe,
    );
    return switch (result) {
      Success(:final data) => Success((
          accessToken: data['accessToken'] as String,
        )),
      HttpFailure(:final failure) => HttpFailure(failure),
    };
  }

  // ... register, confirmTotpSetup, checkEmail, forgotPassword, resetPassword,
  //     acceptInvite, getMe, saveTokens, logout, clearTokens — ALL UNCHANGED ...

  /// Reads the persisted "Lembrar de mim" state for pre-filling the login UI.
  Future<({String? email, bool enabled})> loadRememberMe() =>
      _rememberMe.load();

  /// Persists the e-mail after a successful login when the box was checked.
  Future<void> saveRememberMe(String email) => _rememberMe.save(email: email);

  /// Clears the persisted e-mail when the box is unchecked on a successful login.
  Future<void> clearRememberMe() => _rememberMe.clear();
}
```

The non-login methods (`register`, `confirmTotpSetup`, `checkEmail`, `forgotPassword`, `resetPassword`, `acceptInvite`, `getMe`, `saveTokens`, `logout`, `clearTokens`) keep their current bodies unchanged — do **not** rewrite them during this task.

- [ ] **Step 2: Replace `ApiClient.loginWithPassword`**

In `lib/core/network/api_client.dart`, delete the existing `loginWithPassword` helper (line 185) and replace it with one that accepts `rememberMe` and targets the correct backend route `/auth/login` (the old string `/auth/login/password` does not exist on the backend):

```dart
/// POST /auth/login — returns { accessToken }
Future<Result<Map<String, dynamic>>> loginWithPassword({
  required String email,
  required String password,
  required bool rememberMe,
}) =>
    post<Map<String, dynamic>>(
      '/auth/login',
      fromJson: (json) => json,
      body: {
        'email': email,
        'password': password,
        'rememberMe': rememberMe,
      },
    );
```

- [ ] **Step 3: Update `main.dart` to inject `RememberMeStorage`**

```bash
cd scheduler-frontend && grep -n "AuthRepository(" lib/main.dart
```

At the line where `AuthRepository` is constructed, pass a new `RememberMeStorage()`:

```dart
import 'package:scheduler_frontend/core/auth/remember_me_storage.dart';
// ...
final authRepository = AuthRepository(apiClient, RememberMeStorage());
```

If `main.dart` uses a different variable name for the ApiClient, keep that — just add the second argument.

- [ ] **Step 4: Run analyzer**

```bash
cd scheduler-frontend && flutter analyze lib/
```

Expected: errors only at the bloc / UI call sites that will be fixed in Tasks 9–12. The repository, api_client, and main.dart themselves should be clean.

- [ ] **Step 5: Commit (partial — frontend compile will be fixed in Task 9)**

Do **not** commit yet. Keep this change in the working tree until Task 9 restores compilation.

---

## Task 9: Frontend — `AuthBloc` forwards `rememberMe` and persists on success

**Files:**
- Modify: `scheduler-frontend/lib/core/auth/auth_bloc.dart`
- Modify: `scheduler-frontend/test/core/auth/auth_bloc_test.dart`

- [ ] **Step 1: Write the failing bloc tests**

In `test/core/auth/auth_bloc_test.dart`, extend the existing TOTP and password login groups. Add these inside the existing `group('AuthBloc — AuthTotpLoginSubmitted', ...)` block (or create it if missing):

```dart
blocTest<AuthBloc, AuthState>(
  'saves remember-me on successful TOTP login when rememberMe=true',
  setUp: () {
    when(() => mockRepo.loginWithTotp(
          email: 'j@j.com',
          code: '123456',
          rememberMe: true,
        )).thenAnswer(
      (_) async => const Success((accessToken: 'a')),
    );
    when(() => mockRepo.saveTokens(any())).thenAnswer((_) async {});
    when(() => mockRepo.getMe())
        .thenAnswer((_) async => const Success(_user));
    when(() => mockRepo.saveRememberMe(any())).thenAnswer((_) async {});
  },
  build: () => AuthBloc(mockRepo),
  act: (bloc) => bloc.add(const AuthTotpLoginSubmitted(
    email: 'j@j.com',
    code: '123456',
    rememberMe: true,
  )),
  expect: () => [const AuthLoading(), const AuthAuthenticated(_user)],
  verify: (_) {
    verify(() => mockRepo.saveRememberMe('j@j.com')).called(1);
    verifyNever(() => mockRepo.clearRememberMe());
  },
);

blocTest<AuthBloc, AuthState>(
  'clears remember-me on successful TOTP login when rememberMe=false',
  setUp: () {
    when(() => mockRepo.loginWithTotp(
          email: 'j@j.com',
          code: '123456',
          rememberMe: false,
        )).thenAnswer(
      (_) async => const Success((accessToken: 'a')),
    );
    when(() => mockRepo.saveTokens(any())).thenAnswer((_) async {});
    when(() => mockRepo.getMe())
        .thenAnswer((_) async => const Success(_user));
    when(() => mockRepo.clearRememberMe()).thenAnswer((_) async {});
  },
  build: () => AuthBloc(mockRepo),
  act: (bloc) => bloc.add(const AuthTotpLoginSubmitted(
    email: 'j@j.com',
    code: '123456',
    rememberMe: false,
  )),
  expect: () => [const AuthLoading(), const AuthAuthenticated(_user)],
  verify: (_) {
    verify(() => mockRepo.clearRememberMe()).called(1);
    verifyNever(() => mockRepo.saveRememberMe(any()));
  },
);

blocTest<AuthBloc, AuthState>(
  'does not touch remember-me when TOTP login fails',
  setUp: () {
    when(() => mockRepo.loginWithTotp(
          email: 'j@j.com',
          code: '123456',
          rememberMe: true,
        )).thenAnswer(
      (_) async => const HttpFailure(UnauthorizedFailure('bad code')),
    );
  },
  build: () => AuthBloc(mockRepo),
  act: (bloc) => bloc.add(const AuthTotpLoginSubmitted(
    email: 'j@j.com',
    code: '123456',
    rememberMe: true,
  )),
  expect: () => [
    const AuthLoading(),
    const AuthError('Código inválido ou expirado. Tente novamente.'),
  ],
  verify: (_) {
    verifyNever(() => mockRepo.saveRememberMe(any()));
    verifyNever(() => mockRepo.clearRememberMe());
  },
);
```

Duplicate the same three tests for `AuthPasswordLoginRequested`, swapping `loginWithTotp` for `loginWithPassword` and the event class. Use `password: 'pw'` instead of `code: '123456'`.

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd scheduler-frontend && flutter test test/core/auth/auth_bloc_test.dart
```

Expected: the six new tests FAIL (bloc does not yet forward `rememberMe` or call save/clear). Pre-existing tests should still be failing too because `AuthTotpLoginSubmitted` and `AuthPasswordLoginRequested` constructors in older tests now miss the required `rememberMe` arg — go update those existing tests to pass `rememberMe: false` so only the new behaviour is exercised by the new cases.

- [ ] **Step 3: Update `_onTotpLoginSubmitted`**

In `auth_bloc.dart`, replace the handler (line 58) with:

```dart
Future<void> _onTotpLoginSubmitted(
  AuthTotpLoginSubmitted event,
  Emitter<AuthState> emit,
) async {
  emit(const AuthLoading());
  final loginResult = await _repository.loginWithTotp(
    email: event.email,
    code: event.code,
    rememberMe: event.rememberMe,
  );
  switch (loginResult) {
    case Success(:final data):
      await _repository.saveTokens(data.accessToken);
      await _persistRememberMe(event.email, event.rememberMe);
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
```

- [ ] **Step 4: Update `_onPasswordLoginRequested`**

Replace the handler (line 159) with the equivalent, forwarding `rememberMe` and calling `_persistRememberMe` after `saveTokens`:

```dart
Future<void> _onPasswordLoginRequested(
  AuthPasswordLoginRequested event,
  Emitter<AuthState> emit,
) async {
  emit(const AuthLoading());
  final loginResult = await _repository.loginWithPassword(
    email: event.email,
    password: event.password,
    rememberMe: event.rememberMe,
  );
  switch (loginResult) {
    case Success(:final data):
      await _repository.saveTokens(data.accessToken);
      await _persistRememberMe(event.email, event.rememberMe);
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
```

- [ ] **Step 5: Add the helper**

At the bottom of the class, above `_message`, add:

```dart
/// Persists the "Lembrar de mim" choice after a successful login.
/// Called exactly once per successful login, never on failure.
Future<void> _persistRememberMe(String email, bool rememberMe) async {
  if (rememberMe) {
    await _repository.saveRememberMe(email);
  } else {
    await _repository.clearRememberMe();
  }
}
```

- [ ] **Step 6: Run the bloc test file**

```bash
cd scheduler-frontend && flutter test test/core/auth/auth_bloc_test.dart
```

Expected: all tests PASS, including the six new ones.

- [ ] **Step 7: Commit**

```bash
cd scheduler-frontend
git add lib/core/auth/auth_event.dart lib/core/auth/auth_bloc.dart \
        lib/core/auth/auth_repository.dart lib/core/network/api_client.dart \
        lib/main.dart test/core/auth/auth_bloc_test.dart
git commit -m "feat(auth): forward rememberMe through bloc and repository"
```

---

## Task 10: Frontend — L10n string

**Files:**
- Modify: `scheduler-frontend/lib/core/l10n/app_pt.arb`
- Modify: `scheduler-frontend/lib/core/l10n/app_en.arb`

- [ ] **Step 1: Add the pt_BR string**

In `app_pt.arb`, add (alphabetically near other `login*` keys):

```json
"loginRememberMe": "Lembrar de mim",
"@loginRememberMe": {
  "description": "Checkbox label on the login screen to persist the user's session and e-mail"
}
```

- [ ] **Step 2: Add the en string (keeps generator happy)**

In `app_en.arb`, add:

```json
"loginRememberMe": "Remember me",
"@loginRememberMe": {
  "description": "Checkbox label on the login screen to persist the user's session and e-mail"
}
```

- [ ] **Step 3: Regenerate bindings**

```bash
cd scheduler-frontend && make l10n
```

Expected: the generated file under `lib/core/l10n/generated/` now exposes `context.l10n.loginRememberMe`.

- [ ] **Step 4: Commit**

```bash
cd scheduler-frontend
git add lib/core/l10n/app_pt.arb lib/core/l10n/app_en.arb lib/core/l10n/generated/
git commit -m "feat(auth): l10n string for remember-me checkbox"
```

---

## Task 11: Frontend — `LoginPage` checkbox + prefill

**Files:**
- Modify: `scheduler-frontend/lib/features/auth/presentation/login_page.dart`

This task does not add a widget test — the project's CLAUDE.md flags `pumpAndSettle` hangs on TextField cursor animation. The behaviour is covered indirectly by the bloc tests in Task 9.

- [ ] **Step 1: Add imports and state**

At the top of `login_page.dart`, add:

```dart
import 'package:scheduler_frontend/core/auth/remember_me_storage.dart';
```

In `_LoginPageState`, add fields and an `initState` that pre-fills from storage. The file already uses `_emailController`:

```dart
class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _rememberMeStorage = RememberMeStorage();
  bool _rememberMe = false;

  static const _kBreakpoint = 720.0;

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    final saved = await _rememberMeStorage.load();
    if (!mounted) return;
    if (saved.enabled && saved.email != null) {
      setState(() {
        _emailController.text = saved.email!;
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submitEmail() {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    context.read<AuthBloc>().add(AuthCheckEmailRequested(email: email));
  }
  // ... build() unchanged except _EmailStep gets two new params ...
}
```

- [ ] **Step 2: Pass `rememberMe` state down to `_EmailStep`**

In `build()`, where `_EmailStep(...)` is constructed (around line 60), add the two new props:

```dart
final formWidget = _EmailStep(
  emailController: _emailController,
  isLoading: isLoading,
  onSubmit: _submitEmail,
  rememberMe: _rememberMe,
  onRememberMeChanged: (value) => setState(() => _rememberMe = value),
);
```

- [ ] **Step 3: Update navigation to carry the record**

Still in `build()`, the `BlocConsumer.listener` currently does:

```dart
if (state is AuthEmailChecked) {
  if (state.authMethod == 'totp') {
    context.push('/login/totp', extra: state.email);
  } else {
    context.push('/login/password', extra: state.email);
  }
}
```

Replace with:

```dart
if (state is AuthEmailChecked) {
  final extra = (email: state.email, rememberMe: _rememberMe);
  if (state.authMethod == 'totp') {
    context.push('/login/totp', extra: extra);
  } else {
    context.push('/login/password', extra: extra);
  }
}
```

- [ ] **Step 4: Update `_EmailStep` to render the checkbox**

Replace the existing `_EmailStep` class (line 279) with:

```dart
class _EmailStep extends StatelessWidget {
  final TextEditingController emailController;
  final bool isLoading;
  final VoidCallback onSubmit;
  final bool rememberMe;
  final ValueChanged<bool> onRememberMeChanged;

  const _EmailStep({
    required this.emailController,
    required this.isLoading,
    required this.onSubmit,
    required this.rememberMe,
    required this.onRememberMeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BaseInputField(
          label: context.l10n.loginEmailLabel,
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
        ),
        const SizedBox(height: AppSpacing.sm),
        _RememberMeRow(
          value: rememberMe,
          onChanged: onRememberMeChanged,
          enabled: !isLoading,
        ),
        const SizedBox(height: AppSpacing.md),
        BaseButton(
          label: context.l10n.loginContinueButton,
          isLoading: isLoading,
          onPressed: isLoading ? null : onSubmit,
        ),
        const SizedBox(height: AppSpacing.md),
        _OrDivider(),
        const SizedBox(height: AppSpacing.md),
        BaseButton(
          label: context.l10n.loginNoAccount,
          variant: BaseButtonVariant.secondary,
          onPressed: () => context.go(AppRoutes.register),
        ),
      ],
    );
  }
}

class _RememberMeRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  const _RememberMeRow({
    required this.value,
    required this.onChanged,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => onChanged(!value) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: value,
                onChanged: enabled
                    ? (v) => onChanged(v ?? false)
                    : null,
                // Sharp edges per project convention (no rounded corners).
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              context.l10n.loginRememberMe,
              style: AppTypography.bodySm.copyWith(
                color: context.appColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Run analyzer on this file**

```bash
cd scheduler-frontend && flutter analyze lib/features/auth/presentation/login_page.dart
```

Expected: no errors. The `extra` on `context.push` is typed as `Object?` by GoRouter, so the record is accepted.

- [ ] **Step 6: Commit**

```bash
cd scheduler-frontend
git add lib/features/auth/presentation/login_page.dart
git commit -m "feat(auth): add 'Lembrar de mim' checkbox with prefill on login"
```

---

## Task 12: Frontend — Step-2 pages receive `(email, rememberMe)` record

**Files:**
- Modify: `scheduler-frontend/lib/features/auth/presentation/totp_login_page.dart`
- Modify: `scheduler-frontend/lib/features/auth/presentation/password_login_page.dart`
- Modify: `scheduler-frontend/lib/core/router/app_router.dart`

- [ ] **Step 1: Update `TotpLoginPage` constructor**

In `totp_login_page.dart`:

```dart
class TotpLoginPage extends StatefulWidget {
  final String email;
  final bool rememberMe;

  const TotpLoginPage({
    super.key,
    required this.email,
    required this.rememberMe,
  });

  @override
  State<TotpLoginPage> createState() => _TotpLoginPageState();
}
```

And update `_submitTotp`:

```dart
void _submitTotp(String code) {
  context.read<AuthBloc>().add(
        AuthTotpLoginSubmitted(
          email: widget.email,
          code: code,
          rememberMe: widget.rememberMe,
        ),
      );
}
```

- [ ] **Step 2: Update `PasswordLoginPage` constructor**

In `password_login_page.dart`:

```dart
class PasswordLoginPage extends StatefulWidget {
  final String email;
  final bool rememberMe;

  const PasswordLoginPage({
    super.key,
    required this.email,
    required this.rememberMe,
  });

  @override
  State<PasswordLoginPage> createState() => _PasswordLoginPageState();
}
```

And update `_submit`:

```dart
void _submit() {
  final password = _passwordController.text.trim();
  if (password.isEmpty) return;
  context.read<AuthBloc>().add(
        AuthPasswordLoginRequested(
          email: widget.email,
          password: password,
          rememberMe: widget.rememberMe,
        ),
      );
}
```

- [ ] **Step 3: Update router to decode the record**

In `lib/core/router/app_router.dart`, replace the two routes (lines 72 and 77):

```dart
GoRoute(
  path: '/login/totp',
  builder: (_, state) {
    final extra = state.extra;
    if (extra is ({String email, bool rememberMe})) {
      return TotpLoginPage(email: extra.email, rememberMe: extra.rememberMe);
    }
    // Fallback — deep-link or reload lost the extra. Send user back to login.
    return const TotpLoginPage(email: '', rememberMe: false);
  },
),
GoRoute(
  path: '/login/password',
  builder: (_, state) {
    final extra = state.extra;
    if (extra is ({String email, bool rememberMe})) {
      return PasswordLoginPage(
        email: extra.email,
        rememberMe: extra.rememberMe,
      );
    }
    return const PasswordLoginPage(email: '', rememberMe: false);
  },
),
```

The fallback preserves current behaviour for deep-link reloads (where `extra` is lost) — same as the previous `state.extra as String? ?? ''` fallback.

- [ ] **Step 4: Run analyzer on all modified files**

```bash
cd scheduler-frontend && flutter analyze lib/
```

Expected: zero errors.

- [ ] **Step 5: Run the full frontend test suite**

```bash
cd scheduler-frontend && flutter test
```

Expected: green. Pre-existing 3 failures in `design_system/tokens/app_colors_extension_test.dart` are unrelated per CLAUDE.md and can be ignored.

- [ ] **Step 6: Commit**

```bash
cd scheduler-frontend
git add lib/features/auth/presentation/totp_login_page.dart \
        lib/features/auth/presentation/password_login_page.dart \
        lib/core/router/app_router.dart
git commit -m "feat(auth): carry rememberMe through step-2 login pages"
```

---

## Task 13: Manual smoke test + final verification

**Files:** none

- [ ] **Step 1: Start backend with local infra**

```bash
cd scheduler-backend && npm run docker:infra && npm run dev:local
```

- [ ] **Step 2: Start frontend**

In a separate terminal:

```bash
cd scheduler-frontend && make run-dev
```

- [ ] **Step 3: Happy path — password login with rememberMe checked**

1. Open the app on a web browser or simulator.
2. Enter a seeded member e-mail on the login screen.
3. Check "Lembrar de mim".
4. Tap "Continuar" → goes to `/login/password`.
5. Enter the password and submit.
6. Expected: authenticated, lands on home.
7. In devtools → Application → Cookies (or Flutter inspector), verify `refresh_token` has `Max-Age=2592000` (30 days).
8. Close the app, reopen, hit the login screen again → e-mail field is pre-filled and the checkbox is pre-checked.

- [ ] **Step 4: Happy path — TOTP login with rememberMe unchecked**

1. Log out.
2. Enter a TOTP-enabled e-mail, leave "Lembrar de mim" unchecked.
3. Submit → `/login/totp`.
4. Submit the 6-digit code.
5. Verify `refresh_token` has `Max-Age=604800` (7 days).
6. Log out, reopen login → e-mail field is empty, checkbox unchecked.

- [ ] **Step 5: Transition path — previously remembered, now unchecked**

1. With a remembered e-mail from Step 3, return to the login screen (pre-filled + pre-checked).
2. Uncheck the box.
3. Submit and complete login.
4. Log out, reopen login → e-mail field is empty, checkbox unchecked.
5. This verifies `clearRememberMe()` runs when `rememberMe=false` on success.

- [ ] **Step 6: Failure path — wrong password does not touch storage**

1. With a remembered e-mail, uncheck the box.
2. Submit a wrong password.
3. Expected: error shown, storage unchanged. Reopen the login screen → e-mail still pre-filled from before.

- [ ] **Step 7: Final analyzer + test run**

```bash
cd scheduler-frontend && flutter analyze lib/ && flutter test
cd ../scheduler-backend && npm run lint && npm test
```

Expected: both green (ignoring the 3 pre-existing `app_colors_extension_test.dart` failures).

- [ ] **Step 8: Final status commit (if any fixes were needed)**

If the smoke test surfaced any issues, fix and commit. Otherwise no commit needed.

---

## Self-review checklist

- [x] Spec §Persistence covered by Task 6 (`RememberMeStorage`).
- [x] Spec §AuthRepository covered by Task 8.
- [x] Spec §ApiClient refactor covered by Task 8 Step 2.
- [x] Spec §AuthBloc covered by Task 9.
- [x] Spec §Router extra typing covered by Task 12 Step 3.
- [x] Spec §UI login_page covered by Task 11.
- [x] Spec §UI step-2 screens covered by Task 12 Steps 1–2.
- [x] Spec §Localisation covered by Task 10.
- [x] Spec §Backend DTOs covered by Task 1.
- [x] Spec §Backend AuthService TTL switch covered by Task 3.
- [x] Spec §Backend env / config covered by Task 2.
- [x] Spec §Backend tests covered by Tasks 3, 4, 5.
- [x] Spec §Testing — frontend storage, repository, bloc covered in Tasks 6, 8 (compile), 9.
- [x] Spec §Non-goals respected: no widget test for LoginPage, no changes to confirmTotpSetup / acceptInvite / refresh TTL behaviour, no FlutterSecureStorage dependency, no biometric unlock.
- [x] Types consistent: `({String email, bool rememberMe})` record used identically in `LoginPage`, router, step-2 pages; `saveRememberMe(String)` / `clearRememberMe()` / `loadRememberMe()` names match between `RememberMeStorage`, `AuthRepository`, and `AuthBloc` call sites; `refreshTtlSeconds` returned by `generateTokens` is destructured consistently by all five controller methods.
