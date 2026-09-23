class AppConstants {
  static const String appName = 'AsisGo';
  static const String appVersion = '1.0.0';
  
  // Claves de almacenamiento local
  static const String keyUserSession = 'asisgo_user_session';
  static const String keyAttendanceRecords = 'asisgo_attendance_records';
  static const String keyShiftStatus = 'asisgo_shift_status';
  static const String keyBiometricEnabled = 'asisgo_biometric_enabled';
  static const String keyNotificationsEnabled = 'asisgo_notifications_enabled';
  static const String keyMockProtectionEnabled = 'asisgo_mock_protection_enabled';

  // Seguridad y tiempo de expiracion de sesion
  static const int sessionTimeoutMinutes = 10;
  
  // Umbrales de geocercas y precision GPS
  static const double defaultGeofenceRadiusMeters = 100.0;
  static const int minGpsAccuracyMeters = 50;
  
  // Horarios estandar de turno
  static const String standardShiftStart = '08:30';
  static const String standardShiftEnd = '18:00';
  static const int lunchDurationMinutes = 60;
}
