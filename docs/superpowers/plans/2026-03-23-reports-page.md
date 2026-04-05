# Reports Page — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transformar a página de relatórios em um painel 360° com score de saúde, alertas inteligentes e 5 abas aprofundadas (Geral, Financeiro, Agendamentos, Clientes, Equipe) cobrindo backend e frontend.

**Architecture:** Backend NestJS expande o endpoint `/b/:slug/reports` com métricas de período anterior, análise de clientes (novos vs. recorrentes, em risco) e performance por profissional. Frontend Flutter adiciona novos sub-modelos, widgets focados por responsabilidade e refatora a página em TabBar com BLoC inalterado.

**Tech Stack:** NestJS 11 + Prisma (backend); Flutter + flutter_bloc ^9 + fl_chart (frontend); testes com Jest (backend) e blocTest/flutter_test (frontend).

**Spec:** `docs/superpowers/specs/2026-03-23-reports-page-design.md`

---

> **Nota de escopo:** Esta feature abrange dois apps independentes (`scheduler-backend/` e `scheduler-frontend/`). Execute a Fase 1 (backend) primeiro e confirme que os testes passam antes de iniciar a Fase 2 (frontend).

---

## Mapa de Arquivos

### Backend (`scheduler-backend/`)

| Arquivo | Ação | Responsabilidade |
|---|---|---|
| `src/modules/reports/reports.utils.ts` | Modificar | Adicionar `getPreviousPeriodBounds()` |
| `src/modules/reports/dto/reports-response.dto.ts` | Modificar | Adicionar interfaces novas (clients, staff, campos previous*) |
| `src/modules/reports/reports.service.ts` | Modificar | Adicionar cálculos de período anterior, clients, staff |
| `src/modules/reports/reports.service.spec.ts` | Modificar | Testes das novas seções |
| `src/modules/reports/reports.utils.spec.ts` | Modificar | Teste de `getPreviousPeriodBounds()` |

### Frontend (`scheduler-frontend/`)

| Arquivo | Ação | Responsabilidade |
|---|---|---|
| `lib/features/reports/data/reports_model.dart` | Modificar | Adicionar novos sub-modelos e campos |
| `lib/features/reports/presentation/widgets/daily_series_chart.dart` | Modificar | Tornar `title` parâmetro do construtor |
| `lib/features/reports/utils/health_score.dart` | Criar | Função `computeHealthScore()` pura |
| `lib/features/reports/utils/smart_alerts.dart` | Criar | Lógica de alertas + modelo `ReportAlert` |
| `lib/features/reports/presentation/widgets/kpi_card_with_delta.dart` | Criar | Card KPI com variação e semáforo |
| `lib/features/reports/presentation/widgets/health_score_card.dart` | Criar | Card do score de saúde |
| `lib/features/reports/presentation/widgets/smart_alerts_list.dart` | Criar | Lista de alertas |
| `lib/features/reports/presentation/widgets/new_vs_returning_bar.dart` | Criar | Barra novos vs. recorrentes |
| `lib/features/reports/presentation/widgets/at_risk_clients_list.dart` | Criar | Lista de clientes para reativar |
| `lib/features/reports/presentation/widgets/staff_performance_list.dart` | Criar | Lista de profissionais |
| `lib/features/reports/presentation/widgets/day_of_week_chart.dart` | Criar | Gráfico por dia da semana |
| `lib/features/reports/presentation/widgets/tabs/reports_general_tab.dart` | Criar | Aba Geral |
| `lib/features/reports/presentation/widgets/tabs/reports_financial_tab.dart` | Criar | Aba Financeiro |
| `lib/features/reports/presentation/widgets/tabs/reports_appointments_tab.dart` | Criar | Aba Agendamentos |
| `lib/features/reports/presentation/widgets/tabs/reports_clients_tab.dart` | Criar | Aba Clientes |
| `lib/features/reports/presentation/widgets/tabs/reports_staff_tab.dart` | Criar | Aba Equipe |
| `lib/features/reports/presentation/reports_page.dart` | Modificar | Refatorar para TabBar + TabBarView |
| `test/features/reports/utils/health_score_test.dart` | Criar | Testes unitários do score |
| `test/features/reports/utils/smart_alerts_test.dart` | Criar | Testes dos alertas |
| `test/features/reports/data/reports_model_test.dart` | Criar | Testes do fromJson expandido |
| `test/features/reports/presentation/widgets/kpi_card_with_delta_test.dart` | Criar | Testes do widget KPI |
| `test/features/reports/presentation/reports_page_test.dart` | Modificar | Testes da página refatorada |

---

## FASE 1 — Backend

---

### Task 1: Adicionar `getPreviousPeriodBounds()` em reports.utils.ts

**Arquivos:**
- Modificar: `scheduler-backend/src/modules/reports/reports.utils.ts`
- Modificar: `scheduler-backend/src/modules/reports/reports.utils.spec.ts`

- [ ] **Step 1: Escrever teste que falha**

Adicionar ao final de `reports.utils.spec.ts`:

```typescript
describe('getPreviousPeriodBounds', () => {
  it('returns previous month bounds for monthly period', () => {
    // março 2026 → fevereiro 2026
    jest.useFakeTimers().setSystemTime(new Date('2026-03-15T12:00:00Z'));
    const current = getPeriodBounds('monthly', 'America/Sao_Paulo');
    const prev = getPreviousPeriodBounds(current, 'monthly', 'America/Sao_Paulo');
    expect(prev.from.toISOString().startsWith('2026-02-01')).toBe(true);
    expect(prev.to.toISOString().startsWith('2026-02-28') ||
           prev.to.toISOString().startsWith('2026-03-01')).toBe(true);
    jest.useRealTimers();
  });

  it('returns previous week bounds for weekly period', () => {
    jest.useFakeTimers().setSystemTime(new Date('2026-03-18T12:00:00Z')); // quarta
    const current = getPeriodBounds('weekly', 'America/Sao_Paulo');
    const prev = getPreviousPeriodBounds(current, 'weekly', 'America/Sao_Paulo');
    // semana anterior deve ter 7 dias de diferença
    const diffMs = current.from.getTime() - prev.from.getTime();
    expect(diffMs).toBe(7 * 24 * 60 * 60 * 1000);
    jest.useRealTimers();
  });

  it('returns previous quarter bounds for quarterly period', () => {
    jest.useFakeTimers().setSystemTime(new Date('2026-03-01T12:00:00Z')); // Q1
    const current = getPeriodBounds('quarterly', 'America/Sao_Paulo');
    const prev = getPreviousPeriodBounds(current, 'quarterly', 'America/Sao_Paulo');
    expect(prev.from.toISOString().startsWith('2025-10-01')).toBe(true); // Q4 2025
    jest.useRealTimers();
  });
});
```

- [ ] **Step 2: Executar teste para ver falhar**

```bash
cd scheduler-backend
npx jest src/modules/reports/reports.utils.spec.ts -t "getPreviousPeriodBounds" --no-coverage
```

Esperado: FAIL — `getPreviousPeriodBounds is not a function`

- [ ] **Step 3: Implementar `getPreviousPeriodBounds()` em reports.utils.ts**

Adicionar ao final de `reports.utils.ts` (e ao export):

```typescript
/**
 * Retorna os bounds do período imediatamente anterior ao informado.
 * A duração do período anterior é sempre igual ao período atual.
 */
export function getPreviousPeriodBounds(
  current: { from: Date; to: Date },
  period: string,
  timezone: string,
): { from: Date; to: Date } {
  // Diferença em ms entre from e to do período atual
  const durationMs = current.to.getTime() - current.from.getTime();

  if (period === 'monthly') {
    // Para mensal: mês calendário anterior (não apenas 30 dias)
    const fromInTz = new Date(
      new Date(current.from).toLocaleString('en-US', { timeZone: timezone }),
    );
    const prevMonthFrom = new Date(
      Date.UTC(fromInTz.getFullYear(), fromInTz.getMonth() - 1, 1),
    );
    const prevMonthTo = new Date(
      Date.UTC(fromInTz.getFullYear(), fromInTz.getMonth(), 1),
    );
    // Ajustar para início/fim do mês em UTC considerando timezone
    const tzOffsetMs = current.from.getTime() - new Date(
      new Date(current.from).toLocaleString('en-US', { timeZone: 'UTC' }),
    ).getTime();
    return { from: prevMonthFrom, to: prevMonthTo };
  }

  // Para weekly e quarterly: subtrai a duração exata
  return {
    from: new Date(current.from.getTime() - durationMs),
    to: current.from,
  };
}
```

- [ ] **Step 4: Executar teste para ver passar**

```bash
npx jest src/modules/reports/reports.utils.spec.ts --no-coverage
```

Esperado: PASS em todos os testes de utils

- [ ] **Step 5: Commit**

```bash
cd scheduler-backend
git add src/modules/reports/reports.utils.ts src/modules/reports/reports.utils.spec.ts
git commit -m "feat(reports): add getPreviousPeriodBounds utility"
```

---

### Task 2: Expandir reports-response.dto.ts com novas interfaces

**Arquivos:**
- Modificar: `scheduler-backend/src/modules/reports/dto/reports-response.dto.ts`

- [ ] **Step 1: Substituir o conteúdo do DTO com as interfaces expandidas**

```typescript
export interface DailyPoint {
  date: string;
  count: number;
}

export interface RevenueDailyPoint {
  date: string;
  amount: number;
}

export interface PeakHour {
  hour: number;
  count: number;
}

export interface DayOfWeekPoint {
  day: number; // 0=domingo, 6=sábado
  count: number;
}

export interface TopService {
  name: string;
  count: number;
  revenue: number;
}

export interface AppointmentsReport {
  total: number;
  previousTotal: number;
  byStatus: Record<string, number>;
  cancellationRate: number;
  previousCancellationRate: number;
  noShowRate: number;
  previousNoShowRate: number;
  dailySeries: DailyPoint[];
  byDayOfWeek: DayOfWeekPoint[];
}

export interface RevenueReport {
  confirmed: number;
  previousConfirmed: number;
  realized: number;
  previousRealized: number;
  lost: number;
  previousLost: number;
  averageTicket: number;
  previousAverageTicket: number;
  revenueDailySeries: RevenueDailyPoint[];
  topServices: TopService[];
}

export interface OccupancyReport {
  totalSlotsAvailable: number;
  totalBooked: number;
  occupancyRate: number;
  previousOccupancyRate: number;
  peakHours: PeakHour[];
}

export interface AtRiskClient {
  id: string;
  name: string;
  lastVisitAt: string;
  lastServiceName: string | null;
  daysSinceLastVisit: number;
}

export interface ClientsReport {
  total: number;
  newClients: number;
  previousNewClients: number;
  returningClients: number;
  returnRate: number;
  previousReturnRate: number;
  averageFrequencyDays: number;
  averageTicketPerClient: number;
  previousAverageTicketPerClient: number;
  atRisk: AtRiskClient[];
}

export interface StaffReport {
  id: string;
  name: string;
  photoUrl: string | null;
  roleName: string | null;
  color: string;
  appointments: number;
  revenue: number;
  completionRate: number;
}

export interface ReportsResponse {
  period: string;
  from: string;
  to: string;
  previousFrom: string;
  previousTo: string;
  appointments: AppointmentsReport;
  revenue: RevenueReport;
  occupancy: OccupancyReport;
  clients: ClientsReport;
  staff: StaffReport[];
}
```

