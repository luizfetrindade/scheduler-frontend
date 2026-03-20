import 'package:flutter/material.dart';
import 'package:scheduler_frontend/features/business/data/business_model.dart';

class NavItem {
  final String label;
  final IconData icon;
  final String route;
  const NavItem({required this.label, required this.icon, required this.route});
}

class AppPolicy {
  final bool isSoloMode;
  final bool isAdmin;
  final bool canManageTeam;
  final bool canManageServices;
  final bool canViewReports;
  final bool canViewOtherAppts;
  final List<NavItem> mobileNavItems;
  final List<NavItem> desktopNavItems;

  const AppPolicy._({
    required this.isSoloMode,
    required this.isAdmin,
    required this.canManageTeam,
    required this.canManageServices,
    required this.canViewReports,
    required this.canViewOtherAppts,
    required this.mobileNavItems,
    required this.desktopNavItems,
  });

  factory AppPolicy.from(StaffRole role, int maxStaff) {
    final isSolo = maxStaff <= 1;
    final isAdmin = role == StaffRole.owner || role == StaffRole.manager;
    final canTeam = isAdmin && !isSolo;

    final mobileItems = _buildMobileNav(
      isSolo: isSolo,
      isAdmin: isAdmin,
      canTeam: canTeam,
    );
    final desktopItems = _buildDesktopNav(
      isSolo: isSolo,
      isAdmin: isAdmin,
      canTeam: canTeam,
    );

    return AppPolicy._(
      isSoloMode: isSolo,
      isAdmin: isAdmin,
      canManageTeam: canTeam,
      canManageServices: isAdmin,
      canViewReports: isAdmin,
      canViewOtherAppts: isAdmin && !isSolo,
      mobileNavItems: mobileItems,
      desktopNavItems: desktopItems,
    );
  }

  static List<NavItem> _buildMobileNav({
    required bool isSolo,
    required bool isAdmin,
    required bool canTeam,
  }) {
    return [
      const NavItem(label: 'Início', icon: Icons.home_outlined, route: '/home'),
      const NavItem(
        label: 'Agenda',
        icon: Icons.calendar_today_outlined,
        route: '/appointments',
      ),
      if (!isAdmin || isSolo)
        const NavItem(
          label: 'Clientes',
          icon: Icons.people_outline,
          route: '/clients',
        ),
      if (canTeam)
        const NavItem(
          label: 'Equipe',
          icon: Icons.group_outlined,
          route: '/professionals',
        ),
      if (isAdmin)
        const NavItem(
          label: 'Serviços',
          icon: Icons.cut_outlined,
          route: '/services',
        ),
      if (!isAdmin)
        const NavItem(
          label: 'Conta',
          icon: Icons.person_outline,
          route: '/account',
        ),
      if (isAdmin)
        const NavItem(
          label: 'Config.',
          icon: Icons.settings_outlined,
          route: '/settings',
        ),
    ];
  }

  static List<NavItem> _buildDesktopNav({
    required bool isSolo,
    required bool isAdmin,
    required bool canTeam,
  }) {
    return [
      ..._buildMobileNav(isSolo: isSolo, isAdmin: isAdmin, canTeam: canTeam),
      if (isAdmin)
        const NavItem(
          label: 'Relatórios',
          icon: Icons.bar_chart_outlined,
          route: '/reports',
        ),
    ];
  }
}
