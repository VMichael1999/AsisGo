import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../contracts/i_storage_service.dart';

/// Servicio centralizado para la emisión de retroalimentación háptica táctil
/// (Taptic Engine en iOS / Vibración en Android) y señales sonoras de confirmación.
class HapticFeedbackService {
  final IStorageService? _storageService;
  bool _fallbackHaptic = true;
  bool _fallbackSound = true;

  static HapticFeedbackService? _shared;

  HapticFeedbackService([this._storageService]) {
    _shared = this;
  }

  /// Instancia compartida accesible globalmente
  static HapticFeedbackService get shared {
    return _shared ??= HapticFeedbackService();
  }

  /// Indica si el feedback háptico táctil está activado
  bool get isHapticEnabled {
    return _storageService?.isHapticEnabled() ?? _fallbackHaptic;
  }

  /// Indica si los sonidos de confirmación del sistema están activados
  bool get isSoundEnabled {
    return _storageService?.isSoundEnabled() ?? _fallbackSound;
  }

  /// Actualiza la preferencia de vibración táctil
  Future<void> setHapticEnabled(bool enabled) async {
    _fallbackHaptic = enabled;
    if (_storageService != null) {
      await _storageService.setHapticEnabled(enabled);
    }
  }

  /// Actualiza la preferencia de sonidos de confirmación
  Future<void> setSoundEnabled(bool enabled) async {
    _fallbackSound = enabled;
    if (_storageService != null) {
      await _storageService.setSoundEnabled(enabled);
    }
  }

  /// Feedback de confirmación exitosa de marcación (Impacto medio y click de sistema)
  Future<void> punchSuccess() async {
    try {
      if (isHapticEnabled) {
        await HapticFeedback.mediumImpact();
      }
      if (isSoundEnabled) {
        await SystemSound.play(SystemSoundType.click);
      }
      debugPrint('[HapticFeedbackService] Feedback de éxito emitido (háptico: $isHapticEnabled, sonido: $isSoundEnabled)');
    } catch (e) {
      debugPrint('[HapticFeedbackService] Error al emitir punchSuccess: $e');
    }
  }

  /// Feedback de alerta de seguridad, bloqueo por geocerca o suplantación GPS
  Future<void> securityAlert() async {
    try {
      if (isHapticEnabled) {
        await HapticFeedback.heavyImpact();
      }
      if (isSoundEnabled) {
        await SystemSound.play(SystemSoundType.alert);
      }
      debugPrint('[HapticFeedbackService] Feedback de alerta de seguridad emitido (háptico: $isHapticEnabled, sonido: $isSoundEnabled)');
    } catch (e) {
      debugPrint('[HapticFeedbackService] Error al emitir securityAlert: $e');
    }
  }

  /// Feedback táctil sutil de selección (cambio de pestañas, selección de sucursal, etc.)
  Future<void> selectionClick() async {
    try {
      if (isHapticEnabled) {
        await HapticFeedback.selectionClick();
      }
    } catch (e) {
      debugPrint('[HapticFeedbackService] Error al emitir selectionClick: $e');
    }
  }

  /// Impacto ligero para toques en botones secundarios o cambios de filtro
  Future<void> lightImpact() async {
    try {
      if (isHapticEnabled) {
        await HapticFeedback.lightImpact();
      }
    } catch (e) {
      debugPrint('[HapticFeedbackService] Error al emitir lightImpact: $e');
    }
  }

  /// Feedback de sincronización completada exitosamente de registros offline
  Future<void> syncCompleted() async {
    try {
      if (isHapticEnabled) {
        await HapticFeedback.mediumImpact();
      }
      if (isSoundEnabled) {
        await SystemSound.play(SystemSoundType.click);
      }
      debugPrint('[HapticFeedbackService] Feedback de sincronización completada');
    } catch (e) {
      debugPrint('[HapticFeedbackService] Error al emitir syncCompleted: $e');
    }
  }
}
