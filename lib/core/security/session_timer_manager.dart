import 'dart:async';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

class SessionTimerManager {
  static final SessionTimerManager _instance = SessionTimerManager._internal();
  factory SessionTimerManager() => _instance;
  SessionTimerManager._internal();

  Timer? _timer;
  DateTime? _expiresAt;
  VoidCallback? _onTimeoutCallback;
  Duration _timeoutDuration = const Duration(minutes: AppConstants.sessionTimeoutMinutes);

  bool get isActive => _timer != null && _timer!.isActive;

  Duration get remainingTime {
    if (_expiresAt == null) return Duration.zero;
    final remaining = _expiresAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Inicia la cuenta regresiva de expiracion de sesion
  void startSession(VoidCallback onTimeout, {Duration? customDuration}) {
    cancel();
    _timeoutDuration = customDuration ?? const Duration(minutes: AppConstants.sessionTimeoutMinutes);
    _expiresAt = DateTime.now().add(_timeoutDuration);
    _onTimeoutCallback = onTimeout;

    _timer = Timer(_timeoutDuration, () {
      debugPrint('[SessionTimerManager] Session expired after ${_timeoutDuration.inMinutes} minutes.');
      cancel();
      _onTimeoutCallback?.call();
    });

    debugPrint('[SessionTimerManager] Session started. Auto-logout scheduled at: $_expiresAt');
  }

  /// Reinicia el temporizador de sesion si se realizan acciones activas
  void resetTimer() {
    if (_onTimeoutCallback != null) {
      startSession(_onTimeoutCallback!, customDuration: _timeoutDuration);
    }
  }

  /// Cancela el temporizador de sesion (por ejemplo, en cierre manual de sesion)
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _expiresAt = null;
  }
}