- [ ] **Step 2: Verificar que TypeScript compila sem erros**

```bash
cd scheduler-backend
npx tsc --noEmit
```

Esperado: sem erros de tipo

- [ ] **Step 3: Commit**

```bash
git add src/modules/reports/dto/reports-response.dto.ts
git commit -m "feat(reports): expand response DTO with clients, staff and previous period fields"
```

---

### Task 3: Expandir reports.service.ts — período anterior + byDayOfWeek + averageTicket + revenueDailySeries

**Arquivos:**
- Modificar: `scheduler-backend/src/modules/reports/reports.service.ts`
- Modificar: `scheduler-backend/src/modules/reports/reports.service.spec.ts`

- [ ] **Step 1: Escrever testes que falham para as novas seções**

Adicionar ao `reports.service.spec.ts` (bloco `describe` após os existentes):

```typescript
describe('previous period metrics', () => {
  it('returns previousTotal from previous period', async () => {
    const now = new Date('2026-03-15T12:00:00Z');
    jest.useFakeTimers().setSystemTime(now);

    // Período atual: março → 2 agendamentos
    prisma.appointment.findMany
      .mockResolvedValueOnce([makeAppt(), makeAppt()])  // período atual
      .mockResolvedValueOnce([makeAppt()])              // período anterior
      .mockResolvedValueOnce([])                        // clients query
      .mockResolvedValueOnce([]);                       // staff query

    const result = await service.getReport(userId, slug, 'monthly');
    expect(result.appointments.previousTotal).toBe(1);
    jest.useRealTimers();
  });
});

describe('byDayOfWeek', () => {
  it('groups appointments by local day of week', async () => {
    // Segunda-feira (1) no fuso horário de SP
    const monday = new Date('2026-03-16T12:00:00Z'); // UTC+0 → SP é -3, então 09:00 SP
    prisma.appointment.findMany
      .mockResolvedValueOnce([makeAppt({ startsAt: monday, type: 'APPOINTMENT', status: 'COMPLETED' })])
      .mockResolvedValueOnce([]) // previous period
      .mockResolvedValueOnce([]) // clients
      .mockResolvedValueOnce([]); // staff

    const result = await service.getReport(userId, slug, 'monthly');
    const mondayEntry = result.appointments.byDayOfWeek.find(d => d.day === 1);
    expect(mondayEntry?.count).toBe(1);
  });
});

describe('revenue daily series', () => {
  it('returns revenue grouped by date', async () => {
    const date = new Date('2026-03-10T12:00:00Z');
    prisma.appointment.findMany
      .mockResolvedValueOnce([
        makeAppt({ startsAt: date, status: 'COMPLETED', service: { price: '100.00' } }),
      ])
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([]);

    const result = await service.getReport(userId, slug, 'monthly');
    expect(result.revenue.revenueDailySeries.length).toBeGreaterThan(0);
    const day = result.revenue.revenueDailySeries.find(d => d.date === '2026-03-10');
    expect(day?.amount).toBe(100);
  });
});
```

- [ ] **Step 2: Executar testes para ver falhar**

```bash
npx jest src/modules/reports/reports.service.spec.ts --no-coverage
```

Esperado: FAIL nos novos testes (campos undefined)

- [ ] **Step 3: Adicionar métodos privados no service para período anterior**

No `reports.service.ts`, adicionar o método `_buildPreviousPeriodMetrics()` e expandir `getReport()` para fazer duas queries de appointments (período atual e anterior) e calcular os campos `previous*`.

Estrutura principal de `getReport()` após a mudança:

```typescript
async getReport(userId: string, slug: string, period: string): Promise<ReportsResponse> {
  // ... validação existente (business + staff) ...

  const { from, to } = getPeriodBounds(period, business.timezone);
  const prevBounds = getPreviousPeriodBounds({ from, to }, period, business.timezone);

  // Query período atual (existente)
  const appts = await this.prisma.appointment.findMany({
    where: { businessId: business.id, startsAt: { gte: from, lt: to }, type: 'APPOINTMENT' },
    include: { service: true, client: true, staff: { include: { user: true } } },
  });

  // Query período anterior (NOVO)
  const prevAppts = await this.prisma.appointment.findMany({
    where: {
      businessId: business.id,
      startsAt: { gte: prevBounds.from, lt: prevBounds.to },
      type: 'APPOINTMENT',
    },
    include: { service: true },
  });

  // Construir reports com dados anteriores
  const appointmentsReport = this._buildAppointmentsReport(appts, prevAppts, business.timezone);
  const revenueReport = this._buildRevenueReport(appts, prevAppts, business.timezone);
  // occupancy existente expandido com previousOccupancyRate
  // ...

  return {
    period,
    from: localDateString(from, business.timezone),
    to: localDateString(to, business.timezone),
    previousFrom: localDateString(prevBounds.from, business.timezone),
    previousTo: localDateString(prevBounds.to, business.timezone),
    appointments: appointmentsReport,
    revenue: revenueReport,
    occupancy: occupancyReport,
    clients: clientsReport,
    staff: staffReport,
  };
}
```

Adicionar métodos privados:

```typescript
private _buildAppointmentsReport(appts: any[], prevAppts: any[], tz: string): AppointmentsReport {
  const nonCancelled = appts.filter(a => a.status !== 'CANCELLED' && a.status !== 'NO_SHOW');
  const cancelled = appts.filter(a => a.status === 'CANCELLED');
  const noShow = appts.filter(a => a.status === 'NO_SHOW');

  const total = appts.length;
  const prevTotal = prevAppts.length;
  const cancellationRate = total > 0 ? cancelled.length / total : 0;
  const prevCancelled = prevAppts.filter(a => a.status === 'CANCELLED').length;
  const prevCancellationRate = prevTotal > 0 ? prevCancelled / prevTotal : 0;
  const noShowRate = total > 0 ? noShow.length / total : 0;
  const prevNoShow = prevAppts.filter(a => a.status === 'NO_SHOW').length;
  const prevNoShowRate = prevTotal > 0 ? prevNoShow / prevTotal : 0;

  // byStatus (existente)
  const byStatus: Record<string, number> = {};
  for (const a of appts) { byStatus[a.status] = (byStatus[a.status] ?? 0) + 1; }

  // dailySeries (existente)
  const dailyMap = new Map<string, number>();
  for (const a of appts) {
    const key = localDateString(a.startsAt, tz);
    dailyMap.set(key, (dailyMap.get(key) ?? 0) + 1);
  }
  const dailySeries = [...dailyMap.entries()]
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([date, count]) => ({ date, count }));

  // byDayOfWeek (NOVO)
  const dowMap = new Map<number, number>();
  for (const a of appts.filter(a => a.status !== 'CANCELLED')) {
    const localDate = new Date(a.startsAt.toLocaleString('en-US', { timeZone: tz }));
    const day = localDate.getDay(); // 0=dom, 6=sáb
    dowMap.set(day, (dowMap.get(day) ?? 0) + 1);
  }
  const byDayOfWeek = Array.from({ length: 7 }, (_, i) => ({
    day: i,
    count: dowMap.get(i) ?? 0,
  }));

  return {
    total, previousTotal: prevTotal,
    byStatus,
    cancellationRate, previousCancellationRate: prevCancellationRate,
    noShowRate, previousNoShowRate: prevNoShowRate,
    dailySeries, byDayOfWeek,
  };
}

private _buildRevenueReport(appts: any[], prevAppts: any[], tz: string): RevenueReport {
  const price = (a: any): number => parseFloat(a.service?.price ?? '0') || 0;
  const completedOrConfirmed = appts.filter(a => ['COMPLETED', 'CONFIRMED'].includes(a.status));
  const completed = appts.filter(a => a.status === 'COMPLETED');
  const cancelled = appts.filter(a => a.status === 'CANCELLED');

  const confirmed = completedOrConfirmed.reduce((s, a) => s + price(a), 0);
  const realized = completed.reduce((s, a) => s + price(a), 0);
  const lost = cancelled.reduce((s, a) => s + price(a), 0);
  const averageTicket = completed.length > 0 ? realized / completed.length : 0;

  // Previous
  const prevCompletedOrConfirmed = prevAppts.filter(a => ['COMPLETED', 'CONFIRMED'].includes(a.status));
  const prevCompleted = prevAppts.filter(a => a.status === 'COMPLETED');
  const prevCancelled = prevAppts.filter(a => a.status === 'CANCELLED');
  const previousConfirmed = prevCompletedOrConfirmed.reduce((s, a) => s + price(a), 0);
  const previousRealized = prevCompleted.reduce((s, a) => s + price(a), 0);
  const previousLost = prevCancelled.reduce((s, a) => s + price(a), 0);
  const previousAverageTicket = prevCompleted.length > 0 ? previousRealized / prevCompleted.length : 0;

  // revenueDailySeries (NOVO)
  const revMap = new Map<string, number>();
  for (const a of completed) {
    const key = localDateString(a.startsAt, tz);
    revMap.set(key, (revMap.get(key) ?? 0) + price(a));
  }
  const revenueDailySeries = [...revMap.entries()]
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([date, amount]) => ({ date, amount }));

  // topServices (existente)
  const svcMap = new Map<string, { name: string; count: number; revenue: number }>();
  for (const a of appts.filter(a => a.service)) {
    const key = a.serviceId;
    const cur = svcMap.get(key) ?? { name: a.service.name, count: 0, revenue: 0 };
    svcMap.set(key, { ...cur, count: cur.count + 1, revenue: cur.revenue + price(a) });
  }
  const topServices = [...svcMap.values()]
    .sort((a, b) => b.revenue - a.revenue)
    .slice(0, 10);

  return {
    confirmed, previousConfirmed,
    realized, previousRealized,
    lost, previousLost,
    averageTicket, previousAverageTicket,
    revenueDailySeries, topServices,
  };
}
```

- [ ] **Step 4: Executar testes para ver passar**

```bash
npx jest src/modules/reports/reports.service.spec.ts --no-coverage
```

Esperado: PASS em todos os testes existentes + novos de previousTotal, byDayOfWeek, revenueDailySeries

- [ ] **Step 5: Commit**

```bash
git add src/modules/reports/reports.service.ts src/modules/reports/reports.service.spec.ts
git commit -m "feat(reports): add previous period metrics, byDayOfWeek and revenueDailySeries"
```

---

### Task 4: Adicionar seção `clients` ao reports.service.ts

**Arquivos:**
- Modificar: `scheduler-backend/src/modules/reports/reports.service.ts`
- Modificar: `scheduler-backend/src/modules/reports/reports.service.spec.ts`

- [ ] **Step 1: Escrever testes que falham**

Adicionar ao `reports.service.spec.ts`:

