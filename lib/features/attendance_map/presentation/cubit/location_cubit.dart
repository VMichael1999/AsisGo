import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/contracts/i_location_service.dart';
import '../../../../core/contracts/i_security_service.dart';
import '../../../../core/services/location_service.dart';
import '../../data/branch_repository.dart';
import '../../domain/branch_model.dart';
import 'location_state.dart';

class LocationCubit extends Cubit<LocationState> {
  final ILocationService _locationService;
  final BranchRepository _branchRepository;
  final ISecurityService _securityService;
  StreamSubscription<LocationResult>? _positionSubscription;

  LocationCubit({
    required ILocationService locationService,
    required BranchRepository branchRepository,
    required ISecurityService securityService,
  })  : _locationService = locationService,
        _branchRepository = branchRepository,
        _securityService = securityService,
        super(LocationInitial());

  Future<void> initLocation() async {
    emit(LocationLoading());
    try {
      await _securityService.init();
      final locationResult = await _locationService.getCurrentLocation();
      _processNewPosition(
        position: locationResult.position,
        accuracy: locationResult.accuracy,
        isMocked: locationResult.isMocked,
      );
      // Start live continuous GPS updates
      startLiveLocationTracking();
    } catch (e) {
      emit(LocationError('Error al obtener la posición: $e'));
    }
  }

