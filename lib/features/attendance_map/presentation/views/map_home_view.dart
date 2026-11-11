import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/haptic_feedback_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/asis_glass_card.dart';
import '../../../../core/widgets/asis_security_dialog.dart';
import '../../domain/shift_phase.dart';
import '../cubit/attendance_cubit.dart';
import '../cubit/attendance_state.dart';
import '../cubit/location_cubit.dart';
import '../cubit/location_state.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import 'branches_view.dart';
import '../widgets/attendance_action_dock.dart';
import '../widgets/attendance_modal_sheet.dart';
import '../widgets/map_visuals.dart';
import '../widgets/offline_status_badge.dart';
import 'package:asisgo/features/calendar_history/presentation/cubit/calendar_cubit.dart';
import '../../../../core/widgets/asis_shimmer.dart';
import '../../../../core/widgets/asis_skeletons.dart';

class MapHomeView extends StatefulWidget {
  const MapHomeView({super.key});

  @override
  State<MapHomeView> createState() => _MapHomeViewState();
}

class _MapHomeViewState extends State<MapHomeView> {
  gm.GoogleMapController? _mapController;
  gm.BitmapDescriptor? _branchIcon;
  String? _lastIsolatedBranchId;

  @override
  void initState() {
    super.initState();
    _loadBranchIcon();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationCubit>().initLocation();
      final authState = context.read<AuthCubit>().state;
      if (authState is Authenticated) {
        context.read<AttendanceCubit>().loadDailyAttendance(authState.user.id);
      }
    });
  }

  void _recenter(LatLng point, {double zoom = 16.5}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController?.animateCamera(
        gm.CameraUpdate.newLatLngZoom(point.toGoogle, zoom),
      );
    });
  }

  Future<void> _loadBranchIcon() async {
    final icon = await gm.BitmapDescriptor.asset(
      const ImageConfiguration(),
      'assets/markers/branch_building.png',
      width: 46,
    );
    if (mounted) setState(() => _branchIcon = icon);
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _openAttendanceModal({
    required BuildContext context,
    required List<AttendanceType> options,
    required LocationLoaded locationState,
    required String userId,
    bool isOffline = false,
  }) {
    AttendanceModalSheet.show(
      context: context,
      options: options,
      branch: locationState.currentBranch,
      geozone: locationState.currentGeozone,
      isOffline: isOffline,
      onConfirm: (type, note, selfiePath) {
        context.read<AttendanceCubit>().registerPunch(
          userId: userId,
          type: type,
          branchId: locationState.currentBranch.id,
          branchName: locationState.currentBranch.name,
          geozoneId: locationState.currentGeozone.id,
          geozoneName: locationState.currentGeozone.name,
          latitude: locationState.userPosition.latitude,
          longitude: locationState.userPosition.longitude,
          distanceToGeozone: locationState.distanceMeters,
          isInsideGeozone: locationState.isInsideGeozone,
          isMockedLocation: locationState.isMocked,
          note: note,
          selfiePath: selfiePath,
        );
      },
    );
  }

  void _showMockGpsSecurityDialog(BuildContext context, LocationLoaded loc) {
    HapticFeedbackService.shared.securityAlert();
    AsisSecurityDialog.show(
      context: context,
      type: AsisSecurityDialogType.mockGpsDetected,
      title: 'GPS Simulado Detectado',
      badgeLabel: 'ALERTA DE SEGURIDAD LABORAL',
      description:
          'El sistema ha detectado una alteración o suplantación de señal GPS (Mock Location Provider) activa en las opciones de desarrollador.\n\nPor políticas corporativas y de transparencia, no se permite el registro de asistencia bajo estas condiciones.',
      auditDetails: {
        'Infracción': 'Mock Location / Fake GPS',
        'Estado': 'Bloqueado por Seguridad',
        'Precisión Sensor': '${loc.accuracy.toStringAsFixed(1)} m',
        'Hora Detección': DateFormatter.formatTime(DateTime.now()),
      },
    );
  }

  void _showGeozoneRestrictionDialog(
    BuildContext context,
    LocationLoaded loc,
    AttendanceType type,
  ) {
    HapticFeedbackService.shared.securityAlert();
    AsisSecurityDialog.show(
      context: context,
      type: AsisSecurityDialogType.outsideGeozone,
      title: 'Fuera de Geozona Autorizada',
      badgeLabel: 'RESTRICCIÓN DE COBERTURA',
      description:
          'Debes encontrarte físicamente dentro del perímetro asignado para poder registrar tu ${type.title}.',
      auditDetails: {
        'Sede Requerida': loc.currentBranch.name,
        'Geozona': loc.currentGeozone.name,
        'Tu Distancia':
            loc.distanceMeters < 1000
                ? '${loc.distanceMeters.toStringAsFixed(0)} m'
                : '${(loc.distanceMeters / 1000).toStringAsFixed(2)} km',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final userId = authState.currentUser?.id ?? 'USR-001';

    return Scaffold(
      body: BlocConsumer<AttendanceCubit, AttendanceState>(
        listener: (context, attendanceState) {
          if (attendanceState is AttendanceLoaded &&
              attendanceState.feedbackMessage != null) {
            // Sincronizar el historial de calendario con las marcas registradas
            context.read<CalendarCubit>().loadCalendarData(userId);

            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF10B981),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        attendanceState.feedbackMessage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF0F172A),
                behavior: SnackBarBehavior.floating,
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFF10B981), width: 1.2),
                ),
              ),
            );
          } else if (attendanceState is AttendanceError) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFEF4444),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        attendanceState.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF0F172A),
                behavior: SnackBarBehavior.floating,
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
                ),
              ),
            );
          }
        },
        builder: (context, attendanceState) {
          return BlocConsumer<LocationCubit, LocationState>(
            listener: (context, locationState) {
              if (locationState is LocationLoaded) {
                // Notificar cambio de estado de geozona a la Live Activity de la Dynamic Island
                context.read<AttendanceCubit>().updateGeozoneStatus(
                  isInsideGeozone: locationState.isInsideGeozone,
                );

                if (_lastIsolatedBranchId != locationState.isolatedBranchId) {
                  _lastIsolatedBranchId = locationState.isolatedBranchId;
                  if (locationState.activeMapBranch.geozones.isNotEmpty) {
                    _recenter(
                      locationState.activeMapBranch.geozones.first.coordinates,
                    );
                  }
                }
              }
            },
            builder: (context, locationState) {
              if (locationState is LocationLoading ||
                  locationState is LocationInitial) {
                return const AsisLoadingOverlay(
                  skeleton: AsisMapSkeleton(),
                  message: 'Sincronizando telemetría y geocercas...',
                );
              }

              if (locationState is LocationError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_disabled_rounded,
                          size: 56,
                          color: AppColors.checkOutColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          locationState.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed:
                              () =>
                                  context.read<LocationCubit>().initLocation(),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final loc = locationState as LocationLoaded;
              final mediaQuery = MediaQuery.of(context);
              final screenHeight = mediaQuery.size.height;

              // Boton Registrar centrado abajo; controles a la derecha; tarjeta de sede encima
              const toolButtonsBottom = 16.0;
              final arrowTop = screenHeight * 0.22;

              // Generar elementos visuales de geocercas exclusivamente para la empresa seleccionada
              final circles = <gm.Circle>{};
              final mapMarkers = <gm.Marker>{};

              final activeBranch = loc.activeMapBranch;
              // 1. Geocercas detalladas para la sede activa
              for (final gz in activeBranch.geozones) {
                final isCurrentGz = gz.id == loc.currentGeozone.id;

                // Geocercas en gris neutro; la activa solo se distingue por el trazo
                circles.add(
                  gm.Circle(
                    circleId: gm.CircleId(gz.id),
                    center: gz.coordinates.toGoogle,
                    radius: gz.radiusMeters,
                    fillColor: AppColors.textSecondary.withValues(alpha: 0.16),
                    strokeColor: AppColors.textSecondary.withValues(
                      alpha: isCurrentGz ? 0.9 : 0.5,
                    ),
                    strokeWidth: isCurrentGz ? 3 : 1,
                  ),
                );

                mapMarkers.add(
                  gm.Marker(
                    markerId: gm.MarkerId('gz-${gz.id}'),
                    position: gz.coordinates.toGoogle,
                    icon: _branchIcon ?? gm.BitmapDescriptor.defaultMarker,
                    // Solo nombre de sede y punto; el radio no se muestra al colaborador
                    infoWindow: gm.InfoWindow(
                      title: activeBranch.name,
                      snippet: gz.name,
                    ),
                    // Tocar el marcador solo centra el mapa; nunca altera la posicion del usuario
                    onTap: () => _recenter(gz.coordinates),
                  ),
                );
              }

              // 2. Marcadores interactivos para las otras sedes de la misma empresa
              for (final otherBranch in loc.companyBranches) {
                if (otherBranch.id != activeBranch.id) {
                  mapMarkers.add(
                    gm.Marker(
                      markerId: gm.MarkerId('br-${otherBranch.id}'),
                      position: otherBranch.coordinates.toGoogle,
                      icon: _branchIcon ?? gm.BitmapDescriptor.defaultMarker,
                      infoWindow: gm.InfoWindow(title: otherBranch.name),
                      onTap: () {
                        context.read<LocationCubit>().selectBranch(otherBranch);
                        _recenter(otherBranch.geozones.first.coordinates);
                      },
                    ),
                  );
                }
              }

              return Column(
                children: [
                  _buildHeader(context, loc, authState.currentUser?.fullName),
                  Expanded(
                    child: Stack(
                      children: [
                        // Capa base de mapa de alto rendimiento en modo oscuro
                        Container(
                          color: AppColors.backgroundLight,
                          child: gm.GoogleMap(
                            onMapCreated:
                                (controller) => _mapController = controller,
                            initialCameraPosition: gm.CameraPosition(
                              target: loc.userPosition.toGoogle,
                              zoom: 16.5,
                            ),
                            minMaxZoomPreference: const gm.MinMaxZoomPreference(
                              4,
                              19,
                            ),
                            circles:
                                loc.showAllGeozones
                                    ? circles
                                    : const <gm.Circle>{},
                            markers: mapMarkers,
                            // Punto azul nativo de Google Maps con la ubicacion del dispositivo
                            myLocationEnabled: true,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            mapToolbarEnabled: false,
                            compassEnabled: false,
                          ),
                        ),

                        // Aviso flotante de modo offline y marcas pendientes
                        SafeArea(
                          top: false,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Tarjeta de la sede activa (modo explorador)
                                if (loc.isBranchExplorerActive)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      10,
                                      16,
                                      0,
                                    ),
                                    child: GestureDetector(
                                      onTap:
                                          () => _showCompanyBranchesSheet(
                                            context,
                                            loc,
                                          ),
                                      child: AsisGlassCard(
                                        borderRadius: 18,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        isDark: false,
                                        customBackground: const Color(
                                          0xF7FFFFFF,
                                        ),
                                        customBorderColor:
                                            AppColors.borderLight,
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: AppColors.accent
                                                    .withValues(alpha: 0.15),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.business_rounded,
                                                color: AppColors.accent,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          loc
                                                              .activeMapBranch
                                                              .name,
                                                          style: const TextStyle(
                                                            color:
                                                                AppColors
                                                                    .textPrimary,
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                          maxLines: 1,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                      ),
                                                      const Icon(
                                                        Icons
                                                            .expand_more_rounded,
                                                        size: 18,
                                                        color:
                                                            AppColors
                                                                .textSecondary,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 7,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              AppColors
                                                                  .accentLight,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          'Sede ${loc.currentBranchIndex + 1} de ${loc.companyBranches.length}',
                                                          style:
                                                              const TextStyle(
                                                                color:
                                                                    AppColors
                                                                        .accent,
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '${loc.activeMapBranch.address} • ${loc.selectedCompany.shortName}',
                                                    style: const TextStyle(
                                                      color:
                                                          AppColors
                                                              .textSecondary,
                                                      fontSize: 11,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            GestureDetector(
                                              onTap:
                                                  () => _setBranchExplorer(
                                                    context,
                                                    loc,
                                                    active: false,
                                                  ),
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFF1F5F9,
                                                  ),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close_rounded,
                                                  size: 16,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                if (attendanceState is AttendanceLoaded)
                                  OfflineStatusBadge(
                                    isOffline: attendanceState.isOffline,
                                    pendingSyncCount:
                                        attendanceState.pendingSyncCount,
                                    isSyncing: attendanceState.isSyncing,
                                    onSyncTap:
                                        () =>
                                            context
                                                .read<AttendanceCubit>()
                                                .syncPendingNow(),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Flechas laterales para alternar sedes de la empresa activa
                        if (loc.isBranchExplorerActive &&
                            loc.companyBranches.length > 1) ...[
                          // Flecha lateral izquierda
                          Positioned(
                            left: 12,
                            top: arrowTop,
                            child: AsisGlassCard(
                              borderRadius: 10,
                              padding: EdgeInsets.zero,
                              blurAmount: 0,
                              isDark: false,
                              customBackground: AppColors.primary,
                              customBorderColor: AppColors.primary,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.chevron_left_rounded,
                                  color: Colors.white,
                                  size: 30,
                                ),
                                tooltip:
                                    'Sede anterior de ${loc.selectedCompany.shortName}',
                                onPressed: () {
                                  HapticFeedbackService.shared.selectionClick();
                                  final cubit = context.read<LocationCubit>();
                                  cubit.previousBranch();
                                  final updated = cubit.state;
                                  if (updated is LocationLoaded) {
                                    _recenter(
                                      updated
                                          .activeMapBranch
                                          .geozones
                                          .first
                                          .coordinates,
                                    );
                                  }
                                },
                              ),
                            ),
                          ),

                          // Flecha lateral derecha
                          Positioned(
                            right: 12,
                            top: arrowTop,
                            child: AsisGlassCard(
                              borderRadius: 10,
                              padding: EdgeInsets.zero,
                              blurAmount: 0,
                              isDark: false,
                              customBackground: AppColors.primary,
                              customBorderColor: AppColors.primary,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.white,
                                  size: 30,
                                ),
                                tooltip:
                                    'Siguiente sede de ${loc.selectedCompany.shortName}',
                                onPressed: () {
                                  HapticFeedbackService.shared.selectionClick();
                                  final cubit = context.read<LocationCubit>();
                                  cubit.nextBranch();
                                  final updated = cubit.state;
                                  if (updated is LocationLoaded) {
                                    _recenter(
                                      updated
                                          .activeMapBranch
                                          .geozones
                                          .first
                                          .coordinates,
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        ],

                        // Controles flotantes del mapa
                        Positioned(
                          right: 16,
                          bottom: toolButtonsBottom,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Centrar en la ubicacion real del usuario
                              _buildGlassIconButton(
                                icon: Icons.my_location_rounded,
                                tooltip: 'Centrar en mi ubicación',
                                onTap: () {
                                  // Reanuda el GPS en vivo por si estaba detenido y centra en la posicion real
                                  context
                                      .read<LocationCubit>()
                                      .resumeLiveLocation();
                                  _recenter(loc.userPosition);
                                },
                              ),
                              const SizedBox(height: 8),

                              // Modo explorador de sedes de la empresa activa
                              _buildGlassIconButton(
                                icon: Icons.domain_rounded,
                                isActive: loc.isBranchExplorerActive,
                                tooltip:
                                    loc.isBranchExplorerActive
                                        ? 'Ocultar sedes de ${loc.selectedCompany.shortName}'
                                        : 'Ver sedes de ${loc.selectedCompany.shortName}',
                                onTap:
                                    () => _setBranchExplorer(
                                      context,
                                      loc,
                                      active: !loc.isBranchExplorerActive,
                                    ),
                              ),
                              const SizedBox(height: 8),

                              // Alternar visibilidad de geocercas
                              _buildGlassIconButton(
                                icon:
                                    loc.showAllGeozones
                                        ? Icons.layers_rounded
                                        : Icons.layers_clear_rounded,
                                isActive: loc.showAllGeozones,
                                tooltip: 'Mostrar/Ocultar Geozonas',
                                onTap:
                                    () =>
                                        context
                                            .read<LocationCubit>()
                                            .toggleGeozonesVisibility(),
                              ),
                              const SizedBox(height: 8),

                              // Sincronizar ubicacion del hardware GPS
                              _buildGlassIconButton(
                                icon: Icons.sync_rounded,
                                tooltip: 'Sincronizar Ubicación GPS',
                                onTap: () {
                                  context
                                      .read<LocationCubit>()
                                      .syncDeviceLocation();
                                  ScaffoldMessenger.of(
                                    context,
                                  ).hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Row(
                                        children: [
                                          Icon(
                                            Icons.gps_fixed_rounded,
                                            color: Color(0xFF38BDF8),
                                            size: 20,
                                          ),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'Ubicación GPS sincronizada en tiempo real',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: const Color(0xFF0F172A),
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                      elevation: 6,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        side: const BorderSide(
                                          color: Color(0xFF334155),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        // Barra inferior dinamica de marcacion de asistencia
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 16,
                          child: Center(
                            child: AttendanceActionDock(
                              phase:
                                  attendanceState is AttendanceLoaded
                                      ? attendanceState.currentPhase
                                      : ShiftPhase.notStarted,
                              todayRecords:
                                  attendanceState is AttendanceLoaded
                                      ? attendanceState.todayRecords
                                      : [],
                              lastRecord:
                                  attendanceState is AttendanceLoaded
                                      ? attendanceState.lastRecord
                                      : null,
                              isInsideGeozone: loc.isInsideGeozone,
                              onPrimaryActionPressed: () {
                                final currentPhase =
                                    attendanceState is AttendanceLoaded
                                        ? attendanceState.currentPhase
                                        : ShiftPhase.notStarted;
                                final nextType =
                                    currentPhase.nextExpectedAttendance;
                                if (nextType == null) return;

                                // Evaluacion de seguridad anti fake GPS
                                if (loc.isBlockedBySecurity) {
                                  _showMockGpsSecurityDialog(context, loc);
                                  return;
                                }

                                // Evaluacion de radio de geocerca autorizada
                                if (!loc.isInsideGeozone) {
                                  _showGeozoneRestrictionDialog(
                                    context,
                                    loc,
                                    nextType,
                                  );
                                  return;
                                }

                                // Apertura del modal simplificado de asistencia
                                final isOffline =
                                    attendanceState is AttendanceLoaded &&
                                    attendanceState.isOffline;
                                _openAttendanceModal(
                                  context: context,
                                  // Durante el turno activo tambien se permite la salida anticipada
                                  options: [
                                    nextType,
                                    if (currentPhase == ShiftPhase.working)
                                      AttendanceType.checkOut,
                                  ],
                                  locationState: loc,
                                  userId: userId,
                                  isOffline: isOffline,
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// Cabecera roja: avatar, nombre del colaborador, empresa activa y menu de sucursales.
  Widget _buildHeader(
    BuildContext context,
    LocationLoaded loc,
    String? userName,
  ) {
    final name =
        (userName == null || userName.isEmpty) ? 'Colaborador' : userName;

    void openBranches() {
      HapticFeedbackService.shared.selectionClick();
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder:
              (routeContext) => BranchesView(
                onBranchSelected: (branch) {
                  Navigator.of(routeContext).pop();
                  if (branch.geozones.isNotEmpty) {
                    _recenter(branch.geozones.first.coordinates);
                  }
                },
              ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        color: AppColors.primary,
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.of(context).padding.top + 6,
          4,
          10,
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white,
                  child: Text(
                    name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color:
                          loc.isBlockedBySecurity
                              ? AppColors.checkOutColor
                              : loc.isInsideGeozone
                              ? AppColors.success
                              : AppColors.lunchColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: openBranches,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.business_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            loc.selectedCompany.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.menu_rounded,
                color: Colors.white,
                size: 30,
              ),
              tooltip: 'Sucursales',
              onPressed: openBranches,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool? isActive,
  }) {
    // isActive == null: boton de accion. true/false: interruptor con estado visible.
    final on = isActive ?? false;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        toggled: isActive,
        child: Material(
          color: on ? Colors.white : AppColors.primary,
          elevation: 3,
          shadowColor: Colors.black38,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: AppColors.primary, width: on ? 2 : 0),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              HapticFeedbackService.shared.selectionClick();
              onTap();
            },
            child: SizedBox(
              width: 42,
              height: 42,
              child: Icon(
                icon,
                color: on ? AppColors.primary : Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Enciende o apaga el modo de sedes: tarjeta superior + flechas laterales.
  void _setBranchExplorer(
    BuildContext context,
    LocationLoaded loc, {
    required bool active,
  }) {
    final cubit = context.read<LocationCubit>();
    if (active) {
      if (!loc.isBranchExplorerActive) cubit.toggleBranchExplorer();
      final geozones = loc.activeMapBranch.geozones;
      if (geozones.isNotEmpty) _recenter(geozones.first.coordinates);
    } else {
      cubit.exitBranchExplorer();
      _recenter(loc.userPosition);
    }
  }

  void _showCompanyBranchesSheet(BuildContext context, LocationLoaded loc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131926) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border:
                isDark
                    ? Border.all(color: const Color(0x33FFFFFF), width: 0.8)
                    : null,
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: loc.selectedCompany.primaryColor.withValues(
                        alpha: 0.18,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        loc.selectedCompany.shortName.length > 4
                            ? loc.selectedCompany.shortName.substring(0, 3)
                            : loc.selectedCompany.shortName,
                        style: TextStyle(
                          color: loc.selectedCompany.primaryColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sucursales de ${loc.selectedCompany.shortName}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color:
                                isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${loc.companyBranches.length} sedes registradas en Lima',
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                isDark
                                    ? AppColors.textMuted
                                    : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: loc.companyBranches.length,
                  itemBuilder: (context, idx) {
                    final branch = loc.companyBranches[idx];
                    final isCurrent = branch.id == loc.activeMapBranch.id;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color:
                            isCurrent
                                ? AppColors.accent.withValues(alpha: 0.12)
                                : (isDark
                                    ? const Color(0xFF0D131F)
                                    : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              isCurrent
                                  ? AppColors.accent
                                  : (isDark
                                      ? const Color(0x22FFFFFF)
                                      : AppColors.borderLight),
                          width: isCurrent ? 1.5 : 0.8,
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.location_city_rounded,
                          color:
                              isCurrent
                                  ? AppColors.accent
                                  : (isDark
                                      ? Colors.white60
                                      : AppColors.textSecondary),
                        ),
                        title: Text(
                          branch.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color:
                                isCurrent
                                    ? AppColors.accent
                                    : (isDark
                                        ? Colors.white
                                        : AppColors.textPrimary),
                          ),
                        ),
                        subtitle: Text(
                          '${branch.address} • ${branch.geozones.length} centros autorizados',
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                isDark
                                    ? AppColors.textMuted
                                    : AppColors.textSecondary,
                          ),
                        ),
                        trailing:
                            isCurrent
                                ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'ACTIVA',
                                    style: TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                )
                                : const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: AppColors.textMuted,
                                  size: 14,
                                ),
                        onTap: () {
                          HapticFeedbackService.shared.selectionClick();
                          Navigator.pop(ctx);
                          context.read<LocationCubit>().selectBranch(branch);
                          _recenter(branch.geozones.first.coordinates);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
