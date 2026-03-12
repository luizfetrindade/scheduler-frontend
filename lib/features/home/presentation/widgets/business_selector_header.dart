import 'package:flutter/material.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/business/data/business_model.dart';

class BusinessSelectorHeader extends StatelessWidget {
  final BusinessModel active;
  final List<BusinessModel> businesses;
  final void Function(BusinessModel) onSelect;
  final String userName;

  const BusinessSelectorHeader({
    super.key,
    required this.active,
    required this.businesses,
    required this.onSelect,
    required this.userName,
  });

  void _openSelector(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ListView(
        shrinkWrap: true,
        children: businesses
            .map((b) => ListTile(
                  title: Text(b.name, style: AppTypography.bodyMd),
                  trailing: b.id == active.id
                      ? Icon(Icons.check, color: context.appColors.primary)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    if (b.id != active.id) onSelect(b);
                  },
                ))
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: businesses.length > 1 ? () => _openSelector(context) : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(active.name, style: AppTypography.headingMd),
              if (businesses.length > 1) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: context.appColors.textSecondary,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
        const Spacer(),
        CircleAvatar(
          radius: 18,
          backgroundColor: context.appColors.primaryDark,
          child: Text(
            userName.isNotEmpty ? userName[0].toUpperCase() : '?',
            style: AppTypography.bodyMd.copyWith(color: context.appColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