```typescript
describe('clients report', () => {
  it('counts new clients (first appointment in period)', async () => {
    const clientId = 'client-abc';
    prisma.appointment.findMany
      .mockResolvedValueOnce([makeAppt({ clientId, status: 'COMPLETED' })]) // atual
      .mockResolvedValueOnce([]) // anterior
      // at-risk query
      .mockResolvedValueOnce([])
      // history query: sem appointments anteriores → cliente novo
      .mockResolvedValueOnce([]);

    const result = await service.getReport(userId, slug, 'monthly');
    expect(result.clients.newClients).toBe(1);
    expect(result.clients.returningClients).toBe(0);
  });

  it('identifies returning clients (had prior appointments)', async () => {
    const clientId = 'client-xyz';
    prisma.appointment.findMany
      .mockResolvedValueOnce([makeAppt({ clientId, status: 'COMPLETED' })]) // atual
      .mockResolvedValueOnce([]) // anterior
      .mockResolvedValueOnce([])  // at-risk
      // historico do cliente: tinha visita antes
      .mockResolvedValueOnce([makeAppt({ clientId, status: 'COMPLETED' })]);

    const result = await service.getReport(userId, slug, 'monthly');
    expect(result.clients.returningClients).toBe(1);
    expect(result.clients.newClients).toBe(0);
  });

  it('returns at-risk clients (inactive > 60 days)', async () => {
    const sixtyOneDaysAgo = new Date(Date.now() - 61 * 24 * 60 * 60 * 1000);
    const atRiskAppt = makeAppt({
      clientId: 'client-old',
      status: 'COMPLETED',
      startsAt: sixtyOneDaysAgo,
      client: { id: 'client-old', name: 'Ana Costa' },
      service: { name: 'Corte', price: '50.00' },
    });
    prisma.appointment.findMany
      .mockResolvedValueOnce([]) // atual (período)
      .mockResolvedValueOnce([]) // anterior
      .mockResolvedValueOnce([atRiskAppt]); // at-risk query

    const result = await service.getReport(userId, slug, 'monthly');
    expect(result.clients.atRisk).toHaveLength(1);
    expect(result.clients.atRisk[0].name).toBe('Ana Costa');
    expect(result.clients.atRisk[0].daysSinceLastVisit).toBeGreaterThanOrEqual(61);
  });
});
```

- [ ] **Step 2: Executar testes para ver falhar**

```bash
npx jest src/modules/reports/reports.service.spec.ts -t "clients report" --no-coverage
```

Esperado: FAIL — `result.clients is undefined`

- [ ] **Step 3: Implementar `_buildClientsReport()` e adicionar queries ao getReport()**

Adicionar ao `reports.service.ts`:

```typescript
private async _buildClientsReport(
  appts: any[],
  prevAppts: any[],
  businessId: string,
  periodFrom: Date,
  prevBounds: { from: Date; to: Date }, // usado como cutoff para classificar "novos" no período anterior
  tz: string,
): Promise<ClientsReport> {
  // Clientes únicos no período atual
  const clientIds = [...new Set(appts.filter(a => a.clientId).map(a => a.clientId as string))];
  const total = clientIds.length;

  // Clientes únicos no período anterior
  const prevClientIds = new Set(prevAppts.filter(a => a.clientId).map(a => a.clientId as string));

  // Para cada cliente do período atual, verificar se já tinha visita ANTES do período
  const priorAppts = await this.prisma.appointment.findMany({
    where: {
      businessId,
      clientId: { in: clientIds },
      startsAt: { lt: periodFrom },
      type: 'APPOINTMENT',
      status: { notIn: ['CANCELLED'] },
    },
    select: { clientId: true },
  });
  const clientsWithPriorVisit = new Set(priorAppts.map(a => a.clientId));

  const newClients = clientIds.filter(id => !clientsWithPriorVisit.has(id)).length;
  const returningClients = clientIds.filter(id => clientsWithPriorVisit.has(id)).length;
  const returnRate = total > 0 ? returningClients / total : 0;

  // Para período anterior: verificar quais clientes daquele período tinham visita ANTES do início do período anterior
  // (usar prevBounds.from como cutoff, não periodFrom)
  const prevPriorAppts = clientIds.length > 0
    ? await this.prisma.appointment.findMany({
        where: {
          businessId,
          clientId: { in: [...prevClientIds] },
          startsAt: { lt: prevBounds.from }, // cutoff do período anterior
          type: 'APPOINTMENT',
          status: { notIn: ['CANCELLED'] },
        },
        select: { clientId: true },
      })
    : [];
  const prevClientsWithPriorVisit = new Set(prevPriorAppts.map(a => a.clientId));
  const prevTotal = prevClientIds.size;
  const prevNewClients = [...prevClientIds].filter(id => !prevClientsWithPriorVisit.has(id)).length;
  const previousReturnRate = prevTotal > 0 ? (prevTotal - prevNewClients) / prevTotal : 0;

  // Ticket médio por cliente
  const price = (a: any): number => parseFloat(a.service?.price ?? '0') || 0;
  const completedAppts = appts.filter(a => a.status === 'COMPLETED');
  const realized = completedAppts.reduce((s, a) => s + price(a), 0);
  const averageTicketPerClient = total > 0 ? realized / total : 0;

  const prevCompleted = prevAppts.filter(a => a.status === 'COMPLETED');
  const prevRealized = prevCompleted.reduce((s, a) => s + price(a), 0);
  const previousAverageTicketPerClient = prevTotal > 0 ? prevRealized / prevTotal : 0;

  // Frequência média de retorno (apenas clientes recorrentes)
  const returningIds = clientIds.filter(id => clientsWithPriorVisit.has(id));
  let averageFrequencyDays = 0;
  if (returningIds.length > 0 && clientsWithPriorVisit.size > 0) {
    const lastPriorByClient = new Map<string, Date>();
    for (const a of priorAppts) {
      const cur = lastPriorByClient.get(a.clientId!);
      if (!cur || a.startsAt > cur) lastPriorByClient.set(a.clientId!, a.startsAt);
    }
    const freqDays = returningIds
      .filter(id => lastPriorByClient.has(id))
      .map(id => {
        const lastVisit = lastPriorByClient.get(id)!;
        const currentVisit = appts.filter(a => a.clientId === id && a.status !== 'CANCELLED')[0]?.startsAt;
        if (!currentVisit) return null;
        return Math.round((currentVisit.getTime() - lastVisit.getTime()) / (1000 * 60 * 60 * 24));
      })
      .filter((d): d is number => d !== null);
    averageFrequencyDays = freqDays.length > 0
      ? Math.round(freqDays.reduce((s, d) => s + d, 0) / freqDays.length)
      : 0;
  }

  // At-risk: clientes com última visita > 60 dias atrás (mas que já visitaram)
  const sixtyDaysAgo = new Date(Date.now() - 60 * 24 * 60 * 60 * 1000);
  const atRiskRaw = await this.prisma.appointment.findMany({
    where: {
      businessId,
      type: 'APPOINTMENT',
      status: { notIn: ['CANCELLED'] },
      startsAt: { lt: sixtyDaysAgo },
      clientId: { not: null },
    },
    include: { client: true, service: true },
    orderBy: { startsAt: 'desc' },
  });
  // Apenas a última visita por cliente
  const atRiskMap = new Map<string, any>();
  for (const a of atRiskRaw) {
    if (!atRiskMap.has(a.clientId!)) atRiskMap.set(a.clientId!, a);
  }
  // Excluir clientes que visitaram no período atual
  const activeInPeriod = new Set(clientIds);
  const atRisk = [...atRiskMap.values()]
    .filter(a => !activeInPeriod.has(a.clientId!))
    .map(a => ({
      id: a.clientId!,
      name: a.client.name,
      lastVisitAt: a.startsAt.toISOString(),
      lastServiceName: a.service?.name ?? null,
      daysSinceLastVisit: Math.round((Date.now() - a.startsAt.getTime()) / (1000 * 60 * 60 * 24)),
    }))
    .sort((a, b) => b.daysSinceLastVisit - a.daysSinceLastVisit);

  return {
    total,
    newClients, previousNewClients: prevNewClients,
    returningClients,
    returnRate, previousReturnRate,
    averageFrequencyDays,
    averageTicketPerClient, previousAverageTicketPerClient,
    atRisk,
  };
}
```

No `getReport()`, chamar após as queries existentes:

```typescript
const clientsReport = await this._buildClientsReport(appts, prevAppts, business.id, from, prevBounds, business.timezone);
```

- [ ] **Step 4: Executar testes para ver passar**

```bash
npx jest src/modules/reports/reports.service.spec.ts --no-coverage
```

Esperado: PASS em todos os testes

- [ ] **Step 5: Commit**

```bash
git add src/modules/reports/reports.service.ts src/modules/reports/reports.service.spec.ts
git commit -m "feat(reports): add clients section with new/returning, at-risk and return rate"
```

---

### Task 5: Adicionar seção `staff` ao reports.service.ts

**Arquivos:**
- Modificar: `scheduler-backend/src/modules/reports/reports.service.ts`
- Modificar: `scheduler-backend/src/modules/reports/reports.service.spec.ts`

- [ ] **Step 1: Escrever testes que falham**

```typescript
describe('staff report', () => {
  it('returns revenue and completion rate per staff member', async () => {
    const staffId = 'staff-1';
    prisma.appointment.findMany
      .mockResolvedValueOnce([
        makeAppt({ staffId, status: 'COMPLETED', service: { price: '80.00' } }),
        makeAppt({ staffId, status: 'CANCELLED', service: { price: '80.00' } }),
      ])
      .mockResolvedValueOnce([]) // previous
      .mockResolvedValueOnce([]) // at-risk
      .mockResolvedValueOnce([]); // prior clients

    prisma.staff.findMany.mockResolvedValueOnce([
      { id: staffId, user: { name: 'Marina R.' }, professionalRole: { name: 'Cabeleireira' }, color: '#3b82f6', photoUrl: null },
    ]);

    const result = await service.getReport(userId, slug, 'monthly');
    expect(result.staff).toHaveLength(1);
    expect(result.staff[0].revenue).toBe(80);
    // completionRate: 1 completed / (2 - 1 cancelled) = 1/1 = 1.0
    expect(result.staff[0].completionRate).toBe(1.0);
  });
});
```

- [ ] **Step 2: Executar para ver falhar**

```bash
npx jest src/modules/reports/reports.service.spec.ts -t "staff report" --no-coverage
```

- [ ] **Step 3: Implementar `_buildStaffReport()`**

```typescript
private async _buildStaffReport(appts: any[], businessId: string): Promise<StaffReport[]> {
  const staffIds = [...new Set(appts.filter(a => a.staffId).map(a => a.staffId as string))];
  if (staffIds.length === 0) return [];

  const staffMembers = await this.prisma.staff.findMany({
    where: { id: { in: staffIds }, businessId },
    include: { user: true, professionalRole: true },
  });

  const price = (a: any): number => parseFloat(a.service?.price ?? '0') || 0;

  return staffMembers
    .map(s => {
      const staffAppts = appts.filter(a => a.staffId === s.id);
      const completed = staffAppts.filter(a => a.status === 'COMPLETED');
      const nonCancelled = staffAppts.filter(a => a.status !== 'CANCELLED');
      return {
        id: s.id,
        name: s.user.name,
        photoUrl: s.user.photoUrl ?? null,
        roleName: s.professionalRole?.name ?? null,
        color: (s as any).color ?? '#6b7280',
        appointments: staffAppts.length,
        revenue: completed.reduce((sum, a) => sum + price(a), 0),
        completionRate: nonCancelled.length > 0 ? completed.length / nonCancelled.length : 0,
      };
    })
    .sort((a, b) => b.revenue - a.revenue);
}
```

