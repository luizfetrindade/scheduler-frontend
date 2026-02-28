import 'package:flutter/material.dart';
import 'package:scheduler_frontend/design_system/components/button/base_button_variant.dart';
import 'package:scheduler_frontend/design_system/tokens/app_colors.dart';
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

  Color get _backgroundColor => switch (variant) {
        BaseButtonVariant.primary     => AppColors.purple500,
        BaseButtonVariant.secondary   => Colors.transparent,
        BaseButtonVariant.ghost       => Colors.transparent,
        BaseButtonVariant.destructive => AppColors.error,
      };

  Color get _foregroundColor => switch (variant) {
        BaseButtonVariant.primary     => AppColors.textPrimary,
        BaseButtonVariant.secondary   => AppColors.purple500,
        BaseButtonVariant.ghost       => AppColors.purple500,
        BaseButtonVariant.destructive => AppColors.textPrimary,
      };

  Border? get _border => variant == BaseButtonVariant.secondary
      ? Border.all(color: AppColors.purple500, width: 1.5)
      : null;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: Material(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: _isInteractive ? onPressed : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
          splashColor: AppColors.purple300.withValues(alpha: 0.2),
          child: Container(
            height: AppSpacing.xxxl,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              border: _border,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Center(
              child: isLoading ? _buildLoading() : _buildContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() => SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(_foregroundColor),
        ),
      );

  Widget _buildContent() {
    final label = Text(
      this.label,
      style: AppTypography.bodyMd.copyWith(color: _foregroundColor),
    );

    if (prefixIcon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(prefixIcon, color: _foregroundColor, size: _kPrefixIconSize),
          const SizedBox(width: AppSpacing.sm),
          label,
        ],
      );
    }

    return label;
  }
}
