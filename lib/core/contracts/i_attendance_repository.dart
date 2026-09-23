import '../../features/attendance_map/domain/attendance_record.dart';
import '../../features/attendance_map/domain/shift_phase.dart';

abstract class IAttendanceRepository {
  Future<void> init();

  Future<List<AttendanceRecord>> getAllRecords(String userId);

  Future<List<AttendanceRecord>> getTodayRecords(String userId);

  Future<List<AttendanceRecord>> getRecordsForDate(String userId, DateTime date);

  Future<ShiftPhase> getCurrentShiftPhase(String userId);

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
  });

  Future<void> clearAll();
}