No `getReport()`, adicionar:
```typescript
const staffReport = await this._buildStaffReport(appts, business.id);
```

- [ ] **Step 4: Executar todos os testes do módulo**

```bash
npx jest src/modules/reports/ --no-coverage
```

Esperado: PASS em todos

- [ ] **Step 5: Commit**

```bash
git add src/modules/reports/reports.service.ts src/modules/reports/reports.service.spec.ts
git commit -m "feat(reports): add staff performance section per professional"
```

---

### Task 6: Adicionar previousOccupancyRate ao OccupancyReport

**Arquivos:**
- Modificar: `scheduler-backend/src/modules/reports/reports.service.ts`
- Modificar: `scheduler-backend/src/modules/reports/reports.service.spec.ts`

- [ ] **Step 1: Escrever teste que falha**

```typescript
it('returns previousOccupancyRate from previous period slots', async () => {
  // Configurar mocks existentes + previous period
  // ...
  const result = await service.getReport(userId, slug, 'monthly');
  expect(typeof result.occupancy.previousOccupancyRate).toBe('number');
});
```

- [ ] **Step 2: Executar para ver falhar**

```bash
npx jest src/modules/reports/reports.service.spec.ts -t "previousOccupancyRate" --no-coverage
```

- [ ] **Step 3: Expandir método de occupancy existente**

No método que já calcula `occupancyReport`, calcular também `previousOccupancyRate` usando `prevAppts`.

> **Premissa documentada:** `totalSlotsAvailable` é calculado a partir dos registros de `Schedule` (dias/horários de funcionamento), que raramente mudam entre períodos consecutivos. Para simplificar, a implementação reutiliza o mesmo `totalSlotsAvailable` do período atual como denominador do período anterior. Se o negócio mudou seus horários de funcionamento entre os períodos, o dado pode ter pequena imprecisão — aceitável para esta versão.

```typescript
const prevBooked = prevAppts.filter(a => !['CANCELLED'].includes(a.status)).length;
// totalSlotsAvailable reusado do período atual (veja premissa acima)
const previousOccupancyRate = totalSlotsAvailable > 0 ? prevBooked / totalSlotsAvailable : 0;
```

Adicionar `previousOccupancyRate` ao objeto retornado de occupancy.

- [ ] **Step 4: Executar todos os testes**

```bash
npx jest src/modules/reports/ --no-coverage
```

Esperado: PASS

- [ ] **Step 5: Commit e build final do backend**

```bash
git add src/modules/reports/
git commit -m "feat(reports): add previousOccupancyRate to occupancy section"
npm run build
```

---

## FASE 2 — Frontend

---

### Task 7: Expandir reports_model.dart com novos campos e sub-modelos

**Arquivos:**
- Modificar: `lib/features/reports/data/reports_model.dart`
- Criar: `test/features/reports/data/reports_model_test.dart`

- [ ] **Step 1: Escrever testes que falham**

Criar `test/features/reports/data/reports_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/features/reports/data/reports_model.dart';

void main() {
  group('ReportsModel.fromJson', () {
    test('parses clients section', () {
      final json = _fullReportsJson();
      final model = ReportsModel.fromJson(json);
      expect(model.clients.newClients, 43);
      expect(model.clients.atRisk.length, 1);
      expect(model.clients.atRisk.first.name, 'Ana Costa');
    });

    test('parses staff section', () {
      final json = _fullReportsJson();
      final model = ReportsModel.fromJson(json);
      expect(model.staff.length, 1);
      expect(model.staff.first.name, 'Marina R.');
      expect(model.staff.first.completionRate, 0.9);
    });

    test('parses previousFrom and previousTo', () {
      final json = _fullReportsJson();
      final model = ReportsModel.fromJson(json);
      expect(model.previousFrom, '2026-02-01');
      expect(model.previousTo, '2026-02-28');
    });

    test('parses previousCancellationRate', () {
      final model = ReportsModel.fromJson(_fullReportsJson());
      expect(model.appointments.previousCancellationRate, 0.10);
    });
  });
}

Map<String, dynamic> _fullReportsJson() => {
  'period': 'monthly',
  'from': '2026-03-01',
  'to': '2026-03-31',
  'previousFrom': '2026-02-01',
  'previousTo': '2026-02-28',
  'appointments': {
    'total': 147, 'previousTotal': 140,
    'byStatus': {'COMPLETED': 106, 'CANCELLED': 21},
    'cancellationRate': 0.14, 'previousCancellationRate': 0.10,
    'noShowRate': 0.06, 'previousNoShowRate': 0.07,
    'dailySeries': [{'date': '2026-03-01', 'count': 5}],
    'byDayOfWeek': [
      {'day': 0, 'count': 8}, {'day': 1, 'count': 22},
      {'day': 2, 'count': 18}, {'day': 3, 'count': 20},
      {'day': 4, 'count': 25}, {'day': 5, 'count': 34}, {'day': 6, 'count': 20},
    ],
  },
  'revenue': {
    'confirmed': 14900.0, 'previousConfirmed': 13800.0,
    'realized': 12480.0, 'previousRealized': 11550.0,
    'lost': 1240.0, 'previousLost': 980.0,
    'averageTicket': 84.9, 'previousAverageTicket': 78.9,
    'revenueDailySeries': [{'date': '2026-03-01', 'amount': 415.0}],
    'topServices': [{'name': 'Corte + Barba', 'count': 32, 'revenue': 3840.0}],
  },
  'occupancy': {
    'totalSlotsAvailable': 203, 'totalBooked': 138,
    'occupancyRate': 0.68, 'previousOccupancyRate': 0.70,
    'peakHours': [{'hour': 9, 'count': 38}],
  },
  'clients': {
    'total': 114,
    'newClients': 43, 'previousNewClients': 38,
    'returningClients': 71,
    'returnRate': 0.71, 'previousReturnRate': 0.66,
    'averageFrequencyDays': 28,
    'averageTicketPerClient': 109.0, 'previousAverageTicketPerClient': 97.0,
    'atRisk': [
      {
        'id': 'client-1', 'name': 'Ana Costa',
        'lastVisitAt': '2026-01-23T10:00:00.000Z',
        'lastServiceName': 'Coloração',
        'daysSinceLastVisit': 89,
      }
    ],
  },
  'staff': [
    {
      'id': 'staff-1', 'name': 'Marina R.',
      'photoUrl': null, 'roleName': 'Cabeleireira',
      'color': '#3b82f6',
      'appointments': 58, 'revenue': 4920.0, 'completionRate': 0.9,
    }
  ],
};
```

- [ ] **Step 2: Executar testes para ver falhar**

```bash
cd scheduler-frontend
flutter test test/features/reports/data/reports_model_test.dart
```

Esperado: FAIL — campos não existem no modelo

- [ ] **Step 3: Expandir reports_model.dart**

Adicionar novos modelos e expandir os existentes:

```dart
// Novos sub-modelos
class RevenueDailyPoint {
  final String date;
  final double amount;
  const RevenueDailyPoint({required this.date, required this.amount});
  factory RevenueDailyPoint.fromJson(Map<String, dynamic> json) =>
      RevenueDailyPoint(date: json['date'] as String, amount: (json['amount'] as num).toDouble());
}

class DayOfWeekPoint {
  final int day; // 0=dom, 6=sáb
  final int count;
  const DayOfWeekPoint({required this.day, required this.count});
  factory DayOfWeekPoint.fromJson(Map<String, dynamic> json) =>
      DayOfWeekPoint(day: json['day'] as int, count: json['count'] as int);
}

class AtRiskClient {
  final String id;
  final String name;
  final String lastVisitAt;
  final String? lastServiceName;
  final int daysSinceLastVisit;
  const AtRiskClient({
    required this.id, required this.name, required this.lastVisitAt,
    this.lastServiceName, required this.daysSinceLastVisit,
  });
  factory AtRiskClient.fromJson(Map<String, dynamic> json) => AtRiskClient(
    id: json['id'] as String,
    name: json['name'] as String,
    lastVisitAt: json['lastVisitAt'] as String,
    lastServiceName: json['lastServiceName'] as String?,
    daysSinceLastVisit: json['daysSinceLastVisit'] as int,
  );
}

class ClientsReport {
  final int total;
  final int newClients;
  final int previousNewClients;
  final int returningClients;
  final double returnRate;
  final double previousReturnRate;
  final int averageFrequencyDays;
  final double averageTicketPerClient;
  final double previousAverageTicketPerClient;
  final List<AtRiskClient> atRisk;

  const ClientsReport({
    required this.total, required this.newClients, required this.previousNewClients,
    required this.returningClients, required this.returnRate, required this.previousReturnRate,
    required this.averageFrequencyDays, required this.averageTicketPerClient,
    required this.previousAverageTicketPerClient, required this.atRisk,
  });

  factory ClientsReport.fromJson(Map<String, dynamic> json) => ClientsReport(
    total: json['total'] as int,
    newClients: json['newClients'] as int,
    previousNewClients: json['previousNewClients'] as int,
    returningClients: json['returningClients'] as int,
    returnRate: (json['returnRate'] as num).toDouble(),
    previousReturnRate: (json['previousReturnRate'] as num).toDouble(),
    averageFrequencyDays: json['averageFrequencyDays'] as int,
    averageTicketPerClient: (json['averageTicketPerClient'] as num).toDouble(),
    previousAverageTicketPerClient: (json['previousAverageTicketPerClient'] as num).toDouble(),
    atRisk: (json['atRisk'] as List<dynamic>)
        .map((e) => AtRiskClient.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class StaffReport {
  final String id;
  final String name;
  final String? photoUrl;
  final String? roleName;
  final String color;
  final int appointments;
  final double revenue;
  final double completionRate;

  const StaffReport({
    required this.id, required this.name, this.photoUrl, this.roleName,
    required this.color, required this.appointments, required this.revenue,
    required this.completionRate,
  });

  factory StaffReport.fromJson(Map<String, dynamic> json) => StaffReport(
    id: json['id'] as String,
    name: json['name'] as String,
    photoUrl: json['photoUrl'] as String?,
    roleName: json['roleName'] as String?,
    color: json['color'] as String,
    appointments: json['appointments'] as int,
    revenue: (json['revenue'] as num).toDouble(),
    completionRate: (json['completionRate'] as num).toDouble(),
  );
}
```

Expandir modelos existentes — adicionar campos `previous*` em `AppointmentsReport`, `RevenueReport`, `OccupancyReport`. Expandir `ReportsModel` com `previousFrom`, `previousTo`, `clients`, `staff`.

- [ ] **Step 4: Executar testes para ver passar**

```bash
flutter test test/features/reports/data/reports_model_test.dart
```

Esperado: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/reports/data/reports_model.dart test/features/reports/data/
git commit -m "feat(reports): expand ReportsModel with clients, staff and previous period fields"
```

---

### Task 8: Tornar título de DailySeriesChart configurável

**Arquivos:**
- Modificar: `lib/features/reports/presentation/widgets/daily_series_chart.dart`

- [ ] **Step 1: Adicionar parâmetro `title` ao construtor**

No widget `DailySeriesChart`, adicionar:

```dart
class DailySeriesChart extends StatelessWidget {
  final List<DailyPoint> series;
  final String title; // NOVO — era hardcoded 'Agendamentos por Dia'

