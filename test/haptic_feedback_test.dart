import 'package:flutter_test/flutter_test.dart';
import 'package:asisgo/core/contracts/i_storage_service.dart';
import 'package:asisgo/core/services/haptic_feedback_service.dart';

class MockStorageService implements IStorageService {
  bool _haptic = true;
  bool _sound = true;

  @override
  bool isHapticEnabled() => _haptic;

  @override
  Future<void> setHapticEnabled(bool enabled) async {
    _haptic = enabled;
  }

  @override
  bool isSoundEnabled() => _sound;

  @override
  Future<void> setSoundEnabled(bool enabled) async {
    _sound = enabled;
  }

  @override
  Future<void> clearUserSession() async {}

  @override
  List<Map<String, dynamic>> getAttendanceRecords() => [];

  @override
  String? getShiftStatus() => null;

  @override
  Map<String, dynamic>? getUserSession() => null;

  @override
  bool isBiometricEnabled() => true;

  @override
  bool isMockProtectionEnabled() => true;

  @override
  bool isNotificationsEnabled() => true;

  @override
  Future<void> saveAttendanceRecords(List<Map<String, dynamic>> records) async {}

  @override
  Future<void> saveShiftStatus(String status) async {}

  @override
  Future<void> saveUserSession(Map<String, dynamic> userJson) async {}

  @override
  Future<void> setBiometricEnabled(bool enabled) async {}

  @override
  Future<void> setMockProtectionEnabled(bool enabled) async {}

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HapticFeedbackService Tests', () {
    late MockStorageService mockStorage;
    late HapticFeedbackService hapticService;

    setUp(() {
      mockStorage = MockStorageService();
      hapticService = HapticFeedbackService(mockStorage);
    });

    test('Initial preferences default to enabled', () {
      expect(hapticService.isHapticEnabled, isTrue);
      expect(hapticService.isSoundEnabled, isTrue);
    });

    test('Toggling haptic and sound preferences updates storage', () async {
      await hapticService.setHapticEnabled(false);
      expect(hapticService.isHapticEnabled, isFalse);
      expect(mockStorage.isHapticEnabled(), isFalse);

      await hapticService.setSoundEnabled(false);
      expect(hapticService.isSoundEnabled, isFalse);
      expect(mockStorage.isSoundEnabled(), isFalse);

      await hapticService.setHapticEnabled(true);
      await hapticService.setSoundEnabled(true);
      expect(hapticService.isHapticEnabled, isTrue);
      expect(hapticService.isSoundEnabled, isTrue);
    });

    test('punchSuccess executes safely without exceptions', () async {
      await expectLater(hapticService.punchSuccess(), completes);
    });

    test('securityAlert executes safely without exceptions', () async {
      await expectLater(hapticService.securityAlert(), completes);
    });

    test('selectionClick executes safely without exceptions', () async {
      await expectLater(hapticService.selectionClick(), completes);
    });

    test('lightImpact executes safely without exceptions', () async {
      await expectLater(hapticService.lightImpact(), completes);
    });

    test('syncCompleted executes safely without exceptions', () async {
      await expectLater(hapticService.syncCompleted(), completes);
    });

    test('Executes safely when feedback is disabled', () async {
      await hapticService.setHapticEnabled(false);
      await hapticService.setSoundEnabled(false);

      await expectLater(hapticService.punchSuccess(), completes);
      await expectLater(hapticService.securityAlert(), completes);
      await expectLater(hapticService.selectionClick(), completes);
      await expectLater(hapticService.lightImpact(), completes);
      await expectLater(hapticService.syncCompleted(), completes);
    });

    test('Standalone instance without storage service uses fallback values', () async {
      final standalone = HapticFeedbackService();
      expect(standalone.isHapticEnabled, isTrue);
      expect(standalone.isSoundEnabled, isTrue);

      await standalone.setHapticEnabled(false);
      await standalone.setSoundEnabled(false);
      expect(standalone.isHapticEnabled, isFalse);
      expect(standalone.isSoundEnabled, isFalse);

      await expectLater(standalone.punchSuccess(), completes);
    });
  });
}
