# Roles Management Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow users to create and manage professional roles (cargos) both inline in the professional form and via a dedicated management page.

**Architecture:** Extend the existing `ProfessionalRolesBloc` (already has full CRUD) with new UI components: `RoleFormSheet` (shared bottom sheet) and `RolesManagementPage` (full CRUD list). The backend requires a new greenfield `ProfessionalRole` Prisma model + NestJS module.

**Tech Stack:** Flutter + flutter_bloc, NestJS + Prisma (PostgreSQL), Zod DTOs, mocktail for tests.

**Spec:** `docs/superpowers/specs/2026-03-16-roles-management-design.md`

---

## File Map

### Backend (new)
| File | Action | Responsibility |
|------|--------|----------------|
| `scheduler-backend/prisma/schema.prisma` | Modify | Add `ProfessionalRole` model |
| `scheduler-backend/src/modules/professional-roles/dto/create-professional-role.dto.ts` | Create | Zod schema for create |
| `scheduler-backend/src/modules/professional-roles/dto/update-professional-role.dto.ts` | Create | Zod schema for update |
| `scheduler-backend/src/modules/professional-roles/professional-roles.service.spec.ts` | Create | TDD tests for service layer |
| `scheduler-backend/src/modules/professional-roles/professional-roles.service.ts` | Create | Business logic (CRUD; `_count` deferred until `Professional` model exists) |
| `scheduler-backend/src/modules/professional-roles/professional-roles.controller.ts` | Create | HTTP endpoints |
| `scheduler-backend/src/modules/professional-roles/professional-roles.module.ts` | Create | NestJS module wiring |
| `scheduler-backend/src/app.module.ts` | Modify | Register `ProfessionalRolesModule` |

### Frontend (modify/create)
| File | Action | Responsibility |
|------|--------|----------------|
| `scheduler-frontend/lib/features/professionals/data/professional_role_model.dart` | Modify | Add `professionalCount` field |
| `scheduler-frontend/test/features/professionals/data/professional_role_model_test.dart` | Modify | Add tests for new field |
| `scheduler-frontend/lib/core/router/app_routes.dart` | Modify | Add `professionalRoles` constant |
| `scheduler-frontend/lib/core/router/app_router.dart` | Modify | Add `/professional-roles` route |
| `scheduler-frontend/lib/features/professionals/presentation/widgets/role_form_sheet.dart` | Create | Single-field bottom sheet for create/edit |
| `scheduler-frontend/test/features/professionals/presentation/role_form_sheet_test.dart` | Create | Widget tests for `RoleFormSheet` |
| `scheduler-frontend/lib/features/professionals/presentation/roles_management_page.dart` | Create | Full CRUD roles list page |
| `scheduler-frontend/test/features/professionals/presentation/roles_management_page_test.dart` | Create | Widget tests for `RolesManagementPage` |
| `scheduler-frontend/lib/features/professionals/presentation/widgets/professional_form_sheet.dart` | Modify | Add inline "+ Criar cargo" option |
| `scheduler-frontend/test/features/professionals/presentation/professional_form_sheet_test.dart` | Modify | Add tests for inline role creation |
| `scheduler-frontend/lib/features/professionals/presentation/professionals_page.dart` | Modify | Add AppBar tune IconButton |
| `scheduler-frontend/lib/features/settings/presentation/settings_page.dart` | Modify | Add "Cargos" ListTile entry |

---

## Chunk 1: Backend — ProfessionalRole model + NestJS module

### Task 1: Add ProfessionalRole to Prisma schema

**Files:**
- Modify: `scheduler-backend/prisma/schema.prisma`

- [ ] **Step 1: Add ProfessionalRole model to schema**

Add this block inside `scheduler-backend/prisma/schema.prisma`, after the `Service` model:

```prisma
model ProfessionalRole {
  id         String   @id @default(uuid())
  businessId String
  business   Business @relation(fields: [businessId], references: [id], onDelete: Cascade)
  name       String
  createdAt  DateTime @default(now())
  updatedAt  DateTime @updatedAt

  @@index([businessId])
  @@map("professional_roles")
}
```

Also add the reverse relation on `Business`:
```prisma
// Inside model Business, add:
professionalRoles ProfessionalRole[]
```

> **Note:** The `_count.professionals` relation (used by the management page to show how many professionals use each role) requires a `Professional` model, which does not yet exist. The `findAll` endpoint will return roles **without** `_count` for now. The frontend handles this gracefully: `professionalCount` will be `null`, and the UI uses `professionalCount ?? 0` so the page shows `0 profissional(is)`. The `_count` include will be added in the Professionals feature implementation.

> **Note on `ApiClient.getList()`:** The project memory warns that `HttpClient.getList()` (from `flutter_http`) is broken for this backend. However, `ProfessionalRolesRepository` already uses `_client.getList()` where `_client` is `ApiClient` — this is the correct custom implementation in `lib/core/network/api_client.dart` that properly unwraps the `{ data, meta }` envelope. No changes needed to the repository.

- [ ] **Step 2: Run migration**

```bash
cd scheduler-backend
npx prisma migrate dev --name add-professional-roles
```

Expected: Migration created and applied. No errors.

- [ ] **Step 3: Commit schema**

```bash
git add prisma/schema.prisma prisma/migrations/
git commit -m "feat: add ProfessionalRole Prisma model"
```

---

### Task 2: Create DTOs

**Files:**
- Create: `scheduler-backend/src/modules/professional-roles/dto/create-professional-role.dto.ts`
- Create: `scheduler-backend/src/modules/professional-roles/dto/update-professional-role.dto.ts`

- [ ] **Step 1: Create `create-professional-role.dto.ts`**

```typescript
// scheduler-backend/src/modules/professional-roles/dto/create-professional-role.dto.ts
import { z } from 'zod';

export const CreateProfessionalRoleSchema = z.object({
  name: z.string().min(2).max(50),
});

export type CreateProfessionalRoleDto = z.infer<typeof CreateProfessionalRoleSchema>;
```