  const DailySeriesChart({
    super.key,
    required this.series,
    this.title = 'Agendamentos por Dia', // default preserva comportamento atual
  });
  // ...
  // Substituir a string hardcoded pelo parâmetro `title` no build()
}
```

- [ ] **Step 2: Executar testes existentes para garantir que nada quebrou**

```bash
flutter test test/features/reports/
```

Esperado: PASS (default preserva comportamento)

- [ ] **Step 3: Commit**

```bash
git add lib/features/reports/presentation/widgets/daily_series_chart.dart
git commit -m "refactor(reports): make DailySeriesChart title configurable"
```

---

### Task 9: Criar utilitários de health score e alertas

**Arquivos:**
- Criar: `lib/features/reports/utils/health_score.dart`
- Criar: `lib/features/reports/utils/smart_alerts.dart`
- Criar: `test/features/reports/utils/health_score_test.dart`
- Criar: `test/features/reports/utils/smart_alerts_test.dart`

- [ ] **Step 1: Escrever testes de health score que falham**

Criar `test/features/reports/utils/health_score_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/features/reports/utils/health_score.dart';

void main() {
  group('computeHealthScore', () {
    test('returns 100 for perfect metrics', () {
      final score = computeHealthScore(
        occupancyRate: 1.0, revenueDelta: 0.5,
        clientReturnRate: 1.0, cancellationRate: 0.0, noShowRate: 0.0,
      );
      expect(score, 100.0);
    });

    test('returns 0 for worst case metrics', () {
      final score = computeHealthScore(
        occupancyRate: 0.0, revenueDelta: -1.0,
        clientReturnRate: 0.0, cancellationRate: 1.0, noShowRate: 0.0,
      );
      expect(score, lessThanOrEqualTo(5.0)); // score mínimo real (revenueScore não vai a 0)
    });

    test('treats revenueDelta as 0.0 when previousRealized is 0', () {
      // Caller deve passar 0.0 quando previousRealized == 0
      final score = computeHealthScore(
        occupancyRate: 0.68, revenueDelta: 0.0,
        clientReturnRate: 0.71, cancellationRate: 0.14, noShowRate: 0.06,
      );
      expect(score, greaterThan(0));
      expect(score, lessThanOrEqualTo(100));
    });

    test('returns value between 0 and 100 for typical metrics', () {
      final score = computeHealthScore(
        occupancyRate: 0.68, revenueDelta: 0.08,
        clientReturnRate: 0.71, cancellationRate: 0.14, noShowRate: 0.06,
      );
      expect(score, inInclusiveRange(0, 100));
    });
  });
}
```

- [ ] **Step 2: Escrever testes de alertas que falham**

Criar `test/features/reports/utils/smart_alerts_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/features/reports/data/reports_model.dart';
import 'package:scheduler_frontend/features/reports/utils/smart_alerts.dart';

void main() {
  group('buildAlerts', () {
    test('generates high alert when cancellationRate > 0.15', () {
      final model = _makeModel(cancellationRate: 0.16);
      final alerts = buildAlerts(model);
      expect(alerts.any((a) => a.severity == AlertSeverity.high), isTrue);
    });

    test('no newClients alert when previousNewClients is 0', () {
      final model = _makeModel(previousNewClients: 0, newClients: 10);
      final alerts = buildAlerts(model);
      expect(alerts.any((a) => a.message.contains('clientes novos')), isFalse);
    });

    test('top service alert only when topServices is not empty and realized > 0', () {
      final modelEmpty = _makeModel(topServices: [], realized: 0);
      expect(buildAlerts(modelEmpty).any((a) => a.message.contains('serviço')), isFalse);

      final modelFull = _makeModel(
        topServices: [const TopService(name: 'Corte', count: 32, revenue: 3840)],
        realized: 12480,
      );
      expect(buildAlerts(modelFull).any((a) => a.severity == AlertSeverity.positive), isTrue);
    });

    test('alerts are ordered high → medium → positive', () {
      final model = _makeModel(
        cancellationRate: 0.20,
        atRisk: List.generate(12, (i) => AtRiskClient(
          id: 'c$i', name: 'Cliente $i', lastVisitAt: '2026-01-01T00:00:00Z',
          daysSinceLastVisit: 70,
        )),
        realized: 12480,
        revenueDelta: 0.15,
      );
      final alerts = buildAlerts(model);
      final severities = alerts.map((a) => a.severity.index).toList();
      expect(severities, orderedEquals(severities.toList()..sort()));
    });
  });
}
```

- [ ] **Step 3: Executar para ver falhar**

```bash
flutter test test/features/reports/utils/
```

- [ ] **Step 4: Criar `lib/features/reports/utils/health_score.dart`**

```dart
/// Retorna score de saúde do negócio entre 0 e 100.
///
/// [revenueDelta] deve ser 0.0 quando previousRealized == 0.
/// Caller é responsável por computar: previousRealized > 0
///   ? (realized - previousRealized) / previousRealized
///   : 0.0
double computeHealthScore({
  required double occupancyRate,
  required double revenueDelta,
  required double clientReturnRate,
  required double cancellationRate,
  required double noShowRate,
}) {
  final occupancyScore = occupancyRate.clamp(0.0, 1.0) * 100 * 0.30;
  final revenueScore = ((revenueDelta + 1.0).clamp(0.5, 1.5) / 1.5) * 100 * 0.25;
  final retentionScore = clientReturnRate.clamp(0.0, 1.0) * 100 * 0.25;
  final operationScore =
      (1.0 - (cancellationRate + noShowRate).clamp(0.0, 1.0)) * 100 * 0.20;
  return (occupancyScore + revenueScore + retentionScore + operationScore).clamp(0, 100);
}

String healthScoreLabel(double score) {
  if (score >= 80) return 'Seu negócio está excelente este período';
  if (score >= 60) return 'Seu negócio está bem — há espaço para crescer';
  if (score >= 40) return 'Atenção necessária em algumas áreas';
  return 'Seu negócio precisa de ajustes importantes';
}
```

- [ ] **Step 5: Criar `lib/features/reports/utils/smart_alerts.dart`**

```dart
import 'package:scheduler_frontend/features/reports/data/reports_model.dart';

enum AlertSeverity { high, medium, positive }

class ReportAlert {
  final AlertSeverity severity;
  final String message;
  final String detail;
  const ReportAlert({required this.severity, required this.message, required this.detail});
}

List<ReportAlert> buildAlerts(ReportsModel model) {
  final alerts = <ReportAlert>[];
  final appts = model.appointments;
  final rev = model.revenue;
  final clients = model.clients;

  // Alta — cancelamento
  final cancellationDelta = appts.cancellationRate - appts.previousCancellationRate;
  if (appts.cancellationRate > 0.15 || cancellationDelta > 0.03) {
    final pct = (appts.cancellationRate * 100).toStringAsFixed(0);
    alerts.add(ReportAlert(
      severity: AlertSeverity.high,
      message: 'Taxa de cancelamento subiu para $pct%',
      detail: 'Considere ativar confirmações automáticas de agendamento.',
    ));
  }

  // Média — clientes em risco
  if (clients.atRisk.length > 10) {
    alerts.add(ReportAlert(
      severity: AlertSeverity.medium,
      message: '${clients.atRisk.length} clientes sem agendar há mais de 60 dias',
      detail: 'Oportunidade de reativação — veja a lista na aba Clientes.',
    ));
  }

  // Média — ocupação baixa
  if (model.occupancy.occupancyRate < 0.60) {
    final pct = (model.occupancy.occupancyRate * 100).toStringAsFixed(0);
    alerts.add(ReportAlert(
      severity: AlertSeverity.medium,
      message: 'Ocupação abaixo de 60% ($pct%)',
      detail: 'Considere abrir novos horários ou promover serviços.',
    ));
  }

  // Positivo — receita cresceu
  if (rev.previousRealized > 0) {
    final revenueDelta = (rev.realized - rev.previousRealized) / rev.previousRealized;
    if (revenueDelta > 0.10) {
      final pct = (revenueDelta * 100).toStringAsFixed(0);
      alerts.add(ReportAlert(
        severity: AlertSeverity.positive,
        message: 'Receita cresceu $pct% este período',
        detail: 'Ótimo desempenho! Continue investindo nos serviços mais lucrativos.',
      ));
    }
  }

  // Positivo — clientes novos cresceram
  if (clients.previousNewClients > 0) {
    final newDelta = (clients.newClients - clients.previousNewClients) /
        clients.previousNewClients;
    if (newDelta > 0.10) {
      final pct = (newDelta * 100).toStringAsFixed(0);
      alerts.add(ReportAlert(
        severity: AlertSeverity.positive,
        message: '$pct% mais clientes novos que o período anterior',
        detail: 'Seu negócio está em expansão.',
      ));
    }
  }

  // Positivo — serviço top
  if (rev.topServices.isNotEmpty && rev.realized > 0) {
    final top = rev.topServices.first;
    if (top.revenue / rev.realized > 0.30) {
      final pct = ((top.revenue / rev.realized) * 100).toStringAsFixed(0);
      alerts.add(ReportAlert(
        severity: AlertSeverity.positive,
        message: '${top.name} representa $pct% da receita',
        detail: 'Seu serviço mais lucrativo do período.',
      ));
    }
  }

  // Ordenar: high → medium → positive
  alerts.sort((a, b) => a.severity.index.compareTo(b.severity.index));
  return alerts;
}
```

- [ ] **Step 6: Executar testes para ver passar**

```bash
flutter test test/features/reports/utils/
```

- [ ] **Step 7: Commit**

```bash
git add lib/features/reports/utils/ test/features/reports/utils/
git commit -m "feat(reports): add computeHealthScore and buildAlerts utilities"
```

---

### Task 10: Criar KpiCardWithDelta widget

**Arquivos:**
- Criar: `lib/features/reports/presentation/widgets/kpi_card_with_delta.dart`
- Criar: `test/features/reports/presentation/widgets/kpi_card_with_delta_test.dart`

- [ ] **Step 1: Escrever testes que falham**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/kpi_card_with_delta.dart';

void main() {
  Widget buildCard({required double delta, required String value}) {
    return MaterialApp(
      home: Scaffold(
        body: KpiCardWithDelta(
          label: 'Receita', value: value,
          delta: delta, deltaLabel: '+8%',
          accentColor: Colors.green,
        ),
      ),
    );
  }

  testWidgets('shows green up arrow for positive delta', (tester) async {
    await tester.pump(buildCard(delta: 0.08, value: 'R\$ 12.480'));
    expect(find.text('↑ +8%'), findsOneWidget);
  });

  testWidgets('shows red down arrow for negative delta', (tester) async {
    await tester.pump(buildCard(delta: -0.05, value: '68%'));
    // delta negativo → arrow vermelho descendente
    final text = find.textContaining('↓');
    expect(text, findsOneWidget);
  });
}
```

- [ ] **Step 2: Executar para ver falhar**

