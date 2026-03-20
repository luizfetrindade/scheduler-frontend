# Roles Management Feature — Design Spec

**Date:** 2026-03-16
**Status:** Approved
**Scope:** Flutter frontend + NestJS backend

---

## Problem

When creating a new professional, users see "Erro ao carregar cargos" because no roles exist yet and there is no way to create them from the UI. Users need to be able to create and manage roles (cargos) both inline (while creating a professional) and via a dedicated management page.

---

## Goals

- Allow inline role creation directly from the `ProfessionalFormSheet` dropdown
- Provide a dedicated `RolesManagementPage` with full CRUD + usage stats
- Make `RolesManagementPage` accessible from both the `ProfessionalsPage` and the Settings page

---

## Approach

Extend the existing `ProfessionalRolesBloc` (which already has Create/Update/Delete event infrastructure) and add the missing UI components. This follows the same pattern as `ServicesBloc`.

---

## Architecture

### Components

#### New

| Component | Type | Purpose |
|-----------|------|---------|
| `RoleFormSheet` | Widget (BottomSheet) | Single-field form for create/edit a role name. Shared between inline usage and `RolesManagementPage`. |
| `RolesManagementPage` | Page | Full CRUD list view: role name + count of professionals using each role. FAB to create. |

#### Modified

| Component | Change |
|-----------|--------|
| `ProfessionalRoleModel` | Adds optional `int? professionalCount` field, parsed from `json['_count']?['professionals']`. `copyWith` also updated. |
| `ProfessionalFormSheet` | Adds a `ListTile` "+ Criar cargo" at the bottom of the roles dropdown. On successful creation, auto-selects the new role via `_wasCreatingRole` flag (distinct from the existing `_wasSubmitting` flag — see Data Flow). |
| GoRouter routes | New top-level route `/professional-roles` (not nested under `/professionals/:id` to avoid `:id` param conflict). Declared before the `:id` param route inside `ShellRoute`. |
| `AppRoutes` | New constant: `static const professionalRoles = '/professional-roles'`. |
| `ProfessionalsPage` | Adds an `IconButton` (tune icon) in the AppBar: `context.push(AppRoutes.professionalRoles)`. |
| Settings page | Adds a `ListTile` with tune icon, label "Cargos": `context.push(AppRoutes.professionalRoles)`. Both entry points use `context.push()` (not `go`) so the back button works correctly from `RolesManagementPage`. |

---

## Model Change: `ProfessionalRoleModel`

```dart
class ProfessionalRoleModel {
  final String id;
  final String businessId;
  final String name;
  final int? professionalCount; // NEW: from json['_count']?['professionals']

  factory ProfessionalRoleModel.fromJson(Map<String, dynamic> json) =>
    ProfessionalRoleModel(
      id: json['id'],
      businessId: json['businessId'],
      name: json['name'],
      professionalCount: json['_count']?['professionals'] as int?,
    );
}
```

`copyWith` must include `professionalCount`.

---

## Data Flow

### Inline creation (from ProfessionalFormSheet)

`ProfessionalFormSheet` already has a `_wasSubmitting` flag for its own professional submission. A separate `_wasCreatingRole` flag is added alongside it — these are independent, non-conflicting flags for two different BLoCs inside the same widget.

```
User taps "+ Criar cargo" in dropdown
  → setState(() => _wasCreatingRole = true)
  → Opens RoleFormSheet (create mode) via showModalBottomSheet
  → User types name, taps "Salvar"
  → RoleFormSheet dispatches ProfessionalRolesCreateRequested(businessId, name)
    (_wasSubmitting = true set reactively inside RoleFormSheet on ActionInProgress — see RoleFormSheet section)
  → ProfessionalRolesBloc emits ActionInProgress → Loaded (updated list, new role appended)
  → BlocListener<ProfessionalRolesBloc> inside RoleFormSheet:
      on Loaded + _wasSubmitting == true → Navigator.of(context).pop()
  → BlocListener<ProfessionalRolesBloc> inside ProfessionalFormSheet:
      on Loaded + _wasCreatingRole == true:
        setState(() {
          _selectedRoleId = state.roles.firstWhere((r) => !_previousRoleIds.contains(r.id)).id;
          _wasCreatingRole = false;
        })
```

