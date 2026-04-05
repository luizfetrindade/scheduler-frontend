import 'package:flutter/material.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/services/data/service_model.dart';

class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleActive;
  final VoidCallback? onDelete;
  final bool showDivider;

  const ServiceCard({
    super.key,
    required this.service,
    this.onEdit,
    this.onToggleActive,
    this.onDelete,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: service.isActive ? 1.0 : 0.5,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: showDivider
                ? BorderSide(color: context.appColors.outline)
                : BorderSide.none,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Name + metadata ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          service.name,
                          style: AppTypography.labelLarge.copyWith(
                            color: context.appColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!service.isActive) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          color: context.appColors.surfaceHigh,
                          child: Text(
                            'Inativo',
                            style: AppTypography.caption.copyWith(
                              color: context.appColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  _buildSubtitle(context),
                ],
              ),
            ),

            // ── Actions ──
            IconButton(
              icon: Icon(
                Icons.edit_outlined,
                size: 17,
                color: context.appColors.textSecondary,
              ),
              onPressed: onEdit,
              tooltip: 'Editar',
              visualDensity: VisualDensity.compact,
            ),
            if (onToggleActive != null || onDelete != null)
              PopupMenuButton<_ServiceAction>(
                icon: Icon(
                  Icons.more_vert,
                  size: 17,
                  color: context.appColors.textSecondary,
                ),
                color: context.appColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  side: BorderSide(color: context.appColors.outline),
                ),
                onSelected: (action) {
                  if (action == _ServiceAction.toggleActive) {
                    onToggleActive?.call();
                  }
                  if (action == _ServiceAction.delete) onDelete?.call();
                },
                itemBuilder: (_) => [
                  if (onToggleActive != null)
                    PopupMenuItem(
                      value: _ServiceAction.toggleActive,
                      child: Text(
                        service.isActive ? 'Desativar' : 'Reativar',
                        style: AppTypography.bodySm.copyWith(
                          color: context.appColors.textPrimary,
                        ),
                      ),
                    ),
                  if (onDelete != null)
                    PopupMenuItem(
                      value: _ServiceAction.delete,
                      child: Text(
                        'Excluir',
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    final parts = <String>[];
    if (service.price != null) {
      parts.add(
          'R\$ ${service.price!.toStringAsFixed(2).replaceAll('.', ',')}');
    }
    if (service.durationMinutes != null) {
      parts.add(_formatDuration(service.durationMinutes!));
    }
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      parts.join(' · '),
      style: AppTypography.caption
          .copyWith(color: context.appColors.textSecondary),
    );
  }

  static String _formatDuration(int min) {
    if (min < 60) return '${min}min';
    if (min % 60 == 0) return '${min ~/ 60}h';
    return '${min ~/ 60}h ${min % 60}min';
  }
}

enum _ServiceAction { toggleActive, delete }
