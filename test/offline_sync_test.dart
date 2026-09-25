import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:asisgo/core/services/connectivity_service.dart';
import 'package:asisgo/core/services/offline_sync_service.dart';
import 'package:asisgo/core/services/storage_service.dart';
import 'package:asisgo/features/attendance_map/data/attendance_repository.dart';
import 'package:asisgo/features/attendance_map/domain/shift_phase.dart';
import 'package:asisgo/features/attendance_map/presentation/cubit/attendance_cubit.dart';
import 'package:asisgo/features/attendance_map/presentation/cubit/attendance_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;
  late AttendanceRepository attendanceRepository;
  late ConnectivityService connectivityService;
  late OfflineSyncService offlineSyncService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storageService = StorageService(prefs);
    attendanceRepository = AttendanceRepository(storageService);
    connectivityService = ConnectivityService();
    offlineSyncService = OfflineSyncService(
      attendanceRepository: attendanceRepository,
      connectivityService: connectivityService,
    );
    offlineSyncService.init();
  });

  tearDown(() {
    connectivityService.dispose();
    offlineSyncService.dispose();
  });

  group('ConnectivityService Tests', () {
    test('Can toggle simulated offline mode and notify listeners', () async {
      expect(connectivityService.isSimulatedOffline, isFalse);

      final events = <bool>[];
      final sub = connectivityService.onConnectivityChanged.listen(events.add);

      connectivityService.setSimulatedOffline(true);
      expect(connectivityService.isSimulatedOffline, isTrue);
      expect(connectivityService.isOnline, isFalse);

      connectivityService.setSimulatedOffline(false);
      expect(connectivityService.isSimulatedOffline, isFalse);

      await Future.delayed(const Duration(milliseconds: 50));
      expect(events, contains(false));
      await sub.cancel();
    });
  });

  group('AttendanceRepository Offline & Sync Tests', () {
    test('Offline punch is stored with isSynced = false', () async {
      final record = await attendanceRepository.registerAttendance(
        userId: 'USER_OFFLINE_01',
        type: AttendanceType.checkIn,
        branchId: 'BR-01',
        branchName: 'Sede Central',
        latitude: -12.0967,
        longitude: -77.0347,
        distanceToGeozone: 10,
        isInsideGeozone: true,
        isSynced: false,
      );

      expect(record.isSynced, isFalse);

      final pendingCount = await attendanceRepository.getPendingSyncCount('USER_OFFLINE_01');
      expect(pendingCount, equals(1));

      final pendingRecords = await attendanceRepository.getPendingSyncRecords('USER_OFFLINE_01');
      expect(pendingRecords.length, equals(1));
      expect(pendingRecords.first.id, equals(record.id));
    });

    test('syncPendingRecords marks all pending items as isSynced = true', () async {
      const userId = 'USER_OFFLINE_SYNC';
      await attendanceRepository.registerAttendance(
        userId: userId,
        type: AttendanceType.checkIn,
        branchId: 'BR-01',
        branchName: 'Sede Central',
        latitude: -12.0967,
        longitude: -77.0347,
        distanceToGeozone: 5,
        isInsideGeozone: true,
        isSynced: false,
      );
      await attendanceRepository.registerAttendance(
        userId: userId,
        type: AttendanceType.lunchStart,
        branchId: 'BR-01',
        branchName: 'Sede Central',
        latitude: -12.0967,
        longitude: -77.0347,
        distanceToGeozone: 5,
        isInsideGeozone: true,
        isSynced: false,
      );

      expect(await attendanceRepository.getPendingSyncCount(userId), equals(2));

      final syncedCount = await attendanceRepository.syncPendingRecords(userId);
      expect(syncedCount, equals(2));

      expect(await attendanceRepository.getPendingSyncCount(userId), equals(0));
      final pendingAfter = await attendanceRepository.getPendingSyncRecords(userId);
      expect(pendingAfter, isEmpty);
    });
  });

  group('AttendanceCubit Offline Registration & Auto-Sync Integration', () {
    test('Punches made while offline update shift phase immediately and queue for sync', () async {
      connectivityService.setSimulatedOffline(true);

      final cubit = AttendanceCubit(
        attendanceRepository: attendanceRepository,
        connectivityService: connectivityService,
        offlineSyncService: offlineSyncService,
      );

      const userId = 'USER_OFFLINE_FLOW';
      await cubit.loadDailyAttendance(userId);

      expect(cubit.state, isA<AttendanceLoaded>());
      var loaded = cubit.state as AttendanceLoaded;
      expect(loaded.isOffline, isTrue);
      expect(loaded.pendingSyncCount, equals(0));
      expect(loaded.currentPhase, equals(ShiftPhase.notStarted));

      // 1. Check In offline
      await cubit.registerPunch(
        userId: userId,
        type: AttendanceType.checkIn,
        branchId: 'BR-01',
        branchName: 'Sede Central',
        latitude: -12.0967,
        longitude: -77.0347,
        distanceToGeozone: 8,
        isInsideGeozone: true,
      );

      loaded = cubit.state as AttendanceLoaded;
      expect(loaded.currentPhase, equals(ShiftPhase.working));
      expect(loaded.pendingSyncCount, equals(1));
      expect(loaded.lastRecord?.isSynced, isFalse);
      expect(loaded.feedbackMessage, contains('sin conexión'));

      // 2. Lunch Start offline
      await cubit.registerPunch(
        userId: userId,
        type: AttendanceType.lunchStart,
        branchId: 'BR-01',
        branchName: 'Sede Central',
        latitude: -12.0967,
        longitude: -77.0347,
        distanceToGeozone: 8,
        isInsideGeozone: true,
      );

      loaded = cubit.state as AttendanceLoaded;
      expect(loaded.currentPhase, equals(ShiftPhase.onLunch));
      expect(loaded.pendingSyncCount, equals(2));

      // 3. Restaurar conectividad -> simular retorno de internet
      connectivityService.setSimulatedOffline(false);

      // Esperar brevemente para que el auto-sync procese en background
      await Future.delayed(const Duration(milliseconds: 700));

      loaded = cubit.state as AttendanceLoaded;
      expect(loaded.pendingSyncCount, equals(0));
      expect(loaded.isOffline, isFalse);
      expect(loaded.feedbackMessage, contains('Sincronización completada'));

      await cubit.close();
    });
  });
}
