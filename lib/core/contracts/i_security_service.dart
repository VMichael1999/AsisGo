import '../security/security_check_result.dart';

abstract class ISecurityService {
  /// Indica si la proteccion estricta anti fake GPS esta activa (true en produccion, false para pruebas)
  bool get isMockProtectionEnabled;

  /// Establece el modo de proteccion y persiste la configuracion
  Future<void> setMockProtectionEnabled(bool enabled);

  /// Inicializa el servicio y carga configuraciones persistidas
  Future<void> init();

  /// Evalua la telemetria y retorna el dictamen de seguridad
  SecurityCheckResult evaluateLocationSecurity({
    required bool isMocked,
    required double accuracy,
    required double latitude,
    required double longitude,
  });
}
