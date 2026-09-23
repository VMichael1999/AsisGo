import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:asisgo/core/services/location_service.dart';
import 'package:asisgo/core/services/storage_service.dart';
import 'package:asisgo/features/attendance_map/data/attendance_repository.dart';
import 'package:asisgo/features/attendance_map/data/branch_repository.dart';
import 'package:asisgo/features/attendance_map/domain/shift_phase.dart';
import 'package:asisgo/features/attendance_map/presentation/cubit/attendance_cubit.dart';
import 'package:asisgo/features/attendance_map/presentation/cubit/attendance_state.dart';
import 'package:asisgo/features/attendance_map/presentation/cubit/location_cubit.dart';
import 'package:asisgo/features/attendance_map/presentation/cubit/location_state.dart';
import 'package:asisgo/core/security/security_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;
  late AttendanceRepository attendanceRepository;
  late LocationService locationService;
  late BranchRepository branchRepository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storageService = StorageService(prefs);
    attendanceRepository = AttendanceRepository(storageService);
    locationService = LocationService();
    branchRepository = BranchRepository(locationService);
  });

  group('Geozone & Location Calculation Tests', () {
    test('User exactly at Sede Central is evaluated as INSIDE geozone', () {
      final sede = branchRepository.getAllBranches().first;
      final gz = sede.geozones.first;

      final result = branchRepository.evaluateLocation(gz.coordinates);
      expect(result.isInside, isTrue);
      expect(result.distanceMeters, lessThanOrEqualTo(gz.radiusMeters));
    });

    test('User far away (e.g. 10km away) is evaluated as OUTSIDE geozone', () {
      const farLocation = LatLng(-12.0000, -77.0000);
      final result = branchRepository.evaluateLocation(farLocation);
      expect(result.isInside, isFalse);
      expect(result.distanceMeters, greaterThan(100.0));
    });
  });

  group('AttendanceCubit Shift Lifecycle State Machine', () {
    test('Initial phase starts at notStarted for new user', () async {
      final cubit = AttendanceCubit(attendanceRepository: attendanceRepository);
      await cubit.loadDailyAttendance('NEW_TEST_USER');

      expect(cubit.state, isA<AttendanceLoaded>());
      final loaded = cubit.state as AttendanceLoaded;
      expect(loaded.currentPhase, equals(ShiftPhase.notStarted));
    });

    test('Full sequence: checkIn -> lunchStart -> lunchEnd -> checkOut', () async {
      final cubit = AttendanceCubit(attendanceRepository: attendanceRepository);
      const testUser = 'USR-TEST-LIFECYCLE';
      final branch = branchRepository.getAllBranches().first;
      final gz = branch.geozones.first;

      // Paso 1: Entrada laboral
      await cubit.registerPunch(
        userId: testUser,
        type: AttendanceType.checkIn,
        branchId: branch.id,
        branchName: branch.name,
        geozoneId: gz.id,
        geozoneName: gz.name,
        latitude: gz.latitude,
        longitude: gz.longitude,
        distanceToGeozone: 10.0,
        isInsideGeozone: true,
        note: 'Entrada puntual',
      );
      expect((cubit.state as AttendanceLoaded).currentPhase, equals(ShiftPhase.working));

      // Paso 2: Inicio de refrigerio
      await cubit.registerPunch(
        userId: testUser,
        type: AttendanceType.lunchStart,
        branchId: branch.id,
        branchName: branch.name,
        geozoneId: gz.id,
        geozoneName: gz.name,
        latitude: gz.latitude,
        longitude: gz.longitude,
        distanceToGeozone: 10.0,
        isInsideGeozone: true,
      );
      expect((cubit.state as AttendanceLoaded).currentPhase, equals(ShiftPhase.onLunch));

      // Paso 3: Retorno de refrigerio
      await cubit.registerPunch(
        userId: testUser,
        type: AttendanceType.lunchEnd,
        branchId: branch.id,
        branchName: branch.name,
        geozoneId: gz.id,
        geozoneName: gz.name,
        latitude: gz.latitude,
        longitude: gz.longitude,
        distanceToGeozone: 10.0,
        isInsideGeozone: true,
      );
      expect((cubit.state as AttendanceLoaded).currentPhase, equals(ShiftPhase.resumed));

      // Paso 4: Salida de jornada
      await cubit.registerPunch(
        userId: testUser,
        type: AttendanceType.checkOut,
        branchId: branch.id,
        branchName: branch.name,
        geozoneId: gz.id,
        geozoneName: gz.name,
        latitude: gz.latitude,
        longitude: gz.longitude,
        distanceToGeozone: 10.0,
        isInsideGeozone: true,
        note: 'Fin de jornada con reporte enviado',
      );
      expect((cubit.state as AttendanceLoaded).currentPhase, equals(ShiftPhase.completed));
    });

    test('Record outside geozone retains isInsideGeozone as false for audit', () async {
      final cubit = AttendanceCubit(attendanceRepository: attendanceRepository);
      const testUser = 'USR-TEST-OUTSIDE';
      final branch = branchRepository.getAllBranches().first;

      await cubit.registerPunch(
        userId: testUser,
        type: AttendanceType.checkIn,
        branchId: branch.id,
        branchName: branch.name,
        latitude: -12.0000,
        longitude: -77.0000,
        distanceToGeozone: 9500.0,
        isInsideGeozone: false,
        note: 'Intento con excepción',
      );

      final state = cubit.state as AttendanceLoaded;
      expect(state.lastRecord?.isInsideGeozone, isFalse);
      expect(state.lastRecord?.distanceToGeozone, equals(9500.0));
    });
  });

  group('LocationCubit Multi-Company & Branch Explorer Navigation', () {
    test('Repository contains 5 corporate companies with distinct branches and geozones', () {
      final companies = branchRepository.getAllCompanies();
      expect(companies.length, equals(5));

      final shortNames = companies.map((c) => c.shortName).toList();
      expect(shortNames, containsAll(['BCP', 'BBVA', 'Interbank', 'Scotiabank', 'Banco de la Nación']));

      for (final comp in companies) {
        expect(comp.branches, isNotEmpty);
        for (final br in comp.branches) {
          expect(br.geozones, isNotEmpty);
          expect(br.companyId, equals(comp.id));
        }
      }
    });

    test('Branch Explorer starts inactive and toggles active within selected company', () async {
      final securityService = SecurityService(storageService);
      final locCubit = LocationCubit(
        locationService: locationService,
        branchRepository: branchRepository,
        securityService: securityService,
      );

      locCubit.simulateUserPosition(const LatLng(-12.0967, -77.0347));
      expect(locCubit.state, isA<LocationLoaded>());
      var state = locCubit.state as LocationLoaded;
      expect(state.isBranchExplorerActive, isFalse);
      expect(state.selectedBranchIndex, equals(0));
      expect(state.selectedCompany.shortName, equals('BCP'));

      locCubit.toggleBranchExplorer();
      state = locCubit.state as LocationLoaded;
      expect(state.isBranchExplorerActive, isTrue);

      locCubit.nextBranch();
      state = locCubit.state as LocationLoaded;
      expect(state.selectedBranchIndex, equals(1));
      expect(state.selectedBranch.id, equals('BR-BCP-02'));

      locCubit.previousBranch();
      state = locCubit.state as LocationLoaded;
      expect(state.selectedBranchIndex, equals(0));
      expect(state.selectedBranch.id, equals('BR-01'));

      locCubit.exitBranchExplorer();
      state = locCubit.state as LocationLoaded;
      expect(state.isBranchExplorerActive, isFalse);

      await locCubit.close();
    });

    test('nextBranch wraps around ONLY within selected company branches (never bleeds into other companies)', () async {
      final securityService = SecurityService(storageService);
      final locCubit = LocationCubit(
        locationService: locationService,
        branchRepository: branchRepository,
        securityService: securityService,
      );

      locCubit.simulateUserPosition(const LatLng(-12.0967, -77.0347));
      var state = locCubit.state as LocationLoaded;

      final bcpBranchesCount = state.companyBranches.length;
      expect(bcpBranchesCount, equals(4));

      // Recorrer todas las sedes del BCP
      for (int i = 0; i < bcpBranchesCount; i++) {
        expect(state.activeMapBranch.companyId, equals('EMP-BCP'));
        locCubit.nextBranch();
        state = locCubit.state as LocationLoaded;
      }

      // Despues de 4 llamadas a nextBranch, reinicia al indice 0 del BCP
      expect(state.selectedBranchIndex, equals(0));
      expect(state.activeMapBranch.id, equals('BR-01'));
      expect(state.activeMapBranch.companyId, equals('EMP-BCP'));

      await locCubit.close();
    });

    test('selectCompany switches company and isolates its first branch', () async {
      final securityService = SecurityService(storageService);
      final locCubit = LocationCubit(
        locationService: locationService,
        branchRepository: branchRepository,
        securityService: securityService,
      );

      locCubit.simulateUserPosition(const LatLng(-12.0967, -77.0347));
      var state = locCubit.state as LocationLoaded;
      expect(state.selectedCompany.shortName, equals('BCP'));

      final bbvaCompany = state.allCompanies.firstWhere((c) => c.shortName == 'BBVA');
      locCubit.selectCompany(bbvaCompany);

      state = locCubit.state as LocationLoaded;
      expect(state.selectedCompany.shortName, equals('BBVA'));
      expect(state.companyBranches.length, equals(4));
      expect(state.activeMapBranch.id, equals('BR-BBVA-01'));
      expect(state.activeMapBranch.companyId, equals('EMP-BBVA'));

      // Siguiente sede dentro del BBVA
      locCubit.nextBranch();
      state = locCubit.state as LocationLoaded;
      expect(state.selectedBranchIndex, equals(1));
      expect(state.activeMapBranch.id, equals('BR-BBVA-02'));
      expect(state.activeMapBranch.companyId, equals('EMP-BBVA'));

      await locCubit.close();
    });

    test('selectBranch isolates specific branch in activeMapBranch and updates index', () async {
      final securityService = SecurityService(storageService);
      final locCubit = LocationCubit(
        locationService: locationService,
        branchRepository: branchRepository,
        securityService: securityService,
      );

      locCubit.simulateUserPosition(const LatLng(-12.0967, -77.0347));
      var state = locCubit.state as LocationLoaded;

      // Seleccionar sede 2 del BCP (La Molina)
      final branch2 = state.companyBranches[1];
      locCubit.selectBranch(branch2);

      state = locCubit.state as LocationLoaded;
      expect(state.isolatedBranchId, equals(branch2.id));
      expect(state.activeMapBranch.id, equals(branch2.id));
      expect(state.selectedBranchIndex, equals(1));
      expect(state.isBranchExplorerActive, isTrue);

      // Seleccionar sede 3 del BCP (Miraflores)
      final branch3 = state.companyBranches[2];
      locCubit.selectBranch(branch3);

      state = locCubit.state as LocationLoaded;
      expect(state.isolatedBranchId, equals(branch3.id));
      expect(state.activeMapBranch.id, equals(branch3.id));
      expect(state.selectedBranchIndex, equals(2));

      await locCubit.close();
    });
  });
}
