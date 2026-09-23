import 'package:flutter/foundation.dart';
import '../config/app_security_config.dart';
import '../contracts/i_security_service.dart';
import '../contracts/i_storage_service.dart';
import 'security_check_result.dart';

class SecurityService implements ISecurityService {
  final IStorageService _storageService;
  bool _isMockProtectionEnabled = AppSecurityConfig.defaultMockProtection;
  bool _isInitialized = false;

  SecurityService(this._storageService);

  @override
  bool get isMockProtectionEnabled => _isMockProtectionEnabled;

  @override
  Future<void> init() async {
    if (_isInitialized) return;
    _isMockProtectionEnabled = AppSecurityConfig.defaultMockProtection;
    _isInitialized = true;
    debugPrint('[SecurityService] Initialized. Anti-Mock Protection: $_isMockProtectionEnabled');
  }

  @override
  Future<void> setMockProtectionEnabled(bool enabled) async {
    _isMockProtectionEnabled = enabled;
    await _storageService.setMockProtectionEnabled(enabled);
    debugPrint('[SecurityService] Anti-Mock Protection set to: $enabled');
  }

  @override
  SecurityCheckResult evaluateLocationSecurity({
    required bool isMocked,
    required double accuracy,
    required double latitude,
    required double longitude,
  }) {
    // 1. Si la proteccion esta desactivada por flag administrativo, permitir modo pruebas
    if (!_isMockProtectionEnabled) {
      return SecurityCheckResult(
        isSecure: true,
        isMocked: isMocked,
        violationType: SecurityViolationType.none,
        title: 'Modo Pruebas / Sandbox',
        message: 'Protección estricta desactivada para permitir validación en simulador.',
        evaluatedAt: DateTime.now(),
      );
    }

    // 2. Evaluacion estricta: verificar bandera nativa de mock location del sistema operativo
    if (isMocked) {
      return SecurityCheckResult.violation(
        violationType: SecurityViolationType.mockLocationDetected,
        title: 'Suplantación de GPS Detectada',
        message: 'Se ha detectado un proveedor de ubicación simulada (Mock Provider) o aplicación de Fake GPS activa en las opciones de desarrollador del sistema.',
        isMocked: true,
      );
    }

    // 3. Heuristica de telemetria: precision nula o valores anomalos de senal
    if (accuracy <= 0.0 || accuracy > 2000.0) {
      return SecurityCheckResult.violation(
        violationType: SecurityViolationType.suspiciousAccuracy,
        title: 'Telemetría GPS Inválida',
        message: 'La precisión del sensor reporta valores anómalos (${accuracy.toStringAsFixed(1)}m), indicando posible manipulación externa de la señal.',
        isMocked: false,
      );
    }

    // 4. Telemetria GPS valida y fisica
    return SecurityCheckResult.secure();
  }
}
