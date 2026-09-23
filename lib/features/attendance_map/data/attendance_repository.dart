import 'package:uuid/uuid.dart';
import '../domain/attendance_record.dart';
import '../domain/shift_phase.dart';
import '../../../core/contracts/i_attendance_repository.dart';
import '../../../core/services/storage_service.dart';

class AttendanceRepository implements IAttendanceRepository {
  final StorageService _storageService;
  final _uuid = const Uuid();

  AttendanceRepository(this._storageService);

  List<AttendanceRecord> _cachedRecords = [];
  bool _initialized = false;

  @override
  Future<void> init() async {
    if (_initialized) return;
    final stored = _storageService.getAttendanceRecords();
    if (stored.isNotEmpty) {
      _cachedRecords = stored.map((json) => AttendanceRecord.fromJson(json)).toList();
    } else {
      // Sembrar datos historicos iniciales para dias laborales recientes
      _cachedRecords = _generateInitialHistory();
      await _persist();
    }
    _initialized = true;
  }

  Future<void> _persist() async {
    await _storageService.saveAttendanceRecords(
      _cachedRecords.map((r) => r.toJson()).toList(),
    );
  }

  @override
  Future<List<AttendanceRecord>> getAllRecords(String userId) async {
    await init();
    return _cachedRecords.where((r) => r.userId == userId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<List<AttendanceRecord>> getTodayRecords(String userId) async {
    await init();
    final now = DateTime.now();
    return _cachedRecords.where((r) {
      return r.userId == userId &&
          r.timestamp.year == now.year &&
          r.timestamp.month == now.month &&
          r.timestamp.day == now.day;
    }).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  @override
  Future<List<AttendanceRecord>> getRecordsForDate(String userId, DateTime date) async {
    await init();
    return _cachedRecords.where((r) {
      return r.userId == userId &&
          r.timestamp.year == date.year &&
          r.timestamp.month == date.month &&
          r.timestamp.day == date.day;
    }).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  @override
  Future<ShiftPhase> getCurrentShiftPhase(String userId) async {
    final todayRecords = await getTodayRecords(userId);
    if (todayRecords.isEmpty) {
      return ShiftPhase.notStarted;
    }

    final hasCheckIn = todayRecords.any((r) => r.type == AttendanceType.checkIn);
    final hasLunchStart = todayRecords.any((r) => r.type == AttendanceType.lunchStart);
    final hasLunchEnd = todayRecords.any((r) => r.type == AttendanceType.lunchEnd);
    final hasCheckOut = todayRecords.any((r) => r.type == AttendanceType.checkOut);

    if (hasCheckOut) {
      return ShiftPhase.completed;
    } else if (hasLunchEnd) {
      return ShiftPhase.resumed;
    } else if (hasLunchStart) {
      return ShiftPhase.onLunch;
    } else if (hasCheckIn) {
      return ShiftPhase.working;
    }

    return ShiftPhase.notStarted;
  }

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
  }) async {
    await init();
    final record = AttendanceRecord(
      id: _uuid.v4(),
      userId: userId,
      type: type,
      timestamp: DateTime.now(),
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
      isSynced: true,
    );

    _cachedRecords.add(record);
    await _persist();
    return record;
  }

  List<AttendanceRecord> _generateInitialHistory() {
    final list = <AttendanceRecord>[];
    final now = DateTime.now();
    const userId = 'USR-001';

    // Generate records for previous 5 working days
    for (int i = 5; i >= 1; i--) {
      final day = now.subtract(Duration(days: i));
      // Skip weekends
      if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
        continue;
      }

      final checkInTime = DateTime(day.year, day.month, day.day, 8, 28 + (i % 5));
      final lunchStartTime = DateTime(day.year, day.month, day.day, 13, 0 + (i % 3));
      final lunchEndTime = DateTime(day.year, day.month, day.day, 13, 58 + (i % 4));
      final checkOutTime = DateTime(day.year, day.month, day.day, 18, 5 + (i % 10));

      list.addAll([
        AttendanceRecord(
          id: _uuid.v4(),
          userId: userId,
          type: AttendanceType.checkIn,
          timestamp: checkInTime,
          branchId: 'BR-01',
          branchName: 'Sede Central Corporativa',
          geozoneId: 'GZ-01',
          geozoneName: 'Entrada Principal & Recepción',
          latitude: -12.0967,
          longitude: -77.0347,
          distanceToGeozone: 14.5,
          isInsideGeozone: true,
          note: i == 1 ? 'Inicio puntual de jornada' : null,
        ),
        AttendanceRecord(
          id: _uuid.v4(),
          userId: userId,
          type: AttendanceType.lunchStart,
          timestamp: lunchStartTime,
          branchId: 'BR-01',
          branchName: 'Sede Central Corporativa',
          geozoneId: 'GZ-01',
          geozoneName: 'Entrada Principal & Recepción',
          latitude: -12.0967,
          longitude: -77.0347,
          distanceToGeozone: 18.0,
          isInsideGeozone: true,
        ),
        AttendanceRecord(
          id: _uuid.v4(),
          userId: userId,
          type: AttendanceType.lunchEnd,
          timestamp: lunchEndTime,
          branchId: 'BR-01',
          branchName: 'Sede Central Corporativa',
          geozoneId: 'GZ-01',
          geozoneName: 'Entrada Principal & Recepción',
          latitude: -12.0967,
          longitude: -77.0347,
          distanceToGeozone: 16.2,
          isInsideGeozone: true,
        ),
        AttendanceRecord(
          id: _uuid.v4(),
          userId: userId,
          type: AttendanceType.checkOut,
          timestamp: checkOutTime,
          branchId: 'BR-01',
          branchName: 'Sede Central Corporativa',
          geozoneId: 'GZ-01',
          geozoneName: 'Entrada Principal & Recepción',
          latitude: -12.0967,
          longitude: -77.0347,
          distanceToGeozone: 12.0,
          isInsideGeozone: true,
          note: 'Cierre de sprint y revisión técnica',
        ),
      ]);
    }

    return list;
  }

  @override
  Future<void> clearAll() async {
    _cachedRecords.clear();
    await _persist();
  }
}
