import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/security/session_timer_manager.dart';
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
        emit(const Unauthenticated());
      }
    } catch (e) {
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
    _sessionTimer.startSession(() {
      expireSession();
    });
  }

  Future<void> expireSession() async {
    _sessionTimer.cancel();
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
    await _authRepository.logout();
    emit(const Unauthenticated(
      'El inicio de sesión ha expirado, vuelve a iniciar sesión nuevamente.',
    ));
  }

  Future<void> logout() async {
    _sessionTimer.cancel();
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
