import 'package:flutter/foundation.dart';

import '../../features/attendance_map/domain/shift_phase.dart';
import '../services/permission_service.dart';
import 'background_location_service.dart';
import 'tracked_location.dart';

/// Que hacer con el seguimiento durante el refrigerio.
enum LunchTrackingPolicy {
  /// Se pausa y se reanuda al terminar (mas privado y menos bateria).
  pause,

  /// Sigue registrando.
  keepTracking,
}

/// Une el seguimiento GPS con el ciclo de la jornada:
///
/// - entrada: inicia
/// - inicio de refrigerio: segun [lunchPolicy]
/// - fin de refrigerio: reanuda
/// - salida: detiene por completo
///
/// Es idempotente: recibir la misma fase varias veces (por ejemplo al abrir
/// la app) no crea seguimientos duplicados.
class AttendanceTrackingService {
  AttendanceTrackingService({
    required BackgroundLocationService location,
    required IPermissionService permissions,
    required LocationPointStore store,
    this.lunchPolicy = LunchTrackingPolicy.pause,
  }) : _location = location,
       _permissions = permissions,
       _store = store;

  final BackgroundLocationService _location;
  final IPermissionService _permissions;
  final LocationPointStore _store;
  final LunchTrackingPolicy lunchPolicy;

  BackgroundLocationService get location => _location;

  /// Estado del permiso de ubicacion para guardar junto a cada marcacion.
  Future<String> permissionLabel() async =>
      (await _permissions.snapshot()).locationLabel;

  /// Aplica la fase de la jornada. Se llama al marcar y al abrir la app.
  Future<void> onPhaseChanged({
    required String userId,
    required ShiftPhase phase,
  }) async {
    try {
      switch (phase) {
        case ShiftPhase.working:
        case ShiftPhase.resumed:
          await _startTracking(userId);
        case ShiftPhase.onLunch:
          if (lunchPolicy == LunchTrackingPolicy.pause) {
            await _location.pause();
          } else {
            await _startTracking(userId);
          }
        case ShiftPhase.notStarted:
        case ShiftPhase.completed:
          await _location.stop();
      }
    } catch (e) {
      debugPrint('[AttendanceTracking] No se pudo aplicar la fase $phase: $e');
    }
  }

  /// Cierre de sesion: nunca se sigue rastreando a un usuario que salio.
  Future<void> onSignedOut() => _location.stop();

  Future<void> _startTracking(String userId) async {
    // Si la jornada la abre otro usuario, se corta el seguimiento anterior.
    final current = _location.trackedUserId;
    if (current != null && current != userId) await _location.stop();

    final result = await _location.start(userId: userId);
    if (result == TrackingStartResult.started) await _offerAlwaysOnce();
  }

  /// iOS solo ofrece "Siempre" una vez y tras "Al usar la app": se hace justo al
  /// iniciar la jornada, que es cuando el usuario entiende para que sirve.
  Future<void> _offerAlwaysOnce() async {
    if (await _store.wasAlwaysOffered()) return;
    final snapshot = await _permissions.snapshot();
    if (snapshot.location != LocationAccess.whileInUse) return;
    await _store.markAlwaysOffered();
    await _permissions.requestAlways();
  }
}
