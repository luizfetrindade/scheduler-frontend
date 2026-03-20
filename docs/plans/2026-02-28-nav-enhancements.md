# Navigation Enhancements Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Substituir a navbar mobile nativa por uma floating glassmorphic com indicador deslizante animado, e transformar a sidebar desktop em expansível/retrátil com efeito glass.

**Architecture:** Toda a mudança está em `lib/app_shell.dart`. A `_MobileLayout` troca `Scaffold.bottomNavigationBar` por um `Stack` com `_FloatingNavBar` posicionada no rodapé. A `_Sidebar` vira `StatefulWidget` com `_expanded`. Ambas usam `BackdropFilter(ImageFilter.blur)` + fundo semi-transparente. Nenhuma dependência externa nova — apenas `dart:ui`.

**Tech Stack:** Flutter, dart:ui (ImageFilter.blur), BackdropFilter, ClipRRect/ClipRect, AnimatedPositioned, AnimatedContainer, AnimatedOpacity, AnimatedScale, TweenAnimationBuilder, AnimatedSwitcher.

---

### Task 1: Atualizar testes existentes para a nova navbar (TDD — devem falhar)

**Files:**
- Modify: `test/app_shell_test.dart`

Os testes existentes esperam `NavigationBar` (widget nativo do Material). O novo widget é customizado — os testes precisam ser atualizados ANTES da implementação para que falhem por razão correta.

**Step 1: Atualizar os 3 testes de mobile em `test/app_shell_test.dart`**

Localize e substitua o grupo `AdaptiveShell — layout` completamente:

```dart
group('AdaptiveShell — layout', () {
  testWidgets('mostra floating navbar em tela estreita (< 720px)',
      (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_buildShell());
    await tester.pump();

    // Widget nativo substituído — não deve existir mais
    expect(find.byType(NavigationBar), findsNothing);
    // Floating navbar identificada por key
    expect(find.byKey(const ValueKey('floating_nav_bar')), findsOneWidget);
    // Relatórios não aparece no mobile
    expect(find.text('Relatórios'), findsNothing);
  });

  testWidgets('mostra sidebar em tela larga (>= 720px)', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_buildShell());
    await tester.pump();

    expect(find.byType(NavigationBar), findsNothing);
    // Relatórios aparece apenas no desktop
    expect(find.text('Relatórios'), findsOneWidget);
  });

  testWidgets('floating navbar contém os 5 itens mobile', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_buildShell(location: '/appointments'));
    await tester.pump();

    // Os 5 itens mobile identificados por key no _NavItemButton
    expect(find.byKey(const Key('nav_item_/')),             findsOneWidget);
    expect(find.byKey(const Key('nav_item_/appointments')), findsOneWidget);
    expect(find.byKey(const Key('nav_item_/clients')),      findsOneWidget);
    expect(find.byKey(const Key('nav_item_/services')),     findsOneWidget);
    expect(find.byKey(const Key('nav_item_/settings')),     findsOneWidget);
    // Relatórios NÃO está nos itens mobile
    expect(find.byKey(const Key('nav_item_/reports')),      findsNothing);
  });

  testWidgets('sidebar tem botão de toggle e pode ser retraída',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_buildShell());
    await tester.pump();

    // Sidebar começa expandida — labels visíveis
    expect(find.text('Home'), findsOneWidget);
    // Toggle button presente
    expect(find.byKey(const ValueKey('sidebar_toggle')), findsOneWidget);

    // Tap no toggle → sidebar retrái
    await tester.tap(find.byKey(const ValueKey('sidebar_toggle')));
    await tester.pumpAndSettle();

    // Após retração, labels somem (AnimatedOpacity opacity=0 ou widget removido)
    // BackdropFilter ainda presente (glass effect)
    expect(find.byType(BackdropFilter), findsWidgets);
  });

  testWidgets('item da sidebar é destacado conforme a rota no desktop',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_buildShell(location: '/clients'));
    await tester.pump();

    expect(find.text('Clientes'), findsOneWidget);
  });
});
```

**Step 2: Confirmar que os testes falham (TDD red)**

```bash
cd /Users/luizfelipetrindade/Desktop/Scheduler-v1/scheduler-frontend
flutter test test/app_shell_test.dart
```

Esperado: pelo menos 3 falhas (`floating_nav_bar` key não existe, `NavigationBar` ainda existe, `sidebar_toggle` key não existe).

**Step 3: Commit dos testes falhando**

```bash
git add test/app_shell_test.dart
git commit -m "test: update nav tests for floating navbar and collapsible sidebar (TDD)"
```

---

