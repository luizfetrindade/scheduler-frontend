import 'package:flutter/material.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/reports/data/reports_model.dart';

class AtRiskClientsList extends StatelessWidget {
  final List<AtRiskClient> clients;
  const AtRiskClientsList({super.key, required this.clients});

  @override
  Widget build(BuildContext context) {
    if (clients.isEmpty) return const SizedBox.shrink();
    final colors = context.appColors;
    final preview = clients.take(3).toList();
    final hasMore = clients.length > preview.length;

    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Clientes para reativar',
                style: AppTypography.bodyMd.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                color: AppColors.error,
                child: Text(
                  '${clients.length}',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...preview.asMap().entries.map((entry) {
            final i = entry.key;
            final c = entry.value;
            final isLast = i == preview.length - 1 && !hasMore;
            final isCritical = c.daysSinceLastVisit > 90;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(
                        bottom: BorderSide(color: colors.outline, width: 1),
                      ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.name,
                          style: AppTypography.bodySm.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (c.lastServiceName != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Último: ${c.lastServiceName}',
                            style: AppTypography.caption.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    '${c.daysSinceLastVisit} dias',
                    style: AppTypography.bodySm.copyWith(
                      color: isCritical
                          ? AppColors.error
                          : const Color(0xFFFBBF24),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (hasMore) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '+ ${clients.length - preview.length} outros clientes inativos',
              style: AppTypography.caption.copyWith(
                color: colors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
