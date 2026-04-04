# Remember Me — Login

**Date:** 2026-04-04
**Status:** Approved
**Scope:** Full-stack (scheduler-frontend + scheduler-backend)

## Summary

Add a "Lembrar de mim" checkbox to the login flow that does two things:

1. **Persists the e-mail locally** so the field is pre-filled on the next app open.
2. **Extends the refresh-token session** from the current 7 days to 30 days when checked.

The checkbox lives on **step 1** (the e-mail screen) and is **unchecked by default** for new users. The choice is carried through to step 2 (TOTP or password) and sent with the login request so the backend can set the refresh-token cookie TTL accordingly.

## Goals / Non-goals

### Goals
- Minimise friction for returning users on trusted devices.
- Make session duration an explicit, opt-in choice instead of a fixed 7-day default.
- Keep the change additive: unchecked behaviour reproduces today's experience.

### Non-goals (YAGNI)
- No biometric / Face ID unlock.
- No "remember me" on accept-invite or reset-password flows — these are signups, not logins.
- No server-side "logout all devices" changes.
- No encryption of the remembered e-mail (not a credential).
- No `AuthUserFetched` / app-boot changes — session persistence is already handled by the cookie TTL.
- No new widget tests for `LoginPage` beyond a focused `_EmailStep` test if needed (existing cursor-animation hang rules this out for the full page).

## User flow

```
Tela de e-mail
  [e-mail              ]
  [☐ Lembrar de mim    ]   ← unchecked by default for new users
  [Continuar           ]
     │
     └──push(/login/totp | /login/password, extra: (email, rememberMe))──┐
                                                                          ▼
                                                 Tela TOTP ou senha
                                                 (submete com rememberMe)
                                                          │
                                                          ▼
                                                 AuthBloc → Repository → API
                                                          │
                                                          ▼
                                    POST /auth/login/{totp|password}
                                    body: { ..., rememberMe }
                                                          │
                                                          ▼
                                    Backend sets refresh_token cookie
                                    maxAge = 30d if rememberMe else 7d
                                                          │
                                                          ▼
                                    On success in AuthBloc:
                                      rememberMe=true  → saveRememberMe(email)
                                      rememberMe=false → clearRememberMe()
```

On the next launch, `LoginPage.initState` loads `RememberMeStorage`; if `enabled`, it pre-fills the e-mail field and pre-checks the checkbox.

## Architecture

### Persistence: `RememberMeStorage`

New file: `lib/core/auth/remember_me_storage.dart`. Thin wrapper over `SharedPreferences` with two keys:

- `remember_me_email: String?`
- `remember_me_enabled: bool`

```dart
class RememberMeStorage {
  Future<({String? email, bool enabled})> load();
  Future<void> save({required String email}); // sets enabled = true
  Future<void> clear();                         // removes both keys
}
```

**Why `SharedPreferences` and not `FlutterSecureStorage`?** The e-mail is an identifier, not a credential. Access tokens continue to live in the existing `TokenStorage`. No new dependency.

### AuthRepository

Injected with a `RememberMeStorage`. New params on the login methods and three delegation methods for the bloc:

```dart
Future<Result<TokenRecord>> loginWithTotp({
  required String email,
  required String code,
  required bool rememberMe,
});

Future<Result<TokenRecord>> loginWithPassword({
  required String email,
  required String password,
  required bool rememberMe,
});

Future<({String? email, bool enabled})> loadRememberMe();
Future<void> saveRememberMe(String email);
Future<void> clearRememberMe();
```

The request bodies gain a `rememberMe: bool` field:

- `POST /auth/login/totp` → `{ email, code, rememberMe }`
- `POST /auth/login/password` → `{ email, password, rememberMe }`

### ApiClient refactor

`ApiClient.loginWithPassword` currently delegates to `flutter_http`'s built-in helper, which does not accept extra body fields. It will be replaced with a direct `_http.post('/auth/login/password', body: { email, password, rememberMe })`, mirroring how TOTP login is already wired. One-liner refactor; makes the two login paths consistent.

### AuthBloc / events

`lib/core/auth/auth_event.dart`:

```dart
class AuthTotpLoginSubmitted extends AuthEvent {
  final String email;
  final String code;
  final bool rememberMe; // NEW
}

class AuthPasswordLoginRequested extends AuthEvent {
  final String email;
  final String password;
  final bool rememberMe; // NEW
}
```

`auth_bloc.dart` — the two login handlers receive `rememberMe`, forward it to the repository, and after a successful login:

- `rememberMe == true`  → `_repository.saveRememberMe(email)`
- `rememberMe == false` → `_repository.clearRememberMe()`

On failure, neither is called — the previous remembered state is preserved.

**No new `AuthState`.** Reading `RememberMeStorage` for pre-fill is pure UI state and happens in `LoginPage.initState` directly, not via the bloc. This keeps `AuthState` focused on authentication.

### Router

`GoRouter` route `extra` for `/login/totp` and `/login/password` changes from `String` (e-mail) to a record `({String email, bool rememberMe})`. Only typing at the `state.extra` read site needs updating; `GoRouter` itself accepts any object.

