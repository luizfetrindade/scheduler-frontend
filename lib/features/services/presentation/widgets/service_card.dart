import 'package:flutter/material.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/services/data/service_model.dart';

class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  const ServiceCard({
    super.key,
    required this.service,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: service.isActive ? 1.0 : 0.5,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.surfaceHigh),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          service.name,
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!service.isActive) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceHigh,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            'Inativo',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  _buildSubtitle(),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              color: AppColors.textSecondary,
              onPressed: onEdit,
              tooltip: 'Editar',
            ),
            PopupMenuButton<_ServiceAction>(
              icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textSecondary),
              color: AppColors.surface,
              onSelected: (action) {
                if (action == _ServiceAction.toggleActive) onToggleActive();
                if (action == _ServiceAction.delete) onDelete();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: _ServiceAction.toggleActive,
                  child: Text(
                    service.isActive ? 'Desativar' : 'Reativar',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
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

  Widget _buildSubtitle() {
    final parts = <String>[];
    if (service.price != null) {
      parts.add('R\$ ${service.price!.toStringAsFixed(2).replaceAll('.', ',')}');
    }
    if (service.durationMinutes != null) {
      parts.add(_formatDuration(service.durationMinutes!));
    }
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      parts.join(' · '),
      style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
    );
  }

  static String _formatDuration(int min) {
    if (min < 60) return '${min}min';
    if (min % 60 == 0) return '${min ~/ 60}h';
    return '${min ~/ 60}h ${min % 60}min';
  }
}

enum _ServiceAction { toggleActive, delete }
