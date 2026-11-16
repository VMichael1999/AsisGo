import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../services/connectivity_service.dart';
import '../services/permission_service.dart';
import 'tracked_location.dart';

/// Resultado de intentar iniciar el seguimiento.
enum TrackingStartResult {
  started,
  alreadyTracking,

  /// No hay permiso de ubicacion (o los servicios de ubicacion estan apagados).
  noPermission,
}

/// Fuente de posiciones. Por defecto, Core Location a traves de geolocator.
typedef PositionSource = Stream<Position> Function();

/// Envio de puntos al servidor. Devuelve cuantos quedaron confirmados.
typedef LocationUploader =
    Future<List<String>> Function(List<TrackedLocation> pending);

/// Seguimiento GPS en segundo plano durante la jornada.
///
/// - Usa Core Location (via geolocator) con modo `location` de iOS: precision de
///   ~10 m, filtro de 50 m y un minimo de 60 s entre puntos para cuidar bateria.
/// - Muestra el indicador de ubicacion de iOS: es seguimiento laboral y debe
///   ser visible para el trabajador.
/// - Guarda cada punto en una cola persistente y la envia al recuperar red.
/// - No recoge nada sin permiso ni fuera de [start] / [stop].
class BackgroundLocationService {
  BackgroundLocationService({
    required IPermissionService permissions,
    required LocationPointStore store,
    PositionSource? positionSource,
    LocationUploader? uploader,
    ConnectivityService? connectivity,
    DateTime Function()? clock,
    Duration minInterval = const Duration(seconds: 60),
    Duration retryDelay = const Duration(seconds: 30),
    this.maxQueued = 500,
  }) : _permissions = permissions,
       _store = store,
       _positionSource = positionSource ?? _defaultSource,
       _uploader = uploader ?? _simulatedUploader,
       _connectivity = connectivity,
       _clock = clock ?? DateTime.now,
       _minInterval = minInterval,
       _retryDelay = retryDelay {
    _connectivitySub = _connectivity?.onConnectivityChanged.listen((online) {
      if (online) unawaited(syncPending());
    });
  }

  final IPermissionService _permissions;
  final LocationPointStore _store;
  final PositionSource _positionSource;
  final LocationUploader _uploader;
  final ConnectivityService? _connectivity;
  final DateTime Function() _clock;
  final Duration _minInterval;
  final Duration _retryDelay;

  /// Tope de puntos guardados; al superarlo se descartan los mas antiguos
  /// (primero los ya sincronizados).
  final int maxQueued;

  StreamSubscription<Position>? _positionSub;
  StreamSubscription<bool>? _connectivitySub;
  Timer? _retryTimer;
  String? _userId;
  DateTime? _lastRecordedAt;
  bool _paused = false;
  bool _syncing = false;
  int _consecutiveErrors = 0;

  /// Ultimo error de GPS (null si el seguimiento va bien).
  final ValueNotifier<String?> lastError = ValueNotifier(null);

  bool get isTracking => _userId != null && !_paused;
  bool get isPaused => _userId != null && _paused;
  String? get trackedUserId => _userId;

  static const _uuid = Uuid();

