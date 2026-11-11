import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong2/latlong.dart';

/// Convierte la coordenada de dominio (latlong2) a la de Google Maps.
extension LatLngToGoogle on LatLng {
  gm.LatLng get toGoogle => gm.LatLng(latitude, longitude);
}
