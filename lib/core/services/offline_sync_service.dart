import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/connectivity_service.dart';
import '../../features/attendance_map/data/attendance_repository.dart';

sealed class SyncEvent {
  const SyncEvent();
}

class SyncStartedEvent extends SyncEvent {
  const SyncStartedEvent();
}

class SyncCompletedEvent extends SyncEvent {
  final int syncedCount;
  const SyncCompletedEvent(this.syncedCount);
}

class SyncFailedEvent extends SyncEvent {
  final String error;
  const SyncFailedEvent(this.error);
}

class OfflineSyncService {
  final AttendanceRepository _attendanceRepository;
  final ConnectivityService _connectivityService;
  final StreamController<SyncEvent> _eventController = StreamController<SyncEvent>.broadcast();
  StreamSubscription<bool>? _connectivitySubscription;

  String? _currentUserId;
  bool _isSyncing = false;
  bool _lastKnownOnline = true;
  bool _initialized = false;

  OfflineSyncService({
    required AttendanceRepository attendanceRepository,
    required ConnectivityService connectivityService,
    String? currentUserId,
  })  : _attendanceRepository = attendanceRepository,
        _connectivityService = connectivityService,
        _currentUserId = currentUserId;

  bool get isSyncing => _isSyncing;
  Stream<SyncEvent> get syncEvents => _eventController.stream;

  void setCurrentUserId(String? userId) {
    _currentUserId = userId;
    if (userId != null && _connectivityService.isOnline) {
      // Intentar sincronizacion automatica inicial si hay registros pendientes
      syncNow();
    }
  }

  void init() {
    if (_initialized) return;
    _lastKnownOnline = _connectivityService.isOnline;

    _connectivitySubscription = _connectivityService.onConnectivityChanged.listen((isOnline) {
      debugPrint('[OfflineSyncService] Conectividad cambio: $isOnline (previo: $_lastKnownOnline)');
      // Transicion de offline a online -> auto-sync
      if (isOnline && !_lastKnownOnline) {
        debugPrint('[OfflineSyncService] Señal recuperada. Iniciando auto-sincronización...');
        syncNow();
      }
      _lastKnownOnline = isOnline;
    });

    _initialized = true;
  }

  Future<int> syncNow() async {
    if (_isSyncing) {
      debugPrint('[OfflineSyncService] Ya existe un proceso de sincronización en ejecución.');
      return 0;
    }

    final userId = _currentUserId;
    if (userId == null) {
      debugPrint('[OfflineSyncService] No hay usuario activo para sincronizar.');
      return 0;
    }

    if (!_connectivityService.isOnline) {
      debugPrint('[OfflineSyncService] No se puede sincronizar sin conexión a internet.');
      return 0;
    }

    final pendingCount = await _attendanceRepository.getPendingSyncCount(userId);
    if (pendingCount == 0) {
      debugPrint('[OfflineSyncService] No hay registros pendientes de sincronización.');
      return 0;
    }

    _isSyncing = true;
    _eventController.add(const SyncStartedEvent());
    debugPrint('[OfflineSyncService] Sincronizando $pendingCount marcas pendientes...');

    try {
      final syncedCount = await _attendanceRepository.syncPendingRecords(userId);
      _eventController.add(SyncCompletedEvent(syncedCount));
      debugPrint('[OfflineSyncService] Sincronización exitosa de $syncedCount marcas.');
      return syncedCount;
    } catch (e) {
      debugPrint('[OfflineSyncService] Error al sincronizar marcas: $e');
      _eventController.add(SyncFailedEvent(e.toString()));
      return 0;
    } finally {
      _isSyncing = false;
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _eventController.close();
  }
}