- [ ] **Step 2: Create `update-professional-role.dto.ts`**

```typescript
// scheduler-backend/src/modules/professional-roles/dto/update-professional-role.dto.ts
import { z } from 'zod';

export const UpdateProfessionalRoleSchema = z.object({
  name: z.string().min(2).max(50),
});

export type UpdateProfessionalRoleDto = z.infer<typeof UpdateProfessionalRoleSchema>;
```

---

### Task 3: Implement service (TDD)

**Files:**
- Create: `scheduler-backend/src/modules/professional-roles/professional-roles.service.spec.ts`
- Create: `scheduler-backend/src/modules/professional-roles/professional-roles.service.ts`

- [ ] **Step 1: Write failing service tests**

Create `scheduler-backend/src/modules/professional-roles/professional-roles.service.spec.ts`:

```typescript
import { NotFoundException } from '@nestjs/common';
import { ProfessionalRolesService } from './professional-roles.service';

describe('ProfessionalRolesService', () => {
  let service: ProfessionalRolesService;
  let prisma: any;

  beforeEach(() => {
    prisma = {
      professionalRole: {
        findMany: jest.fn(),
        findUnique: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
        delete: jest.fn(),
      },
      business: { findUnique: jest.fn() },
    };
    service = new ProfessionalRolesService(prisma);
  });

  it('findAll returns roles for a business ordered by name', async () => {
    prisma.professionalRole.findMany.mockResolvedValue([{ id: 'r1', name: 'Manicure' }]);
    const result = await service.findAll('b1');
    expect(prisma.professionalRole.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: { businessId: 'b1' }, orderBy: { name: 'asc' } }),
    );
    expect(result).toHaveLength(1);
  });

  it('create throws NotFoundException when business does not exist', async () => {
    prisma.business.findUnique.mockResolvedValue(null);
    await expect(service.create('unknown', { name: 'X' })).rejects.toThrow(NotFoundException);
  });

  it('create inserts role with businessId', async () => {
    prisma.business.findUnique.mockResolvedValue({ id: 'b1' });
    prisma.professionalRole.create.mockResolvedValue({ id: 'r1', businessId: 'b1', name: 'X' });
    const result = await service.create('b1', { name: 'X' });
    expect(result).toHaveProperty('id');
    expect(prisma.professionalRole.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: { name: 'X', businessId: 'b1' } }),
    );
  });

  it('update throws NotFoundException when role does not exist', async () => {
    prisma.professionalRole.findUnique.mockResolvedValue(null);
    await expect(service.update('r1', 'b1', { name: 'Y' })).rejects.toThrow(NotFoundException);
  });

  it('update throws NotFoundException when role belongs to different business', async () => {
    prisma.professionalRole.findUnique.mockResolvedValue({ id: 'r1', businessId: 'other' });
    await expect(service.update('r1', 'b1', { name: 'Y' })).rejects.toThrow(NotFoundException);
  });

  it('remove throws NotFoundException when role does not exist', async () => {
    prisma.professionalRole.findUnique.mockResolvedValue(null);
    await expect(service.remove('r1', 'b1')).rejects.toThrow(NotFoundException);
  });

  it('remove deletes role when found and belongs to business', async () => {
    prisma.professionalRole.findUnique.mockResolvedValue({ id: 'r1', businessId: 'b1' });
    prisma.professionalRole.delete.mockResolvedValue({ id: 'r1' });
    await service.remove('r1', 'b1');
    expect(prisma.professionalRole.delete).toHaveBeenCalledWith({ where: { id: 'r1' } });
  });
});
```

