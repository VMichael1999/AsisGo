import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../domain/branch_model.dart';
import '../../../core/services/location_service.dart';

class BranchRepository {
  final LocationService _locationService;

  BranchRepository(this._locationService);

  static const List<Company> companies = [
    Company(
      id: 'EMP-BCP',
      name: 'Banco de Crédito del Perú - BCP',
      shortName: 'BCP',
      ruc: '20100047218',
      industry: 'Banca Comercial & Corporativa',
      primaryColor: Color(0xFF002A8F),
      icon: Icons.account_balance_rounded,
      branches: [
        Branch(
          id: 'BR-01',
          name: 'Sede Central San Isidro',
          code: 'BCP-SI-01',
          address: 'Av. Rivera Navarrete 525, San Isidro',
          latitude: -12.0967,
          longitude: -77.0347,
          companyId: 'EMP-BCP',
          companyName: 'BCP',
          geozones: [
            Geozone(
              id: 'GZ-01',
              name: 'Entrada Principal & Recepción',
              latitude: -12.0967,
              longitude: -77.0347,
              radiusMeters: 80.0,
              type: GeozoneType.headquarters,
              description: 'Acceso peatonal principal y torniquetes de ingreso.',
            ),
            Geozone(
              id: 'GZ-02',
              name: 'Centro de Innovación & TI',
              latitude: -12.0962,
              longitude: -77.0342,
              radiusMeters: 60.0,
              type: GeozoneType.branchOffice,
              description: 'Pisos 5 y 6 - Equipos de desarrollo y tecnología.',
            ),
          ],
        ),
        Branch(
          id: 'BR-BCP-02',
          name: 'Sede Principal La Molina',
          code: 'BCP-LM-02',
          address: 'Calle Centenario 156, La Molina',
          latitude: -12.0792,
          longitude: -76.9482,
          companyId: 'EMP-BCP',
          companyName: 'BCP',
          geozones: [
            Geozone(
              id: 'GZ-BCP-03',
              name: 'Torre Central & Operaciones',
              latitude: -12.0792,
              longitude: -76.9482,
              radiusMeters: 120.0,
              type: GeozoneType.headquarters,
              description: 'Torre corporativa y gerencias generales.',
            ),
            Geozone(
              id: 'GZ-BCP-04',
              name: 'Campus Tecnológico BCP',
              latitude: -12.0785,
              longitude: -76.9475,
              radiusMeters: 85.0,
              type: GeozoneType.branchOffice,
              description: 'Centro de desarrollo de software y laboratorios.',
            ),
          ],
        ),
        Branch(
          id: 'BR-BCP-03',
          name: 'Sucursal Miraflores Larco',
          code: 'BCP-MIRA-03',
          address: 'Av. José Larco 670, Miraflores',
          latitude: -12.1228,
          longitude: -77.0295,
          companyId: 'EMP-BCP',
          companyName: 'BCP',
          geozones: [
            Geozone(
              id: 'GZ-BCP-05',
              name: 'Banca Exclusiva & Cajas',
              latitude: -12.1228,
              longitude: -77.0295,
              radiusMeters: 75.0,
              type: GeozoneType.branchOffice,
              description: 'Plataforma de atención premium y ventanillas.',
            ),
          ],
        ),
        Branch(
          id: 'BR-BCP-04',
          name: 'Centro de Operaciones San Borja',
          code: 'BCP-SB-04',
          address: 'Av. Javier Prado Este 2465, San Borja',
          latitude: -12.0862,
          longitude: -77.0035,
          companyId: 'EMP-BCP',
          companyName: 'BCP',
          geozones: [
            Geozone(
              id: 'GZ-BCP-06',
              name: 'Data Center & Procesos',
              latitude: -12.0862,
              longitude: -77.0035,
              radiusMeters: 90.0,
              type: GeozoneType.factory,
              description: 'Centro de procesamiento informático y contingencia.',
            ),
          ],
        ),
      ],
    ),
    Company(
      id: 'EMP-BBVA',
      name: 'BBVA Perú',
      shortName: 'BBVA',
      ruc: '20100130204',
      industry: 'Servicios Bancarios & Patrimoniales',
      primaryColor: Color(0xFF004481),
      icon: Icons.account_balance_rounded,
      branches: [
        Branch(
          id: 'BR-BBVA-01',
          name: 'Torre BBVA Sede Central',
          code: 'BBVA-SI-01',
          address: 'Av. República de Panamá 3055, San Isidro',
          latitude: -12.0955,
          longitude: -77.0278,
          companyId: 'EMP-BBVA',
          companyName: 'BBVA',
          geozones: [
            Geozone(
              id: 'GZ-BBVA-01',
              name: 'Hall Principal Torre BBVA',
              latitude: -12.0955,
              longitude: -77.0278,
              radiusMeters: 100.0,
              type: GeozoneType.headquarters,
              description: 'Acceso central torre financiera.',
            ),
            Geozone(
              id: 'GZ-BBVA-02',
              name: 'Tesorería & Operaciones',
              latitude: -12.0950,
              longitude: -77.0272,
              radiusMeters: 60.0,
              type: GeozoneType.branchOffice,
              description: 'Piso 12 - Mesa de dinero y operaciones bursátiles.',
            ),
          ],
        ),
        Branch(
          id: 'BR-BBVA-02',
          name: 'Sucursal Miraflores Parque Kennedy',
          code: 'BBVA-MIRA-02',
          address: 'Av. Diagonal 492, Miraflores',
          latitude: -12.1215,
          longitude: -77.0305,
          companyId: 'EMP-BBVA',
          companyName: 'BBVA',
          geozones: [
            Geozone(
              id: 'GZ-BBVA-03',
              name: 'Plataforma & Cajas',
              latitude: -12.1215,
              longitude: -77.0305,
              radiusMeters: 75.0,
              type: GeozoneType.branchOffice,
              description: 'Atención al público y ventanillas rápidas.',
            ),
          ],
        ),
        Branch(
          id: 'BR-BBVA-03',
          name: 'Sucursal San Isidro Las Begonias',
          code: 'BBVA-BEG-03',
          address: 'Av. Las Begonias 415, San Isidro',
          latitude: -12.0928,
          longitude: -77.0312,
          companyId: 'EMP-BBVA',
          companyName: 'BBVA',
          geozones: [
            Geozone(
              id: 'GZ-BBVA-04',
              name: 'Banca Empresas & VIP',
              latitude: -12.0928,
              longitude: -77.0312,
              radiusMeters: 70.0,
              type: GeozoneType.branchOffice,
              description: 'Atención corporativa y ejecutivos de cuenta.',
            ),
          ],
        ),
        Branch(
          id: 'BR-BBVA-04',
          name: 'Sucursal San Miguel La Marina',
          code: 'BBVA-SM-04',
          address: 'Av. La Marina 2000, San Miguel',
          latitude: -12.0768,
          longitude: -77.0865,
          companyId: 'EMP-BBVA',
          companyName: 'BBVA',
          geozones: [
            Geozone(
              id: 'GZ-BBVA-05',
              name: 'Atención Comercial Retail',
              latitude: -12.0768,
              longitude: -77.0865,
              radiusMeters: 80.0,
              type: GeozoneType.branchOffice,
              description: 'Centro comercial y operaciones bancarias generales.',
            ),
          ],
        ),
      ],
    ),
    Company(
      id: 'EMP-IBK',
      name: 'Interbank - Banco Internacional del Perú',
      shortName: 'Interbank',
      ruc: '20100053455',
      industry: 'Banca Retail & Digital',
      primaryColor: Color(0xFF009B3A),
      icon: Icons.account_balance_wallet_rounded,
      branches: [
        Branch(
          id: 'BR-IBK-01',
          name: 'Torre Interbank Sede Central',
          code: 'IBK-CAT-01',
          address: 'Av. Carlos Villarán 140, Santa Catalina',
          latitude: -12.0903,
          longitude: -77.0210,
          companyId: 'EMP-IBK',
          companyName: 'Interbank',
          geozones: [
            Geozone(
              id: 'GZ-IBK-01',
              name: 'Acceso Torre Interbank',
              latitude: -12.0903,
              longitude: -77.0210,
              radiusMeters: 95.0,
              type: GeozoneType.headquarters,
              description: 'Ingreso peatonal principal torre corporativa.',
            ),
            Geozone(
              id: 'GZ-IBK-02',
              name: 'Tienda Insignia Financiera',
              latitude: -12.0898,
              longitude: -77.0205,
              radiusMeters: 70.0,
              type: GeozoneType.branchOffice,
              description: 'Tienda flagship y servicios preferenciales.',
            ),
          ],
        ),
        Branch(
          id: 'BR-IBK-02',
          name: 'Tienda Financiera Larco',
          code: 'IBK-MIRA-02',
          address: 'Av. Larco 680, Miraflores',
          latitude: -12.1232,
          longitude: -77.0298,
          companyId: 'EMP-IBK',
          companyName: 'Interbank',
          geozones: [
            Geozone(
              id: 'GZ-IBK-03',
              name: 'Tienda Ágil Express',
              latitude: -12.1232,
              longitude: -77.0298,
              radiusMeters: 65.0,
              type: GeozoneType.branchOffice,
              description: 'Zona de autoservicio digital y asesoría.',
            ),
          ],
        ),
        Branch(
          id: 'BR-IBK-03',
          name: 'Centro Digital y Financiero Surco',
          code: 'IBK-SUR-03',
          address: 'Av. Javier Prado Este 4200, Santiago de Surco',
          latitude: -12.0850,
          longitude: -76.9740,
          companyId: 'EMP-IBK',
          companyName: 'Interbank',
          geozones: [
            Geozone(
              id: 'GZ-IBK-04',
              name: 'Hub Digital & Banca Negocios',
              latitude: -12.0850,
              longitude: -76.9740,
              radiusMeters: 85.0,
              type: GeozoneType.branchOffice,
              description: 'Espacio colaborativo de innovación bancaria.',
            ),
          ],
        ),
      ],
    ),
    Company(
      id: 'EMP-SCOTIA',
      name: 'Scotiabank Perú',
      shortName: 'Scotiabank',
      ruc: '20100187052',
      industry: 'Banca Múltiple & Gestión de Patrimonios',
      primaryColor: Color(0xFFEC111A),
      icon: Icons.payments_rounded,
      branches: [
        Branch(
          id: 'BR-SCOTIA-01',
          name: 'Torre Principal San Isidro',
          code: 'SCO-SI-01',
          address: 'Av. Dionisio Derteano 102, San Isidro',
          latitude: -12.0988,
          longitude: -77.0315,
          companyId: 'EMP-SCOTIA',
          companyName: 'Scotiabank',
          geozones: [
            Geozone(
              id: 'GZ-SCOTIA-01',
              name: 'Hall de Torre & Acceso Principal',
              latitude: -12.0988,
              longitude: -77.0315,
              radiusMeters: 85.0,
              type: GeozoneType.headquarters,
              description: 'Torniquetes de ingreso corporativo.',
            ),
            Geozone(
              id: 'GZ-SCOTIA-02',
              name: 'Plataforma Corporativa',
              latitude: -12.0982,
              longitude: -77.0310,
              radiusMeters: 55.0,
              type: GeozoneType.branchOffice,
              description: 'Pisos 8 y 9 - Banca corporativa e internacional.',
            ),
          ],
        ),
        Branch(
          id: 'BR-SCOTIA-02',
          name: 'Sucursal Miraflores Benavides',
          code: 'SCO-MIRA-02',
          address: 'Av. Alfredo Benavides 1075, Miraflores',
          latitude: -12.1275,
          longitude: -77.0225,
          companyId: 'EMP-SCOTIA',
          companyName: 'Scotiabank',
          geozones: [
            Geozone(
              id: 'GZ-SCOTIA-03',
              name: 'Banca Personal & Cajas',
              latitude: -12.1275,
              longitude: -77.0225,
              radiusMeters: 75.0,
              type: GeozoneType.branchOffice,
              description: 'Ventanillas y módulos de atención personal.',
            ),
          ],
        ),
        Branch(
          id: 'BR-SCOTIA-03',
          name: 'Sucursal Chacarilla',
          code: 'SCO-SUR-03',
          address: 'Av. Primavera 1050, Surco',
          latitude: -12.1110,
          longitude: -76.9920,
          companyId: 'EMP-SCOTIA',
          companyName: 'Scotiabank',
          geozones: [
            Geozone(
              id: 'GZ-SCOTIA-04',
              name: 'Centro Hipotecario & Pymes',
              latitude: -12.1110,
              longitude: -76.9920,
              radiusMeters: 80.0,
              type: GeozoneType.branchOffice,
              description: 'Asesoría hipotecaria y créditos empresariales.',
            ),
          ],
        ),
      ],
    ),
    Company(
      id: 'EMP-BN',
      name: 'Banco de la Nación del Perú',
      shortName: 'Banco de la Nación',
      ruc: '20100030595',
      industry: 'Banca de Estado & Servicios Públicos',
      primaryColor: Color(0xFFB91C1C),
      icon: Icons.account_balance_rounded,
      branches: [
        Branch(
          id: 'BR-BN-01',
          name: 'Torre Banco de la Nación Sede Principal',
          code: 'BN-SB-01',
          address: 'Av. Javier Prado Este 2499, San Borja',
          latitude: -12.0868,
          longitude: -77.0028,
          companyId: 'EMP-BN',
          companyName: 'Banco de la Nación',
          geozones: [
            Geozone(
              id: 'GZ-BN-01',
              name: 'Torre BN & Hall Central',
              latitude: -12.0868,
              longitude: -77.0028,
              radiusMeters: 110.0,
              type: GeozoneType.headquarters,
              description: 'Ingreso central a la torre más alta del Perú.',
            ),
            Geozone(
              id: 'GZ-BN-02',
              name: 'Gerencias Operativas & TI',
              latitude: -12.0863,
              longitude: -77.0022,
              radiusMeters: 70.0,
              type: GeozoneType.branchOffice,
              description: 'Pisos técnicos y centro de control nacional.',
            ),
          ],
        ),
        Branch(
          id: 'BR-BN-02',
          name: 'Sucursal Miraflores 28 de Julio',
          code: 'BN-MIRA-02',
          address: 'Av. 28 de Julio 1002, Miraflores',
          latitude: -12.1290,
          longitude: -77.0270,
          companyId: 'EMP-BN',
          companyName: 'Banco de la Nación',
          geozones: [
            Geozone(
              id: 'GZ-BN-03',
              name: 'Atención al Ciudadano & Cajas',
              latitude: -12.1290,
              longitude: -77.0270,
              radiusMeters: 75.0,
              type: GeozoneType.branchOffice,
              description: 'Trámites de tesorería del Estado y ventanillas.',
            ),
          ],
        ),
        Branch(
          id: 'BR-BN-03',
          name: 'Sucursal Lima Centro Histórico',
          code: 'BN-CEN-03',
          address: 'Jr. Lampa 801, Cercado de Lima',
          latitude: -12.0515,
          longitude: -77.0308,
          companyId: 'EMP-BN',
          companyName: 'Banco de la Nación',
          geozones: [
            Geozone(
              id: 'GZ-BN-04',
              name: 'Ventanillas Centro Histórico',
              latitude: -12.0515,
              longitude: -77.0308,
              radiusMeters: 90.0,
              type: GeozoneType.branchOffice,
              description: 'Plataforma histórica de pagos y recaudaciones.',
            ),
          ],
        ),
      ],
    ),
  ];

