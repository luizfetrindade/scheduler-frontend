# Reports Page — Design Spec

**Date:** 2026-03-23
**Status:** Approved (rev 2 — issues from spec review corrected)
**Scope:** Frontend (Flutter) + Backend (NestJS) — Reports feature

---

## Context

A página de relatórios é uma das mais estratégicas do app. O objetivo é dar ao dono do negócio uma visão 360° da saúde do negócio — financeiro, operação, clientes e equipe — para tomar decisões de crescimento e escala.

**Uso esperado:** revisão mensal estratégica (fechamento de mês, decisões de preço, escala).

**Problema atual:** a página existente tem métricas base (agendamentos, receita, ocupação) mas carece de:
- Comparativo com período anterior
- Métricas de retenção e comportamento de clientes
- Performance por profissional
- Alertas inteligentes que apontem o que precisa de atenção

---

## Estrutura Geral — Abordagem B+C

**Multi-aba** (B) com **score de saúde e alertas inteligentes** (C) na aba principal.

```
┌─────────────────────────────────────────────────┐
│  [Semanal] [● Mensal] [Trimestral]   Mar 2026   │
│  comparando com: Fevereiro 2026                  │
├──────┬───────────────┬──────────┬───────┬───────┤
│ Geral│  Financeiro   │ Agenda   │Clientes│ Equipe│
└──────┴───────────────┴──────────┴───────┴───────┘
```

O label de comparação ("Março 2026 vs. Fevereiro 2026") é renderizado logo abaixo do seletor de período, dentro de `reports_page.dart`, derivado dos campos `from` e `previousFrom` (ISO date → formato por mês/ano em pt_BR).

---

## RBAC

A página de relatórios só é acessível por **owner** e **manager**. A rota permanece bloqueada para members via `AppPolicy.canViewReports = isAdmin` (comportamento existente — nenhuma mudança no guard). Filtrar agendamentos por profissional para members é **fora de escopo nesta versão**.

| Aba | Owner | Manager | Member |
|---|---|---|---|
| Geral | Sim | Sim | Bloqueado |
| Financeiro | Sim | Sim | Bloqueado |
| Agendamentos | Sim | Sim | Bloqueado |
| Clientes | Sim | Sim | Bloqueado |
| Equipe | Sim | Sim | Bloqueado |

---

## Aba 1 — Geral (Home)

Leitura rápida em 30 segundos. Orientada a responder: *"Como foi o mês?"*

### Score de Saúde do Negócio (0–100)

Número composto com frase de contexto e badges de destaque. Calculado no cliente via `computeHealthScore()`.

**Composição do score:**
| Componente | Peso | Direção |
|---|---|---|
| Taxa de ocupação | 30% | maior = melhor |
| Tendência de receita vs. período anterior | 25% | crescimento = melhor |
| Taxa de retorno de clientes | 25% | maior = melhor |
| Taxa de cancelamento + no-show (inversa) | 20% | menor = melhor |

**Frases de contexto por faixa:**
- 80–100: "Seu negócio está excelente este período"
- 60–79: "Seu negócio está bem — há espaço para crescer"
- 40–59: "Atenção necessária em algumas áreas"
- 0–39: "Seu negócio precisa de ajustes importantes"

### KPI Cards (4 principais)

Borda colorida como semáforo (verde/amarelo/vermelho) via `KpiCardWithDelta`. Todos com variação `↑↓` vs. período anterior.

| Métrica | Fonte de dados | Cor saudável |
|---|---|---|
| Receita Realizada | `revenue.realized` | Verde |
| Total de Agendamentos | `appointments.total` | Azul |
| Taxa de Ocupação | `occupancy.occupancyRate` | Amarelo (vermelho se < 60%) |
| Clientes Novos | `clients.newClients` | Roxo |

### Alertas Inteligentes

Lista priorizada por severidade (alta → média → positivo). Calculados no cliente. Representados por enum `AlertSeverity { high, medium, positive }` — sem emoji em código.

| Condição | Severidade | Mensagem (pt_BR) |
|---|---|---|
| `cancellationRate > 0.15` ou `(cancellationRate - previousCancellationRate) > 0.03` | Alta | "Taxa de cancelamento subiu para X% — considere confirmações automáticas" |
| `clients.atRisk.length > 10` | Média | "X clientes sem agendar há mais de 60 dias — oportunidade de reativação" |
| `occupancyRate < 0.60` | Média | "Ocupação abaixo de 60% — considere abrir novos horários" |
| `revenueDelta > 0.10` (somente se `previousRealized > 0`) | Positivo | "Receita cresceu X% este mês — ótimo desempenho!" |
| `(newClients - previousNewClients) / previousNewClients > 0.10` (somente se `previousNewClients > 0`) | Positivo | "X% mais clientes novos que o período anterior" |
| `topServices.isNotEmpty && realized > 0 && topServices.first.revenue / realized > 0.30` | Positivo | "Serviço [X] representa mais de 30% da receita" |

