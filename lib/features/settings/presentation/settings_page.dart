import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scheduler_frontend/core/auth/auth_bloc.dart';
import 'package:scheduler_frontend/core/auth/auth_event.dart';
import 'package:scheduler_frontend/core/auth/auth_state.dart';
import 'package:scheduler_frontend/core/config/schedule_preferences.dart';
import 'package:scheduler_frontend/core/router/app_routes.dart';
import 'package:scheduler_frontend/core/theme/theme_cubit.dart';
import 'package:scheduler_frontend/core/theme/theme_state.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/business/bloc/business_bloc.dart';
import 'package:scheduler_frontend/features/business/bloc/business_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _dragEnabled = true;
  bool _attendancePromptEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final drag = await SchedulePreferences.isDragEnabled();
    final prompt = await SchedulePreferences.isAttendancePromptEnabled();
    if (mounted) {
      setState(() {
        _dragEnabled = drag;
        _attendancePromptEnabled = prompt;
      });
    }
  }

  Future<void> _toggleDrag(bool value) async {
    setState(() => _dragEnabled = value);
    await SchedulePreferences.setDragEnabled(value);
  }

  Future<void> _toggleAttendancePrompt(bool value) async {
    setState(() => _attendancePromptEnabled = value);
    await SchedulePreferences.setAttendancePromptEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
              child: Text(
                'Configurações',
                style: AppTypography.headingMd.copyWith(
                  color: context.appColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: [
                  // ── Conta ──────────────────────────────────────────────
                  _SectionLabel(label: 'Conta'),
                  const SizedBox(height: AppSpacing.sm),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final name =
                          state is AuthAuthenticated ? state.user.name : '';
                      final email =
                          state is AuthAuthenticated ? state.user.email : '';
                      return _SettingsTile(
                        icon: Icons.person_outline,
                        title: name.isNotEmpty ? name : 'Meus dados',
                        subtitle: email.isNotEmpty ? email : null,
                        trailing: Icon(Icons.chevron_right,
                            color: context.appColors.textSecondary),
                        onTap: () => context.push(AppRoutes.profile),
                      );
                    },
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Aparência ──────────────────────────────────────────
                  _SectionLabel(label: 'Aparência'),
                  const SizedBox(height: AppSpacing.sm),
                  BlocBuilder<ThemeCubit, ThemeState>(
                    builder: (context, state) {
                      final isLight = state.themeMode == ThemeMode.light;
                      return _SettingsTile(
                        icon: isLight ? Icons.light_mode : Icons.dark_mode,
                        title: 'Modo claro',
                        trailing: Switch(
                          value: isLight,
                          activeColor: context.appColors.primary,
                          onChanged: (_) =>
                              context.read<ThemeCubit>().toggle(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Agenda ─────────────────────────────────────────────
                  _SectionLabel(label: 'Agenda'),
                  const SizedBox(height: AppSpacing.sm),
                  _SettingsTile(
                    icon: Icons.drag_indicator,
                    title: 'Arrastar e soltar',
                    subtitle: 'Mover agendamentos segurando e arrastando',
                    trailing: Switch(
                      value: _dragEnabled,
                      activeColor: context.appColors.primary,
                      onChanged: _toggleDrag,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _SettingsTile(
                    icon: Icons.event_available,
                    title: 'Confirmar comparecimento',
                    subtitle:
                        'Perguntar o status do agendamento assim que ele terminar',
                    trailing: Switch(
                      value: _attendancePromptEnabled,
                      activeColor: context.appColors.primary,
                      onChanged: _toggleAttendancePrompt,
                    ),
                  ),

                  // ── Gerenciamento ──────────────────────────────────────
                  BlocBuilder<BusinessBloc, BusinessState>(
                    builder: (context, state) {
                      if (state is! BusinessLoaded ||
                          !state.policy.canManageTeam) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.xl),
                          _SectionLabel(label: 'Gerenciamento'),
                          const SizedBox(height: AppSpacing.sm),
                          _SettingsTile(
                            icon: Icons.work_outline,
                            title: 'Cargos',
                            trailing: Icon(Icons.chevron_right,
                                color: context.appColors.textSecondary),
                            onTap: () =>
                                context.push(AppRoutes.professionalRoles),
                          ),
                        ],
                      );
                    },
                  ),

                  // ── Sair (sempre por último) ───────────────────────────
                  const SizedBox(height: AppSpacing.xl),
                  _SectionLabel(label: 'Sessão'),
                  const SizedBox(height: AppSpacing.sm),
                  _SettingsTile(
                    icon: Icons.logout,
                    title: 'Sair',
                    trailing: Icon(Icons.chevron_right,
                        color: context.appColors.textSecondary),
                    onTap: () =>
                        context.read<AuthBloc>().add(const AuthLogoutRequested()),
                  ),

                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.labelLarge.copyWith(
        color: context.appColors.textSecondary,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(),
      leading: Icon(icon, color: context.appColors.primary),
      title: Text(
        title,
        style: AppTypography.bodySm
            .copyWith(color: context.appColors.textPrimary),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTypography.caption
                  .copyWith(color: context.appColors.textSecondary),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}
