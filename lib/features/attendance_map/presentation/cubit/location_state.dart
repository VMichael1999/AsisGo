import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/security/security_check_result.dart';
import '../../domain/branch_model.dart';

abstract class LocationState extends Equatable {
  const LocationState();

  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {}

class LocationLoading extends LocationState {}

class LocationLoaded extends LocationState {
  final LatLng userPosition;
  final Branch currentBranch;
  final Geozone currentGeozone;
  final double distanceMeters;
  final bool isInsideGeozone;
  final double accuracy;
  final bool isMocked;
  final bool isMockProtectionActive;
  final SecurityCheckResult securityCheck;
  final List<Company> allCompanies;
  final Company selectedCompany;
  final List<Branch> allBranches;
  final bool showAllGeozones;
  final bool isBranchExplorerActive;
  final int selectedBranchIndex;
  final String? isolatedBranchId;

  const LocationLoaded({
    required this.userPosition,
    required this.currentBranch,
    required this.currentGeozone,
    required this.distanceMeters,
    required this.isInsideGeozone,
    this.accuracy = 5.0,
    this.isMocked = false,
    this.isMockProtectionActive = false,
    required this.securityCheck,
    required this.allCompanies,
    required this.selectedCompany,
    required this.allBranches,
    this.showAllGeozones = true,
    this.isBranchExplorerActive = false,
    this.selectedBranchIndex = 0,
    this.isolatedBranchId,
  });

  bool get isBlockedBySecurity => isMockProtectionActive && !securityCheck.isSecure;

  /// Sedes correspondientes unicamente a la empresa seleccionada
  List<Branch> get companyBranches => selectedCompany.branches;

  Branch get selectedBranch {
    if (companyBranches.isEmpty) return currentBranch;
    final safeIndex = selectedBranchIndex.clamp(0, companyBranches.length - 1);
    return companyBranches[safeIndex];
  }

  Branch get activeMapBranch {
    if (isolatedBranchId != null) {
      final found = companyBranches.where((b) => b.id == isolatedBranchId).toList();
      if (found.isNotEmpty) return found.first;
      // Verificar en todas las sedes en caso de transicion de empresa
      final foundAny = allBranches.where((b) => b.id == isolatedBranchId).toList();
      if (foundAny.isNotEmpty) return foundAny.first;
    }
    return selectedBranch;
  }

  int get currentBranchIndex {
    final idx = companyBranches.indexWhere((b) => b.id == activeMapBranch.id);
    return idx >= 0 ? idx : 0;
  }

  LocationLoaded copyWith({
    LatLng? userPosition,
    Branch? currentBranch,
    Geozone? currentGeozone,
    double? distanceMeters,
    bool? isInsideGeozone,
    double? accuracy,
    bool? isMocked,
    bool? isMockProtectionActive,
    SecurityCheckResult? securityCheck,
    List<Company>? allCompanies,
    Company? selectedCompany,
    List<Branch>? allBranches,
    bool? showAllGeozones,
    bool? isBranchExplorerActive,
    int? selectedBranchIndex,
    String? isolatedBranchId,
  }) {
    return LocationLoaded(
      userPosition: userPosition ?? this.userPosition,
      currentBranch: currentBranch ?? this.currentBranch,
      currentGeozone: currentGeozone ?? this.currentGeozone,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      isInsideGeozone: isInsideGeozone ?? this.isInsideGeozone,
      accuracy: accuracy ?? this.accuracy,
      isMocked: isMocked ?? this.isMocked,
      isMockProtectionActive: isMockProtectionActive ?? this.isMockProtectionActive,
      securityCheck: securityCheck ?? this.securityCheck,
      allCompanies: allCompanies ?? this.allCompanies,
      selectedCompany: selectedCompany ?? this.selectedCompany,
      allBranches: allBranches ?? this.allBranches,
      showAllGeozones: showAllGeozones ?? this.showAllGeozones,
      isBranchExplorerActive: isBranchExplorerActive ?? this.isBranchExplorerActive,
      selectedBranchIndex: selectedBranchIndex ?? this.selectedBranchIndex,
      isolatedBranchId: isolatedBranchId ?? this.isolatedBranchId,
    );
  }

  @override
  List<Object?> get props => [
        userPosition,
        currentBranch,
        currentGeozone,
        distanceMeters,
        isInsideGeozone,
        accuracy,
        isMocked,
        isMockProtectionActive,
        securityCheck,
        allCompanies,
        selectedCompany,
        allBranches,
        showAllGeozones,
        isBranchExplorerActive,
        selectedBranchIndex,
        isolatedBranchId,
      ];
}

class LocationError extends LocationState {
  final String message;

  const LocationError(this.message);

  @override
  List<Object?> get props => [message];
}
