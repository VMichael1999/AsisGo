import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/haptic_feedback_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/offline_sync_service.dart';
import '../../data/attendance_repository.dart';
import '../../domain/attendance_record.dart';
import '../../domain/shift_phase.dart';
import 'attendance_state.dart';

class AttendanceCubit extends Cubit<AttendanceState> {
  final AttendanceRepository _attendanceRepository;
  final NotificationService _notificationService;
  final ConnectivityService _connectivityService;
  final OfflineSyncService _offlineSyncService;
  final HapticFeedbackService _hapticFeedbackService;

  StreamSubscription<bool>? _connectivitySub;
  StreamSubscription<SyncEvent>? _syncEventsSub;
  String? _activeUserId;

  AttendanceCubit({
    required AttendanceRepository attendanceRepository,
    NotificationService? notificationService,
    ConnectivityService? connectivityService,
    OfflineSyncService? offlineSyncService,
    HapticFeedbackService? hapticFeedbackService,
  })  : _attendanceRepository = attendanceRepository,
        _notificationService = notificationService ?? NotificationService(),
        _connectivityService = connectivityService ?? ConnectivityService(),
        _hapticFeedbackService = hapticFeedbackService ?? HapticFeedbackService.shared,
        _offlineSyncService = offlineSyncService ??
            OfflineSyncService(
              attendanceRepository: attendanceRepository,
              connectivityService: connectivityService ?? ConnectivityService(),
            ),
        super(AttendanceInitial()) {
    _initListeners();
  }

  void _initListeners() {
    _connectivitySub = _connectivityService.onConnectivityChanged.listen((isOnline) {
      final current = state;
      if (current is AttendanceLoaded) {
        emit(current.copyWith(isOffline: !isOnline));
      }
    });

    _syncEventsSub = _offlineSyncService.syncEvents.listen((event) async {
      final current = state;
      if (current is AttendanceLoaded) {
        if (event is SyncStartedEvent) {
          emit(current.copyWith(isSyncing: true));
        } else if (event is SyncCompletedEvent) {
          if (_activeUserId != null) {
            final updatedRecords = await _attendanceRepository.getTodayRecords(_activeUserId!);
            final pendingCount = await _attendanceRepository.getPendingSyncCount(_activeUserId!);
            if (event.syncedCount > 0) {
              _hapticFeedbackService.syncCompleted();
            }
            emit(current.copyWith(
              isSyncing: false,
              todayRecords: updatedRecords,
              pendingSyncCount: pendingCount,
              feedbackMessage: event.syncedCount > 0
                  ? 'Sincronización completada: ${event.syncedCount} marca(s) sincronizada(s) con éxito.'
                  : null,
            ));
          } else {
            emit(current.copyWith(isSyncing: false));
          }
        } else if (event is SyncFailedEvent) {
          _hapticFeedbackService.securityAlert();
          emit(current.copyWith(
            isSyncing: false,
            feedbackMessage: 'Error al sincronizar marcas pendientes.',
          ));
        }
      }
    });
  }

  Future<void> loadDailyAttendance(String userId) async {
    _activeUserId = userId;
    _offlineSyncService.setCurrentUserId(userId);
    emit(AttendanceLoading());
    try {
      final records = await _attendanceRepository.getTodayRecords(userId);
      final phase = await _attendanceRepository.getCurrentShiftPhase(userId);
      final pendingCount = await _attendanceRepository.getPendingSyncCount(userId);
      final last = records.isNotEmpty ? records.last : null;

      emit(AttendanceLoaded(
        currentPhase: phase,
        todayRecords: records,
        lastRecord: last,
        isOffline: !_connectivityService.isOnline,
        pendingSyncCount: pendingCount,
      ));

      // Sincronizar notificacion persistente del turno en vivo
      _syncNotification(phase, records, last?.branchName ?? 'Sede Central');
    } catch (e) {
      emit(AttendanceError('Error al cargar la asistencia: ${e.toString()}'));
    }
  }

