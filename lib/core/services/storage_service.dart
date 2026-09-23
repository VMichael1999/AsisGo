import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_security_config.dart';
import '../constants/app_constants.dart';
import '../contracts/i_storage_service.dart';

class StorageService implements IStorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // --- User Session ---
  @override
  Future<void> saveUserSession(Map<String, dynamic> userJson) async {
    await _prefs.setString(AppConstants.keyUserSession, jsonEncode(userJson));
  }

  @override
  Map<String, dynamic>? getUserSession() {
    final raw = _prefs.getString(AppConstants.keyUserSession);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearUserSession() async {
    await _prefs.remove(AppConstants.keyUserSession);
  }

  // --- Attendance Records ---
  @override
  Future<void> saveAttendanceRecords(List<Map<String, dynamic>> records) async {
    await _prefs.setString(AppConstants.keyAttendanceRecords, jsonEncode(records));
  }

  @override
  List<Map<String, dynamic>> getAttendanceRecords() {
    final raw = _prefs.getString(AppConstants.keyAttendanceRecords);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((item) => item as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Shift Status ---
  @override
  Future<void> saveShiftStatus(String status) async {
    await _prefs.setString(AppConstants.keyShiftStatus, status);
  }

  @override
  String? getShiftStatus() {
    return _prefs.getString(AppConstants.keyShiftStatus);
  }

  // --- Settings ---
  @override
  Future<void> setBiometricEnabled(bool enabled) async {
    await _prefs.setBool(AppConstants.keyBiometricEnabled, enabled);
  }

  @override
  bool isBiometricEnabled() {
    return _prefs.getBool(AppConstants.keyBiometricEnabled) ?? true;
  }

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(AppConstants.keyNotificationsEnabled, enabled);
  }

  @override
  bool isNotificationsEnabled() {
    return _prefs.getBool(AppConstants.keyNotificationsEnabled) ?? true;
  }

  // --- Security & Anti-Mock GPS Protection Flag ---
  @override
  Future<void> setMockProtectionEnabled(bool enabled) async {
    await _prefs.setBool(AppConstants.keyMockProtectionEnabled, enabled);
  }

  @override
  bool isMockProtectionEnabled() {
    return _prefs.getBool(AppConstants.keyMockProtectionEnabled) ??
        AppSecurityConfig.defaultMockProtection;
  }
}