### Mini Destaques (links para abas)

Dois cards pequenos no rodapé da aba Geral:
- Receita perdida com cancelamentos (`revenue.lost`) → toca na aba Financeiro
- Taxa de retorno de clientes (`clients.returnRate`) → toca na aba Clientes

---

## Aba 2 — Financeiro

Análise completa de receita. Responde: *"Estou ganhando bem? Com o quê?"*

### Métricas (todas com variação vs. período anterior)

| Métrica | Fonte de dados |
|---|---|
| Receita Realizada | `revenue.realized` vs `revenue.previousRealized` |
| Receita Confirmada | `revenue.confirmed` vs `revenue.previousConfirmed` |
| Receita Perdida (cancelamentos) | `revenue.lost` vs `revenue.previousLost` |
| Ticket Médio / Agendamento | `revenue.averageTicket` vs `revenue.previousAverageTicket` |

### Gráficos

- **Linha de evolução de receita:** usa `revenue.revenueDailySeries` (campo novo no backend). Widget `DailySeriesChart` com o parâmetro `title` tornado configurável (tarefa de refactor antes do reuso). Mostra receita realizada por dia/semana.
- **Lista ranqueada:** `TopServicesList` reaproveitado com `revenue.topServices` (nome, qtd, valor total).

---

## Aba 3 — Agendamentos

Qualidade operacional. Responde: *"Minha agenda está eficiente?"*

Widget `reports_appointments_tab.dart` recebe o `ReportsModel` completo (necessário pois usa dados de `appointments` e `occupancy` simultaneamente).

### Métricas

| Métrica | Fonte de dados |
|---|---|
| Total de Agendamentos | `appointments.total` vs `appointments.previousTotal` |
| Taxa de Cancelamento | `appointments.cancellationRate` vs `appointments.previousCancellationRate` |
| Taxa de No-Show | `appointments.noShowRate` vs `appointments.previousNoShowRate` |
| Taxa de Ocupação | `occupancy.occupancyRate` vs `occupancy.previousOccupancyRate` |

### Visualizações

- **Barra de ocupação:** progresso visual `occupancyRate%` com slots absolutos (`totalBooked` / `totalSlotsAvailable`). Fonte: `occupancy`.
- **Breakdown por status:** barras horizontais — `StatusBarChart` reaproveitado com `appointments.byStatus`.
- **Horários de pico:** ranking das 5 horas mais movimentadas. Fonte: `occupancy.peakHours`.
- **Dias da semana:** ranking dos 7 dias. Fonte: `appointments.byDayOfWeek` (0 = domingo, 6 = sábado). Widget `DayOfWeekChart`.

---

## Aba 4 — Clientes

Fidelização e crescimento. Responde: *"Minha base de clientes está crescendo e voltando?"*

### Métricas

| Métrica | Fonte de dados |
|---|---|
| Clientes Novos | `clients.newClients` vs `clients.previousNewClients` |
| Clientes Recorrentes | `clients.returningClients` |
| Taxa de Retorno | `clients.returnRate` vs `clients.previousReturnRate` |
| Frequência Média de Retorno | `clients.averageFrequencyDays` |
| Ticket Médio por Cliente | `clients.averageTicketPerClient` vs `clients.previousAverageTicketPerClient` |
| Clientes Ativos | `clients.total` |

### Visualizações

- **Barra horizontal bicolor:** `NewVsReturningBar` — Novos (roxo) vs. Recorrentes (verde) com contagens e percentuais. Fonte: `clients.newClients` e `clients.returningClients`.
- **Lista "Clientes para Reativar":** `AtRiskClientsList` — exibe primeiros 2 itens de `clients.atRisk` com nome, último serviço e dias sem visitar. Botão "Ver todos" abre lista completa (tela separada ou bottom sheet — a definir na implementação). Ordenado por `daysSinceLastVisit` decrescente.

> **Limiar de inatividade:** 60 dias (fixo no backend, configurável por query param futuramente).

---

## Aba 5 — Equipe

Performance individual. Responde: *"Quem está performando bem?"*

### Card por profissional (ordenado por receita decrescente)

Widget `StaffPerformanceList` com `staff[]`. Cada item:
- Avatar com iniciais e cor (`staff.color`)
- Nome e cargo (`staff.name`, `staff.roleName`)
- Receita gerada (`staff.revenue`)
- Número de agendamentos (`staff.appointments`)
- Taxa de conclusão (`staff.completionRate`) — exibida como percentual

---

## Estados da Página

### Loading e Error

