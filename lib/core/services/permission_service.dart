import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' show Geolocator;
import 'package:permission_handler/permission_handler.dart';

/// Nivel de acceso a la ubicacion que el usuario ha concedido.
enum LocationAccess {
  /// Aun no se le ha preguntado.
  notDetermined,

  /// Lo rechazo (puede volver a pedirse una vez; despues solo desde Ajustes).
  denied,

  /// Bloqueado por el sistema o por control parental; no se puede pedir.
  restricted,

  /// "Al usar la app". Permite seguir en segundo plano si el seguimiento se
  /// inicio con la app abierta, pero iOS no la relanza si se cierra.
  whileInUse,

  /// "Siempre". Necesario para un seguimiento de fondo fiable.
  always,
}

/// Estado de un permiso simple (Movimiento y condicion fisica).
enum SimplePermission { notDetermined, granted, denied, restricted }

/// Estado de "Actualizacion en segundo plano" de iOS (solo lectura).
enum BackgroundRefresh { available, denied, restricted, unknown }

/// Foto del estado de todos los permisos que usa el seguimiento.
@immutable
class PermissionSnapshot {
  final LocationAccess location;
  final bool locationServicesEnabled;
  final SimplePermission motion;
  final BackgroundRefresh backgroundRefresh;

  const PermissionSnapshot({
    required this.location,
    this.locationServicesEnabled = true,
    this.motion = SimplePermission.notDetermined,
    this.backgroundRefresh = BackgroundRefresh.unknown,
  });

  /// Se puede registrar ubicacion (al menos mientras la app esta en uso).
  bool get canTrack =>
      locationServicesEnabled &&
      (location == LocationAccess.whileInUse ||
          location == LocationAccess.always);

  /// Condiciones para un seguimiento de fondo fiable.
  bool get isFullyConfigured =>
      location == LocationAccess.always &&
      locationServicesEnabled &&
      backgroundRefresh != BackgroundRefresh.denied &&
      backgroundRefresh != BackgroundRefresh.restricted;

  /// Texto corto para guardar junto a cada marcacion o punto GPS.
  String get locationLabel {
    if (!locationServicesEnabled && location != LocationAccess.notDetermined) {
      return 'servicesOff';
    }
    return switch (location) {
      LocationAccess.notDetermined => 'notDetermined',
      LocationAccess.denied => 'denied',
      LocationAccess.restricted => 'restricted',
      LocationAccess.whileInUse => 'whileInUse',
      LocationAccess.always => 'always',
    };
  }

  @override
  bool operator ==(Object other) =>
      other is PermissionSnapshot &&
      other.location == location &&
      other.locationServicesEnabled == locationServicesEnabled &&
      other.motion == motion &&
      other.backgroundRefresh == backgroundRefresh;

  @override
  int get hashCode =>
      Object.hash(location, locationServicesEnabled, motion, backgroundRefresh);
}

/// Contrato del servicio de permisos (permite sustituirlo en pruebas).
abstract class IPermissionService {
  Future<PermissionSnapshot> snapshot();

  /// Pide "Al usar la app". No repite la solicitud si ya hay una en curso.
  Future<LocationAccess> requestWhenInUse();

  /// Pide "Siempre". iOS exige tener antes "Al usar la app" y solo muestra el
  /// aviso de ampliacion una vez; despues hay que cambiarlo desde Ajustes.
  Future<LocationAccess> requestAlways();

  Future<SimplePermission> requestMotion();

  /// Abre los Ajustes de la app. Devuelve false si no pudo abrirlos.
  Future<bool> openSettings();
}

/// Traduce el estado de permission_handler al nivel de acceso de ubicacion.
///
/// En iOS `locationWhenInUse` queda concedido con "Al usar" y con "Siempre";
/// `locationAlways` solo con "Siempre".
@visibleForTesting
LocationAccess resolveLocationAccess({
  required PermissionStatus whenInUse,
  required PermissionStatus always,
}) {
  if (always.isGranted) return LocationAccess.always;
  if (whenInUse.isGranted || whenInUse.isLimited) {
    return LocationAccess.whileInUse;
  }
  if (whenInUse.isRestricted) return LocationAccess.restricted;
  if (whenInUse.isPermanentlyDenied || whenInUse.isDenied) {
    return LocationAccess.denied;
  }
  return LocationAccess.notDetermined;
}

