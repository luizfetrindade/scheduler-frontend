import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scheduler_frontend/design_system/tokens/app_colors.dart';
import 'package:scheduler_frontend/design_system/tokens/app_colors_extension.dart';
import 'package:scheduler_frontend/design_system/tokens/app_radius.dart';
import 'package:scheduler_frontend/design_system/tokens/app_spacing.dart';
import 'package:scheduler_frontend/design_system/tokens/app_typography.dart';

const double _kIconSize = 20;
const double _kFocusedBorderWidth = 1.5;

class BaseInputField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? errorText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final bool isPassword;
  final bool isDisabled;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;

  const BaseInputField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.isPassword = false,
    this.isDisabled = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.onChanged,
  });

  @override
  State<BaseInputField> createState() => _BaseInputFieldState();
}

class _BaseInputFieldState extends State<BaseInputField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    const borderRadius = BorderRadius.zero;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: AppTypography.bodySm.copyWith(
            color: widget.isDisabled
                ? context.appColors.textDisabled
                : context.appColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: widget.controller,
          enabled: !widget.isDisabled,
          obscureText: widget.isPassword && _obscureText,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          onChanged: widget.onChanged,
          style: AppTypography.bodyMd.copyWith(color: context.appColors.textPrimary),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle:
                AppTypography.bodyMd.copyWith(color: context.appColors.textSecondary),
            filled: true,
            fillColor: widget.isDisabled
                ? context.appColors.surface.withValues(alpha: 0.5)
                : context.appColors.surface,
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon,
                    color: context.appColors.textSecondary, size: _kIconSize)
                : null,
            suffixIcon: _buildSuffixIcon(context),
            border: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(
                  color: hasError ? AppColors.error : context.appColors.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(
                  color: hasError ? AppColors.error : context.appColors.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(
                color: hasError ? AppColors.error : context.appColors.primary,
                width: _kFocusedBorderWidth,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(color: context.appColors.outline),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.errorText!,
            style: AppTypography.caption.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }

  Widget? _buildSuffixIcon(BuildContext context) {
    if (widget.isPassword) {
      return IconButton(
        icon: Icon(
          _obscureText
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: context.appColors.textSecondary,
          size: _kIconSize,
        ),
        onPressed: () => setState(() => _obscureText = !_obscureText),
      );
    }
    if (widget.suffixIcon != null) {
      return Icon(widget.suffixIcon, color: context.appColors.textSecondary, size: _kIconSize);
    }
    return null;
  }
}
