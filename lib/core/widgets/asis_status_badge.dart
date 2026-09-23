import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'asis_radar_indicator.dart';

enum AsisBadgeVariant {
  success,
  warning,
  danger,
  indigo,
  neutral,
}

class AsisStatusBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool showRadar;
  final AsisBadgeVariant variant;
  final Color? customColor;
  final EdgeInsetsGeometry padding;
  final double fontSize;

  const AsisStatusBadge({
    super.key,
    required this.label,
    this.icon,
    this.showRadar = false,
    this.variant = AsisBadgeVariant.neutral,
    this.customColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    this.fontSize = 11,
  });

  Color _resolveColor() {
    if (customColor != null) return customColor!;
    switch (variant) {
      case AsisBadgeVariant.success:
        return AppColors.accent;
      case AsisBadgeVariant.warning:
        return AppColors.lunchColor;
      case AsisBadgeVariant.danger:
        return AppColors.checkOutColor;
      case AsisBadgeVariant.indigo:
        return AppColors.indigoAccent;
      case AsisBadgeVariant.neutral:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _resolveColor();

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showRadar) ...[
            AsisRadarIndicator(color: color, size: 7),
            const SizedBox(width: 4),
          ] else if (icon != null) ...[
            Icon(icon, size: fontSize + 3, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