```bash
flutter test test/features/reports/presentation/widgets/kpi_card_with_delta_test.dart
```

- [ ] **Step 3: Criar o widget**

```dart
import 'package:flutter/material.dart';

class KpiCardWithDelta extends StatelessWidget {
  final String label;
  final String value;
  final double delta;       // ex: 0.08 = +8%, -0.05 = -5%
  final String deltaLabel;  // texto formatado, ex: '+8%'
  final Color accentColor;  // cor da borda esquerda

  const KpiCardWithDelta({
    super.key,
    required this.label,
    required this.value,
    required this.delta,
    required this.deltaLabel,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = delta >= 0;
    final arrowColor = isPositive ? Colors.green.shade400 : Colors.red.shade400;
    final arrow = isPositive ? '↑' : '↓';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accentColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          )),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 2),
          Text('$arrow $deltaLabel',
            style: TextStyle(fontSize: 12, color: arrowColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Executar testes para ver passar**

```bash
flutter test test/features/reports/presentation/widgets/kpi_card_with_delta_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/reports/presentation/widgets/kpi_card_with_delta.dart \
        test/features/reports/presentation/widgets/kpi_card_with_delta_test.dart
git commit -m "feat(reports): add KpiCardWithDelta widget with color semaphore"
```

---

### Task 11: Criar widgets de suporte (HealthScoreCard, SmartAlertsList, NewVsReturningBar, AtRiskClientsList, StaffPerformanceList, DayOfWeekChart)

**Arquivos:**
- Criar: `lib/features/reports/presentation/widgets/health_score_card.dart`
- Criar: `lib/features/reports/presentation/widgets/smart_alerts_list.dart`
- Criar: `lib/features/reports/presentation/widgets/new_vs_returning_bar.dart`
- Criar: `lib/features/reports/presentation/widgets/at_risk_clients_list.dart`
- Criar: `lib/features/reports/presentation/widgets/staff_performance_list.dart`
- Criar: `lib/features/reports/presentation/widgets/day_of_week_chart.dart`

- [ ] **Step 1: Criar `health_score_card.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:scheduler_frontend/features/reports/utils/health_score.dart';

class HealthScoreCard extends StatelessWidget {
  final double score;   // 0–100
  final List<String> badges; // ex: ['Receita ↑', 'Clientes ↑']

  const HealthScoreCard({super.key, required this.score, this.badges = const []});

  Color _scoreColor() {
    if (score >= 80) return Colors.green.shade400;
    if (score >= 60) return Colors.blue.shade400;
    if (score >= 40) return Colors.orange.shade400;
    return Colors.red.shade400;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        // Score circular
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(shape: BoxShape.circle,
            border: Border.all(color: _scoreColor(), width: 3)),
          alignment: Alignment.center,
          child: Text(score.round().toString(),
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _scoreColor())),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(healthScoreLabel(score),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(spacing: 6, children: badges
            .map((b) => Chip(label: Text(b, style: const TextStyle(fontSize: 10)),
                  padding: EdgeInsets.zero, visualDensity: VisualDensity.compact))
            .toList()),
        ])),
      ]),
    );
  }
}
```

- [ ] **Step 2: Criar `smart_alerts_list.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:scheduler_frontend/features/reports/utils/smart_alerts.dart';

class SmartAlertsList extends StatelessWidget {
  final List<ReportAlert> alerts;
  const SmartAlertsList({super.key, required this.alerts});

  Color _bgColor(AlertSeverity s) => switch (s) {
    AlertSeverity.high => Colors.red.shade900.withValues(alpha: 0.2),
    AlertSeverity.medium => Colors.orange.shade900.withValues(alpha: 0.2),
    AlertSeverity.positive => Colors.green.shade900.withValues(alpha: 0.2),
  };

  Color _borderColor(AlertSeverity s) => switch (s) {
    AlertSeverity.high => Colors.red.shade400,
    AlertSeverity.medium => Colors.orange.shade400,
    AlertSeverity.positive => Colors.green.shade400,
  };

  String _icon(AlertSeverity s) => switch (s) {
    AlertSeverity.high => '⚠️',
    AlertSeverity.medium => '💡',
    AlertSeverity.positive => '🏆',
  };

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Alertas do período',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...alerts.map((a) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _bgColor(a.severity),
            borderRadius: BorderRadius.circular(8),
            border: Border(left: BorderSide(color: _borderColor(a.severity), width: 3)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_icon(a.severity), style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.message, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(height: 2),
              Text(a.detail, style: TextStyle(fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ])),
          ]),
        )),
      ],
    );
  }
}
```

- [ ] **Step 3: Criar `new_vs_returning_bar.dart`**

```dart
import 'package:flutter/material.dart';

class NewVsReturningBar extends StatelessWidget {
  final int newClients;
  final int returningClients;
  const NewVsReturningBar({super.key, required this.newClients, required this.returningClients});

  @override
  Widget build(BuildContext context) {
    final total = newClients + returningClients;
    if (total == 0) return const SizedBox.shrink();
    final newPct = newClients / total;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Novos vs. Recorrentes',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Row(children: [
          Expanded(flex: (newPct * 100).round(),
            child: Container(height: 16, color: const Color(0xFF7c3aed))),
          Expanded(flex: ((1 - newPct) * 100).round(),
            child: Container(height: 16, color: const Color(0xFF16a34a))),
        ]),
      ),
      const SizedBox(height: 6),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('$newClients novos (${(newPct * 100).round()}%)',
          style: const TextStyle(fontSize: 11, color: Color(0xFF7c3aed))),
        Text('$returningClients recorrentes (${((1 - newPct) * 100).round()}%)',
          style: const TextStyle(fontSize: 11, color: Color(0xFF16a34a))),
      ]),
    ]);
  }
}
```

- [ ] **Step 4: Criar `at_risk_clients_list.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:scheduler_frontend/features/reports/data/reports_model.dart';

class AtRiskClientsList extends StatelessWidget {
  final List<AtRiskClient> clients;
  const AtRiskClientsList({super.key, required this.clients});

  @override
  Widget build(BuildContext context) {
    if (clients.isEmpty) return const SizedBox.shrink();
    final preview = clients.take(2).toList();
    final hasMore = clients.length > 2;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Clientes para reativar',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: Colors.red.shade900,
            borderRadius: BorderRadius.circular(10)),
          child: Text('${clients.length} clientes',
            style: const TextStyle(fontSize: 10, color: Colors.white)),
        ),
      ]),
      const SizedBox(height: 8),
      ...preview.map((c) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            if (c.lastServiceName != null)
              Text('Último: ${c.lastServiceName}',
                style: TextStyle(fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ])),
          Text('${c.daysSinceLastVisit} dias',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
              color: c.daysSinceLastVisit > 90 ? Colors.red.shade400 : Colors.orange.shade400)),
        ]),
      )),
      if (hasMore)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('+ ${clients.length - 2} clientes inativos...',
            style: TextStyle(fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
    ]);
  }
}
```

- [ ] **Step 5: Criar `staff_performance_list.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:scheduler_frontend/features/reports/data/reports_model.dart';

class StaffPerformanceList extends StatelessWidget {
  final List<StaffReport> staff;
  const StaffPerformanceList({super.key, required this.staff});

  @override
  Widget build(BuildContext context) {
    if (staff.isEmpty) {
      return Center(child: Text('Nenhum dado de equipe disponível',
        style: Theme.of(context).textTheme.bodyMedium));
    }
    return Column(
      children: staff.map((s) {
        final initials = s.name.trim().split(' ')
            .take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();
        final color = Color(int.parse(s.color.replaceFirst('#', '0xFF')));

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            CircleAvatar(backgroundColor: color, radius: 20,
              child: Text(initials, style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.bold, fontSize: 13))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              if (s.roleName != null)
                Text(s.roleName!, style: TextStyle(fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('R\$ ${s.revenue.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16a34a))),
              Text('${s.appointments} agend. · ${(s.completionRate * 100).round()}% concluídos',
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ]),
          ]),
        );
      }).toList(),
    );
  }
}
```

- [ ] **Step 6: Criar `day_of_week_chart.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:scheduler_frontend/features/reports/data/reports_model.dart';

class DayOfWeekChart extends StatelessWidget {
  final List<DayOfWeekPoint> data;
  const DayOfWeekChart({super.key, required this.data});

  static const _labels = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final maxCount = data.map((d) => d.count).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dias mais movimentados',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...data.map((d) {
          final ratio = maxCount > 0 ? d.count / maxCount : 0.0;
          final isPeak = d.count == maxCount && maxCount > 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              SizedBox(width: 32,
                child: Text(_labels[d.day],
                  style: TextStyle(fontSize: 10,
                    color: isPeak ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant))),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 10,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(isPeak
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${d.count}', style: const TextStyle(fontSize: 10)),
            ]),
          );
        }),
      ],
    );
  }
}
```

- [ ] **Step 7: Executar análise de lint**

```bash
flutter analyze lib/features/reports/presentation/widgets/
```

Esperado: sem erros

- [ ] **Step 8: Commit**

```bash
git add lib/features/reports/presentation/widgets/health_score_card.dart \
        lib/features/reports/presentation/widgets/smart_alerts_list.dart \
        lib/features/reports/presentation/widgets/new_vs_returning_bar.dart \
        lib/features/reports/presentation/widgets/at_risk_clients_list.dart \
        lib/features/reports/presentation/widgets/staff_performance_list.dart \
        lib/features/reports/presentation/widgets/day_of_week_chart.dart
git commit -m "feat(reports): add HealthScoreCard, SmartAlertsList and detail widgets"
```

---

### Task 12: Criar as 5 abas de relatório

**Arquivos:**
- Criar: `lib/features/reports/presentation/widgets/tabs/reports_general_tab.dart`
- Criar: `lib/features/reports/presentation/widgets/tabs/reports_financial_tab.dart`
- Criar: `lib/features/reports/presentation/widgets/tabs/reports_appointments_tab.dart`
- Criar: `lib/features/reports/presentation/widgets/tabs/reports_clients_tab.dart`
- Criar: `lib/features/reports/presentation/widgets/tabs/reports_staff_tab.dart`

- [ ] **Step 1: Criar `reports_general_tab.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scheduler_frontend/features/reports/data/reports_model.dart';
import 'package:scheduler_frontend/features/reports/utils/health_score.dart';
import 'package:scheduler_frontend/features/reports/utils/smart_alerts.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/health_score_card.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/smart_alerts_list.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/kpi_card_with_delta.dart';