- [ ] **Step 2: Run to confirm tests fail (service doesn't exist yet)**

```bash
cd scheduler-backend
npm run test -- professional-roles.service
```

Expected: Test file compiles but fails — `ProfessionalRolesService` not found.

- [ ] **Step 3: Implement the service**

Create `scheduler-backend/src/modules/professional-roles/professional-roles.service.ts`:

```typescript
import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateProfessionalRoleDto } from './dto/create-professional-role.dto';
import { UpdateProfessionalRoleDto } from './dto/update-professional-role.dto';

@Injectable()
export class ProfessionalRolesService {
  constructor(private readonly prisma: PrismaService) {}

  findAll(businessId: string) {
    // NOTE: _count.professionals omitted until Professional model is added in Professionals feature.
    return this.prisma.professionalRole.findMany({
      where: { businessId },
      orderBy: { name: 'asc' },
    });
  }

  async create(businessId: string, dto: CreateProfessionalRoleDto) {
    const business = await this.prisma.business.findUnique({ where: { id: businessId } });
    if (!business) throw new NotFoundException('Business not found');
    return this.prisma.professionalRole.create({ data: { ...dto, businessId } });
  }

  async update(id: string, businessId: string, dto: UpdateProfessionalRoleDto) {
    const role = await this.prisma.professionalRole.findUnique({ where: { id } });
    if (!role || role.businessId !== businessId) throw new NotFoundException('Role not found');
    return this.prisma.professionalRole.update({ where: { id }, data: dto });
  }

  async remove(id: string, businessId: string) {
    const role = await this.prisma.professionalRole.findUnique({ where: { id } });
    if (!role || role.businessId !== businessId) throw new NotFoundException('Role not found');
    return this.prisma.professionalRole.delete({ where: { id } });
  }
}
```

- [ ] **Step 4: Run service tests to confirm they pass**

```bash
cd scheduler-backend
npm run test -- professional-roles.service
```

Expected: All 7 service tests pass.

---

### Task 4: Create controller + module + register in app.module.ts

**Files:**
- Create: `scheduler-backend/src/modules/professional-roles/professional-roles.controller.ts`
- Create: `scheduler-backend/src/modules/professional-roles/professional-roles.module.ts`
- Modify: `scheduler-backend/src/app.module.ts`

- [ ] **Step 1: Create controller**

```typescript
// scheduler-backend/src/modules/professional-roles/professional-roles.controller.ts
import { Body, Controller, Delete, Get, HttpCode, HttpStatus, Param, Patch, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { ProfessionalRolesService } from './professional-roles.service';
import { CreateProfessionalRoleSchema, CreateProfessionalRoleDto } from './dto/create-professional-role.dto';
import { UpdateProfessionalRoleSchema, UpdateProfessionalRoleDto } from './dto/update-professional-role.dto';
import { ZodValidationPipe } from '../../shared/pipes/zod-validation.pipe';

@ApiTags('professional-roles')
@ApiBearerAuth()
@Controller('businesses/:businessId/professional-roles')
export class ProfessionalRolesController {
  constructor(private readonly service: ProfessionalRolesService) {}

  @Get()
  @ApiOperation({ summary: 'List professional roles for a business' })
  findAll(@Param('businessId') businessId: string) {
    return this.service.findAll(businessId);
  }

  @Post()
  @ApiOperation({ summary: 'Create a professional role' })
  create(
    @Param('businessId') businessId: string,
    @Body(new ZodValidationPipe(CreateProfessionalRoleSchema)) dto: CreateProfessionalRoleDto,
  ) {
    return this.service.create(businessId, dto);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update a professional role' })
  update(
    @Param('id') id: string,
    @Param('businessId') businessId: string,
    @Body(new ZodValidationPipe(UpdateProfessionalRoleSchema)) dto: UpdateProfessionalRoleDto,
  ) {
    return this.service.update(id, businessId, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete a professional role' })
  remove(@Param('id') id: string, @Param('businessId') businessId: string) {
    return this.service.remove(id, businessId);
  }
}
```

- [ ] **Step 2: Create module**

```typescript
// scheduler-backend/src/modules/professional-roles/professional-roles.module.ts
import { Module } from '@nestjs/common';
import { ProfessionalRolesService } from './professional-roles.service';
import { ProfessionalRolesController } from './professional-roles.controller';

@Module({
  controllers: [ProfessionalRolesController],
  providers: [ProfessionalRolesService],
})
export class ProfessionalRolesModule {}
```

- [ ] **Step 3: Register in app.module.ts**

In `scheduler-backend/src/app.module.ts`, add:
```typescript
import { ProfessionalRolesModule } from '@modules/professional-roles/professional-roles.module';
```

And add `ProfessionalRolesModule` to the `imports` array (after `ServicesModule`):
```typescript
ServicesModule,
ProfessionalRolesModule,   // add this line
SchedulesModule,
```

- [ ] **Step 4: Run full backend test suite**

```bash
cd scheduler-backend
npm run test
```

Expected: All tests pass (7 new service tests + all pre-existing tests).

- [ ] **Step 5: Commit backend**

```bash
cd scheduler-backend
git add src/modules/professional-roles/ src/app.module.ts
git commit -m "feat: add ProfessionalRoles NestJS module with full CRUD"
```

---

## Chunk 2: Frontend — Model update + Routes

### Task 5: Add `professionalCount` to ProfessionalRoleModel (TDD)

**Files:**
- Modify: `scheduler-frontend/lib/features/professionals/data/professional_role_model.dart`
- Modify: `scheduler-frontend/test/features/professionals/data/professional_role_model_test.dart`

- [ ] **Step 1: Write failing tests for professionalCount**

Add to `test/features/professionals/data/professional_role_model_test.dart`:

```dart
group('ProfessionalRoleModel.fromJson with professionalCount', () {
  test('parses professionalCount from _count.professionals', () {
    final json = {
      'id': 'r1',
      'businessId': 'b1',
      'name': 'Cabeleireira',
      '_count': {'professionals': 3},
    };
    final model = ProfessionalRoleModel.fromJson(json);
    expect(model.professionalCount, 3);
  });

  test('professionalCount is null when _count absent', () {
    final json = {'id': 'r1', 'businessId': 'b1', 'name': 'Cabeleireira'};
    final model = ProfessionalRoleModel.fromJson(json);
    expect(model.professionalCount, isNull);
  });
});

group('ProfessionalRoleModel.copyWith with professionalCount', () {
  test('copies professionalCount', () {
    final base = ProfessionalRoleModel(id: 'r1', businessId: 'b1', name: 'X', professionalCount: 2);
    expect(base.copyWith(professionalCount: 5).professionalCount, 5);
  });
});
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
cd scheduler-frontend
flutter test test/features/professionals/data/professional_role_model_test.dart
```

Expected: `professionalCount` tests fail — field doesn't exist yet.

- [ ] **Step 3: Update ProfessionalRoleModel**

Replace `lib/features/professionals/data/professional_role_model.dart` with:

```dart
import 'package:equatable/equatable.dart';

class ProfessionalRoleModel extends Equatable {
  final String id;
  final String businessId;
  final String name;
  final int? professionalCount;

  const ProfessionalRoleModel({
    required this.id,
    required this.businessId,
    required this.name,
    this.professionalCount,
  });

  factory ProfessionalRoleModel.fromJson(Map<String, dynamic> json) =>
      ProfessionalRoleModel(
        id: json['id'] as String,
        businessId: json['businessId'] as String,
        name: json['name'] as String,
        professionalCount: (json['_count'] as Map<String, dynamic>?)?['professionals'] as int?,
      );

  ProfessionalRoleModel copyWith({
    String? id,
    String? businessId,
    String? name,
    int? professionalCount,
  }) =>
      ProfessionalRoleModel(
        id: id ?? this.id,
        businessId: businessId ?? this.businessId,
        name: name ?? this.name,
        professionalCount: professionalCount ?? this.professionalCount,
      );

  @override
  List<Object?> get props => [id, businessId, name, professionalCount];
}
```

- [ ] **Step 4: Run all professional tests to confirm all pass**

```bash
cd scheduler-frontend
flutter test test/features/professionals/
```

Expected: All tests pass (professionalCount is `int?`, so existing tests that don't provide it still compile fine).

---

### Task 6: Add route constant + GoRouter entry

**Files:**
- Modify: `scheduler-frontend/lib/core/router/app_routes.dart`
- Modify: `scheduler-frontend/lib/core/router/app_router.dart`

- [ ] **Step 1: Add constant to AppRoutes**

In `lib/core/router/app_routes.dart`, add:
```dart
static const professionalRoles = '/professional-roles';
```

Final file:
```dart
abstract final class AppRoutes {
  static const login         = '/login';
  static const register      = '/register';
  static const home          = '/';
  static const appointments  = '/appointments';
  static const clients       = '/clients';
  static const services      = '/services';
  static const professionals = '/professionals';
  static const professionalRoles = '/professional-roles';
  static const reports       = '/reports';
  static const settings      = '/settings';
}
```

- [ ] **Step 2: Add route to app_router.dart**

In `lib/core/router/app_router.dart`, add the import:
```dart
import 'package:scheduler_frontend/features/professionals/presentation/roles_management_page.dart';
```

Inside the `ShellRoute.routes` list, add the new route as a **direct sibling of `/professionals`** (not inside it — do NOT add it inside `routes: [...]` of the professionals `GoRoute`). Place it anywhere in the `ShellRoute.routes` list:

```dart
GoRoute(path: AppRoutes.home,              builder: (context, _) => const HomePage()),
GoRoute(path: AppRoutes.appointments,      builder: (context, _) => const AppointmentsPage()),
GoRoute(path: AppRoutes.clients,           builder: (context, _) => const ClientsPage()),
GoRoute(path: AppRoutes.services,          builder: (context, _) => const ServicesPage()),
GoRoute(
  path: AppRoutes.professionals,
  builder: (_, __) => const ProfessionalsPage(),
  routes: [
    GoRoute(
      path: ':id',
      builder: (_, state) => ProfessionalProfilePage(
        professionalId: state.pathParameters['id']!,
      ),
    ),
  ],
),
GoRoute(                                    // ADD THIS — sibling of /professionals
  path: AppRoutes.professionalRoles,
  builder: (_, __) => const RolesManagementPage(),
),
GoRoute(path: AppRoutes.reports,           builder: (context, _) => const ReportsPage()),
GoRoute(path: AppRoutes.settings,          builder: (context, _) => const SettingsPage()),
```

- [ ] **Step 3: Run router tests**

```bash
cd scheduler-frontend
flutter test test/core/router/
```

Expected: All pass.

- [ ] **Step 4: Commit model + routes**

```bash
cd scheduler-frontend
git add lib/features/professionals/data/professional_role_model.dart \
        test/features/professionals/data/professional_role_model_test.dart \
        lib/core/router/app_routes.dart \
        lib/core/router/app_router.dart
git commit -m "feat: add professionalCount to ProfessionalRoleModel and add /professional-roles route"
```

---

## Chunk 3: RoleFormSheet widget

### Task 7: Create RoleFormSheet (TDD)

**Files:**
- Create: `scheduler-frontend/lib/features/professionals/presentation/widgets/role_form_sheet.dart`
- Create: `scheduler-frontend/test/features/professionals/presentation/role_form_sheet_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/features/professionals/presentation/role_form_sheet_test.dart`:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scheduler_frontend/features/business/bloc/business_bloc.dart';
import 'package:scheduler_frontend/features/business/bloc/business_event.dart';
import 'package:scheduler_frontend/features/business/bloc/business_state.dart';
import 'package:scheduler_frontend/features/business/data/business_model.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_bloc.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_event.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_state.dart';
import 'package:scheduler_frontend/features/professionals/data/professional_role_model.dart';
import 'package:scheduler_frontend/features/professionals/presentation/widgets/role_form_sheet.dart';
import 'package:scheduler_frontend/design_system/tokens/app_theme.dart';

class MockProfessionalRolesBloc
    extends MockBloc<ProfessionalRolesEvent, ProfessionalRolesState>
    implements ProfessionalRolesBloc {}

class MockBusinessBloc extends MockBloc<BusinessEvent, BusinessState>
    implements BusinessBloc {}

class FakeProfessionalRolesEvent extends Fake
    implements ProfessionalRolesEvent {}

void main() {
  late MockProfessionalRolesBloc rolesBloc;
  late MockBusinessBloc businessBloc;

  setUpAll(() {
    registerFallbackValue(FakeProfessionalRolesEvent());
  });

  setUp(() {
    rolesBloc = MockProfessionalRolesBloc();
    businessBloc = MockBusinessBloc();
    when(() => rolesBloc.state).thenReturn(const ProfessionalRolesInitial());
    when(() => businessBloc.state).thenReturn(const BusinessInitial());
  });

  Widget buildSheet({ProfessionalRoleModel? role}) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider<ProfessionalRolesBloc>.value(value: rolesBloc),
              BlocProvider<BusinessBloc>.value(value: businessBloc),
            ],
            child: RoleFormSheet(role: role),
          ),
        ),
      );

  testWidgets('shows Novo Cargo title in create mode', (tester) async {
    await tester.pumpWidget(buildSheet());
    await tester.pump();
    expect(find.text('Novo Cargo'), findsOneWidget);
  });

  testWidgets('shows Editar Cargo title in edit mode', (tester) async {
    final role = ProfessionalRoleModel(id: 'r1', businessId: 'b1', name: 'Manicure');
    await tester.pumpWidget(buildSheet(role: role));
    await tester.pump();
    expect(find.text('Editar Cargo'), findsOneWidget);
  });

  testWidgets('submit with empty name shows validation error', (tester) async {
    await tester.pumpWidget(buildSheet());
    await tester.pump();

    await tester.tap(find.text('Salvar'));
    await tester.pump();

    expect(find.text('Nome é obrigatório'), findsOneWidget);
    verifyNever(() => rolesBloc.add(any()));
  });

  testWidgets('valid create dispatches ProfessionalRolesCreateRequested', (tester) async {
    when(() => rolesBloc.state).thenReturn(const ProfessionalRolesLoaded([]));
    when(() => businessBloc.state).thenReturn(
      BusinessLoaded(
        businesses: const [],
        active: const BusinessModel(
          id: 'b1', slug: 'my-biz', name: 'My Business',
          logo: null, timezone: 'America/Sao_Paulo',
        ),
      ),
    );

    await tester.pumpWidget(buildSheet());
    await tester.pump();

    await tester.enterText(find.byType(TextFormField), 'Esteticista');
    await tester.pump();

    await tester.tap(find.text('Salvar'));
    await tester.pump();

    verify(() => rolesBloc.add(any(that: isA<ProfessionalRolesCreateRequested>()))).called(1);
  });

  testWidgets('sheet does not close on initial Loaded state (wasSubmitting guard)', (tester) async {
    when(() => rolesBloc.state).thenReturn(const ProfessionalRolesLoaded([]));
    when(() => rolesBloc.stream)
        .thenAnswer((_) => Stream.value(const ProfessionalRolesLoaded([])));

    await tester.pumpWidget(buildSheet());
    await tester.pump();
    await tester.pump();

    // Sheet should still be in the tree — not closed
    expect(find.byType(RoleFormSheet), findsOneWidget);
  });
}
```


- [ ] **Step 2: Run tests to confirm they fail (file doesn't exist yet)**

```bash
cd scheduler-frontend
flutter test test/features/professionals/presentation/role_form_sheet_test.dart
```

Expected: Compilation error — `RoleFormSheet` not found.

- [ ] **Step 3: Implement RoleFormSheet**

Create `lib/features/professionals/presentation/widgets/role_form_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/business/bloc/business_bloc.dart';
import 'package:scheduler_frontend/features/business/bloc/business_state.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_bloc.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_event.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_state.dart';
import 'package:scheduler_frontend/features/professionals/data/professional_role_model.dart';

