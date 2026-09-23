abstract class IStorageService {
  Future<void> saveUserSession(Map<String, dynamic> userJson);
  Map<String, dynamic>? getUserSession();
  Future<void> clearUserSession();

  Future<void> saveAttendanceRecords(List<Map<String, dynamic>> records);
  List<Map<String, dynamic>> getAttendanceRecords();

  Future<void> saveShiftStatus(String status);
  String? getShiftStatus();

  Future<void> setBiometricEnabled(bool enabled);
  bool isBiometricEnabled();

  Future<void> setNotificationsEnabled(bool enabled);
  bool isNotificationsEnabled();

  Future<void> setMockProtectionEnabled(bool enabled);
  bool isMockProtectionEnabled();
}
