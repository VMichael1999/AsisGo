import 'dart:async';

import 'package:asisgo/core/services/connectivity_service.dart';
import 'package:asisgo/core/services/permission_service.dart';
import 'package:asisgo/core/services/storage_service.dart';
import 'package:asisgo/core/tracking/attendance_tracking_service.dart';
import 'package:asisgo/core/tracking/background_location_service.dart';
import 'package:asisgo/core/tracking/tracked_location.dart';
import 'package:asisgo/features/attendance_map/data/attendance_repository.dart';
import 'package:asisgo/features/attendance_map/domain/shift_phase.dart';
import 'package:asisgo/features/attendance_map/presentation/cubit/attendance_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de permisos controlable desde el test.
class FakePermissions implements IPermissionService {
  PermissionSnapshot current;
  int alwaysRequests = 0;
  int settingsOpened = 0;

  FakePermissions([PermissionSnapshot? initial])
    : current =
          initial ?? const PermissionSnapshot(location: LocationAccess.always);

  @override
  Future<PermissionSnapshot> snapshot() async => current;

  @override
  Future<LocationAccess> requestWhenInUse() async => current.location;

  @override
  Future<LocationAccess> requestAlways() async {
    alwaysRequests++;
    return current.location;
  }

  @override
  Future<SimplePermission> requestMotion() async => current.motion;

  @override
  Future<bool> openSettings() async {
    settingsOpened++;
    return true;
  }
}