class RoleFormSheet extends StatefulWidget {
  /// If non-null, edit mode — pre-fills name field.
  final ProfessionalRoleModel? role;

  const RoleFormSheet({super.key, this.role});

  @override
  State<RoleFormSheet> createState() => _RoleFormSheetState();
}

class _RoleFormSheetState extends State<RoleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  bool _wasSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.role?.name ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.role != null;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfessionalRolesBloc, ProfessionalRolesState>(
      listener: (context, state) {
        if (state is ProfessionalRolesActionInProgress) {
          _wasSubmitting = true;
        } else if (state is ProfessionalRolesLoaded && _wasSubmitting) {
          Navigator.of(context).pop();
        } else if (state is ProfessionalRolesError && _wasSubmitting) {
          _wasSubmitting = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? 'Editar Cargo' : 'Novo Cargo',
                style: AppTypography.headingMd
                    .copyWith(color: context.appColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _nameCtrl,
                decoration: _inputDecoration(context, 'Nome do cargo *'),
                style: AppTypography.bodySm
                    .copyWith(color: context.appColors.textPrimary),
                autofocus: true,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Nome é obrigatório';
                  if (v.trim().length < 2) return 'Mínimo 2 caracteres';
                  if (v.trim().length > 50) return 'Máximo 50 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              BlocBuilder<ProfessionalRolesBloc, ProfessionalRolesState>(
                builder: (context, state) {
                  final isLoading = state is ProfessionalRolesActionInProgress;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancelar',
                          style: AppTypography.bodySm
                              .copyWith(color: context.appColors.textSecondary),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.appColors.primary,
                          foregroundColor: context.appColors.background,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        child: isLoading
                            ? SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: context.appColors.background,
                                ),
                              )
                            : const Text('Salvar'),
                      ),
                    ],
                  );
                },
              ),
            ],
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

    if (_isEditing) {
      context.read<ProfessionalRolesBloc>().add(ProfessionalRolesUpdateRequested(
            businessId: businessId,
            roleId: widget.role!.id,
            name: name,
          ));
    } else {
      context.read<ProfessionalRolesBloc>().add(ProfessionalRolesCreateRequested(
            businessId: businessId,
            name: name,
          ));
    }
  }

  InputDecoration _inputDecoration(BuildContext context, String label) =>
      InputDecoration(
        labelText: label,
        labelStyle: AppTypography.bodySm
            .copyWith(color: context.appColors.textSecondary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: context.appColors.surfaceHigh),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: context.appColors.primary),
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
        fillColor: context.appColors.surface,
      );
}
```

- [ ] **Step 4: Run tests**

```bash
cd scheduler-frontend
flutter test test/features/professionals/presentation/role_form_sheet_test.dart
```

Expected: All pass.

- [ ] **Step 5: Commit**

```bash
cd scheduler-frontend
git add lib/features/professionals/presentation/widgets/role_form_sheet.dart \
        test/features/professionals/presentation/role_form_sheet_test.dart
