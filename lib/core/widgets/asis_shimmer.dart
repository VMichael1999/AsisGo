import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Componente que aplica un efecto de brillo animado (shimmer) sobre sus hijos.
class AsisShimmer extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  const AsisShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<AsisShimmer> createState() => _AsisShimmerState();
}

class _AsisShimmerState extends State<AsisShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = widget.baseColor ??
        (isDark ? const Color(0xFF1A2436) : const Color(0xFFCBD5E1));
    final highlight = widget.highlightColor ??
        (isDark ? const Color(0xFF3E5173) : const Color(0xFFFFFFFF));

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final dx = progress * (bounds.width * 2) - bounds.width;
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                base,
                highlight,
                base,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(slidePercent: dx / bounds.width),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

/// Contenedor rectangular con esquinas redondeadas y contraste reforzado.
class AsisSkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Widget? child;
  final Color? color;
  final Border? border;

  const AsisSkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 12.0,
    this.margin,
    this.padding,
    this.child,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? (isDark ? const Color(0xFF182234) : const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ??
            Border.all(
              color: isDark ? const Color(0x334A628A) : const Color(0x1F000000),
              width: 1.0,
            ),
      ),
      child: child,
    );
  }
}

/// Contenedor circular para avatares o botones de esqueleto.
class AsisSkeletonCircle extends StatelessWidget {
  final double size;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Widget? child;

  const AsisSkeletonCircle({
    super.key,
    this.size = 48.0,
    this.margin,
    this.color,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? (isDark ? const Color(0xFF182234) : const Color(0xFFE2E8F0)),
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? const Color(0x334A628A) : const Color(0x1F000000),
          width: 1.0,
        ),
      ),
      child: child,
    );
  }
}

/// Contenedor de linea redondeada para representar textos en carga.
class AsisSkeletonLine extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const AsisSkeletonLine({
    super.key,
    this.width,
    this.height = 14.0,
    this.borderRadius = 6.0,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return AsisSkeletonBox(
      width: width,
      height: height,
      borderRadius: borderRadius,
      margin: margin,
    );
  }
}

/// Superposicion completa que muestra el esqueleto animado en el fondo
/// con alto contraste visual junto con la tarjeta de carga informativa.
class AsisLoadingOverlay extends StatelessWidget {
  final Widget skeleton;
  final String message;
  final bool showSpinner;

  const AsisLoadingOverlay({
    super.key,
    required this.skeleton,
    this.message = 'Cargando información...',
    this.showSpinner = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? AppColors.obsidianCanvas : AppColors.backgroundLight,
      child: Stack(
        children: [
          // 1. Esqueleto estructurado animado directamente sobre el canvas
          Positioned.fill(
            child: AsisShimmer(
              child: skeleton,
            ),
          ),

          // 2. Indicador de carga central con diseno pulido y bordes nitidos
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xEA101726)
                    : Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? const Color(0x444E6A9C) : AppColors.borderLight,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showSpinner) ...[
                    const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        color: AppColors.accent,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