/// Implementacion real sobre permission_handler y un canal nativo para
/// Background App Refresh. Nunca cambia ajustes del sistema por su cuenta.
class PermissionService implements IPermissionService {
  PermissionService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('com.asisgo.app/system_status');

  final MethodChannel _channel;

  // Evita lanzar dos solicitudes iguales a la vez (el sistema las ignora o
  // devuelve estados intermedios).
  Future<LocationAccess>? _pendingLocation;

  @override
  Future<PermissionSnapshot> snapshot() async {
    final results = await Future.wait([
      _locationAccess(),
      _servicesEnabled(),
      Permission.sensors.status,
      _backgroundRefresh(),
    ]);
    return PermissionSnapshot(
      location: results[0] as LocationAccess,
      locationServicesEnabled: results[1] as bool,
      motion: _mapSimple(results[2] as PermissionStatus),
      backgroundRefresh: results[3] as BackgroundRefresh,
    );
  }

  /// Autorizacion real de Core Location; si el canal no responde, se infiere
  /// del estado de permission_handler.
  Future<LocationAccess> _locationAccess() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final raw = await _channel.invokeMethod<String>(
          'locationAuthorization',
        );
        final mapped = switch (raw) {
          'notDetermined' => LocationAccess.notDetermined,
          'denied' => LocationAccess.denied,
          'restricted' => LocationAccess.restricted,
          'whenInUse' => LocationAccess.whileInUse,
          'always' => LocationAccess.always,
          _ => null,
        };
        if (mapped != null) return mapped;
      } catch (_) {}
    }
    return resolveLocationAccess(
      whenInUse: await Permission.locationWhenInUse.status,
      always: await Permission.locationAlways.status,
    );
  }

  @override
  Future<LocationAccess> requestWhenInUse() => _serialized(() async {
    await Permission.locationWhenInUse.request();
    return (await snapshot()).location;
  });

  @override
  Future<LocationAccess> requestAlways() => _serialized(() async {
    // iOS solo ofrece "Siempre" despues de conceder "Al usar la app".
    if (!(await Permission.locationWhenInUse.status).isGranted) {
      await Permission.locationWhenInUse.request();
      if (!(await Permission.locationWhenInUse.status).isGranted) {
        return (await snapshot()).location;
      }
    }
    await Permission.locationAlways.request();
    return (await snapshot()).location;
  });

  @override
  Future<SimplePermission> requestMotion() async {
    final status = await Permission.sensors.request();
    return _mapSimple(status);
  }

  @override
  Future<bool> openSettings() => openAppSettings();

  Future<LocationAccess> _serialized(Future<LocationAccess> Function() run) {
    final running = _pendingLocation;
    if (running != null) return running;
    final future = run().whenComplete(() => _pendingLocation = null);
    _pendingLocation = future;
    return future;
  }

  Future<bool> _servicesEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      return true;
    }
  }

  Future<BackgroundRefresh> _backgroundRefresh() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return BackgroundRefresh.available;
    }
    try {
      final value = await _channel.invokeMethod<String>(
        'backgroundRefreshStatus',
      );
      return switch (value) {
        'available' => BackgroundRefresh.available,
        'denied' => BackgroundRefresh.denied,
        'restricted' => BackgroundRefresh.restricted,
        _ => BackgroundRefresh.unknown,
      };
    } on MissingPluginException {
      return BackgroundRefresh.unknown;
    } catch (_) {
      return BackgroundRefresh.unknown;
    }
  }

  static SimplePermission _mapSimple(PermissionStatus s) {
    if (s.isGranted || s.isLimited) return SimplePermission.granted;
    if (s.isRestricted) return SimplePermission.restricted;
    if (s.isPermanentlyDenied) return SimplePermission.denied;
    return SimplePermission.notDetermined;
  }
}
