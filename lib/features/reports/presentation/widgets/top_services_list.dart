import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/reports/data/reports_model.dart';

class TopServicesList extends StatelessWidget {
  final List<TopService> services;

  const TopServicesList({super.key, required this.services});

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) return const SizedBox.shrink();

    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final colors = context.appColors;

    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Serviços',
            style: AppTypography.bodyMd.copyWith(
                color: colors.textPrimary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.md),
          ...services.asMap().entries.map((entry) {
            final i = entry.key;
            final svc = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${i + 1}.',
                      style: AppTypography.bodySm
                          .copyWith(color: colors.textDisabled),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      svc.name,
                      style: AppTypography.bodySm
                          .copyWith(color: colors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${svc.count}x',
                    style: AppTypography.bodySm
                        .copyWith(color: colors.textSecondary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    currency.format(svc.revenue),
                    style: AppTypography.bodySm
                        .copyWith(color: AppColors.success),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