git commit -m "feat: add RoleFormSheet widget with TDD tests"
```

---

## Chunk 4: RolesManagementPage

### Task 8: Create RolesManagementPage (TDD)

**Files:**
- Create: `scheduler-frontend/lib/features/professionals/presentation/roles_management_page.dart`
- Create: `scheduler-frontend/test/features/professionals/presentation/roles_management_page_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/features/professionals/presentation/roles_management_page_test.dart`:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scheduler_frontend/design_system/tokens/app_theme.dart';
import 'package:scheduler_frontend/features/business/bloc/business_bloc.dart';
import 'package:scheduler_frontend/features/business/bloc/business_event.dart';
import 'package:scheduler_frontend/features/business/bloc/business_state.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_bloc.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_event.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_state.dart';
import 'package:scheduler_frontend/features/professionals/data/professional_role_model.dart';
import 'package:scheduler_frontend/features/professionals/presentation/roles_management_page.dart';

class MockProfessionalRolesBloc
    extends MockBloc<ProfessionalRolesEvent, ProfessionalRolesState>
    implements ProfessionalRolesBloc {}

class MockBusinessBloc extends MockBloc<BusinessEvent, BusinessState>
    implements BusinessBloc {}

class FakeProfessionalRolesEvent extends Fake implements ProfessionalRolesEvent {}

void main() {
  late MockProfessionalRolesBloc rolesBloc;
  late MockBusinessBloc businessBloc;

  setUpAll(() {
    registerFallbackValue(FakeProfessionalRolesEvent());
  });

  setUp(() {
    rolesBloc = MockProfessionalRolesBloc();
    businessBloc = MockBusinessBloc();
    when(() => rolesBloc.state).thenReturn(const ProfessionalRolesInitial());
    when(() => businessBloc.state).thenReturn(const BusinessInitial());
  });

  Widget buildPage() => MaterialApp(
        theme: AppTheme.light(),
        home: MultiBlocProvider(
          providers: [
            BlocProvider<ProfessionalRolesBloc>.value(value: rolesBloc),
            BlocProvider<BusinessBloc>.value(value: businessBloc),
          ],
          child: const RolesManagementPage(),
        ),
      );

  final role1 = ProfessionalRoleModel(
    id: 'r1', businessId: 'b1', name: 'Cabeleireira', professionalCount: 2,
  );
  final role2 = ProfessionalRoleModel(
    id: 'r2', businessId: 'b1', name: 'Manicure', professionalCount: 0,
  );

  testWidgets('renders role list with names and counts', (tester) async {
    when(() => rolesBloc.state).thenReturn(ProfessionalRolesLoaded([role1, role2]));

    await tester.pumpWidget(buildPage());
    await tester.pump();

    expect(find.text('Cabeleireira'), findsOneWidget);
    expect(find.text('Manicure'), findsOneWidget);
    expect(find.text('2 profissional(is)'), findsOneWidget);
    expect(find.text('0 profissional(is)'), findsOneWidget);
  });

  testWidgets('renders empty state when list is empty', (tester) async {
    when(() => rolesBloc.state).thenReturn(const ProfessionalRolesLoaded([]));

    await tester.pumpWidget(buildPage());
    await tester.pump();

    expect(find.textContaining('Nenhum cargo cadastrado'), findsOneWidget);
  });

  testWidgets('delete button shows confirmation dialog when count > 0', (tester) async {
    when(() => rolesBloc.state).thenReturn(ProfessionalRolesLoaded([role1]));

    await tester.pumpWidget(buildPage());
    await tester.pump();

    // Tap the delete button for role1 (which has count = 2)
    await tester.tap(find.byKey(const Key('delete-r1')));
    await tester.pump();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('profissional'), findsWidgets);
  });

  testWidgets('delete fires immediately when count == 0 (no dialog)', (tester) async {
    when(() => rolesBloc.state).thenReturn(ProfessionalRolesLoaded([role2]));

    await tester.pumpWidget(buildPage());
    await tester.pump();

    // Tap the delete button for role2 (count = 0) — no dialog expected
    await tester.tap(find.byKey(const Key('delete-r2')));
    await tester.pump();

    expect(find.byType(AlertDialog), findsNothing);
    verify(() => rolesBloc.add(any(that: isA<ProfessionalRolesDeleteRequested>()))).called(1);
  });
}
```