  Future<void> registerPunch({
    required String userId,
    required AttendanceType type,
    required String branchId,
    required String branchName,
    String? geozoneId,
    String? geozoneName,
    required double latitude,
    required double longitude,
    required double distanceToGeozone,
    required bool isInsideGeozone,
    bool isMockedLocation = false,
    String? note,
    String? selfiePath,
  }) async {
    final currentState = state;
    if (currentState is AttendanceLoaded) {
      emit(currentState.copyWith(isSubmitting: true));
    }

    try {
      final isOnline = _connectivityService.isOnline;
      final newRecord = await _attendanceRepository.registerAttendance(
        userId: userId,
        type: type,
        branchId: branchId,
        branchName: branchName,
        geozoneId: geozoneId,
        geozoneName: geozoneName,
        latitude: latitude,
        longitude: longitude,
        distanceToGeozone: distanceToGeozone,
        isInsideGeozone: isInsideGeozone,
        isMockedLocation: isMockedLocation,
        note: note,
        selfiePath: selfiePath,
        isSynced: isOnline,
      );

      final nextPhase = _determineNextPhase(type);
      final updatedRecords = await _attendanceRepository.getTodayRecords(userId);
      final pendingCount = await _attendanceRepository.getPendingSyncCount(userId);

      emit(AttendanceLoaded(
        currentPhase: nextPhase,
        todayRecords: updatedRecords,
        lastRecord: newRecord,
        isSubmitting: false,
        isOffline: !isOnline,
        pendingSyncCount: pendingCount,
        feedbackMessage: isOnline
            ? '${type.title} registrada exitosamente.'
            : '${type.title} registrada sin conexión. Se sincronizará automáticamente al recuperar señal.',
      ));

      // Feedback háptico y sonoro de registro exitoso
      _hapticFeedbackService.punchSuccess();

      // Sincronizar notificacion persistente del turno
      _syncNotification(nextPhase, updatedRecords, branchName, isInsideGeozone: isInsideGeozone);
    } catch (e) {
      _hapticFeedbackService.securityAlert();
      emit(AttendanceError('Error al registrar la asistencia: ${e.toString()}'));
      // Reload current state
      await loadDailyAttendance(userId);
    }
  }

  Future<void> syncPendingNow() async {
    final current = state;
    if (current is AttendanceLoaded && !current.isSyncing) {
      emit(current.copyWith(isSyncing: true));
      await _offlineSyncService.syncNow();
    }
  }

  bool _lastReportedInsideGeozone = true;

  /// Actualiza en tiempo real el estado de geozona para la Dynamic Island y notificaciones
  void updateGeozoneStatus({required bool isInsideGeozone}) {
    if (_lastReportedInsideGeozone == isInsideGeozone) return;
    _lastReportedInsideGeozone = isInsideGeozone;
    final current = state;
    if (current is AttendanceLoaded &&
        (current.currentPhase == ShiftPhase.working ||
            current.currentPhase == ShiftPhase.onLunch ||
            current.currentPhase == ShiftPhase.resumed)) {
      _syncNotification(
        current.currentPhase,
        current.todayRecords,
        current.lastRecord?.branchName ?? 'Sede Central',
        isInsideGeozone: isInsideGeozone,
      );
    }
  }

  void _syncNotification(
    ShiftPhase phase,
    List<AttendanceRecord> records,
    String branchName, {
    bool? isInsideGeozone,
  }) {
    if (isInsideGeozone != null) {
      _lastReportedInsideGeozone = isInsideGeozone;
    }
    final checkIn = records.cast<AttendanceRecord?>().firstWhere(
          (r) => r?.type == AttendanceType.checkIn,
          orElse: () => null,
        );
    final lunchStart = records.cast<AttendanceRecord?>().firstWhere(
          (r) => r?.type == AttendanceType.lunchStart,
          orElse: () => null,
        );

    _notificationService.updateShiftNotification(
      phase: phase,
      branchName: branchName,
      shiftStartTime: checkIn?.timestamp,
      lunchStartTime: lunchStart?.timestamp,
      isInsideGeozone: _lastReportedInsideGeozone,
      punchesCount: records.length,
    );
  }