  void startLiveLocationTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = _locationService.getPositionStream().listen(
      (result) {
        _processNewPosition(
          position: result.position,
          accuracy: result.accuracy,
          isMocked: result.isMocked,
        );
      },
      onError: (e) {
        debugPrint('Live GPS stream error: $e');
      },
    );
  }

  void _processNewPosition({
    required LatLng position,
    double accuracy = 5.0,
    bool isMocked = false,
  }) {
    final allCompanies = _branchRepository.getAllCompanies();
    final allBranches = _branchRepository.getAllBranches();

    // Determine active company
    Company activeCompany;
    if (state is LocationLoaded) {
      activeCompany = (state as LocationLoaded).selectedCompany;
    } else {
      activeCompany = allCompanies.first;
    }

    final companyBranches = activeCompany.branches;

    final isolatedId = state is LocationLoaded
        ? (state as LocationLoaded).isolatedBranchId ?? companyBranches.first.id
        : companyBranches.first.id;

    final match = _branchRepository.evaluateLocation(
      position,
      activeCompanyId: activeCompany.id,
      isolatedBranchId: isolatedId,
    );

    final showAll = state is LocationLoaded
        ? (state as LocationLoaded).showAllGeozones
        : true;
    final isExplorerActive = state is LocationLoaded
        ? (state as LocationLoaded).isBranchExplorerActive
        : false;
    final selectedIdx = state is LocationLoaded
        ? (state as LocationLoaded).selectedBranchIndex.clamp(0, companyBranches.length - 1)
        : 0;

    final securityCheck = _securityService.evaluateLocationSecurity(
      isMocked: isMocked,
      accuracy: accuracy,
      latitude: position.latitude,
      longitude: position.longitude,
    );

    emit(LocationLoaded(
      userPosition: position,
      currentBranch: match.branch,
      currentGeozone: match.geozone,
      distanceMeters: match.distanceMeters,
      isInsideGeozone: match.isInside,
      accuracy: accuracy,
      isMocked: isMocked,
      isMockProtectionActive: _securityService.isMockProtectionEnabled,
      securityCheck: securityCheck,
      allCompanies: allCompanies,
      selectedCompany: activeCompany,
      allBranches: allBranches,
      showAllGeozones: showAll,
      isBranchExplorerActive: isExplorerActive,
      selectedBranchIndex: selectedIdx,
      isolatedBranchId: isolatedId,
    ));
  }

  void selectCompany(Company company, {Branch? initialBranch}) {
    if (state is LocationLoaded) {
      final current = state as LocationLoaded;
      final branches = company.branches;
      final branchToIsolate = initialBranch ?? (branches.isNotEmpty ? branches.first : current.currentBranch);
      final idx = branches.indexWhere((b) => b.id == branchToIsolate.id);

      final match = _branchRepository.evaluateLocation(
        current.userPosition,
        activeCompanyId: company.id,
        isolatedBranchId: branchToIsolate.id,
      );

      emit(current.copyWith(
        selectedCompany: company,
        isolatedBranchId: branchToIsolate.id,
        selectedBranchIndex: idx >= 0 ? idx : 0,
        isBranchExplorerActive: true,
        currentBranch: match.branch,
        currentGeozone: match.geozone,
        distanceMeters: match.distanceMeters,
        isInsideGeozone: match.isInside,
      ));
    }
  }

  void selectBranch(Branch branch) {
    if (state is LocationLoaded) {
      final current = state as LocationLoaded;
      Company targetCompany = current.selectedCompany;
      if (branch.companyId.isNotEmpty && branch.companyId != current.selectedCompany.id) {
        final found = current.allCompanies.where((c) => c.id == branch.companyId).toList();
        if (found.isNotEmpty) {
          targetCompany = found.first;
        }
      }

      final branches = targetCompany.branches;
      final idx = branches.indexWhere((b) => b.id == branch.id);

      final match = _branchRepository.evaluateLocation(
        current.userPosition,
        activeCompanyId: targetCompany.id,
        isolatedBranchId: branch.id,
      );

      emit(current.copyWith(
        selectedCompany: targetCompany,
        isolatedBranchId: branch.id,
        selectedBranchIndex: idx >= 0 ? idx : 0,
        isBranchExplorerActive: true,
        currentBranch: match.branch,
        currentGeozone: match.geozone,
        distanceMeters: match.distanceMeters,
        isInsideGeozone: match.isInside,
      ));
    }
  }

  void toggleBranchExplorer() {
    if (state is LocationLoaded) {
      final current = state as LocationLoaded;
      emit(current.copyWith(
        isBranchExplorerActive: !current.isBranchExplorerActive,
      ));
    }
  }

  void nextBranch() {
    if (state is LocationLoaded) {
      final current = state as LocationLoaded;
      final branches = current.companyBranches;
      if (branches.isEmpty) return;
      final nextIdx = (current.selectedBranchIndex + 1) % branches.length;
      final nextBranch = branches[nextIdx];

      final match = _branchRepository.evaluateLocation(
        current.userPosition,
        activeCompanyId: current.selectedCompany.id,
        isolatedBranchId: nextBranch.id,
      );

      emit(current.copyWith(
        selectedBranchIndex: nextIdx,
        isolatedBranchId: nextBranch.id,
        isBranchExplorerActive: true,
        currentBranch: match.branch,
        currentGeozone: match.geozone,
        distanceMeters: match.distanceMeters,
        isInsideGeozone: match.isInside,
      ));
    }
  }

  void previousBranch() {
    if (state is LocationLoaded) {
      final current = state as LocationLoaded;
      final branches = current.companyBranches;
      if (branches.isEmpty) return;
      final prevIdx = (current.selectedBranchIndex - 1 + branches.length) % branches.length;
      final prevBranch = branches[prevIdx];

      final match = _branchRepository.evaluateLocation(
        current.userPosition,
        activeCompanyId: current.selectedCompany.id,
        isolatedBranchId: prevBranch.id,
      );

      emit(current.copyWith(
        selectedBranchIndex: prevIdx,
        isolatedBranchId: prevBranch.id,
        isBranchExplorerActive: true,
        currentBranch: match.branch,
        currentGeozone: match.geozone,
        distanceMeters: match.distanceMeters,
        isInsideGeozone: match.isInside,
      ));
    }
  }

  void exitBranchExplorer() {
    if (state is LocationLoaded) {
      final current = state as LocationLoaded;
      emit(current.copyWith(isBranchExplorerActive: false));
    }
  }

  Future<void> syncDeviceLocation() async {
    try {
      final result = await _locationService.getCurrentLocation();
      _processNewPosition(
        position: result.position,
        accuracy: result.accuracy,
        isMocked: result.isMocked,
      );
      startLiveLocationTracking();
    } catch (e) {
      debugPrint('Sync GPS error: $e');
    }
  }

  Future<void> toggleMockProtection() async {
    final next = !_securityService.isMockProtectionEnabled;
    await setMockProtection(next);
  }

  Future<void> setMockProtection(bool enabled) async {
    await _securityService.setMockProtectionEnabled(enabled);
    if (state is LocationLoaded) {
      final cur = state as LocationLoaded;
      _processNewPosition(
        position: cur.userPosition,
        accuracy: cur.accuracy,
        isMocked: cur.isMocked,
      );
    }
  }

  void simulateUserPosition(LatLng position, {bool isMocked = false}) {
    // Pause live stream during manual simulation so test position stays stable
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _processNewPosition(position: position, accuracy: 4.0, isMocked: isMocked);
  }

  void simulateMockGpsAttack() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    if (state is LocationLoaded) {
      final cur = state as LocationLoaded;
      _processNewPosition(
        position: cur.userPosition,
        accuracy: 0.0,
        isMocked: true,
      );
    }
  }

  void resumeLiveLocation() {
    startLiveLocationTracking();
  }

  void toggleGeozonesVisibility() {
    if (state is LocationLoaded) {
      final current = state as LocationLoaded;
      emit(current.copyWith(showAllGeozones: !current.showAllGeozones));
    }
  }

  @override
  Future<void> close() {
    _positionSubscription?.cancel();
    return super.close();
  }
}
