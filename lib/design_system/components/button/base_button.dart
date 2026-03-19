import 'package:flutter/material.dart';
import 'package:scheduler_frontend/design_system/components/button/base_button_variant.dart';
import 'package:scheduler_frontend/design_system/tokens/app_colors.dart';
import 'package:scheduler_frontend/design_system/tokens/app_colors_extension.dart';
import 'package:scheduler_frontend/design_system/tokens/app_radius.dart';
import 'package:scheduler_frontend/design_system/tokens/app_spacing.dart';
import 'package:scheduler_frontend/design_system/tokens/app_typography.dart';

const double _kPrefixIconSize = 18;

class BaseButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final BaseButtonVariant variant;
  final bool isLoading;
  final bool isDisabled;
  final IconData? prefixIcon;

  const BaseButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = BaseButtonVariant.primary,
    this.isLoading = false,
    this.isDisabled = false,
    this.prefixIcon,
  });

  bool get _isInteractive => !isDisabled && !isLoading;

  Color _backgroundColor(BuildContext context) => switch (variant) {
        BaseButtonVariant.primary     => context.appColors.primary,
        BaseButtonVariant.secondary   => Colors.transparent,
        BaseButtonVariant.ghost       => Colors.transparent,
        BaseButtonVariant.destructive => AppColors.error,
      };

  Color _foregroundColor(BuildContext context) => switch (variant) {
        BaseButtonVariant.primary     => context.appColors.textPrimary,
        BaseButtonVariant.secondary   => context.appColors.primary,
        BaseButtonVariant.ghost       => context.appColors.primary,
        BaseButtonVariant.destructive => context.appColors.textPrimary,
      };

  Border? _border(BuildContext context) =>
      variant == BaseButtonVariant.secondary
          ? Border.all(color: context.appColors.primary, width: 1.5)
          : null;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(AppRadius.lg);
    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: Material(
        color: _backgroundColor(context),
        borderRadius: borderRadius,
        child: InkWell(
          onTap: _isInteractive ? onPressed : null,
          borderRadius: borderRadius,
          splashColor: context.appColors.primaryLight.withValues(alpha: 0.2),
          child: Container(
            height: AppSpacing.xxxl,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              border: _border(context),
              borderRadius: borderRadius,
            ),
            child: Center(
              child: isLoading
                  ? _buildLoading(context)
                  : _buildContent(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) => SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(_foregroundColor(context)),
        ),
      );

  Widget _buildContent(BuildContext context) {
    final labelWidget = Text(
      label,
      style: AppTypography.bodyMd.copyWith(color: _foregroundColor(context)),
    );

    if (prefixIcon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(prefixIcon, color: _foregroundColor(context), size: _kPrefixIconSize),
          const SizedBox(width: AppSpacing.sm),
          labelWidget,
        ],
      );
    }

    return labelWidget;
  }
}
