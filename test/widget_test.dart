import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asisgo/core/widgets/asis_session_expired_dialog.dart';
import 'package:asisgo/core/widgets/asis_skeletons.dart';
import 'package:asisgo/core/services/live_activity_service.dart';
import 'package:asisgo/core/services/notification_service.dart';
import 'package:asisgo/features/attendance_map/presentation/widgets/attendance_action_dock.dart';
import 'package:asisgo/features/attendance_map/presentation/cubit/attendance_cubit.dart';
import 'package:asisgo/features/attendance_map/domain/attendance_record.dart';
import 'package:asisgo/features/auth/domain/user_model.dart';
import 'package:asisgo/features/attendance_map/domain/shift_phase.dart';
import 'package:asisgo/features/attendance_map/data/attendance_repository.dart';

void main() {
  test('User model serialization and deserialization', () {
    const user = User(
      id: 'USR-999',
      fullName: 'Test Developer',
      email: 'test@asisgo.com',
      role: 'QA Engineer',
      documentNumber: '88776655',
      assignedBranchId: 'BR-01',
      shiftStartTime: '08:30',
      shiftEndTime: '18:00',
    );

    final json = user.toJson();
    final reconstructed = User.fromJson(json);

    expect(reconstructed.id, equals(user.id));
    expect(reconstructed.fullName, equals(user.fullName));
    expect(reconstructed.email, equals(user.email));
  });

  test('ShiftPhase labels and nextExpectedAttendance mapping', () {
    expect(ShiftPhase.notStarted.nextExpectedAttendance, equals(AttendanceType.checkIn));
    expect(ShiftPhase.working.nextExpectedAttendance, equals(AttendanceType.lunchStart));
    expect(ShiftPhase.onLunch.nextExpectedAttendance, equals(AttendanceType.lunchEnd));
    expect(ShiftPhase.resumed.nextExpectedAttendance, equals(AttendanceType.checkOut));
    expect(ShiftPhase.completed.nextExpectedAttendance, isNull);
  });

  testWidgets('AsisSessionExpiredDialog renders properly and responds to buttons', (tester) async {
    bool dismissedViaX = false;
    bool dismissedViaButton = false;

    // Prueba de pulsacion sobre boton de cierre X
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AsisSessionExpiredDialog(
            message: 'El inicio de sesión ha expirado, vuelve a iniciar sesión nuevamente.',
            onDismissAndLogin: () {
              dismissedViaX = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Inicio de Sesión Expirado'), findsOneWidget);
    expect(find.text('SEGURIDAD CORPORATIVA'), findsOneWidget);
    expect(find.text('Volver a Iniciar Sesión'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    expect(dismissedViaX, isTrue);

    // Prueba de pulsacion sobre boton principal de inicio de sesion
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AsisSessionExpiredDialog(
            message: 'El inicio de sesión ha expirado, vuelve a iniciar sesión nuevamente.',
            onDismissAndLogin: () {
              dismissedViaButton = true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Volver a Iniciar Sesión'));
    await tester.pump();
    expect(dismissedViaButton, isTrue);
  });

  testWidgets('AsisShimmer and AsisBottomNavSkeleton render properly without layout errors', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Content'),
          ),
          bottomNavigationBar: AsisBottomNavSkeleton(),
        ),
      ),
    );

    expect(find.byType(AsisBottomNavSkeleton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AttendanceActionDock shows secondary action only when in working phase', (tester) async {
    // 1. Fase notStarted no debe mostrar opcion de salida anticipada
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AttendanceActionDock(
            phase: ShiftPhase.notStarted,
            todayRecords: const [],
            isInsideGeozone: true,
            onPrimaryActionPressed: () {},
            onSecondaryActionPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('¿Deseas marcar salida anticipada?'), findsNothing);

    // 2. Fase working debe mostrar opcion de salida anticipada
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AttendanceActionDock(
            phase: ShiftPhase.working,
            todayRecords: const [],
            isInsideGeozone: true,
            onPrimaryActionPressed: () {},
            onSecondaryActionPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('¿Deseas marcar salida anticipada?'), findsOneWidget);
  });

  test('NotificationService updateShiftNotification executes safely with all shift phases and Live Activity metadata', () async {
    final service = NotificationService();
    await service.initialize();

    final now = DateTime.now();
    final entryTime = now.subtract(const Duration(hours: 4));
    final lunchTime = now.subtract(const Duration(minutes: 30));

    // 1. Fase Turno Activo (Entrada)
    await service.updateShiftNotification(
      phase: ShiftPhase.working,
      branchName: 'Sede Central San Isidro',
      shiftStartTime: entryTime,
      isInsideGeozone: true,
      punchesCount: 1,
    );

    // 2. Fase Refrigerio en curso (Ámbar con cronómetro y cup icon)
    await service.updateShiftNotification(
      phase: ShiftPhase.onLunch,
      branchName: 'Sede Central San Isidro',
      shiftStartTime: entryTime,
      lunchStartTime: lunchTime,
      isInsideGeozone: false,
      punchesCount: 2,
    );

    // 3. Fase Retorno / Reanudado
    await service.updateShiftNotification(
      phase: ShiftPhase.resumed,
      branchName: 'Sede Central San Isidro',
      shiftStartTime: entryTime,
      isInsideGeozone: true,
      punchesCount: 3,
    );

    // 4. Conclusión de jornada
    await service.updateShiftNotification(
      phase: ShiftPhase.completed,
      branchName: 'Sede Central San Isidro',
      shiftStartTime: entryTime,
      punchesCount: 4,
    );

    await service.cancelShiftNotification();
  });

  test('LiveActivityService exposes shiftActivityKey and handles safe lifecycle with geozone & phases', () async {
    final service = LiveActivityService();
    expect(LiveActivityService.shiftActivityKey, equals('asisgo_shift_tracker'));
    expect(LiveActivityService.appGroupId, equals('group.com.asisgo.app.asisgo'));

    final startTime = DateTime.now().subtract(const Duration(hours: 3));

    // 1. Entrada / Jornada Activa dentro de geozona
    await service.syncShift(
      phase: ShiftPhase.working,
      branchName: 'Torre Interbank Sede Central',
      shiftStartTime: startTime,
      isInsideGeozone: true,
    );

    // 2. Transición a refrigerio
    await service.syncShift(
      phase: ShiftPhase.onLunch,
      branchName: 'Torre Interbank Sede Central',
      shiftStartTime: startTime,
      lunchStartTime: DateTime.now().subtract(const Duration(minutes: 15)),
      isInsideGeozone: false, // Fuera de geozona durante refrigerio
    );

    // 3. Retorno de refrigerio -> Jornada Activa reanudada
    await service.syncShift(
      phase: ShiftPhase.resumed,
      branchName: 'Torre Interbank Sede Central',
      shiftStartTime: startTime,
      isInsideGeozone: true,
    );

    // 4. Cierre de turno / Fin de jornada
    await service.syncShift(
      phase: ShiftPhase.completed,
      branchName: 'Torre Interbank Sede Central',
    );
    await service.endShiftActivity();
  });

  test('AttendanceCubit updateGeozoneStatus executes safely without errors', () async {
    final fakeRepo = FakeAttendanceRepository([
      AttendanceRecord(
        id: 'REC-1',
        userId: 'USR-01',
        type: AttendanceType.checkIn,
        branchId: 'BR-01',
        branchName: 'Sede Central',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        latitude: -12.08,
        longitude: -77.03,
        distanceToGeozone: 10,
        isInsideGeozone: true,
      ),
    ]);

    final cubit = AttendanceCubit(attendanceRepository: fakeRepo);
    await cubit.loadDailyAttendance('USR-01');

    // Cambiar estado a fuera de geozona
    cubit.updateGeozoneStatus(isInsideGeozone: false);
    // Cambiar estado a dentro de geozona
    cubit.updateGeozoneStatus(isInsideGeozone: true);
    // Invocar con el mismo estado no debe provocar errores
    cubit.updateGeozoneStatus(isInsideGeozone: true);

    await cubit.close();
  });
}

class FakeAttendanceRepository implements AttendanceRepository {
  final List<AttendanceRecord> records;
  FakeAttendanceRepository(this.records);

  @override
  Future<List<AttendanceRecord>> getTodayRecords(String userId) async => records;

  @override
  Future<void> setTodayRecordsForDemo(List<AttendanceRecord> records) async {}

  @override
  Future<ShiftPhase> getCurrentShiftPhase(String userId) async => ShiftPhase.working;

  @override
  Future<void> init() async {}

  @override
  Future<List<AttendanceRecord>> getAllRecords(String userId) async => records;

  @override
  Future<List<AttendanceRecord>> getRecordsForDate(String userId, DateTime date) async => records;

  @override
  Future<void> clearAll() async {}

  @override
  Future<List<AttendanceRecord>> getPendingSyncRecords(String userId) async => [];

  @override
  Future<int> getPendingSyncCount(String userId) async => 0;

  @override
  Future<int> syncPendingRecords(String userId) async => 0;

  @override
  Future<AttendanceRecord> registerAttendance({
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
    bool isSynced = true,
  }) async => records.first;
}
