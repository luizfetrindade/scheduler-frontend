import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:scheduler_frontend/design_system/tokens/app_colors.dart';
import 'package:scheduler_frontend/design_system/tokens/app_colors_extension.dart';
import 'package:scheduler_frontend/design_system/tokens/app_radius.dart';
import 'package:scheduler_frontend/design_system/tokens/app_typography.dart';

const double _kCellWidth = 48;
const double _kCellHeight = 56;
const double _kFocusedBorderWidth = 1.5;
const int _kOtpLength = 6;

/// A 6-cell OTP input field styled to match the design system.
/// Uses [BorderRadius.zero] and the system color tokens.
class OtpInputField extends StatelessWidget {
  final TextEditingController? controller;
  final void Function(String pin)? onCompleted;
  final bool hasError;
  final bool isDisabled;

  const OtpInputField({
    super.key,
    this.controller,
    this.onCompleted,
    this.hasError = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final defaultTheme = PinTheme(
      width: _kCellWidth,
      height: _kCellHeight,
      textStyle: AppTypography.headingMd.copyWith(
        color: context.appColors.textPrimary,
      ),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        border: Border.all(
          color: hasError ? AppColors.error : context.appColors.outline,
        ),
        borderRadius: BorderRadius.zero,
      ),
    );

    final focusedTheme = defaultTheme.copyWith(
      decoration: BoxDecoration(
        color: context.appColors.surface,
        border: Border.all(
          color: hasError ? AppColors.error : context.appColors.primary,
          width: _kFocusedBorderWidth,
        ),
        borderRadius: BorderRadius.zero,
      ),
    );

    final errorTheme = defaultTheme.copyWith(
      decoration: BoxDecoration(
        color: context.appColors.surface,
        border: Border.all(color: AppColors.error),
        borderRadius: BorderRadius.zero,
      ),
    );

    return Pinput(
      length: _kOtpLength,
      controller: controller,
      enabled: !isDisabled,
      defaultPinTheme: defaultTheme,
      focusedPinTheme: focusedTheme,
      errorPinTheme: errorTheme,
      forceErrorState: hasError,
      keyboardType: TextInputType.number,
      onCompleted: onCompleted,
      hapticFeedbackType: HapticFeedbackType.lightImpact,
    );
  }
}