Position gps(double lat, double lng) => Position(
  latitude: lat,
  longitude: lng,
  timestamp: DateTime(2026, 11, 12),
  accuracy: 8,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

/// Fuente de posiciones que el test alimenta a mano.
class FakeSource {
  final List<StreamController<Position>> controllers = [];
  int get opened => controllers.length;

  Stream<Position> call() {
    final c = StreamController<Position>();
    controllers.add(c);
    return c.stream;
  }

  StreamController<Position> get last => controllers.last;
}

Future<void> pump() => Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakePermissions permissions;
  late FakeSource source;
  late MemoryLocationPointStore store;
  late DateTime now;
  late List<List<String>> uploads;

  BackgroundLocationService build({
    ConnectivityService? connectivity,
    Duration retry = const Duration(milliseconds: 40),
    int maxQueued = 500,
  }) => BackgroundLocationService(
    permissions: permissions,
    store: store,
    positionSource: source.call,
    connectivity: connectivity,
    clock: () => now,
    minInterval: const Duration(seconds: 60),
    retryDelay: retry,
    maxQueued: maxQueued,
    uploader: (pending) async {
      uploads.add(pending.map((p) => p.id).toList());
      return pending.map((p) => p.id).toList();
    },
  );

  setUp(() {
    permissions = FakePermissions();
    source = FakeSource();
    store = MemoryLocationPointStore();
    now = DateTime(2026, 11, 12, 9, 0);
    uploads = [];
  });

  group('PermissionSnapshot / resolveLocationAccess', () {
    test('"Siempre" gana sobre "Al usar"', () {
      expect(
        resolveLocationAccess(
          whenInUse: PermissionStatus.granted,
          always: PermissionStatus.granted,
        ),
        LocationAccess.always,
      );
    });

    test('solo "Al usar la app" concedido', () {
      expect(
        resolveLocationAccess(
          whenInUse: PermissionStatus.granted,
          always: PermissionStatus.denied,
        ),
        LocationAccess.whileInUse,
      );
    });

    test('denegado y restringido se distinguen', () {
      expect(
        resolveLocationAccess(
          whenInUse: PermissionStatus.permanentlyDenied,
          always: PermissionStatus.denied,
        ),
        LocationAccess.denied,
      );
      expect(
        resolveLocationAccess(
          whenInUse: PermissionStatus.restricted,
          always: PermissionStatus.denied,
        ),
        LocationAccess.restricted,
      );
    });

    test('canTrack exige permiso y servicios de ubicacion encendidos', () {
      expect(
        const PermissionSnapshot(location: LocationAccess.whileInUse).canTrack,
        isTrue,
      );
      expect(
        const PermissionSnapshot(location: LocationAccess.denied).canTrack,
        isFalse,
      );
      expect(
        const PermissionSnapshot(
          location: LocationAccess.always,
          locationServicesEnabled: false,
        ).canTrack,
        isFalse,
      );
    });

    test('isFullyConfigured pide Siempre y Background App Refresh activo', () {
      expect(
        const PermissionSnapshot(
          location: LocationAccess.always,
          backgroundRefresh: BackgroundRefresh.available,
        ).isFullyConfigured,
        isTrue,
      );
      expect(
        const PermissionSnapshot(
          location: LocationAccess.always,
          backgroundRefresh: BackgroundRefresh.denied,
        ).isFullyConfigured,
        isFalse,
      );
      expect(
        const PermissionSnapshot(
          location: LocationAccess.whileInUse,
        ).isFullyConfigured,
        isFalse,
      );
    });

    test('locationLabel resume el estado para guardarlo', () {
      expect(
        const PermissionSnapshot(location: LocationAccess.always).locationLabel,
        'always',
      );
      expect(
        const PermissionSnapshot(
          location: LocationAccess.whileInUse,
        ).locationLabel,
        'whileInUse',
      );
      expect(
        const PermissionSnapshot(
          location: LocationAccess.always,
          locationServicesEnabled: false,
        ).locationLabel,
        'servicesOff',
      );
    });
  });

  group('BackgroundLocationService', () {
    test('sin permiso no inicia ni abre el GPS', () async {
      permissions.current = const PermissionSnapshot(
        location: LocationAccess.denied,
      );
      final service = build();

      final result = await service.start(userId: 'U1');

      expect(result, TrackingStartResult.noPermission);
      expect(service.isTracking, isFalse);
      expect(source.opened, 0);
    });

    test('con permiso guarda puntos y respeta el intervalo minimo', () async {
      final service = build();
      await service.start(userId: 'U1');

      source.last.add(gps(-12.0967, -77.0347));
      await pump();
      now = now.add(const Duration(seconds: 20)); // dentro del intervalo
      source.last.add(gps(-12.0968, -77.0348));
      await pump();
      now = now.add(const Duration(seconds: 61));
      source.last.add(gps(-12.0969, -77.0349));
      await pump();

      final points = await service.storedPoints();
      expect(points, hasLength(2));
      expect(points.first.userId, 'U1');
      expect(points.first.permission, 'always');
    });

    test('start es idempotente: no abre dos suscripciones', () async {
      final service = build();
      await service.start(userId: 'U1');
      final second = await service.start(userId: 'U1');

      expect(second, TrackingStartResult.alreadyTracking);
      expect(source.opened, 1);
    });

    test('pausa deja de recoger y reanudar vuelve a hacerlo', () async {
      final service = build();
      await service.start(userId: 'U1');
      await service.pause();

      expect(service.isPaused, isTrue);
      expect(source.last.hasListener, isFalse);

      await service.resume();
      expect(service.isTracking, isTrue);
      expect(source.opened, 2);
      source.last.add(gps(-12.0, -77.0));
      await pump();
      expect(await service.storedPoints(), hasLength(1));
    });

    test('stop detiene por completo y no recoge mas puntos', () async {
      final service = build();
      await service.start(userId: 'U1');
      source.last.add(gps(-12.0, -77.0));
      await pump();

      await service.stop();
      await pump();

      expect(service.isTracking, isFalse);
      expect(service.trackedUserId, isNull);
      expect(source.last.hasListener, isFalse);
      // lo pendiente se envio al detener
      expect((await service.storedPoints()).every((p) => p.isSynced), isTrue);
    });

    test('permiso retirado a mitad de jornada: no guarda y se pausa', () async {
      final service = build();
      await service.start(userId: 'U1');

      permissions.current = const PermissionSnapshot(
        location: LocationAccess.denied,
      );
      source.last.add(gps(-12.0, -77.0));
      await pump();

      expect(await service.storedPoints(), isEmpty);
      expect(service.isPaused, isTrue);
      expect(service.lastError.value, isNotNull);
    });

    test('error de GPS: reintenta y reabre la fuente', () async {
      final service = build(retry: const Duration(milliseconds: 30));
      await service.start(userId: 'U1');

      source.last.addError(StateError('sin senal'));
      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(source.opened, greaterThanOrEqualTo(2));
      expect(service.isTracking, isTrue);

      source.last.add(gps(-12.0, -77.0));
      await pump();
      expect(service.lastError.value, isNull);
      expect(await service.storedPoints(), hasLength(1));
    });

    test(
      'sin internet los puntos quedan pendientes y se envian al volver',
      () async {
        SharedPreferences.setMockInitialValues({});
        final connectivity = ConnectivityService();
        connectivity.setSimulatedOffline(true);
        final service = build(connectivity: connectivity);
        await service.start(userId: 'U1');

        source.last.add(gps(-12.0, -77.0));
        await pump();
        expect(uploads, isEmpty);
        expect((await service.storedPoints()).single.isSynced, isFalse);

        connectivity.setSimulatedOffline(false);
        await pump();

        expect(uploads, hasLength(1));
        expect((await service.storedPoints()).single.isSynced, isTrue);
      },
    );

    test(
      'el tope de cola descarta primero los ya sincronizados y antiguos',
      () async {
        final service = build(maxQueued: 3);
        await service.start(userId: 'U1');

        for (var i = 0; i < 5; i++) {
          now = now.add(const Duration(minutes: 2));
          source.last.add(gps(-12.0 + i / 1000, -77.0));
          await pump();
        }

        final points = await service.storedPoints();
        expect(points.length, lessThanOrEqualTo(3));
        // se conservan los mas recientes
        expect(points.last.latitude, closeTo(-12.0 + 4 / 1000, 1e-9));
      },
    );
  });

  group('AttendanceTrackingService (fases de la jornada)', () {
    late BackgroundLocationService location;
    late AttendanceTrackingService tracking;

    setUp(() {
      location = build();
      tracking = AttendanceTrackingService(
        location: location,
        permissions: permissions,
        store: store,
      );
    });

    test(
      'entrada inicia; refrigerio pausa; fin reanuda; salida detiene',
      () async {
        await tracking.onPhaseChanged(userId: 'U1', phase: ShiftPhase.working);
        expect(location.isTracking, isTrue);

        await tracking.onPhaseChanged(userId: 'U1', phase: ShiftPhase.onLunch);
        expect(location.isPaused, isTrue);

        await tracking.onPhaseChanged(userId: 'U1', phase: ShiftPhase.resumed);
        expect(location.isTracking, isTrue);

        await tracking.onPhaseChanged(
          userId: 'U1',
          phase: ShiftPhase.completed,
        );
        expect(location.isTracking, isFalse);
        expect(location.trackedUserId, isNull);
      },
    );

    test('repetir la misma fase no duplica el seguimiento', () async {
      for (var i = 0; i < 3; i++) {
        await tracking.onPhaseChanged(userId: 'U1', phase: ShiftPhase.working);
      }
      expect(source.opened, 1);
    });

    test('sin jornada iniciada no hay seguimiento', () async {
      await tracking.onPhaseChanged(userId: 'U1', phase: ShiftPhase.notStarted);
      expect(source.opened, 0);
      expect(location.isTracking, isFalse);
    });

    test('con politica keepTracking el refrigerio no pausa', () async {
      final keep = AttendanceTrackingService(
        location: location,
        permissions: permissions,
        store: store,
        lunchPolicy: LunchTrackingPolicy.keepTracking,
      );
      await keep.onPhaseChanged(userId: 'U1', phase: ShiftPhase.working);
      await keep.onPhaseChanged(userId: 'U1', phase: ShiftPhase.onLunch);
      expect(location.isTracking, isTrue);
    });

    test('otro usuario corta el seguimiento anterior', () async {
      await tracking.onPhaseChanged(userId: 'U1', phase: ShiftPhase.working);
      await tracking.onPhaseChanged(userId: 'U2', phase: ShiftPhase.working);
      expect(location.trackedUserId, 'U2');
    });

    test('cerrar sesion detiene el seguimiento', () async {
      await tracking.onPhaseChanged(userId: 'U1', phase: ShiftPhase.working);
      await tracking.onSignedOut();
      expect(location.isTracking, isFalse);
    });

    test('ofrece "Siempre" una sola vez, tras "Al usar la app"', () async {
      permissions.current = const PermissionSnapshot(
        location: LocationAccess.whileInUse,
      );
      await tracking.onPhaseChanged(userId: 'U1', phase: ShiftPhase.working);
      await tracking.onPhaseChanged(userId: 'U1', phase: ShiftPhase.onLunch);
      await tracking.onPhaseChanged(userId: 'U1', phase: ShiftPhase.resumed);

      expect(permissions.alwaysRequests, 1);
      expect(store.alwaysOffered, isTrue);
    });

    test('con "Siempre" ya concedido no vuelve a pedirlo', () async {
      await tracking.onPhaseChanged(userId: 'U1', phase: ShiftPhase.working);
      expect(permissions.alwaysRequests, 0);
    });

    test('con permiso denegado la entrada no inicia el GPS', () async {
      permissions.current = const PermissionSnapshot(
        location: LocationAccess.denied,
      );
      await tracking.onPhaseChanged(userId: 'U1', phase: ShiftPhase.working);
      expect(source.opened, 0);
    });
  });

  group('Integracion con AttendanceCubit', () {
    late AttendanceCubit cubit;
    late AttendanceRepository repository;
    late AttendanceTrackingService tracking;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repository = AttendanceRepository(StorageService(prefs));
      tracking = AttendanceTrackingService(
        location: build(),
        permissions: permissions,
        store: store,
      );
      cubit = AttendanceCubit(
        attendanceRepository: repository,
        trackingService: tracking,
      );
    });

    Future<void> punch(AttendanceType type) => cubit.registerPunch(
      userId: 'TRACK_USER',
      type: type,
      branchId: 'BR-01',
      branchName: 'Sede',
      latitude: -12.0967,
      longitude: -77.0347,
      distanceToGeozone: 5,
      isInsideGeozone: true,
    );

    test(
      'la jornada gobierna el seguimiento y cada marca guarda el permiso',
      () async {
        await punch(AttendanceType.checkIn);
        await pump();
        expect(tracking.location.isTracking, isTrue);

        await punch(AttendanceType.lunchStart);
        await pump();
        expect(tracking.location.isPaused, isTrue);

        await punch(AttendanceType.lunchEnd);
        await pump();
        expect(tracking.location.isTracking, isTrue);

        await punch(AttendanceType.checkOut);
        await pump();
        expect(tracking.location.isTracking, isFalse);

        final records = await repository.getTodayRecords('TRACK_USER');
        expect(records, hasLength(4));
        expect(records.every((r) => r.locationPermission == 'always'), isTrue);
      },
    );

    test(
      'al abrir la app con la jornada en curso retoma el seguimiento',
      () async {
        await punch(AttendanceType.checkIn);
        await pump();
        await tracking.location
            .stop(); // la app se cerro o el telefono se reinicio
        expect(tracking.location.isTracking, isFalse);

        await cubit.loadDailyAttendance('TRACK_USER');
        await pump();

        expect(tracking.location.isTracking, isTrue);
      },
    );
  });
}
