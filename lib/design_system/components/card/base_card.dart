import 'package:flutter/material.dart';
import 'package:scheduler_frontend/design_system/tokens/app_colors_extension.dart';
import 'package:scheduler_frontend/design_system/tokens/app_shadows.dart';
import 'package:scheduler_frontend/design_system/tokens/app_spacing.dart';

const double _kSplashAlpha = 0.1;

class BaseCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool elevated;
  final double padding;
  final Color? color;

  const BaseCard({
    super.key,
    required this.child,
    this.onTap,
    this.elevated = false,
    this.padding = AppSpacing.lg,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.zero;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = color ?? context.appColors.surface;
    return Material(
      color: bgColor,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        splashColor: context.appColors.primaryLight.withValues(alpha: _kSplashAlpha),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: borderRadius,
            border: Border.all(color: context.appColors.outline, width: 1),
            boxShadow: isDark ? null : AppShadows.cardLight,
          ),
          child: child,
        ),
      ),
    );
  }
}
