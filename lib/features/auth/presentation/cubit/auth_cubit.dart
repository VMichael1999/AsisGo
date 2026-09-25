import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/security/session_timer_manager.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/live_activity_service.dart';
import '../../data/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  final SessionTimerManager _sessionTimer = SessionTimerManager();

  AuthCubit(this._authRepository) : super(AuthInitial());

  Future<void> checkAuthStatus() async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        _startSessionTimer();
        emit(Authenticated(user));
      } else {
        await LiveActivityService().endShiftActivity();
        emit(const Unauthenticated());
      }
    } catch (e) {
      await LiveActivityService().endShiftActivity();
      emit(const Unauthenticated());
    }
  }

  Future<void> login({required String email, required String password}) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.loginWithCredentials(
        email: email,
        password: password,
      );
      _startSessionTimer();
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError('Error al iniciar sesión: ${e.toString()}'));
    }
  }

  Future<void> loginWithBiometrics() async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.loginWithBiometrics();
      _startSessionTimer();
      emit(Authenticated(user));
    } catch (e) {
      emit(const AuthError('No se pudo validar la biometría. Intente con contraseña.'));
    }
  }

  void _startSessionTimer() {
    // Sesión perenne sin expiración automática de tiempo por inactividad
  }

  Future<void> expireSession() async {
    _sessionTimer.cancel();
    await NotificationService().cancelShiftNotification();
    await LiveActivityService().endShiftActivity();
    final currentState = state;
    if (currentState is Authenticated) {
      emit(AuthSessionExpired(
        user: currentState.user,
        message:
            'El inicio de sesión ha expirado, vuelve a iniciar sesión nuevamente.',
      ));
    } else {
      await _authRepository.logout();
      emit(const Unauthenticated(
        'El inicio de sesión ha expirado, vuelve a iniciar sesión nuevamente.',
      ));
    }
  }

  Future<void> confirmLogoutAfterExpiration() async {
    _sessionTimer.cancel();
    await NotificationService().cancelShiftNotification();
    await LiveActivityService().endShiftActivity();
    await _authRepository.logout();
    emit(const Unauthenticated(
      'El inicio de sesión ha expirado, vuelve a iniciar sesión nuevamente.',
    ));
  }

  Future<void> logout() async {
    _sessionTimer.cancel();
    await NotificationService().cancelShiftNotification();
    await LiveActivityService().endShiftActivity();
    emit(AuthLoading());
    await _authRepository.logout();
    emit(const Unauthenticated());
  }

  @override
  Future<void> close() {
    _sessionTimer.cancel();
    return super.close();
  }
}
