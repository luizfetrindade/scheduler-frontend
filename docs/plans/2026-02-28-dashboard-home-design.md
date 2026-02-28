# Dashboard Home — Design Document

**Date:** 2026-02-28
**Project:** scheduler-frontend (Flutter)
**Backend:** scheduler-backend (NestJS + PostgreSQL + JWT)

---

## Context

The scheduler-frontend is a Flutter mobile app for a multi-tenant SaaS scheduling system. The backend exposes REST APIs under `/auth`, `/businesses`, and `/b/:slug/appointments`. The home screen is the first screen after login and must serve two user roles: business owner/manager and staff members.

---

## Goals

- Show today's appointment overview for the active business
- Allow business owners/managers to confirm or mark appointments as no-show
- Support users who belong to multiple businesses (business switcher in header)
- Adapt UI based on staff role (OWNER/MANAGER vs MEMBER)

---

## Architecture

### State Management: Bloc (Events + States)

Three Blocs, each responsible for a distinct domain:

**AuthBloc**
- Events: `AuthLoginRequested(email, password)`, `AuthLogoutRequested`, `AuthUserFetched`
- States: `AuthInitial`, `AuthLoading`, `AuthAuthenticated(user)`, `AuthUnauthenticated`, `AuthError(message)`
- Replaces the current mock `AuthService`

**BusinessBloc**
- Events: `BusinessLoadRequested`, `BusinessSelected(business)`
- States: `BusinessInitial`, `BusinessLoading`, `BusinessLoaded(businesses, active)`, `BusinessError(message)`
- Persists selected business ID to SharedPreferences for session continuity

**AppointmentsBloc**
- Events: `AppointmentsLoadRequested(date)`, `AppointmentStatusChanged(id, status)`
- States: `AppointmentsInitial`, `AppointmentsLoading`, `AppointmentsLoaded(appointments)`, `AppointmentsError(message)`

### Data Layer: Repositories

Each repository uses the existing `flutter_http` package (already in pubspec):

- `AuthRepository` — `POST /auth/login`, `POST /auth/logout`, `GET /auth/me`
- `BusinessRepository` — `GET /businesses`, `GET /businesses/:id`
- `AppointmentRepository` — `GET /b/:slug/appointments?date=...`, `PATCH /b/:slug/appointments/:id/status`

### Models (Dart)

- `UserModel(id, name, email, roles)`
- `BusinessModel(id, slug, name, logo, timezone)`
- `AppointmentModel(id, startsAt, endsAt, status, clientName, serviceName, staffId, notes)`
- `StaffRoleEnum(OWNER, MANAGER, MEMBER)`
- `AppointmentStatusEnum(PENDING, CONFIRMED, CANCELLED, NO_SHOW, COMPLETED)`

### Packages to Add

```yaml
flutter_bloc: ^9.0.0
equatable: ^2.0.7
```

---

## UI Design

### Home Screen Layout

```
┌─────────────────────────────────────┐
│  [Logo/Nome negócio ▼]   [Avatar]   │  ← Header
├─────────────────────────────────────┤
│  Bom dia, João!  •  Sex, 28 fev     │  ← Greeting + date
├─────────────────────────────────────┤
│  ┌─────────┐ ┌─────────┐ ┌───────┐ │
│  │   12    │ │    3    │ │   9   │ │  ← Stats cards (derived from appointments list)
│  │ Total   │ │Pendentes│ │Confirm│ │
│  └─────────┘ └─────────┘ └───────┘ │
├─────────────────────────────────────┤
│  Agendamentos de hoje               │
│  ┌─────────────────────────────────┐│
│  │ 09:00  João Silva               ││
│  │        Corte de cabelo • 30min  ││
│  │        [PENDENTE]    [✓][✗]    ││  ← Actions only for OWNER/MANAGER
│  └─────────────────────────────────┘│
│  ┌─────────────────────────────────┐│
│  │ 10:00  Maria Santos             ││
│  │        Manicure • 45min         ││
│  │        [CONFIRMADO]             ││
│  └─────────────────────────────────┘│
└─────────────────────────────────────┘
```

### Component Breakdown

- **BusinessSelectorHeader** — dropdown showing active business name with chevron; tapping opens a bottom sheet listing all businesses
- **GreetingRow** — user first name + formatted current date
- **StatsSummaryRow** — 3 `BaseCard` widgets showing: Total, Pending, Confirmed counts (derived from the loaded appointments list, no extra API call)
- **AppointmentCard** — time, client name, service name + duration, status badge, quick action buttons (confirm/no-show) shown only when `staffRole == OWNER || MANAGER` and `appointment.status == PENDING`

### Role-based Behavior

| UI Element | OWNER/MANAGER | MEMBER |
|---|---|---|
| Stats cards | Visible | Visible |
| Quick action buttons | Visible | Hidden |
| Appointment list | All appointments | Only own appointments (filtered by staffId) |

---

## API Calls & Data Flow

1. App launches → `AuthBloc` dispatches `AuthUserFetched` → `GET /auth/me`
2. On `AuthAuthenticated` → `BusinessBloc` dispatches `BusinessLoadRequested` → `GET /businesses`
3. On `BusinessLoaded` → set active business (first or last saved) → `AppointmentsBloc` dispatches `AppointmentsLoadRequested(today)` → `GET /b/:slug/appointments?date=YYYY-MM-DD`
4. On business switch → `BusinessBloc` dispatches `BusinessSelected` → re-trigger `AppointmentsLoadRequested`
5. Quick action tap → `AppointmentsBloc` dispatches `AppointmentStatusChanged(id, CONFIRMED|NO_SHOW)` → `PATCH /b/:slug/appointments/:id/status`

---

## File Structure (New Files)

```
lib/
├── core/
│   ├── auth/
│   │   ├── auth_bloc.dart
│   │   ├── auth_event.dart
│   │   ├── auth_state.dart
│   │   └── auth_repository.dart
│   └── network/
│       └── api_client.dart          ← Wraps flutter_http with auth headers
├── features/
│   ├── business/
│   │   ├── data/
│   │   │   ├── business_model.dart
│   │   │   └── business_repository.dart
│   │   └── bloc/
│   │       ├── business_bloc.dart
│   │       ├── business_event.dart
│   │       └── business_state.dart
│   ├── appointments/
│   │   ├── data/
│   │   │   ├── appointment_model.dart
│   │   │   └── appointment_repository.dart
│   │   └── bloc/
│   │       ├── appointments_bloc.dart
│   │       ├── appointments_event.dart
│   │       └── appointments_state.dart
│   └── home/
│       └── presentation/
│           ├── home_page.dart           ← Replaces mock home
│           └── widgets/
│               ├── business_selector_header.dart
│               ├── greeting_row.dart
│               ├── stats_summary_row.dart
│               └── appointment_card.dart
```

---

## Out of Scope (This Iteration)

- Login screen API integration (keep mock for now, AuthBloc will be wired but login still navigates manually)
- Notifications / reminders
- Services, Staff, Clients management screens
- Date picker to view other days
- Pull-to-refresh (can be added trivially after)
