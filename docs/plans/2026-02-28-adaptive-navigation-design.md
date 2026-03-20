# Adaptive Navigation Design

**Goal:** Diferenciar a experiência mobile e web/desktop com sidebar fixa no web e bottom nav no mobile, mantendo as mesmas rotas e BLoCs.

**Architecture:** Um único `AdaptiveShell` (StatefulWidget) usa `LayoutBuilder` para decidir o layout. Abaixo de 720px renderiza `_MobileLayout` (bottom nav com 5 itens); acima renderiza `_DesktopLayout` (sidebar com 6 itens). O conteúdo da rota ativa é passado como `child` via `ShellRoute` do `go_router`.

**Tech Stack:** Flutter, go_router (ShellRoute), LayoutBuilder, NavigationBar, NavigationRail.

---

## Breakpoint

| Faixa | Layout |
|-------|--------|
| `width < 720px` | `_MobileLayout` — bottom nav |
| `width >= 720px` | `_DesktopLayout` — sidebar |

---

## Itens de navegação

| Ícone | Label | Rota | Mobile | Web |
|-------|-------|------|--------|-----|
| `home` | Home | `/` | ✅ | ✅ |
| `calendar_month` | Agendamentos | `/appointments` | ✅ | ✅ |
| `people` | Clientes | `/clients` | ✅ | ✅ |
| `content_cut` | Serviços | `/services` | ✅ | ✅ |
| `bar_chart` | Relatórios | `/reports` | ❌ | ✅ |
| `settings` | Configurações | `/settings` | ✅ | ✅ |

Relatórios é uma feature analítica — exibida apenas no web/desktop.

---

## Componentes

### `AdaptiveShell`
- `StatefulWidget` que mantém `_selectedIndex`
- `_selectedIndex` é derivado da rota atual via `GoRouterState` para suportar deep links e redirects
- Delega para `_MobileLayout` ou `_DesktopLayout` via `LayoutBuilder`

### `_MobileLayout`
- `Scaffold` com `bottomNavigationBar: NavigationBar`
- 5 destinos: Home, Agendamentos, Clientes, Serviços, Configurações
- `body` recebe o `child` do `ShellRoute`

### `_DesktopLayout`
- `Scaffold` com `body: Row`
  - `_Sidebar` (largura fixa 220px): logo, 6 itens de nav, user info + logout no rodapé
  - `Expanded(child: child)`: conteúdo da rota ativa

---

## Arquivos

**Modificados:**
- `lib/app_shell.dart` — substituído pelo `AdaptiveShell`
- `lib/core/router/app_routes.dart` — +5 rotas
- `lib/core/router/app_router.dart` — +5 `GoRoute` dentro do `ShellRoute`

**Criados (placeholders):**
- `lib/features/appointments/presentation/appointments_page.dart`
- `lib/features/clients/presentation/clients_page.dart`
- `lib/features/services/presentation/services_page.dart`
- `lib/features/reports/presentation/reports_page.dart`
- `lib/features/settings/presentation/settings_page.dart`

---

## Fora do escopo desta fase

- Conteúdo real das telas placeholder
- Relatórios no mobile
- Animação de transição entre layouts