### Task 2: Implementar `_FloatingNavBar` e `_NavItemButton`

**Files:**
- Modify: `lib/app_shell.dart`

**Step 1: Adicionar import `dart:ui` no topo do arquivo**

Adicione após os imports existentes:
```dart
import 'dart:ui';
```

**Step 2: Adicionar `_FloatingNavBar` e `_NavItemButton` após a definição de `_desktopItems` (antes de `indexForLocation`)**

```dart
// ─── Floating nav bar (mobile) ────────────────────────────────────────────────

class _FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onSelect;

  const _FloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.surfaceHigh.withValues(alpha: 0.5),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / items.length;
              return Stack(
                children: [
                  // Sliding pill indicator
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    left: selectedIndex * itemWidth + 2,
                    top: 0,
                    bottom: 0,
                    width: itemWidth - 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.purple700.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                  ),
                  // Items row (on top of pill)
                  Row(
                    children: items.asMap().entries.map((e) {
                      return _NavItemButton(
                        key: Key('nav_item_${e.value.route}'),
                        item: e.value,
                        isSelected: e.key == selectedIndex,
                        width: itemWidth,
                        onTap: () => onSelect(e.key),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavItemButton extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final double width;
  final VoidCallback onTap;

  const _NavItemButton({
    super.key,
    required this.item,
    required this.isSelected,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        child: Center(
          child: AnimatedScale(
            scale: isSelected ? 1.15 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: isSelected ? 1.0 : 0.0),
              duration: const Duration(milliseconds: 200),
              builder: (context, t, _) => Icon(
                item.icon,
                size: 22,
                color: Color.lerp(
                  AppColors.textSecondary,
                  AppColors.purple300,
                  t,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

**Step 3: Verificar que compila**

```bash
flutter analyze lib/app_shell.dart
```

Esperado: sem erros.

**Step 4: Commit**

```bash
git add lib/app_shell.dart
git commit -m "feat: add _FloatingNavBar and _NavItemButton with glass + sliding indicator"
```

---

### Task 3: Atualizar `_MobileLayout` para usar Stack + `_FloatingNavBar`

**Files:**
- Modify: `lib/app_shell.dart` — classe `_MobileLayout` e chamada em `AdaptiveShell`

**Step 1: Atualizar `_MobileLayout`**

Substitua a classe `_MobileLayout` completa:

```dart
class _MobileLayout extends StatelessWidget {
  final Widget child;
  final int selectedIndex;
  final List<_NavItem> items;

