import 'package:flutter/material.dart';

/// Tokens de color semanticos que cambian entre modo claro y oscuro.
///
/// Uso: `context.palette.textPrimary`. Los colores de estado (exito, alerta,
/// error) tambien tienen variante oscura para mantener el contraste.
@immutable
class AsisPalette extends ThemeExtension<AsisPalette> {
  /// Fondo de las pantallas.
  final Color background;

  /// Tarjetas, dialogos, hojas inferiores y barra de navegacion.
  final Color surface;

  /// Campos de texto y filas secundarias dentro de una tarjeta.
  final Color surfaceAlt;

  /// Contornos y divisores.
  final Color border;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  /// Color de marca para botones, seleccion e iconos activos.
  final Color primary;

  /// Fondo suave de elementos seleccionados.
  final Color primarySoft;

  /// Fondo de la cabecera (AppBar y cabecera del mapa).
  final Color header;

  final Color success;
  final Color warning;
  final Color danger;

  const AsisPalette({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.primary,
    required this.primarySoft,
    required this.header,
    required this.success,
    required this.warning,
    required this.danger,
  });

  static const light = AsisPalette(
    background: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF1F5F9),
    border: Color(0xFFE2E8F0),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF64748B),
    textMuted: Color(0xFF94A3B8),
    primary: Color(0xFF1E3A8A),
    primarySoft: Color(0xFFE3EAFB),
    header: Color(0xFF1E3A8A),
    success: Color(0xFF047857),
    warning: Color(0xFFB45309),
    danger: Color(0xFFDC2626),
  );

  static const dark = AsisPalette(
    background: Color(0xFF0B1120),
    surface: Color(0xFF151C2C),
    surfaceAlt: Color(0xFF1E2738),
    border: Color(0xFF2A3447),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFFA7B1C3),
    textMuted: Color(0xFF6E7A90),
    primary: Color(0xFF4A6CD4),
    primarySoft: Color(0xFF1D2A4D),
    header: Color(0xFF111A33),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
  );

  @override
  AsisPalette copyWith() => this;

  @override
  AsisPalette lerp(ThemeExtension<AsisPalette>? other, double t) {
    if (other is! AsisPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AsisPalette(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceAlt: l(surfaceAlt, other.surfaceAlt),
      border: l(border, other.border),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textMuted: l(textMuted, other.textMuted),
      primary: l(primary, other.primary),
      primarySoft: l(primarySoft, other.primarySoft),
      header: l(header, other.header),
      success: l(success, other.success),
      warning: l(warning, other.warning),
      danger: l(danger, other.danger),
    );
  }
}

extension AsisPaletteContext on BuildContext {
  AsisPalette get palette =>
      Theme.of(this).extension<AsisPalette>() ?? AsisPalette.light;
}