class ReportsGeneralTab extends StatelessWidget {
  final ReportsModel model;
  const ReportsGeneralTab({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    final appts = model.appointments;
    final rev = model.revenue;
    final occ = model.occupancy;
    final clients = model.clients;

    if (appts.total == 0) {
      return const Center(child: Text('Nenhum agendamento neste período'));
    }

    final revenueDelta = rev.previousRealized > 0
        ? (rev.realized - rev.previousRealized) / rev.previousRealized
        : 0.0;
    final score = computeHealthScore(
      occupancyRate: occ.occupancyRate,
      revenueDelta: revenueDelta,
      clientReturnRate: clients.returnRate,
      cancellationRate: appts.cancellationRate,
      noShowRate: appts.noShowRate,
    );
    final alerts = buildAlerts(model);
    final currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final pctFmt = (double v) => '${(v * 100).toStringAsFixed(1)}%';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        HealthScoreCard(score: score, badges: _scoreBadges(score, revenueDelta, clients)),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1.6,
          children: [
            KpiCardWithDelta(
              label: 'Receita Realizada',
              value: currencyFmt.format(rev.realized),
              delta: revenueDelta,
              deltaLabel: _deltaLabel(revenueDelta),
              accentColor: Colors.green.shade400,
            ),
            KpiCardWithDelta(
              label: 'Agendamentos',
              value: '${appts.total}',
              delta: appts.previousTotal > 0
                  ? (appts.total - appts.previousTotal) / appts.previousTotal : 0,
              deltaLabel: _deltaLabel(appts.previousTotal > 0
                  ? (appts.total - appts.previousTotal) / appts.previousTotal : 0),
              accentColor: Colors.blue.shade400,
            ),
            KpiCardWithDelta(
              label: 'Taxa de Ocupação',
              value: pctFmt(occ.occupancyRate),
              delta: occ.occupancyRate - occ.previousOccupancyRate,
              deltaLabel: _deltaLabel(occ.occupancyRate - occ.previousOccupancyRate),
              accentColor: occ.occupancyRate < 0.6
                  ? Colors.red.shade400 : Colors.orange.shade400,
            ),
            KpiCardWithDelta(
              label: 'Clientes Novos',
              value: '${clients.newClients}',
              delta: clients.previousNewClients > 0
                  ? (clients.newClients - clients.previousNewClients) / clients.previousNewClients
                  : 0,
              deltaLabel: _deltaLabel(clients.previousNewClients > 0
                  ? (clients.newClients - clients.previousNewClients) / clients.previousNewClients
                  : 0),
              accentColor: Colors.purple.shade400,
            ),
          ],
        ),
        const SizedBox(height: 16),
        SmartAlertsList(alerts: alerts),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _miniCard(context,
            label: 'Receita perdida (cancelamentos)',
            value: currencyFmt.format(rev.lost),
            color: Colors.red.shade400)),
          const SizedBox(width: 8),
          Expanded(child: _miniCard(context,
            label: 'Taxa de retorno de clientes',
            value: pctFmt(clients.returnRate),
            color: Colors.purple.shade400)),
        ]),
      ]),
    );
  }

  List<String> _scoreBadges(double score, double revDelta, ClientsReport clients) {
    final badges = <String>[];
    if (revDelta > 0) badges.add('Receita ↑');
    if (clients.newClients > clients.previousNewClients) badges.add('Clientes ↑');
    return badges;
  }

  String _deltaLabel(double delta) {
    final pct = (delta * 100).abs().toStringAsFixed(1);
    return delta >= 0 ? '+$pct%' : '-$pct%';
  }

  Widget _miniCard(BuildContext context, {required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }
}
```

- [ ] **Step 2: Criar `reports_financial_tab.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scheduler_frontend/features/reports/data/reports_model.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/kpi_card_with_delta.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/daily_series_chart.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/top_services_list.dart';

class ReportsFinancialTab extends StatelessWidget {
  final ReportsModel model;
  const ReportsFinancialTab({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    final rev = model.revenue;
    if (rev.realized == 0 && rev.confirmed == 0) {
      return const Center(child: Text('Sem receita registrada neste período'));
    }

    final currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final delta = (double prev, double curr) =>
        prev > 0 ? (curr - prev) / prev : 0.0;
    final deltaLabel = (double d) {
      final pct = (d * 100).abs().toStringAsFixed(1);
      return d >= 0 ? '+$pct%' : '-$pct%';
    };

    // Converter revenueDailySeries para DailyPoint para reutilizar DailySeriesChart
    final dailyAsCount = rev.revenueDailySeries
        .map((p) => DailyPoint(date: p.date, count: p.amount.round()))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 3 colunas: Realizada / Confirmada / Perdida
        Row(children: [
          Expanded(child: _revenueBlock(context, 'Realizada',
            currencyFmt.format(rev.realized),
            delta(rev.previousRealized, rev.realized), deltaLabel,
            Colors.green.shade400)),
          const SizedBox(width: 8),
          Expanded(child: _revenueBlock(context, 'Confirmada',
            currencyFmt.format(rev.confirmed),
            delta(rev.previousConfirmed, rev.confirmed), deltaLabel,
            Colors.blue.shade400)),
          const SizedBox(width: 8),
          Expanded(child: _revenueBlock(context, 'Perdida',
            currencyFmt.format(rev.lost),
            delta(rev.previousLost, rev.lost), deltaLabel,
            Colors.red.shade400)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: KpiCardWithDelta(
            label: 'Ticket Médio / Agend.',
            value: currencyFmt.format(rev.averageTicket),
            delta: delta(rev.previousAverageTicket, rev.averageTicket),
            deltaLabel: deltaLabel(delta(rev.previousAverageTicket, rev.averageTicket)),
            accentColor: Colors.teal.shade400,
          )),
        ]),
        const SizedBox(height: 16),
        if (dailyAsCount.isNotEmpty)
          DailySeriesChart(series: dailyAsCount, title: 'Evolução da Receita (R\$)'),
        const SizedBox(height: 16),
        TopServicesList(services: rev.topServices),
      ]),
    );
  }

  Widget _revenueBlock(BuildContext context, String label, String value,
      double d, String Function(double) fmtDelta, Color color) {
    final isPos = d >= 0;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border(top: BorderSide(color: color, width: 2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(fmtDelta(d), style: TextStyle(fontSize: 10,
          color: isPos ? Colors.green.shade400 : Colors.red.shade400)),
      ]),
    );
  }
}
```

- [ ] **Step 3: Criar `reports_appointments_tab.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:scheduler_frontend/features/reports/data/reports_model.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/kpi_card_with_delta.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/status_bar_chart.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/day_of_week_chart.dart';

class ReportsAppointmentsTab extends StatelessWidget {
  final ReportsModel model; // usa appointments + occupancy
  const ReportsAppointmentsTab({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    final appts = model.appointments;
    final occ = model.occupancy;

    if (appts.total == 0) {
      return const Center(child: Text('Nenhum agendamento neste período'));
    }

    final delta = (double prev, double curr) => prev > 0 ? (curr - prev) / prev : 0.0;
    final deltaLabel = (double d) {
      final pct = (d * 100).abs().toStringAsFixed(1);
      return d >= 0 ? '+$pct%' : '-$pct%';
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1.6,
          children: [
            KpiCardWithDelta(label: 'Agendamentos', value: '${appts.total}',
              delta: delta(appts.previousTotal.toDouble(), appts.total.toDouble()),
              deltaLabel: deltaLabel(delta(appts.previousTotal.toDouble(), appts.total.toDouble())),
              accentColor: Colors.blue.shade400),
            KpiCardWithDelta(label: 'Cancelamentos', value: '${(appts.cancellationRate * 100).toStringAsFixed(1)}%',
              delta: -(appts.cancellationRate - appts.previousCancellationRate),
              deltaLabel: deltaLabel(-(appts.cancellationRate - appts.previousCancellationRate)),
              accentColor: Colors.red.shade400),
            KpiCardWithDelta(label: 'No-show', value: '${(appts.noShowRate * 100).toStringAsFixed(1)}%',
              delta: -(appts.noShowRate - appts.previousNoShowRate),
              deltaLabel: deltaLabel(-(appts.noShowRate - appts.previousNoShowRate)),
              accentColor: Colors.orange.shade400),
            KpiCardWithDelta(label: 'Ocupação', value: '${(occ.occupancyRate * 100).toStringAsFixed(1)}%',
              delta: occ.occupancyRate - occ.previousOccupancyRate,
              deltaLabel: deltaLabel(occ.occupancyRate - occ.previousOccupancyRate),
              accentColor: occ.occupancyRate < 0.6 ? Colors.red.shade400 : Colors.green.shade400),
          ],
        ),
        const SizedBox(height: 8),
        // Barra de ocupação
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Taxa de Ocupação', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              Text('${(occ.occupancyRate * 100).round()}%',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14,
                  color: occ.occupancyRate < 0.6 ? Colors.red.shade400 : Colors.orange.shade400)),
            ]),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: occ.occupancyRate, minHeight: 8,
              borderRadius: BorderRadius.circular(4)),
            const SizedBox(height: 4),
            Text('${occ.totalBooked} de ${occ.totalSlotsAvailable} slots ocupados',
              style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ]),
        ),
        const SizedBox(height: 16),
        StatusBarChart(byStatus: appts.byStatus),
        const SizedBox(height: 16),
        // Horários de pico
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Horários de pico', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 8),
            ...occ.peakHours.take(5).map((h) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                SizedBox(width: 48,
                  child: Text('${h.hour.toString().padLeft(2, '0')}h',
                    style: const TextStyle(fontSize: 11))),
                Expanded(child: LinearProgressIndicator(
                  value: occ.peakHours.first.count > 0 ? h.count / occ.peakHours.first.count : 0,
                  minHeight: 8, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Text('${h.count}', style: const TextStyle(fontSize: 11)),
              ]),
            )),
          ]),
        ),
        const SizedBox(height: 16),
        DayOfWeekChart(data: appts.byDayOfWeek),
      ]),
    );
  }
}
```

- [ ] **Step 4: Criar `reports_clients_tab.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scheduler_frontend/features/reports/data/reports_model.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/kpi_card_with_delta.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/new_vs_returning_bar.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/at_risk_clients_list.dart';

class ReportsClientsTab extends StatelessWidget {
  final ReportsModel model;
  const ReportsClientsTab({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    final clients = model.clients;
    if (clients.total == 0) {
      return const Center(child: Text('Nenhum cliente atendido neste período'));
    }

    final currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final delta = (double prev, double curr) => prev > 0 ? (curr - prev) / prev : 0.0;
    final deltaLabel = (double d) {
      final pct = (d * 100).abs().toStringAsFixed(1);
      return d >= 0 ? '+$pct%' : '-$pct%';
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        NewVsReturningBar(newClients: clients.newClients, returningClients: clients.returningClients),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1.6,
          children: [
            KpiCardWithDelta(label: 'Taxa de Retorno', value: '${(clients.returnRate * 100).toStringAsFixed(1)}%',
              delta: clients.returnRate - clients.previousReturnRate,
              deltaLabel: deltaLabel(clients.returnRate - clients.previousReturnRate),
              accentColor: Colors.purple.shade400),
            KpiCardWithDelta(label: 'Frequência Média', value: '${clients.averageFrequencyDays} dias',
              delta: 0, deltaLabel: '', accentColor: Colors.blue.shade400),
            KpiCardWithDelta(label: 'Ticket Médio / Cliente',
              value: currencyFmt.format(clients.averageTicketPerClient),
              delta: delta(clients.previousAverageTicketPerClient, clients.averageTicketPerClient),
              deltaLabel: deltaLabel(delta(clients.previousAverageTicketPerClient, clients.averageTicketPerClient)),
              accentColor: Colors.green.shade400),
            KpiCardWithDelta(label: 'Clientes Ativos', value: '${clients.total}',
              delta: 0, deltaLabel: '', accentColor: Colors.teal.shade400),
          ],
        ),
        const SizedBox(height: 16),
        AtRiskClientsList(clients: clients.atRisk),
      ]),
    );
  }
}
```

- [ ] **Step 5: Criar `reports_staff_tab.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:scheduler_frontend/features/reports/data/reports_model.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/staff_performance_list.dart';