**Auto-selection strategy (robust):** `ProfessionalFormSheet` stores `_previousRoleIds` (Set<String>) before opening `RoleFormSheet`. On next `Loaded`, it identifies the new role by finding the id not present in `_previousRoleIds`. This is safer than `roles.last` in case of concurrent edits.

### RolesManagementPage

`RolesManagementPage` reads `businessId` from `context.read<BusinessBloc>().state` — guard with `if (state is! BusinessLoaded) return;`, following the same pattern as `ProfessionalFormSheet._submit()`.

```
Create:  FAB → RoleFormSheet(mode: create) → CreateRequested → Loaded
Update:  Edit icon → RoleFormSheet(mode: edit, role: role) → UpdateRequested → Loaded
Delete (count == 0):  Delete icon → DeleteRequested immediately (no dialog)
Delete (count > 0):   Delete icon → Confirmation dialog → user confirms → DeleteRequested
```

---

## Backend (New Greenfield Feature)

The backend does **not** have `ProfessionalRole` implemented. The Prisma schema has no `ProfessionalRole` model and there is no corresponding NestJS module. This is a **new backend feature** requiring:

1. **Prisma schema**: Add `ProfessionalRole` model with `id`, `businessId`, `name`, relation to `Business` and to `Professional` (via `roleId` on `Professional`)
2. **Migration**: `npx prisma migrate dev --name add-professional-roles`
3. **NestJS module**: `ProfessionalRolesModule` with controller + service + DTOs
4. **Endpoints to implement:**

| Method | Route | Body | Response (wrapped in `{ data, meta }`) |
|--------|-------|------|----------------------------------------|
| GET | `/businesses/:id/professional-roles` | — | `{ data: [{ id, businessId, name, _count: { professionals } }], meta }` |
| POST | `/businesses/:id/professional-roles` | `{ name: string }` | `{ data: { id, businessId, name }, meta }` |
| PATCH | `/businesses/:id/professional-roles/:roleId` | `{ name: string }` | `{ data: { id, businessId, name }, meta }` |
| DELETE | `/businesses/:id/professional-roles/:roleId` | — | 204 No Content |

The GET endpoint must use `include: { _count: { select: { professionals: true } } }` in the Prisma query.

All responses (except DELETE) are wrapped in the standard `{ data, meta }` envelope via `TransformInterceptor`, which `ApiClient.getList()` / `ApiClient.get()` expects and unwraps.

---

## Error Handling

| Scenario | Behavior |
|----------|----------|
| Create fails | SnackBar error, `RoleFormSheet` stays open |
| Update fails | SnackBar error, `RoleFormSheet` stays open |
| Delete (count == 0) | No confirmation dialog; fires `DeleteRequested` immediately |
| Delete (count > 0) | Confirmation dialog: "X profissional(is) usa(m) este cargo. Deseja excluir mesmo assim?" |
| Delete API error | SnackBar error, item remains in list |
| Load fails | Existing "Erro ao carregar cargos" message in form dropdown (no change) |

No optimistic updates for any operation. All operations emit `ActionInProgress` (preserving existing list) and only emit `Loaded` after server confirmation.

---

## `RolesManagementPage` — UI Spec

- **AppBar:** "Cargos" title + back button
- **List:** Each item shows:
  - Role name (leading text)
  - Professional count (trailing): `"${role.professionalCount ?? 0} profissional(is)"` — null defaults to `0`
  - Edit `IconButton` → opens `RoleFormSheet` in edit mode
  - Delete `IconButton` → fires immediately if count == 0; shows confirmation dialog if count > 0
