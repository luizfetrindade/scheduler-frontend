import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scheduler_frontend/core/router/app_routes.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/home/presentation/widgets/empty_state_cta_card.dart';
import 'package:scheduler_frontend/features/services/bloc/services_bloc.dart';
import 'package:scheduler_frontend/features/services/bloc/services_state.dart';
import 'package:scheduler_frontend/features/services/data/service_model.dart';

class ServicesSummaryCard extends StatelessWidget {
  const ServicesSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ServicesBloc, ServicesState>(
      builder: (context, state) {
        final services = _extractServices(state);
        if (services.isEmpty) {
          return EmptyStateCtaCard(
            icon: Icons.category_outlined,
            title: 'Nenhum serviço cadastrado',
            subtitle: 'Adicione os serviços que você oferece',
            ctaLabel: 'Adicionar serviço',
            onTap: () => context.go(AppRoutes.services),
          );
        }
        return _ServicesList(services: services);
      },
    );
  }

  List<ServiceModel> _extractServices(ServicesState state) => switch (state) {
        ServicesLoaded(:final services) => services,
        ServicesActionInProgress(:final services) => services,
        ServicesError(:final services) => services,
        _ => const [],
      };
}

class _ServicesList extends StatelessWidget {
  final List<ServiceModel> services;

  const _ServicesList({required this.services});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final preview = services.take(4).toList();
    final overflow = services.length - 4;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BaseCard(
      color: isDark ? null : Colors.white,
      onTap: () => context.go(AppRoutes.services),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.category_outlined,
            label: 'Serviços',
            count: services.length,
          ),
          const SizedBox(height: AppSpacing.md),
          ...preview.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      s.name,
                      style: AppTypography.bodySm
                          .copyWith(color: colors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (s.price != null)
                    Text(
                      'R\$ ${s.price!.toStringAsFixed(0)}',
                      style: AppTypography.caption
                          .copyWith(color: colors.textSecondary),
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

class _CardHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;

  const _CardHeader({
    required this.icon,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Icon(icon, size: 16, color: colors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style:
              AppTypography.labelLarge.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(width: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          color: colors.surfaceHigh,
          child: Text(
            '$count',
            style: AppTypography.caption.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        Icon(Icons.chevron_right, size: 16, color: colors.outline),
      ],
    );
  }
}