- [ ] **Step 2: Run to confirm compilation failure**

```bash
cd scheduler-frontend
flutter test test/features/professionals/presentation/roles_management_page_test.dart
```

Expected: Compilation error — `RolesManagementPage` not found.

- [ ] **Step 3: Implement RolesManagementPage**

Create `lib/features/professionals/presentation/roles_management_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/business/bloc/business_bloc.dart';
import 'package:scheduler_frontend/features/business/bloc/business_state.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_bloc.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_event.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_state.dart';
import 'package:scheduler_frontend/features/professionals/data/professional_role_model.dart';
import 'package:scheduler_frontend/features/professionals/presentation/widgets/role_form_sheet.dart';

class RolesManagementPage extends StatelessWidget {
  const RolesManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        backgroundColor: context.appColors.background,
        elevation: 0,
        title: Text(
          'Cargos',
          style: AppTypography.headingMd
              .copyWith(color: context.appColors.textPrimary),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.appColors.primary,
        foregroundColor: context.appColors.background,
        onPressed: () => _openForm(context, role: null),
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<ProfessionalRolesBloc, ProfessionalRolesState>(
        listener: (context, state) {
          if (state is ProfessionalRolesError && state.roles.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ProfessionalRolesLoading) {
            return Center(
              child: CircularProgressIndicator(color: context.appColors.primary),
            );
          }

          final roles = switch (state) {
            ProfessionalRolesLoaded(:final roles) => roles,
            ProfessionalRolesActionInProgress(:final roles) => roles,
            ProfessionalRolesError(:final roles) => roles,
            _ => <ProfessionalRoleModel>[],
          };

          if (roles.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: roles.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final role = roles[index];
              return _RoleListItem(
                role: role,
                onEdit: () => _openForm(context, role: role),
                onDelete: () => _onDeleteTapped(context, role),
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
          Icon(Icons.work_outline, size: 48, color: context.appColors.textDisabled),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Nenhum cargo cadastrado.',
            style: AppTypography.bodySm
                .copyWith(color: context.appColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Toque em + para criar o primeiro.',
            style: AppTypography.bodySm
                .copyWith(color: context.appColors.textDisabled),
          ),
        ],
      ),
    );
  }

  void _onDeleteTapped(BuildContext context, ProfessionalRoleModel role) {
    final count = role.professionalCount ?? 0;
    if (count == 0) {
      _dispatchDelete(context, role);
      return;
    }
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir cargo'),
        content: Text(
          '$count profissional(is) usa(m) este cargo. Deseja excluir mesmo assim?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        _dispatchDelete(context, role);
      }
    });
  }

  void _dispatchDelete(BuildContext context, ProfessionalRoleModel role) {
    final businessState = context.read<BusinessBloc>().state;
    if (businessState is! BusinessLoaded) return;
    context.read<ProfessionalRolesBloc>().add(ProfessionalRolesDeleteRequested(
          businessId: businessState.active.id,
          roleId: role.id,
        ));
  }

  void _openForm(BuildContext context, {required ProfessionalRoleModel? role}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<ProfessionalRolesBloc>()),
          BlocProvider.value(value: context.read<BusinessBloc>()),
        ],
        child: RoleFormSheet(role: role),
      ),
    );
  }
}

class _RoleListItem extends StatelessWidget {
  final ProfessionalRoleModel role;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RoleListItem({
    required this.role,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final count = role.professionalCount ?? 0;
    return ListTile(
      tileColor: context.appColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      title: Text(
        role.name,
        style:
            AppTypography.bodySm.copyWith(color: context.appColors.textPrimary),
      ),
      subtitle: Text(
        '$count profissional(is)',
        style: AppTypography.bodySm
            .copyWith(color: context.appColors.textSecondary),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit_outlined,
                color: context.appColors.textSecondary),
            onPressed: onEdit,
          ),
          IconButton(
            key: Key('delete-${role.id}'),
            icon: Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests**

```bash
cd scheduler-frontend
flutter test test/features/professionals/presentation/roles_management_page_test.dart
```

Expected: All pass.

- [ ] **Step 5: Commit**

```bash
cd scheduler-frontend
git add lib/features/professionals/presentation/roles_management_page.dart \
        test/features/professionals/presentation/roles_management_page_test.dart
