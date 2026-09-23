import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum GeozoneType {
  headquarters,
  branchOffice,
  warehouse,
  factory,
  clientSite,
}

extension GeozoneTypeExtension on GeozoneType {
  String get label {
    switch (this) {
      case GeozoneType.headquarters:
        return 'Sede Principal';
      case GeozoneType.branchOffice:
        return 'Sucursal / Oficina';
      case GeozoneType.warehouse:
        return 'Almacén / Logística';
      case GeozoneType.factory:
        return 'Planta de Operaciones';
      case GeozoneType.clientSite:
        return 'Punto de Cliente';
    }
  }

  IconData get icon {
    switch (this) {
      case GeozoneType.headquarters:
        return Icons.corporate_fare_rounded;
      case GeozoneType.branchOffice:
        return Icons.business_rounded;
      case GeozoneType.warehouse:
        return Icons.warehouse_rounded;
      case GeozoneType.factory:
        return Icons.precision_manufacturing_rounded;
      case GeozoneType.clientSite:
        return Icons.location_city_rounded;
    }
  }

  Color get color {
    switch (this) {
      case GeozoneType.headquarters:
        return const Color(0xFF10B981); // Emerald
      case GeozoneType.branchOffice:
        return const Color(0xFF6366F1); // Indigo
      case GeozoneType.warehouse:
        return const Color(0xFFF59E0B); // Amber
      case GeozoneType.factory:
        return const Color(0xFFEC4899); // Pink
      case GeozoneType.clientSite:
        return const Color(0xFF06B6D4); // Cyan
    }
  }
}

class Geozone extends Equatable {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final GeozoneType type;
  final String description;

  const Geozone({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.type,
    this.description = '',
  });

  LatLng get coordinates => LatLng(latitude, longitude);

  @override
  List<Object?> get props => [id, name, latitude, longitude, radiusMeters, type, description];
}

class Branch extends Equatable {
  final String id;
  final String name;
  final String code;
  final String address;
  final double latitude;
  final double longitude;
  final List<Geozone> geozones;
  final String companyId;
  final String companyName;

  const Branch({
    required this.id,
    required this.name,
    required this.code,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.geozones,
    this.companyId = '',
    this.companyName = '',
  });

  LatLng get coordinates => LatLng(latitude, longitude);

  @override
  List<Object?> get props => [id, name, code, address, latitude, longitude, geozones, companyId, companyName];
}

class Company extends Equatable {
  final String id;
  final String name;
  final String shortName;
  final String ruc;
  final String industry;
  final Color primaryColor;
  final IconData icon;
  final List<Branch> branches;

  const Company({
    required this.id,
    required this.name,
    required this.shortName,
    required this.ruc,
    this.industry = 'Banca & Servicios Financieros',
    required this.primaryColor,
    this.icon = Icons.business_rounded,
    required this.branches,
  });

  int get totalGeozones => branches.fold(0, (sum, b) => sum + b.geozones.length);

  @override
  List<Object?> get props => [id, name, shortName, ruc, industry, primaryColor, icon, branches];
}
