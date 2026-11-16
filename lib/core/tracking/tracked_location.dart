import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Un punto GPS registrado durante la jornada, pendiente o ya sincronizado.
class TrackedLocation extends Equatable {
  final String id;
  final String userId;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double accuracy;

  /// Estado del permiso de ubicacion cuando se tomo el punto
  /// (`always`, `whileInUse`, ...).
  final String permission;
  final bool isMocked;
  final bool isSynced;

  const TrackedLocation({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.permission,
    this.isMocked = false,
    this.isSynced = false,
  });

  TrackedLocation copyWith({bool? isSynced}) => TrackedLocation(
    id: id,
    userId: userId,
    timestamp: timestamp,
    latitude: latitude,
    longitude: longitude,
    accuracy: accuracy,
    permission: permission,
    isMocked: isMocked,
    isSynced: isSynced ?? this.isSynced,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'timestamp': timestamp.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'permission': permission,
    'isMocked': isMocked,
    'isSynced': isSynced,
  };

  factory TrackedLocation.fromJson(Map<String, dynamic> json) =>
      TrackedLocation(
        id: json['id'] as String,
        userId: json['userId'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        accuracy: (json['accuracy'] as num).toDouble(),
        permission: json['permission'] as String? ?? 'unknown',
        isMocked: json['isMocked'] as bool? ?? false,
        isSynced: json['isSynced'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [
    id,
    userId,
    timestamp,
    latitude,
    longitude,
    accuracy,
    permission,
    isMocked,
    isSynced,
  ];
}

/// Almacen de la cola de puntos y de las marcas del seguimiento.
abstract class LocationPointStore {
  Future<List<TrackedLocation>> load();
  Future<void> save(List<TrackedLocation> points);

  /// Si ya se ofrecio ampliar el permiso a "Siempre" (iOS solo lo muestra una vez).
  Future<bool> wasAlwaysOffered();
  Future<void> markAlwaysOffered();
}

/// Implementacion sobre SharedPreferences.
class PrefsLocationPointStore implements LocationPointStore {
  PrefsLocationPointStore(this._prefs);

  final SharedPreferences _prefs;

  static const _pointsKey = 'asisgo_tracked_locations';
  static const _alwaysKey = 'asisgo_always_offered';

  @override
  Future<List<TrackedLocation>> load() async {
    final raw = _prefs.getString(_pointsKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => TrackedLocation.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> save(List<TrackedLocation> points) => _prefs.setString(
    _pointsKey,
    jsonEncode(points.map((p) => p.toJson()).toList()),
  );

  @override
  Future<bool> wasAlwaysOffered() async => _prefs.getBool(_alwaysKey) ?? false;

  @override
  Future<void> markAlwaysOffered() => _prefs.setBool(_alwaysKey, true);
}

/// Almacen en memoria para pruebas.
class MemoryLocationPointStore implements LocationPointStore {
  List<TrackedLocation> points = [];
  bool alwaysOffered = false;

  @override
  Future<List<TrackedLocation>> load() async => List.of(points);

  @override
  Future<void> save(List<TrackedLocation> value) async => points = List.of(value);

  @override
  Future<bool> wasAlwaysOffered() async => alwaysOffered;

  @override
  Future<void> markAlwaysOffered() async => alwaysOffered = true;
}