class ReportsStaffTab extends StatelessWidget {
  final ReportsModel model;
  const ReportsStaffTab({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: StaffPerformanceList(staff: model.staff),
    );
  }
}
```

- [ ] **Step 6: Executar lint nas novas abas**

```bash
flutter analyze lib/features/reports/presentation/widgets/tabs/
```

Esperado: sem erros

- [ ] **Step 7: Commit**

```bash
git add lib/features/reports/presentation/widgets/tabs/
git commit -m "feat(reports): add 5 report tabs (Geral, Financeiro, Agendamentos, Clientes, Equipe)"
```

---

### Task 13: Refatorar reports_page.dart para estrutura multi-aba

**Arquivos:**
- Modificar: `lib/features/reports/presentation/reports_page.dart`
- Modificar: `test/features/reports/presentation/reports_page_test.dart`

- [ ] **Step 1: Escrever testes de página que falham**

Adicionar ao `test/features/reports/presentation/reports_page_test.dart`. O padrão do projeto é testar BLoCs com `blocTest` — para widgets que dependem de BLoC, usar `BlocProvider.value` com um mock bloc via `bloc_test` package:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scheduler_frontend/features/reports/bloc/reports_bloc.dart';
import 'package:scheduler_frontend/features/reports/bloc/reports_state.dart';
import 'package:scheduler_frontend/features/reports/data/reports_model.dart';
import 'package:scheduler_frontend/features/reports/presentation/reports_page.dart';

class MockReportsBloc extends MockBloc<ReportsEvent, ReportsState> implements ReportsBloc {}

void main() {
  late MockReportsBloc mockBloc;

  setUp(() { mockBloc = MockReportsBloc(); });

  Widget buildPage() => MaterialApp(
    home: BlocProvider<ReportsBloc>.value(
      value: mockBloc,
      child: const _ReportsView(slug: 'my-salon'),
    ),
  );

  testWidgets('shows TabBar with 5 tabs when ReportsLoaded', (tester) async {
    when(() => mockBloc.state).thenReturn(ReportsLoaded(
      data: _fakeModel(), period: ReportPeriod.monthly));
    await tester.pump(buildPage());
    expect(find.text('Geral'), findsOneWidget);
    expect(find.text('Financeiro'), findsOneWidget);
    expect(find.text('Clientes'), findsOneWidget);
    expect(find.byType(TabBar), findsOneWidget);
  });

  testWidgets('shows CircularProgressIndicator during loading, no TabBar', (tester) async {
    when(() => mockBloc.state).thenReturn(const ReportsLoading());
    await tester.pump(buildPage());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(TabBar), findsNothing);
  });

  testWidgets('shows SnackBar on ReportsError', (tester) async {
    when(() => mockBloc.state).thenReturn(
      const ReportsError(message: 'Erro ao carregar relatórios', period: ReportPeriod.monthly));
    whenListen(mockBloc,
      Stream.fromIterable([
        const ReportsLoading(),
        const ReportsError(message: 'Erro ao carregar relatórios', period: ReportPeriod.monthly),
      ]),
      initialState: const ReportsLoading(),
    );
    await tester.pump(buildPage());
    await tester.pump(); // processa stream
    expect(find.text('Erro ao carregar relatórios'), findsOneWidget);
  });
}

ReportsModel _fakeModel() => ReportsModel.fromJson({
  'period': 'monthly', 'from': '2026-03-01', 'to': '2026-03-31',
  'previousFrom': '2026-02-01', 'previousTo': '2026-02-28',
  'appointments': {
    'total': 0, 'previousTotal': 0,
    'byStatus': <String, dynamic>{},
    'cancellationRate': 0.0, 'previousCancellationRate': 0.0,
    'noShowRate': 0.0, 'previousNoShowRate': 0.0,
    'dailySeries': <dynamic>[], 'byDayOfWeek': <dynamic>[],
  },
  'revenue': {
    'confirmed': 0.0, 'previousConfirmed': 0.0,
    'realized': 0.0, 'previousRealized': 0.0,
    'lost': 0.0, 'previousLost': 0.0,
    'averageTicket': 0.0, 'previousAverageTicket': 0.0,
    'revenueDailySeries': <dynamic>[], 'topServices': <dynamic>[],
  },
  'occupancy': {
    'totalSlotsAvailable': 0, 'totalBooked': 0,
    'occupancyRate': 0.0, 'previousOccupancyRate': 0.0,
    'peakHours': <dynamic>[],
  },
  'clients': {
    'total': 0, 'newClients': 0, 'previousNewClients': 0,
    'returningClients': 0, 'returnRate': 0.0, 'previousReturnRate': 0.0,
    'averageFrequencyDays': 0, 'averageTicketPerClient': 0.0,
    'previousAverageTicketPerClient': 0.0, 'atRisk': <dynamic>[],
  },
  'staff': <dynamic>[],
});
```

> **Nota:** `_ReportsView` precisa ser exportada ou o teste deve estar no mesmo diretório lib. Se a classe for privada, mover o teste para dentro de `lib/` como `_test` ou tornar `_ReportsView` `@visibleForTesting`.

- [ ] **Step 2: Executar testes para ver falhar**

```bash
flutter test test/features/reports/presentation/reports_page_test.dart
```

- [ ] **Step 3: Refatorar reports_page.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:scheduler_frontend/features/reports/bloc/reports_bloc.dart';
import 'package:scheduler_frontend/features/reports/bloc/reports_event.dart';
import 'package:scheduler_frontend/features/reports/bloc/reports_state.dart';
import 'package:scheduler_frontend/features/reports/data/reports_repository.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/period_selector.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/tabs/reports_general_tab.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/tabs/reports_financial_tab.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/tabs/reports_appointments_tab.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/tabs/reports_clients_tab.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/tabs/reports_staff_tab.dart';

class ReportsPage extends StatelessWidget {
  final String slug;
  const ReportsPage({super.key, required this.slug});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReportsBloc(context.read<ReportsRepository>())
        ..add(ReportsLoadRequested(slug: slug, period: ReportPeriod.monthly)),
      child: _ReportsView(slug: slug),
    );
  }
}

// Adicionar import: import 'package:flutter/foundation.dart' show visibleForTesting;
@visibleForTesting
class ReportsView extends StatelessWidget {  // exposta para testes; renomear de _ReportsView
  final String slug;
  const ReportsView({required this.slug});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: BlocConsumer<ReportsBloc, ReportsState>(
        listener: (context, state) {
          if (state is ReportsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                action: SnackBarAction(
                  label: 'Tentar novamente',
                  onPressed: () => context.read<ReportsBloc>().add(
                    ReportsLoadRequested(slug: slug, period: state.period),
                  ),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          final currentPeriod = state is ReportsLoaded
              ? state.period
              : state is ReportsError
                  ? state.period
                  : ReportPeriod.monthly;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Relatórios'),
              bottom: state is ReportsLoaded
                  ? TabBar(tabs: const [
                      Tab(text: 'Geral'),
                      Tab(text: 'Financeiro'),
                      Tab(text: 'Agenda'),
                      Tab(text: 'Clientes'),
                      Tab(text: 'Equipe'),
                    ])
                  : null,
            ),
            body: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  PeriodSelector(
                    selected: currentPeriod,
                    onChanged: (p) => context.read<ReportsBloc>().add(
                      ReportsLoadRequested(slug: slug, period: p),
                    ),
                  ),
                  if (state is ReportsLoaded) ...[
                    const SizedBox(height: 4),
                    Text(
                      _comparisonLabel(state.data.from, state.data.previousFrom),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ]),
              ),
              const SizedBox(height: 8),
              if (state is ReportsLoading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (state is ReportsLoaded)
                Expanded(
                  child: TabBarView(children: [
                    ReportsGeneralTab(model: state.data),
                    ReportsFinancialTab(model: state.data),
                    ReportsAppointmentsTab(model: state.data),
                    ReportsClientsTab(model: state.data),
                    ReportsStaffTab(model: state.data),
                  ]),
                )
              else if (state is ReportsInitial)
                const Expanded(child: SizedBox.shrink()),
            ]),
          );
        },
      ),
    );
  }

  String _comparisonLabel(String from, String previousFrom) {
    final fmt = DateFormat('MMMM yyyy', 'pt_BR');
    try {
      final current = fmt.format(DateTime.parse(from));
      final previous = fmt.format(DateTime.parse(previousFrom));
      return '$current vs. $previous'; // ex: "Março 2026 vs. Fevereiro 2026"
    } catch (_) {
      return '';
    }
  }
}
```

- [ ] **Step 4: Executar todos os testes de reports**

```bash
flutter test test/features/reports/
```

Esperado: PASS em todos

- [ ] **Step 5: Executar lint geral**

```bash
flutter analyze lib/features/reports/
```

Esperado: sem erros

- [ ] **Step 6: Commit**

```bash
git add lib/features/reports/presentation/reports_page.dart \
        test/features/reports/presentation/reports_page_test.dart
git commit -m "feat(reports): refactor page to multi-tab with TabBar + health score + alerts"
```

---

### Task 14: Remover widgets não mais usados e verificação final

**Arquivos:**
- Modificar: `lib/features/reports/presentation/widgets/summary_cards.dart` → verificar se pode ser removido
- Modificar: `lib/features/reports/presentation/widgets/revenue_donut.dart` → verificar se pode ser removido

- [ ] **Step 1: Verificar que SummaryCards e RevenueDonut não são mais referenciados**

```bash
cd scheduler-frontend
grep -r "SummaryCards\|RevenueDonut" lib/ --include="*.dart"
```

Se não houver referências além dos próprios arquivos, os widgets podem ser removidos. Se houver, não remover.

- [ ] **Step 2: Executar suite completa de testes**

```bash
flutter test
```

Esperado: PASS com cobertura suficiente. Ignorar os 3 erros pré-existentes em `design_system/tokens/app_colors_extension_test.dart`.

- [ ] **Step 3: Build de validação**

```bash
make analyze
```

Esperado: sem erros de análise

- [ ] **Step 4: Commit final**

```bash
git add -A
git commit -m "feat(reports): complete 360 dashboard with health score, tabs and smart alerts"
```

---

## Verificação End-to-End

1. **Backend:** Iniciar backend local (`npm run dev:local`) e fazer request manual:
   ```bash
   curl -H "Authorization: Bearer <token>" \
     "http://localhost:3000/b/<slug>/reports?period=monthly" | jq '.data.clients'
   ```
   Verificar que `clients.newClients`, `clients.atRisk`, `staff[]` estão presentes.

2. **Frontend:** Executar o app (`make run-dev`) e navegar até a aba Relatórios.
   - Verificar que TabBar aparece com 5 abas
   - Verificar que score de saúde renderiza
   - Verificar que alertas aparecem quando aplicável
   - Verificar que aba Clientes mostra lista de risco
   - Verificar que aba Equipe lista profissionais por receita

3. **Testes:** `flutter test && cd scheduler-backend && npm test`