O `BlocConsumer` em `reports_page.dart` controla o estado da página inteira. A `TabBar` só é renderizada quando o estado é `ReportsLoaded`. Durante loading, exibe um `CircularProgressIndicator` centralizado acima da tab bar (não dentro das abas). Em estado de erro, exibe snackbar com botão de retry que dispara `ReportsLoadRequested` novamente — igual ao comportamento atual.

### Empty States

Quando um período não tem dados, cada aba exibe um empty state inline com ícone e texto explicativo:

| Aba | Condição | Mensagem |
|---|---|---|
| Geral | `appointments.total == 0` | "Nenhum agendamento neste período" |
| Financeiro | `revenue.realized == 0` | "Sem receita registrada neste período" |
| Agendamentos | `appointments.total == 0` | "Nenhum agendamento neste período" |
| Clientes | `clients.total == 0` | "Nenhum cliente atendido neste período" |
| Equipe | `staff.isEmpty` | "Nenhum dado de equipe disponível" |

O score de saúde e os alertas não são exibidos quando `appointments.total == 0`.

---

## Período e Comparação

- **Seletor:** Semanal / Mensal / Trimestral — `PeriodSelector` existente (arquivo: `lib/features/reports/presentation/widgets/period_selector.dart`)
- **Comparação automática:** calculada no backend — período imediatamente anterior de mesmo tamanho
  - Mensal: mês atual vs. mês anterior
  - Semanal: semana atual vs. semana anterior
  - Trimestral: trimestre atual vs. anterior
- **Label de comparação:** renderizado em `reports_page.dart` logo abaixo do `PeriodSelector`. Formato: "Março 2026 vs. Fevereiro 2026". Derivado de `from` e `previousFrom` formatados com `DateFormat('MMMM yyyy', 'pt_BR')`.

---

## Mudanças no Backend

O endpoint existente `GET /b/:slug/reports?period=` é expandido — sem breaking change (campos adicionais são novos).

### Novo contrato da ReportsResponse

```typescript
{
  period: "weekly" | "monthly" | "quarterly"
  from: string          // "YYYY-MM-DD"
  to: string
  previousFrom: string  // NEW — início do período anterior
  previousTo: string    // NEW — fim do período anterior

  appointments: {
    total: number
    previousTotal: number                    // NEW
    byStatus: Record<string, number>
    cancellationRate: number
    previousCancellationRate: number         // NEW
    noShowRate: number
    previousNoShowRate: number               // NEW
    dailySeries: { date: string; count: number }[]
    byDayOfWeek: { day: number; count: number }[]  // NEW (0=dom, 6=sáb)
  }

  revenue: {
    confirmed: number
    previousConfirmed: number                // NEW
    realized: number
    previousRealized: number                 // NEW
    lost: number
    previousLost: number                     // NEW
    averageTicket: number                    // NEW — realized / qtd completados
    previousAverageTicket: number            // NEW
    revenueDailySeries: {                    // NEW — para gráfico de linha
      date: string                           // "YYYY-MM-DD"
      amount: number                         // receita realizada do dia
    }[]
    topServices: { name: string; count: number; revenue: number }[]
  }

  occupancy: {
    totalSlotsAvailable: number
    totalBooked: number
    occupancyRate: number
    previousOccupancyRate: number            // NEW
    peakHours: { hour: number; count: number }[]
  }

  clients: {                                 // NEW — seção inteira
    total: number                            // únicos no período
    newClients: number                       // primeira visita
    previousNewClients: number               // NEW — para calcular delta
    returningClients: number
    returnRate: number                       // 0.0–1.0
    previousReturnRate: number
    averageFrequencyDays: number             // dias médios entre visitas
    averageTicketPerClient: number
    previousAverageTicketPerClient: number
    atRisk: {                                // inativos > 60 dias, ordenado por daysSinceLastVisit desc
      id: string
      name: string
      lastVisitAt: string                    // ISO datetime
      lastServiceName: string | null
      daysSinceLastVisit: number
    }[]
  }

  staff: {                                   // NEW — por profissional, ordenado por revenue desc
    id: string
    name: string
    photoUrl: string | null
    roleName: string | null
    color: string
    appointments: number
    revenue: number
    completionRate: number                   // completed / (total - cancelled)
  }[]
}
```

---

## Mudanças no Frontend

### Arquivos existentes a modificar

| Arquivo | Mudança |
|---|---|
| `lib/features/reports/data/reports_model.dart` | Adicionar todos os novos campos e sub-modelos (`ClientsReport`, `StaffReport`, `AtRiskClient`) |
| `lib/features/reports/bloc/reports_bloc.dart` | Nenhuma mudança necessária — `ReportsLoaded` já carrega `ReportsModel` completo |
| `lib/features/reports/presentation/reports_page.dart` | Refatorar para estrutura multi-aba com `TabBar` + `TabBarView` |
| `lib/features/reports/presentation/widgets/daily_series_chart.dart` | Tornar parâmetro `title` configurável via construtor (antes do reuso na aba Financeiro) |