  static List<Branch> get branches => companies.expand((c) => c.branches).toList();

  List<Company> getAllCompanies() => companies;

  Company? getCompanyById(String id) {
    try {
      return companies.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Branch> getBranchesByCompany(String companyId) {
    final company = getCompanyById(companyId);
    return company?.branches ?? [];
  }

  List<Branch> getAllBranches() => branches;

  Branch? getBranchById(String id) {
    try {
      return branches.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Encuentra la geozona mas cercana y determina si [position] esta dentro de ella.
  /// Cuando se provee [activeCompanyId], la evaluacion restringe los candidatos
  /// estrictamente a las sucursales pertenecientes a esa empresa.
  GeozoneMatchResult evaluateLocation(
    LatLng position, {
    String? activeCompanyId,
    String? isolatedBranchId,
  }) {
    List<Branch> candidateBranches;
    if (activeCompanyId != null && activeCompanyId.isNotEmpty) {
      candidateBranches = getBranchesByCompany(activeCompanyId);
      if (isolatedBranchId != null && isolatedBranchId.isNotEmpty) {
        final isolated = candidateBranches.where((b) => b.id == isolatedBranchId).toList();
        if (isolated.isNotEmpty) {
          candidateBranches = isolated;
        }
      }
    } else if (isolatedBranchId != null && isolatedBranchId.isNotEmpty) {
      candidateBranches = branches.where((b) => b.id == isolatedBranchId).toList();
    } else {
      candidateBranches = branches;
    }

    if (candidateBranches.isEmpty) {
      candidateBranches = branches;
    }

    Geozone? closestGeozone;
    Branch? matchedBranch;
    double minDistance = double.infinity;

    for (final branch in candidateBranches) {
      for (final geozone in branch.geozones) {
        final distance = _locationService.calculateDistance(
          position,
          geozone.coordinates,
        );
        if (distance < minDistance) {
          minDistance = distance;
          closestGeozone = geozone;
          matchedBranch = branch;
        }
      }
    }

    if (closestGeozone == null || matchedBranch == null) {
      final fallbackBranch = candidateBranches.first;
      return GeozoneMatchResult(
        isInside: false,
        distanceMeters: minDistance,
        branch: fallbackBranch,
        geozone: fallbackBranch.geozones.first,
      );
    }

    final isInside = minDistance <= closestGeozone.radiusMeters;
    return GeozoneMatchResult(
      isInside: isInside,
      distanceMeters: minDistance,
      branch: matchedBranch,
      geozone: closestGeozone,
    );
  }
}

class GeozoneMatchResult {
  final bool isInside;
  final double distanceMeters;
  final Branch branch;
  final Geozone geozone;

  const GeozoneMatchResult({
    required this.isInside,
    required this.distanceMeters,
    required this.branch,
    required this.geozone,
  });
}
