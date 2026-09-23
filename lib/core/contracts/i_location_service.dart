import 'package:latlong2/latlong.dart';
import '../../core/services/location_service.dart';

/// Interfaz de operaciones de localizacion, transmision GPS y calculos geodesicos
abstract class ILocationService {
  /// Verifica y solicita permisos de ubicacion en tiempo de ejecucion
  Future<bool> checkAndRequestPermission();

  /// Obtiene la ubicacion actual instantanea
  Future<LocationResult> getCurrentLocation();

  /// Transmite actualizaciones continuas de posicion GPS en tiempo real
  Stream<LocationResult> getPositionStream();

  /// Calcula la distancia geodesica entre dos puntos en metros (Haversine)
  double calculateDistance(LatLng start, LatLng end);

  /// Verifica si la posicion del usuario esta dentro del radio de la geozona objetivo
  bool isInsideGeozone(LatLng userPosition, LatLng targetCenter, double radiusMeters);
}
