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
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) => context.go(items[i].route),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.purple700,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: items
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon, color: AppColors.textSecondary),
                selectedIcon: Icon(item.icon, color: AppColors.textPrimary),
                label: item.label,
              ),
            )
            .toList(),
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
          const VerticalDivider(width: 1, thickness: 1, color: AppColors.surfaceHigh),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ─── Sidebar ──────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final List<_NavItem> items;

  const _Sidebar({required this.selectedIndex, required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: ColoredBox(
        color: AppColors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text('Scheduler', style: AppTypography.headingMd),
            ),
            const SizedBox(height: AppSpacing.xl),
            ...items.asMap().entries.map((e) => _SidebarTile(
                  item: e.value,
                  isSelected: e.key == selectedIndex,
                  onTap: () => context.go(e.value.route),
                )),
            const Spacer(),
            const Divider(color: AppColors.surfaceHigh, height: 1),
            const _SidebarFooter(),
          ],
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        item.icon,
        color: isSelected ? AppColors.purple300 : AppColors.textSecondary,
        size: 20,
      ),
      title: Text(
        item.label,
        style: AppTypography.bodySm.copyWith(
          color: isSelected ? AppColors.purple300 : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
  const _SidebarFooter();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final name =
            state is AuthAuthenticated ? state.user.firstName : '';
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.purple700,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: AppTypography.bodySm
                      .copyWith(color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  name,
                  style: AppTypography.bodySm,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout,
                    color: AppColors.textSecondary, size: 18),
                tooltip: 'Sair',
                onPressed: () =>
                    context.read<AuthBloc>().add(const AuthLogoutRequested()),
              ),
            ],
          ),
        );
      },
    );
  }
}