git commit -m "feat: add RolesManagementPage with CRUD and TDD tests"
```

---

## Chunk 5: ProfessionalFormSheet — inline role creation

### Task 9: Add inline "+ Criar cargo" option (TDD)

**Files:**
- Modify: `scheduler-frontend/lib/features/professionals/presentation/widgets/professional_form_sheet.dart`
- Modify: `scheduler-frontend/test/features/professionals/presentation/professional_form_sheet_test.dart`

- [ ] **Step 1: Write failing tests**

Add to `test/features/professionals/presentation/professional_form_sheet_test.dart`:

```dart
// Add this import at top
import 'package:scheduler_frontend/features/professionals/presentation/widgets/role_form_sheet.dart';

// Add MockBusinessBloc class
class MockBusinessBloc extends MockBloc<BusinessEvent, BusinessState>
    implements BusinessBloc {}

// Register fallback in setUpAll:
// registerFallbackValue(FakeBusinessEvent()); // if needed

// Add setUp for businessBloc:
late MockBusinessBloc businessBloc;
// in setUp():
businessBloc = MockBusinessBloc();
when(() => businessBloc.state).thenReturn(const BusinessInitial());

// Update buildSheet to include BusinessBloc provider:
Widget buildSheet({ProfessionalModel? professional}) => MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: MultiBlocProvider(
          providers: [
            BlocProvider<ProfessionalsBloc>.value(value: profsBloc),
            BlocProvider<ProfessionalRolesBloc>.value(value: rolesBloc),
            BlocProvider<BusinessBloc>.value(value: businessBloc),
          ],
          child: ProfessionalFormSheet(professional: professional),
        ),
      ),
    );

// New test cases:
testWidgets('shows "+ Criar cargo" option in roles dropdown', (tester) async {
  when(() => rolesBloc.state)
      .thenReturn(const ProfessionalRolesLoaded([]));

  await tester.pumpWidget(buildSheet());
  await tester.pump();

  expect(find.text('+ Criar cargo'), findsOneWidget);
});