  ShiftPhase _determineNextPhase(AttendanceType punchedType) {
    switch (punchedType) {
      case AttendanceType.checkIn:
        return ShiftPhase.working;
      case AttendanceType.lunchStart:
        return ShiftPhase.onLunch;
      case AttendanceType.lunchEnd:
        return ShiftPhase.resumed;
      case AttendanceType.checkOut:
        return ShiftPhase.completed;
    }
  }

  /// Método de utilidad para pruebas y demostraciones en vivo de estados de turno
  Future<void> simulatePhaseForDemo(ShiftPhase targetPhase) async {
    final userId = _activeUserId ?? 'USR-001';
    final now = DateTime.now();
    final records = <AttendanceRecord>[];

    if (targetPhase != ShiftPhase.notStarted) {
      records.add(AttendanceRecord(
        id: 'demo-checkin',
        userId: userId,
        type: AttendanceType.checkIn,
        timestamp: DateTime(now.year, now.month, now.day, 8, 15),
        branchId: 'BR-01',
        branchName: 'Sede Central San Isidro',
        geozoneId: 'GZ-01',
        geozoneName: 'Entrada Principal',
        latitude: -12.0967,
        longitude: -77.0347,
        distanceToGeozone: 10.0,
        isInsideGeozone: true,
      ));
    }
    if (targetPhase == ShiftPhase.onLunch ||
        targetPhase == ShiftPhase.resumed ||
        targetPhase == ShiftPhase.completed) {
      records.add(AttendanceRecord(
        id: 'demo-lunch-start',
        userId: userId,
        type: AttendanceType.lunchStart,
        timestamp: DateTime(now.year, now.month, now.day, 13, 0),
        branchId: 'BR-01',
        branchName: 'Sede Central San Isidro',
        geozoneId: 'GZ-01',
        geozoneName: 'Entrada Principal',
        latitude: -12.0967,
        longitude: -77.0347,
        distanceToGeozone: 12.0,
        isInsideGeozone: true,
      ));
    }
    if (targetPhase == ShiftPhase.resumed || targetPhase == ShiftPhase.completed) {
      records.add(AttendanceRecord(
        id: 'demo-lunch-end',
        userId: userId,
        type: AttendanceType.lunchEnd,
        timestamp: DateTime(now.year, now.month, now.day, 14, 0),
        branchId: 'BR-01',
        branchName: 'Sede Central San Isidro',
        geozoneId: 'GZ-01',
        geozoneName: 'Entrada Principal',
        latitude: -12.0967,
        longitude: -77.0347,
        distanceToGeozone: 14.0,
        isInsideGeozone: true,
      ));
    }
    if (targetPhase == ShiftPhase.completed) {
      records.add(AttendanceRecord(
        id: 'demo-checkout',
        userId: userId,
        type: AttendanceType.checkOut,
        timestamp: DateTime(now.year, now.month, now.day, 18, 0),
        branchId: 'BR-01',
        branchName: 'Sede Central San Isidro',
        geozoneId: 'GZ-01',
        geozoneName: 'Entrada Principal',
        latitude: -12.0967,
        longitude: -77.0347,
        distanceToGeozone: 15.0,
        isInsideGeozone: true,
      ));
    }

    await _attendanceRepository.setTodayRecordsForDemo(records);

    emit(AttendanceLoaded(
      currentPhase: targetPhase,
      todayRecords: records,
      lastRecord: records.isNotEmpty ? records.last : null,
      isOffline: !_connectivityService.isOnline,
      pendingSyncCount: 0,
    ));

    _syncNotification(
      targetPhase,
      records,
      'Sede Central San Isidro',
      isInsideGeozone: _lastReportedInsideGeozone,
    );
  }

  @override
  Future<void> close() {
    _connectivitySub?.cancel();
    _syncEventsSub?.cancel();
    return super.close();
  }
}
