/// Configuración interna de seguridad y flags de compilación para AsisGo.
class AppSecurityConfig {
  /// Feature flag para la protección contra Mock / Fake GPS.
  ///
  /// En producción y despliegue corporativo siempre se mantiene en `true`.
  /// Para pruebas internas o entornos de desarrollo, puede anularse en tiempo de
  /// compilación mediante:
  /// `--dart-define=STRICT_MOCK_PROTECTION=false`
  static const bool defaultMockProtection = bool.fromEnvironment(
    'STRICT_MOCK_PROTECTION',
    defaultValue: true,
  );
}