### Estrutura de widgets novos

```
lib/features/reports/presentation/
├── widgets/
│   ├── period_selector.dart                 (existente — sem mudança)
│   ├── status_bar_chart.dart                (existente — reaproveitado na aba Agendamentos)
│   ├── daily_series_chart.dart              (existente — title vira parâmetro; reaproveitado em Financeiro)
│   ├── top_services_list.dart               (existente — reaproveitado em Financeiro)
│   ├── tabs/
│   │   ├── reports_general_tab.dart         (novo — recebe ReportsModel)
│   │   ├── reports_financial_tab.dart       (novo — recebe ReportsModel)
│   │   ├── reports_appointments_tab.dart    (novo — recebe ReportsModel; usa appointments + occupancy)
│   │   ├── reports_clients_tab.dart         (novo — recebe ReportsModel)
│   │   └── reports_staff_tab.dart           (novo — recebe ReportsModel)
│   ├── health_score_card.dart               (novo)
│   ├── smart_alerts_list.dart               (novo)
│   ├── kpi_card_with_delta.dart             (novo — KPI + variação delta + cor semáforo)
│   ├── new_vs_returning_bar.dart            (novo)
│   ├── at_risk_clients_list.dart            (novo)
│   ├── staff_performance_list.dart          (novo)
│   └── day_of_week_chart.dart              (novo)
```

Todos os tabs recebem o `ReportsModel` completo para simplicidade e evitar prop drilling.

### Widgets existentes substituídos (não mais usados)

- `SummaryCards` — substituído por `KpiCardWithDelta`
- `RevenueDonut` — substituído por 3 blocos (realizada/confirmada/perdida)

---

## Cálculo do Health Score (Frontend)

```dart
/// Retorna score de 0 a 100.
/// [revenueDelta] deve ser 0.0 quando previousRealized == 0 (negócio novo).
double computeHealthScore({
  required double occupancyRate,     // 0.0–1.0
  required double revenueDelta,      // ex: 0.08 = +8%; use 0.0 se previousRealized == 0
  required double clientReturnRate,  // 0.0–1.0
  required double cancellationRate,  // 0.0–1.0
  required double noShowRate,        // 0.0–1.0
}) {
  final occupancyScore  = occupancyRate.clamp(0.0, 1.0) * 100 * 0.30;
  final revenueScore    = ((revenueDelta + 1.0).clamp(0.5, 1.5) / 1.5) * 100 * 0.25;
  final retentionScore  = clientReturnRate.clamp(0.0, 1.0) * 100 * 0.25;
  final operationScore  = (1.0 - (cancellationRate + noShowRate).clamp(0.0, 1.0)) * 100 * 0.20;
  return (occupancyScore + revenueScore + retentionScore + operationScore).clamp(0, 100);
}
```

**Chamada do caller:**
```dart
final revenueDelta = model.revenue.previousRealized > 0
    ? (model.revenue.realized - model.revenue.previousRealized) / model.revenue.previousRealized
    : 0.0;
```

---

## Testes

### Unitários

- `computeHealthScore()` — score mínimo (todas as métricas no pior caso), máximo (todas no melhor caso), `previousRealized == 0` (revenueDelta = 0.0 sem divisão por zero)
- Lógica de alertas — cada regra individualmente: condição verdadeira gera alerta, condição falsa não gera; guard `previousNewClients == 0` não gera alerta de novos clientes
- `ReportsModel.fromJson()` — todos os novos campos; campos nullable ausentes no JSON não lançam exceção

### Integração (blocTest)

- `ReportsBloc`: `ReportsLoadRequested` → `ReportsLoading` → `ReportsLoaded` com `ReportsModel` completo
- `ReportsBloc`: `ReportsLoadRequested` → `ReportsError` em falha de rede (ServerFailure)

### Widget

- `KpiCardWithDelta`: exibe seta e cor verde para delta positivo, vermelho para negativo, neutro para zero
- `HealthScoreCard`: renderiza frase correta para cada faixa (0–39, 40–59, 60–79, 80–100)
- `SmartAlertsList`: renderiza alert de cancelamento quando `cancellationRate > 0.15`; não renderiza alert de novos clientes quando `previousNewClients == 0`
- `AtRiskClientsList`: exibe 2 primeiros itens + "Ver todos" quando `atRisk.length > 2`; exibe todos quando `atRisk.length <= 2`
- Empty state: aba Geral exibe mensagem quando `appointments.total == 0` e oculta score/alertas

---

## Fora de Escopo (v1)

- Exportar relatório como PDF/CSV
- Comparação com mesmo período do ano anterior (YoY)
- Threshold de inatividade configurável pelo usuário
- Notificações push quando alertas disparam
- Relatório por serviço específico (drill-down)
- Filtrar agendamentos por profissional para role member
