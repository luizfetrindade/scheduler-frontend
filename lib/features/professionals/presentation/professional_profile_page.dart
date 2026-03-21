import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/appointments/bloc/schedule_bloc.dart';
import 'package:scheduler_frontend/features/appointments/bloc/schedule_event.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_repository.dart';
import 'package:scheduler_frontend/features/appointments/presentation/appointments_page.dart';
import 'package:scheduler_frontend/features/business/bloc/business_bloc.dart';
import 'package:scheduler_frontend/features/business/bloc/business_state.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professionals_bloc.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professionals_event.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professionals_state.dart';
import 'package:scheduler_frontend/features/professionals/data/professional_model.dart';
import 'package:scheduler_frontend/features/professionals/presentation/widgets/professional_form_sheet.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_bloc.dart';

class ProfessionalProfilePage extends StatelessWidget {
  final String professionalId;

  const ProfessionalProfilePage({super.key, required this.professionalId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfessionalsBloc, ProfessionalsState>(
      builder: (context, state) {
        final professionals = switch (state) {
          ProfessionalsLoaded(:final professionals) => professionals,
          ProfessionalsActionInProgress(:final professionals) => professionals,
          ProfessionalsError(:final professionals) => professionals,
          _ => <ProfessionalModel>[],
        };

        final prof = professionals
            .where((p) => p.id == professionalId)
            .cast<ProfessionalModel?>()
            .firstOrNull;

        if (prof == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profissional')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: context.appColors.background,
            appBar: AppBar(
              backgroundColor: context.appColors.background,
              elevation: 0,
              title: Text(
                prof.name,
                style: AppTypography.headingMd
                    .copyWith(color: context.appColors.textPrimary),
              ),
              bottom: TabBar(
                labelColor: context.appColors.primary,
                unselectedLabelColor: context.appColors.textSecondary,
                indicatorColor: context.appColors.primary,
                tabs: const [
                  Tab(text: 'Perfil'),
                  Tab(text: 'Agenda'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _ProfileTab(professional: prof),
                _AgendaTab(professionalId: professionalId),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Perfil tab
// ---------------------------------------------------------------------------

class _ProfileTab extends StatelessWidget {
  final ProfessionalModel professional;

  const _ProfileTab({required this.professional});

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(professional.color);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      professional.name,
                      style: AppTypography.headingMd
                          .copyWith(color: context.appColors.textPrimary),
                    ),
                    if (professional.roleName != null)
                      Text(
                        professional.roleName!,
                        style: AppTypography.bodySm.copyWith(
                          color: context.appColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: context.appColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  professional.isActive ? 'Ativo' : 'Inativo',
                  style: AppTypography.caption.copyWith(
                    color: context.appColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (professional.phone != null) ...[
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Telefone',
              value: professional.phone!,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (professional.bio != null) ...[
            _InfoRow(
              icon: Icons.info_outline,
              label: 'Bio',
              value: professional.bio!,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          const SizedBox(height: AppSpacing.lg),
          BlocBuilder<BusinessBloc, BusinessState>(
            builder: (context, bizState) {
              final canManage =
                  bizState is BusinessLoaded && bizState.policy.canManageTeam;
              if (!canManage) return const SizedBox.shrink();
              return Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openEditForm(context),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Editar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.appColors.primary,
                        side: BorderSide(color: context.appColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _toggleActive(context),
                      icon: Icon(professional.isActive
                          ? Icons.person_off_outlined
                          : Icons.person_outlined),
                      label: Text(
                        professional.isActive ? 'Desativar' : 'Ativar',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: professional.isActive
                            ? AppColors.error
                            : context.appColors.primary,
                        side: BorderSide(
                          color: professional.isActive
                              ? AppColors.error
                              : context.appColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _openEditForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<ProfessionalsBloc>()),
          BlocProvider.value(value: context.read<ProfessionalRolesBloc>()),
          BlocProvider.value(value: context.read<BusinessBloc>()),
        ],
        child: ProfessionalFormSheet(professional: professional),
      ),
    );
  }

  void _toggleActive(BuildContext context) {
    final bizState = context.read<BusinessBloc>().state;
    if (bizState is! BusinessLoaded) return;
    context.read<ProfessionalsBloc>().add(ProfessionalsUpdateRequested(
          businessId: bizState.active.id,
          professionalId: professional.id,
          isActive: !professional.isActive,
        ));
  }

  Color _parseColor(String hex) {
    try {
      final cleaned = hex.replaceAll('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return const Color(0xFF4A90E2); // default blue
    }
  }
}

// ---------------------------------------------------------------------------
// Agenda tab — locally-scoped ScheduleBloc pre-filtered by professional
// ---------------------------------------------------------------------------

class _AgendaTab extends StatefulWidget {
  final String professionalId;
  const _AgendaTab({required this.professionalId});

  @override
  State<_AgendaTab> createState() => _AgendaTabState();
}

class _AgendaTabState extends State<_AgendaTab> {
  late ScheduleBloc _scheduleBloc;

  @override
  void initState() {
    super.initState();
    final repo = context.read<AppointmentRepository>();
    _scheduleBloc = ScheduleBloc(repo);

    final bizState = context.read<BusinessBloc>().state;
    if (bizState is BusinessLoaded) {
      _scheduleBloc.add(ScheduleInitialized(
        slug: bizState.active.slug,
        date: DateTime.now(),
      ));
      _scheduleBloc
          .add(ScheduleFilterByProfessional(widget.professionalId));
    }
  }

  @override
  void dispose() {
    _scheduleBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _scheduleBloc,
      child: const AppointmentsBody(),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: context.appColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.caption
                    .copyWith(color: context.appColors.textSecondary),
              ),
              Text(
                value,
                style: AppTypography.bodySm
                    .copyWith(color: context.appColors.textPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
