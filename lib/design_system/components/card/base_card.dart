import 'package:flutter/material.dart';
import 'package:scheduler_frontend/design_system/tokens/app_colors.dart';
import 'package:scheduler_frontend/design_system/tokens/app_radius.dart';
import 'package:scheduler_frontend/design_system/tokens/app_shadows.dart';
import 'package:scheduler_frontend/design_system/tokens/app_spacing.dart';

const double _kSplashAlpha = 0.1;

class BaseCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool elevated;
  final double padding;

  const BaseCard({
    super.key,
    required this.child,
    this.onTap,
    this.elevated = false,
    this.padding = AppSpacing.lg,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(AppRadius.lg);
    return Material(
      color: AppColors.surface,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        splashColor: AppColors.purple300.withValues(alpha: _kSplashAlpha),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            boxShadow: elevated ? AppShadows.card : null,
          ),
          child: child,
        ),
      ),
    );
  }
}
