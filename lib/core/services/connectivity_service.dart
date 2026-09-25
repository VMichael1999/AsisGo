import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  final Connectivity _connectivity;
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  List<ConnectivityResult> _lastResults = [ConnectivityResult.wifi];
  bool _isSimulatedOffline = false;
  bool _initialized = false;

  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  bool get isSimulatedOffline => _isSimulatedOffline;

  bool get isOnline {
    if (_isSimulatedOffline) return false;
    return _isRealOnline(_lastResults);
  }

  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  Future<void> init() async {
    if (_initialized) return;
    try {
      _lastResults = await _connectivity.checkConnectivity();
    } catch (e) {
      debugPrint('[ConnectivityService] Error al verificar conectividad inicial: $e');
      _lastResults = [ConnectivityResult.none];
    }

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _lastResults = results;
      if (!_isSimulatedOffline) {
        _connectivityController.add(isOnline);
      }
    });

    _initialized = true;
  }

  void setSimulatedOffline(bool simulated) {
    if (_isSimulatedOffline == simulated) return;
    _isSimulatedOffline = simulated;
    _connectivityController.add(isOnline);
    debugPrint('[ConnectivityService] Modo simulado offline cambiado a: $_isSimulatedOffline. En línea: $isOnline');
  }

  Future<bool> checkConnection() async {
    try {
      _lastResults = await _connectivity.checkConnectivity();
    } catch (_) {}
    return isOnline;
  }

  bool _isRealOnline(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return !results.every((r) => r == ConnectivityResult.none);
  }

  void dispose() {
    _subscription?.cancel();
    _connectivityController.close();
  }
}