testWidgets('tapping "+ Criar cargo" opens RoleFormSheet', (tester) async {
  when(() => rolesBloc.state)
      .thenReturn(const ProfessionalRolesLoaded([]));

  await tester.pumpWidget(buildSheet());
  await tester.pump();

  await tester.tap(find.text('+ Criar cargo'));
  await tester.pump();
  await tester.pump(); // advance sheet animation frame

  expect(find.byType(RoleFormSheet), findsOneWidget);
});
```

- [ ] **Step 2: Run to confirm tests fail**

```bash
cd scheduler-frontend
flutter test test/features/professionals/presentation/professional_form_sheet_test.dart
```

Expected: New tests fail — `+ Criar cargo` not found.

- [ ] **Step 3: Update ProfessionalFormSheet**

In `lib/features/professionals/presentation/widgets/professional_form_sheet.dart`:

**3a.** Add state fields for inline role creation (after `_wasSubmitting`):

```dart
bool _wasCreatingRole = false;
Set<String> _previousRoleIds = {};
```

**3b.** Add a `BlocListener<ProfessionalRolesBloc>` wrapping the existing `BlocListener<ProfessionalsBloc>`.
The `build` method becomes a nested listener:

```dart
@override
Widget build(BuildContext context) {
  return BlocListener<ProfessionalRolesBloc, ProfessionalRolesState>(
    listener: (context, state) {
      if (state is ProfessionalRolesLoaded && _wasCreatingRole) {
        // .where().firstOrNull is Dart 3.0+ built-in — no extra package needed.
        final newRole = state.roles
            .where((r) => !_previousRoleIds.contains(r.id))
            .firstOrNull;
        if (newRole != null) {
          setState(() {
            _selectedRoleId = newRole.id;
            _wasCreatingRole = false;
          });
        }
        // If newRole == null (user cancelled RoleFormSheet without creating),
        // _wasCreatingRole stays true but is harmless — the guard only fires
        // when a genuinely new role is detected. It resets on next success.
      }
    },
    child: BlocListener<ProfessionalsBloc, ProfessionalsState>(
      listener: (context, state) {
        // ... existing listener body unchanged
      },
      child: Padding(
        // ... existing Padding unchanged
      ),
    ),
  );
}
```

**3c.** Update `_buildRoleDropdown` to add the `+ Criar cargo` option at the bottom of the dropdown items list. Replace the return of `DropdownButtonFormField` with a `Column`:

```dart
// At the end of _buildRoleDropdown, replace the return statement with:
return Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    DropdownButtonFormField<String>(
      value: _selectedRoleId,
      decoration: _inputDecoration(context, 'Cargo (opcional)'),
      style: AppTypography.bodySm
          .copyWith(color: context.appColors.textPrimary),
      dropdownColor: context.appColors.surface,
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Text(
            'Sem cargo',
            style: AppTypography.bodySm
                .copyWith(color: context.appColors.textSecondary),
          ),
        ),
        ...roles.map(
          (r) => DropdownMenuItem<String>(
            value: r.id,
            child: Text(r.name),
          ),
        ),
      ],
      onChanged: (v) => setState(() => _selectedRoleId = v),
    ),
    const SizedBox(height: AppSpacing.xs),
    GestureDetector(
      onTap: () => _openRoleForm(context, roles),
      child: Row(
        children: [
          Icon(Icons.add, size: 16, color: context.appColors.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '+ Criar cargo',
            style: AppTypography.bodySm
                .copyWith(color: context.appColors.primary),
          ),
        ],
      ),
    ),
  ],
);
```

**3d.** Add the `_openRoleForm` method to `_ProfessionalFormSheetState`:

```dart
void _openRoleForm(BuildContext context, List<ProfessionalRoleModel> currentRoles) {
  setState(() {
    _wasCreatingRole = true;
    _previousRoleIds = currentRoles.map((r) => r.id).toSet();
  });
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.appColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.read<ProfessionalRolesBloc>()),
        BlocProvider.value(value: context.read<BusinessBloc>()),
      ],
      child: const RoleFormSheet(),
    ),
  );
}
```

Add import for `RoleFormSheet`:
```dart
import 'package:scheduler_frontend/features/professionals/presentation/widgets/role_form_sheet.dart';
```

- [ ] **Step 4: Run tests**

```bash
cd scheduler-frontend
flutter test test/features/professionals/presentation/professional_form_sheet_test.dart
```

Expected: All pass.

- [ ] **Step 5: Commit**

```bash
cd scheduler-frontend
git add lib/features/professionals/presentation/widgets/professional_form_sheet.dart \
        test/features/professionals/presentation/professional_form_sheet_test.dart
git commit -m "feat: add inline role creation to ProfessionalFormSheet"
```

---

## Chunk 6: Navigation — ProfessionalsPage + Settings

### Task 10: Add AppBar button to ProfessionalsPage

**Files:**
- Modify: `scheduler-frontend/lib/features/professionals/presentation/professionals_page.dart`

- [ ] **Step 1: Add IconButton to AppBar**

In `lib/features/professionals/presentation/professionals_page.dart`, update the `AppBar`:

```dart
// Add import
import 'package:go_router/go_router.dart'; // already imported

appBar: AppBar(
  backgroundColor: context.appColors.background,
  elevation: 0,
  title: Text(
    'Profissionais',
    style: AppTypography.headingMd
        .copyWith(color: context.appColors.textPrimary),
  ),
  actions: [
    IconButton(
      icon: Icon(Icons.tune, color: context.appColors.textPrimary),
      tooltip: 'Gerenciar cargos',
      onPressed: () => context.push(AppRoutes.professionalRoles),
    ),
  ],
),
```

---

### Task 11: Add Cargos entry to SettingsPage

**Files:**
- Modify: `scheduler-frontend/lib/features/settings/presentation/settings_page.dart`

- [ ] **Step 1: Add Cargos ListTile to SettingsPage**

In `lib/features/settings/presentation/settings_page.dart`, add import and new ListTile:

```dart
// Add imports:
import 'package:go_router/go_router.dart';
import 'package:scheduler_frontend/core/router/app_routes.dart';
```

After the existing theme `ListTile`, add:

```dart
const SizedBox(height: AppSpacing.sm),
ListTile(
  tileColor: context.appColors.surface,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.md),
  ),
  leading: Icon(Icons.work_outline, color: context.appColors.primary),
  title: Text(
    'Cargos',
    style: AppTypography.bodySm
        .copyWith(color: context.appColors.textPrimary),
  ),
  trailing: Icon(Icons.chevron_right,
      color: context.appColors.textSecondary),
  onTap: () => context.push(AppRoutes.professionalRoles),
),
```

- [ ] **Step 2: Run full test suite**

```bash
cd scheduler-frontend
flutter test --reporter=github
```

Expected: All existing tests pass + new tests pass. No regressions.

- [ ] **Step 3: Final commit**

```bash
cd scheduler-frontend
git add lib/features/professionals/presentation/professionals_page.dart \
        lib/features/settings/presentation/settings_page.dart
git commit -m "feat: add navigation to RolesManagementPage from ProfessionalsPage and Settings"
```

---

## Final Verification

- [ ] Run backend: `cd scheduler-backend && npm run start:dev` — server starts without errors
- [ ] Run frontend: `cd scheduler-frontend && flutter run` — app runs, no compilation errors
- [ ] Manual smoke test:
  1. Go to Profissionais → tap tune icon → `RolesManagementPage` opens
  2. Tap FAB → `RoleFormSheet` opens → type "Cabeleireira" → Salvar → role appears in list
  3. Open "Novo Profissional" form → dropdown shows "Cabeleireira" + "+ Criar cargo"
  4. Tap "+ Criar cargo" → creates new role → auto-selected in dropdown
  5. Go to Settings → tap "Cargos" → `RolesManagementPage` opens
  6. Edit a role name → name updates
  7. Delete a role with professionals → confirmation dialog appears
  8. Delete a role with 0 professionals → deleted immediately
