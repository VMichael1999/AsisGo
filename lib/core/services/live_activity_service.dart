import 'package:flutter/foundation.dart';
import 'package:live_activities/live_activities.dart';
import '../../features/attendance_map/domain/shift_phase.dart';

/// Servicio nativo para gestionar Live Activities y Dynamic Island en iOS (ActivityKit / WidgetKit)
class LiveActivityService {
  static final LiveActivityService _instance = LiveActivityService._internal();
  factory LiveActivityService() => _instance;
  LiveActivityService._internal();

  final LiveActivities _liveActivities = LiveActivities();
  bool _isInitialized = false;
  bool _isSupported = false;
  String? _currentActivityId;
  String? get currentActivityId => _currentActivityId;

  static const String appGroupId = 'group.com.asisgo.app.asisgo';
  static const String shiftActivityKey = 'asisgo_shift_tracker';

  /// Inicializa la conexión con ActivityKit
  Future<void> initialize() async {
    if (_isInitialized) return;

    if (defaultTargetPlatform != TargetPlatform.iOS) {
      debugPrint('[LiveActivityService] Live Activities solo está disponible en iOS.');
      return;
    }

    try {
      _isSupported = await _liveActivities.areActivitiesSupported();
      if (!_isSupported) {
        debugPrint('[LiveActivityService] Live Activities no soportado en este dispositivo/SO.');
        return;
      }

      await _liveActivities.init(appGroupId: appGroupId);
      _isInitialized = true;
      debugPrint('[LiveActivityService] Conexión nativa ActivityKit inicializada con éxito.');
    } catch (e) {
      debugPrint('[LiveActivityService] Error al inicializar ActivityKit: $e');
    }
  }

  DateTime? _lastKnownShiftStartTime;

  /// Sincroniza el estado del turno con la Dynamic Island y la pantalla de bloqueo nativa
  Future<void> syncShift({
    required ShiftPhase phase,
    required String branchName,
    DateTime? shiftStartTime,
    DateTime? lunchStartTime,
    bool isInsideGeozone = true,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    if (!_isInitialized) {
      await initialize();
      if (!_isInitialized) return;
    }

    // Si la jornada terminó o no ha iniciado, finalizamos la actividad en Dynamic Island
    if (phase == ShiftPhase.notStarted || phase == ShiftPhase.completed) {
      _lastKnownShiftStartTime = null;
      await endShiftActivity();
      return;
    }

    if (shiftStartTime != null) {
      _lastKnownShiftStartTime = shiftStartTime;
    }

    final bool isBreak = phase == ShiftPhase.onLunch;
    final String title = isBreak ? 'Refrigerio en Curso' : 'Jornada Activa';
    
    // Medir cronómetro continuo desde la hora de entrada original del turno
    final DateTime effectiveStartTime =
        (shiftStartTime ?? _lastKnownShiftStartTime) ?? DateTime.now();
    _lastKnownShiftStartTime ??= effectiveStartTime;

    final data = <String, dynamic>{
      'title': title,
      'subtitle': branchName,
      'companyName': _extractCompanyName(branchName),
      'checkInTimeStr': _formatTime(effectiveStartTime),
      'isBreak': isBreak,
      'isInsideGeozone': isInsideGeozone,
      'checkInEpoch': effectiveStartTime.millisecondsSinceEpoch.toDouble(),
    };

    try {
      await _liveActivities.endAllActivities();
      await Future.delayed(const Duration(milliseconds: 100));
      await _liveActivities.createActivity(
        shiftActivityKey,
        data,
        removeWhenAppIsKilled: false,
      );
      _currentActivityId = shiftActivityKey;
      debugPrint(
          '[LiveActivityService] Dynamic Island actualizada: $title ($branchName) | Geozona: ${isInsideGeozone ? "DENTRO" : "FUERA"}');
    } catch (e) {
      debugPrint('[LiveActivityService] Error al sincronizar Live Activity nativa: $e');
    }
  }

  /// Finaliza la Live Activity en curso en la Dynamic Island
  Future<void> endShiftActivity() async {
    _lastKnownShiftStartTime = null;
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      await _liveActivities.endAllActivities();
      _currentActivityId = null;
      debugPrint('[LiveActivityService] Live Activity finalizada de Dynamic Island.');
    } catch (e) {
      debugPrint('[LiveActivityService] Error al finalizar Live Activity: $e');
    }
  }

  String _extractCompanyName(String full) {
    if (full.isEmpty) return 'AsisGo';
    final words = full.split(' ');
    if (words.length >= 2) return '${words[0]} ${words[1]}';
    return words[0];
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
