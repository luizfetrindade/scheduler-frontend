import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scheduler_frontend/core/auth/auth_bloc.dart';
import 'package:scheduler_frontend/core/auth/auth_event.dart';
import 'package:scheduler_frontend/core/auth/auth_state.dart';
import 'package:scheduler_frontend/core/router/app_routes.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';

// ─── Nav item descriptor ─────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  const _NavItem({required this.icon, required this.label, required this.route});
}

const _mobileItems = [
  _NavItem(icon: Icons.home_outlined,          label: 'Home',          route: AppRoutes.home),
  _NavItem(icon: Icons.calendar_month_outlined, label: 'Agendamentos',  route: AppRoutes.appointments),
  _NavItem(icon: Icons.people_outline,          label: 'Clientes',      route: AppRoutes.clients),
  _NavItem(icon: Icons.content_cut,             label: 'Serviços',      route: AppRoutes.services),
  _NavItem(icon: Icons.settings_outlined,       label: 'Configurações', route: AppRoutes.settings),
];

const _desktopItems = [
  _NavItem(icon: Icons.home_outlined,          label: 'Home',          route: AppRoutes.home),
  _NavItem(icon: Icons.calendar_month_outlined, label: 'Agendamentos',  route: AppRoutes.appointments),
  _NavItem(icon: Icons.people_outline,          label: 'Clientes',      route: AppRoutes.clients),
  _NavItem(icon: Icons.content_cut,             label: 'Serviços',      route: AppRoutes.services),
  _NavItem(icon: Icons.bar_chart,               label: 'Relatórios',    route: AppRoutes.reports),
  _NavItem(icon: Icons.settings_outlined,       label: 'Configurações', route: AppRoutes.settings),
];

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
            border: Border.all(
              color: AppColors.surfaceHigh.withValues(alpha: 0.5),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth == 0 || items.isEmpty) {
                return const SizedBox.shrink();
              }
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
              key: ValueKey(isSelected),
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 200),
              builder: (context, t, _) => Icon(
                item.icon,
                size: 22,
                color: Color.lerp(
                  isSelected ? AppColors.textSecondary : AppColors.purple300,
                  isSelected ? AppColors.purple300 : AppColors.textSecondary,
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

// ─── Helper exported for tests ────────────────────────────────────────────────

/// Returns the nav index that matches [location].
/// Pass [isMobile] to select the correct item list.
/// Falls back to 0 if no match is found.
int indexForLocation(String location, {required bool isMobile}) {
  final items = isMobile ? _mobileItems : _desktopItems;
  final i = items.indexWhere(
    (item) => location == item.route || location.startsWith('${item.route}/'),
  );
  return i < 0 ? 0 : i;
}

// ─── AdaptiveShell ────────────────────────────────────────────────────────────

class AdaptiveShell extends StatelessWidget {
  final Widget child;
  final String currentLocation;

  const AdaptiveShell({
    super.key,
    required this.child,
    required this.currentLocation,
  });

  static const _kBreakpoint = 720.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < _kBreakpoint;
        final index = indexForLocation(currentLocation, isMobile: isMobile);

        if (isMobile) {
          return _MobileLayout(
            selectedIndex: index,
            items: _mobileItems,
            child: child,
          );
        }

        return _DesktopLayout(
          selectedIndex: index,
          items: _desktopItems,
          child: child,
        );
      },
    );
  }
}

// ─── Mobile layout ────────────────────────────────────────────────────────────

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

// ─── Desktop layout ───────────────────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  final Widget child;
  final int selectedIndex;
  final List<_NavItem> items;

  const _DesktopLayout({
    required this.child,
    required this.selectedIndex,
    required this.items,
  });

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
}

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
    // Single widget tree always in the tree — title cross-fades via
    // AnimatedSwitcher so the content animates smoothly during the sidebar
    // width transition. After pumpAndSettle the Text is removed from the tree
    // when collapsed, keeping find.text assertions reliable in tests.
    return Tooltip(
      message: expanded ? '' : item.label,
      child: ListTile(
        leading: Icon(
          item.icon,
          color: isSelected ? AppColors.purple300 : AppColors.textSecondary,
          size: 20,
        ),
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: expanded
              ? Text(
                  item.label,
                  key: const ValueKey('label'),
                  style: AppTypography.bodySm.copyWith(
                    color: isSelected
                        ? AppColors.purple300
                        : AppColors.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('empty')),
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
      ),
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