- **Empty state:** "Nenhum cargo cadastrado. Toque em + para criar o primeiro."
- **FAB:** Opens `RoleFormSheet` in create mode

---

## `RoleFormSheet` — UI Spec

- Single `TextFormField`: "Nome do cargo" (required, min 2 chars, max 50 chars)
- Buttons: "Cancelar" (always active — closes sheet even during loading) + "Salvar" (dispatches event, replaced by spinner during `ActionInProgress`)
- **`_wasSubmitting` flag** (mirrors pattern in `ProfessionalFormSheet`, NOT `ServiceFormSheet` which does not use this pattern):
  - `_wasSubmitting` is set to `true` **reactively** inside the `BlocListener` when `ActionInProgress` is received (same timing as `ProfessionalFormSheet`)
  - `BlocListener` on `Loaded` + `_wasSubmitting == true` → `Navigator.of(context).pop()`
  - `BlocListener` on `Error` + `_wasSubmitting == true` → show SnackBar, `setState(() => _wasSubmitting = false)`
  - Sheet does NOT close on initial `Loaded` state (before any submission — `_wasSubmitting` is `false` initially)
- `businessId` from `context.read<BusinessBloc>().state` — guard with `if (state is! BusinessLoaded) return;`

---

## Testing

### Unit (blocTest)

- `ProfessionalRolesBloc`: create happy path → emits `ActionInProgress` then `Loaded` with new role appended
- `ProfessionalRolesBloc`: create failure → emits `ActionInProgress` then `Error` with list preserved
- `ProfessionalRolesBloc`: update happy path → emits `ActionInProgress` then `Loaded` with updated name
- `ProfessionalRolesBloc`: delete happy path → emits `ActionInProgress` then `Loaded` without deleted role
- `ProfessionalRolesBloc`: delete failure → emits `ActionInProgress` then `Error` with original list preserved

### Widget

- `RoleFormSheet`: submitting empty name shows validation error, does not dispatch event
- `RoleFormSheet`: valid submit dispatches `ProfessionalRolesCreateRequested`
- `RoleFormSheet`: does NOT auto-close when BLoC starts in `Loaded` state before any submission (`_wasSubmitting` guard)
- `RolesManagementPage`: renders role list with professional counts
- `RolesManagementPage`: renders empty state when list is empty
- `RolesManagementPage`: delete button shows confirmation dialog when `professionalCount > 0`
- `RolesManagementPage`: delete button fires immediately (no dialog) when `professionalCount == 0`
- `ProfessionalFormSheet`: "+ Criar cargo" item present in dropdown when roles loaded
- `ProfessionalFormSheet`: tapping "+ Criar cargo" opens `RoleFormSheet` bottom sheet

### Coverage target: 80%+

---

## File Plan

```
lib/features/professionals/
  presentation/
    roles_management_page.dart                      (new)
    widgets/
      role_form_sheet.dart                          (new)

  # Existing files modified:
  data/professional_role_model.dart                 (add professionalCount + copyWith)
  presentation/widgets/professional_form_sheet.dart (add _wasCreatingRole flag + BlocListener on ProfessionalRolesBloc)
  presentation/professionals_page.dart              (add AppBar IconButton)

  # BLoC — verify all CRUD events are wired
  bloc/professional_roles_bloc.dart

lib/core/router/
  app_router.dart                                   (add /professional-roles route BEFORE :id param)
  app_routes.dart                                   (add professionalRoles constant)

lib/features/settings/                              (add ListTile entry)

# Backend (new):
scheduler-backend/
  prisma/schema.prisma                              (add ProfessionalRole model)
  src/modules/professional-roles/                   (new NestJS module: controller, service, DTOs)
```

---

## Out of Scope

- Role reordering / priority
- Role color coding
- Global (cross-business) role templates
- Role-based permissions (separate from professional roles)