  static Stream<Position> _defaultSource() {
    final LocationSettings settings;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      settings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
        activityType: ActivityType.other,
        // iOS puede pausar las actualizaciones si el usuario no se mueve.
        pauseLocationUpdatesAutomatically: true,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    } else {
      settings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
      );
    }
    return Geolocator.getPositionStream(locationSettings: settings);
  }

  // El servidor aun es simulado, igual que la sincronizacion de marcaciones.
  static Future<List<String>> _simulatedUploader(
    List<TrackedLocation> pending,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return pending.map((p) => p.id).toList();
  }

  /// Inicia el seguimiento para [userId]. Idempotente.
  Future<TrackingStartResult> start({required String userId}) async {
    if (_userId == userId && !_paused && _positionSub != null) {
      return TrackingStartResult.alreadyTracking;
    }
    final snapshot = await _permissions.snapshot();
    if (!snapshot.canTrack) return TrackingStartResult.noPermission;

    await _cancelStream();
    _userId = userId;
    _paused = false;
    _consecutiveErrors = 0;
    lastError.value = null;
    _subscribe();
    debugPrint('[BackgroundLocation] Seguimiento iniciado ($userId)');
    return TrackingStartResult.started;
  }

  /// Pausa sin cerrar la jornada (refrigerio): deja de recoger puntos.
  Future<void> pause() async {
    if (_userId == null || _paused) return;
    _paused = true;
    await _cancelStream();
    debugPrint('[BackgroundLocation] Seguimiento en pausa');
  }

  /// Reanuda tras una pausa.
  Future<TrackingStartResult> resume() async {
    final user = _userId;
    if (user == null) return TrackingStartResult.noPermission;
    _paused = false;
    return start(userId: user);
  }

  /// Detiene por completo el seguimiento y envia lo pendiente.
  Future<void> stop() async {
    final wasActive = _userId != null;
    await _cancelStream();
    _userId = null;
    _paused = false;
    _lastRecordedAt = null;
    lastError.value = null;
    if (wasActive) {
      debugPrint('[BackgroundLocation] Seguimiento detenido');
      unawaited(syncPending());
    }
  }

  void _subscribe() {
    _positionSub = _positionSource().listen(
      _onPosition,
      onError: _onError,
      cancelOnError: false,
    );
  }

  Future<void> _cancelStream() async {
    _retryTimer?.cancel();
    _retryTimer = null;
    final sub = _positionSub;
    _positionSub = null;
    await sub?.cancel();
  }

  Future<void> _onPosition(Position position) async {
    final user = _userId;
    if (user == null || _paused) return;
    _consecutiveErrors = 0;
    lastError.value = null;

    final now = _clock();
    final last = _lastRecordedAt;
    if (last != null && now.difference(last) < _minInterval) return;
    _lastRecordedAt = now;

    final snapshot = await _permissions.snapshot();
    // Sin permiso no se guarda nada y se detiene la recogida.
    if (!snapshot.canTrack) {
      lastError.value = 'Permiso de ubicación retirado';
      await pause();
      return;
    }

    final point = TrackedLocation(
      id: _uuid.v4(),
      userId: user,
      timestamp: now,
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      permission: snapshot.locationLabel,
      isMocked: position.isMocked,
    );
    final queue = await _store.load()
      ..add(point);
    await _store.save(_trim(queue));
    debugPrint(
      '[BackgroundLocation] Punto guardado (${point.latitude.toStringAsFixed(5)}, '
      '${point.longitude.toStringAsFixed(5)}) permiso=${point.permission}',
    );

    if (_connectivity?.isOnline ?? true) unawaited(syncPending());
  }

  /// Error de GPS (senal perdida, servicio apagado): se reintenta con espera.
  void _onError(Object error) {
    _consecutiveErrors++;
    lastError.value = error.toString();
    debugPrint('[BackgroundLocation] Error de GPS: $error');
    if (_userId == null || _paused || _retryTimer != null) return;
    // Espera creciente (hasta 4 veces) para no gastar bateria si no hay senal.
    final wait = _retryDelay * (_consecutiveErrors.clamp(1, 4));
    _retryTimer = Timer(wait, () async {
      _retryTimer = null;
      if (_userId == null || _paused) return;
      await _cancelStream();
      _subscribe();
    });
  }

  List<TrackedLocation> _trim(List<TrackedLocation> points) {
    if (points.length <= maxQueued) return points;
    final overflow = points.length - maxQueued;
    final sorted = [...points]
      ..sort((a, b) {
        if (a.isSynced != b.isSynced) return a.isSynced ? -1 : 1;
        return a.timestamp.compareTo(b.timestamp);
      });
    final drop = sorted.take(overflow).map((p) => p.id).toSet();
    return points.where((p) => !drop.contains(p.id)).toList();
  }

  /// Envia los puntos pendientes. Devuelve cuantos se confirmaron.
  Future<int> syncPending() async {
    if (_syncing) return 0;
    if (!(_connectivity?.isOnline ?? true)) return 0;
    _syncing = true;
    try {
      final all = await _store.load();
      final pending = all.where((p) => !p.isSynced).toList();
      if (pending.isEmpty) return 0;
      final confirmed = (await _uploader(pending)).toSet();
      if (confirmed.isEmpty) return 0;
      final updated = (await _store.load())
          .map((p) => confirmed.contains(p.id) ? p.copyWith(isSynced: true) : p)
          .toList();
      await _store.save(updated);
      return confirmed.length;
    } catch (e) {
      debugPrint('[BackgroundLocation] Error al sincronizar puntos: $e');
      return 0;
    } finally {
      _syncing = false;
    }
  }

  /// Puntos guardados (para depuracion y pruebas).
  Future<List<TrackedLocation>> storedPoints() => _store.load();

  Future<void> dispose() async {
    await _cancelStream();
    await _connectivitySub?.cancel();
    lastError.dispose();
  }
}
