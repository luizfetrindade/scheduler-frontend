import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scheduler_frontend/core/router/app_routes.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/clients/bloc/clients_bloc.dart';
import 'package:scheduler_frontend/features/clients/bloc/clients_state.dart';
import 'package:scheduler_frontend/features/clients/data/client_model.dart';
import 'package:scheduler_frontend/features/home/presentation/widgets/empty_state_cta_card.dart';

class ClientsSummaryCard extends StatelessWidget {
  const ClientsSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientsBloc, ClientsState>(
      builder: (context, state) {
        final clients = _extractClients(state);
        if (clients.isEmpty) {
          return EmptyStateCtaCard(
            icon: Icons.people_outline,
            title: 'Nenhum cliente ainda',
            subtitle: 'Cadastre seus primeiros clientes',
            ctaLabel: 'Adicionar cliente',
            onTap: () => context.go(AppRoutes.clients),
          );
        }
        return _ClientsList(clients: clients);
      },
    );
  }

  List<ClientModel> _extractClients(ClientsState state) => switch (state) {
        ClientsLoaded(:final clients) => clients,
        ClientsActionInProgress(:final clients) => clients,
        ClientsError(:final clients) => clients,
        _ => const [],
      };
}

class _ClientsList extends StatelessWidget {
  final List<ClientModel> clients;

  const _ClientsList({required this.clients});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final preview = clients.take(4).toList();
    final overflow = clients.length - 4;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BaseCard(
      color: isDark ? null : Colors.white,
      onTap: () => context.go(AppRoutes.clients),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ClientCardHeader(count: clients.length),
          const SizedBox(height: AppSpacing.md),
          ...preview.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  _InitialAvatar(name: c.name),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      c.name,
                      style: AppTypography.bodySm
                          .copyWith(color: colors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (overflow > 0)
            Text(
              '+$overflow mais',
              style:
                  AppTypography.caption.copyWith(color: colors.textSecondary),
            ),
        ],
      ),
    );
  }
}

class _ClientCardHeader extends StatelessWidget {
  final int count;
  const _ClientCardHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Icon(Icons.people_outline, size: 16, color: colors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Text(
          'Clientes',
          style:
              AppTypography.labelLarge.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(width: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          color: AppColors.success.withValues(alpha: 0.12),
          child: Text(
            '$count',
            style: AppTypography.caption.copyWith(color: AppColors.success),
          ),
        ),
        const Spacer(),
        Icon(Icons.chevron_right, size: 16, color: colors.outline),
      ],
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  final String name;
  const _InitialAvatar({required this.name});

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: colors.accent.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          fontFamily: 'Lexend',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: colors.accent,
        ),
      ),
    );
  }
}
