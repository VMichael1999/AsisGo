import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AsisGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool isDark;
  final double blurAmount;
  final Color? customBackground;
  final Color? customBorderColor;
  final VoidCallback? onTap;

  const AsisGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 20,
    this.isDark = true,
    this.blurAmount = 16,
    this.customBackground,
    this.customBorderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = customBackground ??
        (isDark ? AppColors.darkGlassBackground : AppColors.lightGlassBackground);
    final borderColor = customBorderColor ??
        (isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder);

    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderColor, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }

    return content;
  }
}
