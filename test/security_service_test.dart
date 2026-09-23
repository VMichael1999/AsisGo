import 'package:flutter_test/flutter_test.dart';
import 'package:asisgo/core/contracts/i_storage_service.dart';
import 'package:asisgo/core/security/security_check_result.dart';
import 'package:asisgo/core/security/security_service.dart';
import 'package:asisgo/core/security/session_timer_manager.dart';
import 'package:asisgo/features/auth/data/auth_repository.dart';
import 'package:asisgo/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:asisgo/features/auth/presentation/cubit/auth_state.dart';

class FakeStorageService implements IStorageService {
  bool _mockProtection = false;

  @override
  bool isMockProtectionEnabled() => _mockProtection;

  @override
  Future<void> setMockProtectionEnabled(bool enabled) async {
    _mockProtection = enabled;
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
  Future<void> setNotificationsEnabled(bool enabled) async {}
}

void main() {
  group('SecurityService & Anti-Mock GPS Tests', () {
    late FakeStorageService fakeStorage;
    late SecurityService securityService;

    setUp(() async {
      fakeStorage = FakeStorageService();
      securityService = SecurityService(fakeStorage);
      await securityService.init();
    });

    test('Initial state: Mock protection is enabled by default for strict security', () {
      expect(securityService.isMockProtectionEnabled, isTrue);
    });

    test('When protection is disabled (Sandbox/Dev mode), mocked location is permitted', () async {
      await securityService.setMockProtectionEnabled(false);
      final result = securityService.evaluateLocationSecurity(
        isMocked: true,
        accuracy: 5.0,
        latitude: -12.0967,
        longitude: -77.0347,
      );

      expect(result.isSecure, isTrue);
      expect(result.violationType, SecurityViolationType.none);
      expect(result.title, contains('Sandbox'));
    });

    test('When protection is enabled (Strict/Production mode), mocked location is blocked', () async {
      await securityService.setMockProtectionEnabled(true);
      expect(securityService.isMockProtectionEnabled, isTrue);

      final result = securityService.evaluateLocationSecurity(
        isMocked: true,
        accuracy: 5.0,
        latitude: -12.0967,
        longitude: -77.0347,
      );

      expect(result.isSecure, isFalse);
      expect(result.violationType, SecurityViolationType.mockLocationDetected);
      expect(result.title, contains('Suplantación de GPS Detectada'));
    });

    test('When protection is enabled, invalid/zero accuracy is flagged as anomaly', () async {
      await securityService.setMockProtectionEnabled(true);

      final result = securityService.evaluateLocationSecurity(
        isMocked: false,
        accuracy: 0.0,
        latitude: -12.0967,
        longitude: -77.0347,
      );

      expect(result.isSecure, isFalse);
      expect(result.violationType, SecurityViolationType.suspiciousAccuracy);
    });

    test('When protection is enabled and location is genuine hardware GPS, result is clean', () async {
      await securityService.setMockProtectionEnabled(true);

      final result = securityService.evaluateLocationSecurity(
        isMocked: false,
        accuracy: 8.5,
        latitude: -12.0967,
        longitude: -77.0347,
      );

      expect(result.isSecure, isTrue);
      expect(result.violationType, SecurityViolationType.none);
    });
  });

  group('SessionTimerManager Tests', () {
    test('Session timer calculates remaining time and triggers timeout', () async {
      final manager = SessionTimerManager();
      bool timedOut = false;

      manager.startSession(() {
        timedOut = true;
      }, customDuration: const Duration(milliseconds: 50));

      expect(manager.isActive, isTrue);
      expect(manager.remainingTime, isNotNull);

      await Future.delayed(const Duration(milliseconds: 70));
      expect(timedOut, isTrue);
      expect(manager.isActive, isFalse);
    });

    test('Cancel terminates session countdown', () {
      final manager = SessionTimerManager();
      bool timedOut = false;

      manager.startSession(() {
        timedOut = true;
      }, customDuration: const Duration(seconds: 10));

      expect(manager.isActive, isTrue);
      manager.cancel();
      expect(manager.isActive, isFalse);
      expect(timedOut, isFalse);
    });
  });

  group('AuthCubit Session Expiration & Soft-Logout Tests', () {
    late FakeStorageService fakeStorage;
    late AuthRepository authRepository;
    late AuthCubit authCubit;

    setUp(() {
      fakeStorage = FakeStorageService();
      authRepository = AuthRepository(fakeStorage);
      authCubit = AuthCubit(authRepository);
    });

    tearDown(() {
      authCubit.close();
    });

    test('When session expires for Authenticated user, emits AuthSessionExpired without abrupt logout', () async {
      await authCubit.login(
        email: AuthRepository.demoUsers.first.email,
        password: 'password123',
      );

      expect(authCubit.state, isA<Authenticated>());
      final authedUser = (authCubit.state as Authenticated).user;

      await authCubit.expireSession();

      expect(authCubit.state, isA<AuthSessionExpired>());
      final expiredState = authCubit.state as AuthSessionExpired;
      expect(expiredState.user.id, equals(authedUser.id));
      expect(authCubit.state.currentUser, equals(authedUser));
      expect(expiredState.message, contains('expirado'));
    });

    test('When user confirms logout after expiration dialog, emits Unauthenticated', () async {
      await authCubit.login(
        email: AuthRepository.demoUsers.first.email,
        password: 'password123',
      );

      await authCubit.expireSession();
      expect(authCubit.state, isA<AuthSessionExpired>());

      await authCubit.confirmLogoutAfterExpiration();
      expect(authCubit.state, isA<Unauthenticated>());
      expect(authCubit.state.currentUser, isNull);
    });

    test('checkAuthStatus does not automatically log in when no session exists', () async {
      await authCubit.checkAuthStatus();
      expect(authCubit.state, isA<Unauthenticated>());
      expect(authCubit.state.currentUser, isNull);
    });
  });
}