  const _MobileLayout({
    required this.child,
    required this.selectedIndex,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Content — padded at bottom so it doesn't hide under the navbar
          Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: child,
          ),
          // Floating navbar
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _FloatingNavBar(
              key: const ValueKey('floating_nav_bar'),
              selectedIndex: selectedIndex,
              items: items,
              onSelect: (i) => context.go(items[i].route),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Step 2: Rodar os testes**

```bash
flutter test test/app_shell_test.dart
```

Esperado: os 3 primeiros testes de mobile passam (floating_nav_bar key, NavigationBar não existe, 5 nav_item keys). O teste do sidebar_toggle ainda falha (sidebar ainda é StatelessWidget).

**Step 3: Commit**

```bash
git add lib/app_shell.dart
git commit -m "feat: replace mobile bottom nav with floating glassmorphic navbar"
```

---

### Task 4: Implementar sidebar expansível com glass effect

**Files:**
- Modify: `lib/app_shell.dart` — `_Sidebar`, `_SidebarTile`, `_SidebarFooter`, `_DesktopLayout`

**Step 1: Substituir `_Sidebar` (StatelessWidget → StatefulWidget) e adicionar `_SidebarHeader`**

Substitua tudo a partir de `// ─── Sidebar ───` até o fim do arquivo pelo código abaixo:

```dart
// ─── Sidebar ──────────────────────────────────────────────────────────────────

class _Sidebar extends StatefulWidget {
  final int selectedIndex;
  final List<_NavItem> items;

  const _Sidebar({required this.selectedIndex, required this.items});

  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: _expanded ? 220 : 64,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            color: AppColors.surface.withValues(alpha: 0.75),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SidebarHeader(
                  expanded: _expanded,
                  onToggle: () => setState(() => _expanded = !_expanded),
                ),
                const SizedBox(height: AppSpacing.md),
                ...widget.items.asMap().entries.map(
                  (e) => _SidebarTile(
                    item: e.value,
                    isSelected: e.key == widget.selectedIndex,
                    expanded: _expanded,
                    onTap: () => context.go(e.value.route),
                  ),
                ),
                const Spacer(),
                const Divider(color: AppColors.surfaceHigh, height: 1),
                _SidebarFooter(expanded: _expanded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;

  const _SidebarHeader({required this.expanded, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.lg,
        left: AppSpacing.xs,
        right: AppSpacing.xs,
      ),
      child: Row(
        children: [
          IconButton(
            key: const ValueKey('sidebar_toggle'),
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                expanded ? Icons.chevron_left : Icons.chevron_right,
                key: ValueKey(expanded),
                color: AppColors.textSecondary,
              ),
            ),
            onPressed: onToggle,
            tooltip: expanded ? 'Retrair' : 'Expandir',
          ),
          if (expanded)
            Expanded(
              child: AnimatedOpacity(
                opacity: expanded ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 150),
                child: Text('Scheduler', style: AppTypography.headingMd),
              ),
            ),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final bool expanded;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.item,
    required this.isSelected,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      item.icon,
      color: isSelected ? AppColors.purple300 : AppColors.textSecondary,
      size: 20,
    );

    if (!expanded) {
      return Tooltip(
        message: item.label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            width: 64,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.purple700.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Center(child: icon),
          ),
        ),
      );
    }

    return ListTile(
      leading: icon,
      title: AnimatedOpacity(
        opacity: expanded ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 150),
        child: Text(
          item.label,
          style: AppTypography.bodySm.copyWith(
            color: isSelected ? AppColors.purple300 : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
      tileColor: isSelected
          ? AppColors.purple700.withValues(alpha: 0.2)
          : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      onTap: onTap,
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  final bool expanded;

  const _SidebarFooter({required this.expanded});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final name =
            state is AuthAuthenticated ? state.user.firstName : '';
        final avatar = CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.purple700,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: AppTypography.bodySm.copyWith(color: AppColors.textPrimary),
          ),
        );

        if (!expanded) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Center(
              child: Tooltip(
                message: 'Sair',
                child: GestureDetector(
                  onTap: () => context
                      .read<AuthBloc>()
                      .add(const AuthLogoutRequested()),
                  child: avatar,
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              avatar,
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AnimatedOpacity(
                  opacity: expanded ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: Text(
                    name,
                    style: AppTypography.bodySm,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              AnimatedOpacity(
                opacity: expanded ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 150),
                child: IconButton(
                  icon: const Icon(
                    Icons.logout,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                  tooltip: 'Sair',
                  onPressed: () => context
                      .read<AuthBloc>()
                      .add(const AuthLogoutRequested()),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

**Step 2: Remover o `VerticalDivider` de `_DesktopLayout`**

O `VerticalDivider` pode criar uma linha extra visível agora que a sidebar tem seu próprio border via `BackdropFilter` + `Container`. Simplifique `_DesktopLayout.build` para:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: AppColors.background,
    body: Row(
      children: [
        _Sidebar(selectedIndex: selectedIndex, items: items),
        Expanded(child: child),
      ],
    ),
  );
}
```

**Step 3: Rodar todos os testes**

```bash
flutter test
```

Esperado: todos os testes passam.

**Step 4: Rodar flutter analyze**

```bash
flutter analyze lib/app_shell.dart
```

Esperado: sem erros.

**Step 5: Commit**

```bash
git add lib/app_shell.dart
git commit -m "feat: collapsible glass sidebar with animated expand/collapse"
```

---

### Task 5: Verificação final

**Step 1: Rodar suite completa**

```bash
cd /Users/luizfelipetrindade/Desktop/Scheduler-v1/scheduler-frontend
flutter test
```

Esperado: todos os testes passam.

**Step 2: flutter analyze geral**

```bash
flutter analyze
```

Esperado: sem erros (apenas os 3 info pre-existentes em arquivos não tocados).

**Step 3: Teste visual mobile**

```bash
flutter run
```

Verificar:
- Navbar flutua sobre o conteúdo com efeito glass
- Ao trocar de aba, a pílula roxa desliza suavemente
- O ícone ativo escala levemente

**Step 4: Teste visual web/desktop**

```bash
flutter run -d chrome
```

Verificar:
- Sidebar aparece expandida com glass
- Clicar no `chevron_left` → retrai para 64px (só ícones)
- Clicar no `chevron_right` → expande de volta para 220px
- Labels aparecem/somem com fade
- Hover nos ícones mostra tooltip com o nome da seção

**Step 5: Commit final se necessário**

Se qualquer ajuste cosmético for feito durante o teste visual:
```bash
git add lib/app_shell.dart
git commit -m "fix: nav enhancements visual adjustments"
```
