import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../contracts/i_location_service.dart';

class LocationResult {
  final LatLng position;
  final double accuracy;
  final bool isMocked;
  final String? errorMessage;

  LocationResult({
    required this.position,
    this.accuracy = 5.0,
    this.isMocked = false,
    this.errorMessage,
  });

  bool get hasError => errorMessage != null;
}

class LocationService implements ILocationService {
  // Coordenada predeterminada de contingencia (Sede Central BCP San Isidro, Lima)
  static const LatLng defaultLocation = LatLng(-12.0967, -77.0347);

  @override
  Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  @override
  Future<LocationResult> getCurrentLocation() async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) {
        // Contingencia cuando los permisos son denegados
        return LocationResult(
          position: defaultLocation,
          errorMessage: 'Permisos de ubicación no concedidos. Usando ubicación de demostración.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return LocationResult(
        position: LatLng(position.latitude, position.longitude),
        accuracy: position.accuracy,
        isMocked: position.isMocked,
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
      return LocationResult(
        position: defaultLocation,
        errorMessage: 'No se pudo obtener la posición GPS exacta: $e',
      );
    }
  }

  @override
  Stream<LocationResult> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2, // Actualizacion cada 2 metros
      ),
    ).map((position) => LocationResult(
          position: LatLng(position.latitude, position.longitude),
          accuracy: position.accuracy,
          isMocked: position.isMocked,
        ));
  }

  /// Calcula la distancia geodesica en metros utilizando la formula de Haversine
  @override
  double calculateDistance(LatLng start, LatLng end) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, start, end);
  }

  /// Verifica si la coordenada se encuentra dentro del radio permitido
  @override
  bool isInsideGeozone(LatLng userPosition, LatLng targetCenter, double radiusMeters) {
    final distance = calculateDistance(userPosition, targetCenter);
    return distance <= radiusMeters;
  }
}