### UI — `login_page.dart`

Inside `_EmailStep`:

- New row **below** the e-mail field, **above** the "Continuar" button: checkbox + "Lembrar de mim" label.
- Uses the design system's checkbox if available; otherwise a minimal wrapper around Material's `Checkbox` honouring `BorderRadius.zero` (per project convention — sharp edges).
- New local state in `_LoginPageState`: `bool _rememberMe = false`.
- `initState` calls `RememberMeStorage.load()`; if `enabled`, `setState` sets `_emailController.text = email` and `_rememberMe = true`.
- `_submitEmail` pushes `extra: (email: email, rememberMe: _rememberMe)` to the next step.

### UI — step 2 screens

`totp_login_page.dart` and `password_login_page.dart`:

- `extra` parameter changes from `String` to `({String email, bool rememberMe})`.
- The `rememberMe` flag is forwarded when dispatching `AuthTotpLoginSubmitted` / `AuthPasswordLoginRequested`.

### Localisation

Add `loginRememberMe` to `app_pt.arb` (and any other `.arb` files present) with value `"Lembrar de mim"`. Run `make l10n` to regenerate bindings. pt_BR only per project rules.

## Backend changes

### DTOs (`src/modules/auth/dto/`)

- `login-totp.dto.ts`: add `rememberMe: z.boolean().optional().default(false)`.
- `login-password.dto.ts`: same.

### AuthService

- Read `rememberMe` in the two login methods.
- Pick TTL based on flag:
  - `rememberMe === true`  → `REFRESH_TOKEN_TTL_LONG` (default `30d`)
  - `rememberMe === false` → `REFRESH_TOKEN_TTL_SHORT` (default `7d`)
- Apply the chosen TTL to:
  - The JWT payload (`expiresIn`) for the refresh token.
  - The `Set-Cookie` `maxAge` for `refresh_token`.
  - Any session-tracking record written to Redis (if present).

### Env / config

Add to `.env.example` and `ConfigModule` schema:

```
REFRESH_TOKEN_TTL_SHORT=7d
REFRESH_TOKEN_TTL_LONG=30d
```

Defaults preserve today's behaviour for unchecked logins.

### Controller

Pass the flag from DTO into the service. No route changes.

## Testing

### Frontend

**Unit — `RememberMeStorage`** (`test/core/auth/remember_me_storage_test.dart`, new):
- `load()` returns `(null, false)` when empty.
- `save(email)` persists; `load()` returns `(email, true)`.
- `clear()` removes both keys.
- Uses `SharedPreferences.setMockInitialValues({})`.

**Unit — `AuthRepository`** (extend existing):
- `loginWithTotp(..., rememberMe: true)` sends `rememberMe` in body.
- `loginWithPassword(..., rememberMe: false)` sends `rememberMe: false` in body.
- `saveRememberMe` / `clearRememberMe` delegate correctly to a mocked `RememberMeStorage`.

**BLoC — `AuthBloc`** (extend existing, `blocTest`):
- `AuthTotpLoginSubmitted(rememberMe: true)` on success → calls `saveRememberMe(email)`.
- `AuthTotpLoginSubmitted(rememberMe: false)` on success → calls `clearRememberMe()`.
- Same two cases for `AuthPasswordLoginRequested`.
- On login failure → neither `saveRememberMe` nor `clearRememberMe` is called (`verifyNever`).

**No full `LoginPage` widget test** — `pumpAndSettle` hangs on TextField cursor animation per project rules. If visual coverage of the checkbox becomes necessary, add a focused `_EmailStep`-only test with manual `pump()` calls.

### Backend

- `auth.service.spec.ts`: asserts the refresh-token cookie `maxAge` is 30 days when `rememberMe: true`, 7 days when `false`.
- DTO tests: Zod accepts `rememberMe` boolean, defaults to `false` when omitted.
- E2E `test/auth.e2e-spec.ts`: `POST /auth/login/password` with `rememberMe: true` returns a `Set-Cookie` header containing `Max-Age=2592000`.

## Files touched

**Frontend — new**
- `lib/core/auth/remember_me_storage.dart`
- `test/core/auth/remember_me_storage_test.dart`

**Frontend — modified**
- `lib/core/auth/auth_event.dart`
- `lib/core/auth/auth_bloc.dart`
- `lib/core/auth/auth_repository.dart`
- `lib/core/network/api_client.dart`
- `lib/features/auth/presentation/login_page.dart`
- `lib/features/auth/presentation/totp_login_page.dart`
- `lib/features/auth/presentation/password_login_page.dart`
- `lib/core/router/app_router.dart`
- `lib/core/l10n/app_*.arb`
- Existing `auth_bloc` / `auth_repository` tests extended

**Backend — modified**
- `src/modules/auth/dto/login-totp.dto.ts`
- `src/modules/auth/dto/login-password.dto.ts`
- `src/modules/auth/auth.service.ts`
- `src/modules/auth/auth.controller.ts`
- `.env.example` (+ config schema)
- Corresponding `.spec.ts` files and `test/auth.e2e-spec.ts`
