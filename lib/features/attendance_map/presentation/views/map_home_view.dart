import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/asis_glass_card.dart';
import '../../../../core/widgets/asis_security_dialog.dart';
import '../../domain/branch_model.dart';
import '../../domain/shift_phase.dart';
import '../cubit/attendance_cubit.dart';
import '../cubit/attendance_state.dart';
import '../cubit/location_cubit.dart';
import '../cubit/location_state.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../widgets/attendance_action_dock.dart';
import '../widgets/attendance_modal_sheet.dart';
import '../widgets/geozone_status_badge.dart';
import 'package:asisgo/features/calendar_history/presentation/cubit/calendar_cubit.dart';
import '../../../../core/widgets/asis_shimmer.dart';
import '../../../../core/widgets/asis_skeletons.dart';

class MapHomeView extends StatefulWidget {
  const MapHomeView({super.key});

  @override
  State<MapHomeView> createState() => _MapHomeViewState();
}

class _MapHomeViewState extends State<MapHomeView> {
  final MapController _mapController = MapController();
  String? _lastIsolatedBranchId;

  @override
  void initState() {
    super.initState();
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
      try {
        _mapController.move(point, zoom);
      } catch (e) {
        debugPrint('MapController not ready yet: $e');
      }
    });
  }

  void _openAttendanceModal({
    required BuildContext context,
    required AttendanceType type,
    required LocationLoaded locationState,
    required String userId,
  }) {
    AttendanceModalSheet.show(
      context: context,
      type: type,
      branch: locationState.currentBranch,
      geozone: locationState.currentGeozone,
      distanceMeters: locationState.distanceMeters,
      isInside: locationState.isInsideGeozone,
      onConfirm: (note, selfiePath) {
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
        'Radio Permitido': '${loc.currentGeozone.radiusMeters.toStringAsFixed(0)} m',
        'Tu Distancia': loc.distanceMeters < 1000
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

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(child: Text(attendanceState.feedbackMessage!)),
                  ],
                ),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          } else if (attendanceState is AttendanceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(attendanceState.message),
                backgroundColor: AppColors.checkOutColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, attendanceState) {
          return BlocConsumer<LocationCubit, LocationState>(
            listener: (context, locationState) {
              if (locationState is LocationLoaded) {
                if (_lastIsolatedBranchId != locationState.isolatedBranchId) {
                  _lastIsolatedBranchId = locationState.isolatedBranchId;
                  if (locationState.activeMapBranch.geozones.isNotEmpty) {
                    _recenter(locationState.activeMapBranch.geozones.first.coordinates);
                  }
                }
              }
            },
            builder: (context, locationState) {
              if (locationState is LocationLoading || locationState is LocationInitial) {
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
                        const Icon(Icons.location_disabled_rounded, size: 56, color: AppColors.checkOutColor),
                        const SizedBox(height: 16),
                        Text(
                          locationState.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => context.read<LocationCubit>().initLocation(),
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
              final safeAreaTop = mediaQuery.padding.top;
              final safeAreaBottom = mediaQuery.padding.bottom;

              // Calculo dinamico para evitar solapamientos con el dock de asistencia
              final isWorkingPhase = attendanceState is AttendanceLoaded &&
                  attendanceState.currentPhase == ShiftPhase.working;
              final branchCardBottom = safeAreaBottom + (isWorkingPhase ? 218.0 : 176.0);

              // Posicionamiento de controles flotantes y flechas laterales anticolision
              final toolButtonsTop = safeAreaTop + 86.0;
              final arrowTop = math.max(screenHeight * 0.48, toolButtonsTop + 195.0);

              // Generar elementos visuales de geocercas exclusivamente para la empresa seleccionada
              final circleMarkers = <CircleMarker>[];
              final mapMarkers = <Marker>[];

              final activeBranch = loc.activeMapBranch;
              // 1. Geocercas detalladas para la sede activa
              for (final gz in activeBranch.geozones) {
                final isCurrentGz = gz.id == loc.currentGeozone.id;
                final isCurrentAndInside = isCurrentGz && loc.isInsideGeozone;

                circleMarkers.add(
                  CircleMarker(
                    point: gz.coordinates,
                    radius: gz.radiusMeters,
                    useRadiusInMeter: true,
                    color: isCurrentAndInside
                        ? AppColors.accent.withValues(alpha: 0.18)
                        : isCurrentGz
                            ? AppColors.lunchColor.withValues(alpha: 0.15)
                            : gz.type.color.withValues(alpha: 0.08),
                    borderColor: isCurrentAndInside
                        ? AppColors.accent
                        : isCurrentGz
                            ? AppColors.lunchColor
                            : gz.type.color.withValues(alpha: 0.6),
                    borderStrokeWidth: isCurrentGz ? 2.5 : 1.2,
                  ),
                );

                mapMarkers.add(
                  Marker(
                    point: gz.coordinates,
                    width: 90,
                    height: 54,
                    child: GestureDetector(
                      onTap: () {
                        _recenter(gz.coordinates);
                        context.read<LocationCubit>().simulateUserPosition(gz.coordinates);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xEE1E293B),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isCurrentGz ? AppColors.accent : Colors.white24,
                                width: isCurrentGz ? 1.5 : 0.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(gz.type.icon, size: 11, color: isCurrentGz ? AppColors.accent : Colors.white),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    gz.name,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: isCurrentGz ? AppColors.accent : Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.location_on_rounded,
                            size: 20,
                            color: isCurrentGz ? AppColors.accent : gz.type.color,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // 2. Marcadores interactivos para las otras sedes de la misma empresa
              for (final otherBranch in loc.companyBranches) {
                if (otherBranch.id != activeBranch.id) {
                  mapMarkers.add(
                    Marker(
                      point: otherBranch.coordinates,
                      width: 84,
                      height: 50,
                      child: GestureDetector(
                        onTap: () {
                          context.read<LocationCubit>().selectBranch(otherBranch);
                          _recenter(otherBranch.geozones.first.coordinates);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xDD0D131F),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white24, width: 0.8),
                              ),
                              child: Text(
                                otherBranch.name,
                                style: const TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.location_city_rounded, size: 18, color: Colors.white60),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              }

              // Marcador de posicion actual del usuario
              mapMarkers.add(
                Marker(
                  point: loc.userPosition,
                  width: 44,
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (loc.isBlockedBySecurity
                                  ? AppColors.checkOutColor
                                  : loc.isInsideGeozone
                                      ? AppColors.accent
                                      : AppColors.lunchColor)
                              .withValues(alpha: 0.25),
                        ),
                      ),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: loc.isBlockedBySecurity
                              ? AppColors.checkOutColor
                              : loc.isInsideGeozone
                                  ? AppColors.accent
                                  : AppColors.lunchColor,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );

              return Stack(
                children: [
                  // Capa base de mapa de alto rendimiento en modo oscuro
                  Container(
                    color: AppColors.obsidianCanvas,
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: loc.userPosition,
                        initialZoom: 16.5,
                        minZoom: 4,
                        maxZoom: 19,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          tileBuilder: (context, tileWidget, tile) {
                            return ColorFiltered(
                              colorFilter: const ColorFilter.matrix(<double>[
                                -0.85, 0, 0, 0, 215,
                                0, -0.85, 0, 0, 215,
                                0, 0, -0.80, 0, 225,
                                0, 0, 0, 1, 0,
                              ]),
                              child: tileWidget,
                            );
                          },
                          userAgentPackageName: 'com.asisgo.app',
                          maxZoom: 19,
                        ),
                        if (loc.showAllGeozones) CircleLayer(circles: circleMarkers),
                        MarkerLayer(markers: mapMarkers),
                      ],
                    ),
                  ),

                  // Capsula flotante superior con estado de geozona
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: GeozoneStatusBadge(
                        isInside: loc.isInsideGeozone,
                        distanceMeters: loc.distanceMeters,
                        branch: loc.currentBranch,
                        geozone: loc.currentGeozone,
                        isMocked: loc.isMocked,
                        isMockProtectionActive: loc.isMockProtectionActive,
                      ),
                    ),
                  ),

                  // Flechas laterales para alternar sedes de la empresa activa
                  if (loc.isBranchExplorerActive && loc.companyBranches.length > 1) ...[
                    // Flecha lateral izquierda
                    Positioned(
                      left: 14,
                      top: arrowTop,
                      child: AsisGlassCard(
                        borderRadius: 28,
                        padding: EdgeInsets.zero,
                        isDark: true,
                        customBackground: const Color(0xEE0D131F),
                        customBorderColor: const Color(0x44FFFFFF),
                        child: IconButton(
                          icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 30),
                          tooltip: 'Sede anterior de ${loc.selectedCompany.shortName}',
                          onPressed: () {
                            final cubit = context.read<LocationCubit>();
                            cubit.previousBranch();
                            final updated = cubit.state;
                            if (updated is LocationLoaded) {
                              _recenter(updated.activeMapBranch.geozones.first.coordinates);
                            }
                          },
                        ),
                      ),
                    ),

                    // Flecha lateral derecha
                    Positioned(
                      right: 14,
                      top: arrowTop,
                      child: AsisGlassCard(
                        borderRadius: 28,
                        padding: EdgeInsets.zero,
                        isDark: true,
                        customBackground: const Color(0xEE0D131F),
                        customBorderColor: const Color(0x44FFFFFF),
                        child: IconButton(
                          icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 30),
                          tooltip: 'Siguiente sede de ${loc.selectedCompany.shortName}',
                          onPressed: () {
                            final cubit = context.read<LocationCubit>();
                            cubit.nextBranch();
                            final updated = cubit.state;
                            if (updated is LocationLoaded) {
                              _recenter(updated.activeMapBranch.geozones.first.coordinates);
                            }
                          },
                        ),
                      ),
                    ),
                  ],

                  // Tarjeta flotante de exploracion de sedes sobre el dock con elevacion dinamica
                  if (loc.isBranchExplorerActive)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      left: 16,
                      right: 16,
                      bottom: branchCardBottom,
                      child: GestureDetector(
                        onTap: () => _showCompanyBranchesSheet(context, loc),
                        child: AsisGlassCard(
                          borderRadius: 18,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          isDark: true,
                          customBackground: const Color(0xEE0B111E),
                          customBorderColor: AppColors.accent.withValues(alpha: 0.5),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.business_rounded, color: AppColors.accent, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            loc.activeMapBranch.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '${loc.currentBranchIndex + 1} de ${loc.companyBranches.length}',
                                            style: const TextStyle(
                                              color: AppColors.accent,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${loc.activeMapBranch.address} • ${loc.selectedCompany.shortName}',
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  context.read<LocationCubit>().exitBranchExplorer();
                                  _recenter(loc.userPosition);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded, size: 16, color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Controles flotantes del mapa
                  Positioned(
                    right: 16,
                    top: toolButtonsTop,
                    child: AsisGlassCard(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                      borderRadius: 22,
                      isDark: true,
                      customBackground: const Color(0xDD0D131F),
                      customBorderColor: const Color(0x33FFFFFF),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Centrar en la ubicacion real del usuario
                          _buildGlassIconButton(
                            icon: Icons.my_location_rounded,
                            tooltip: 'Centrar en mi ubicación',
                            onTap: () {
                              _recenter(loc.userPosition);
                            },
                          ),
                          const SizedBox(height: 6),

                          // Modo explorador de sedes de la empresa activa
                          _buildGlassIconButton(
                            icon: Icons.domain_rounded,
                            color: loc.isBranchExplorerActive ? AppColors.accent : Colors.white70,
                            tooltip: 'Sedes de ${loc.selectedCompany.shortName}',
                            onTap: () {
                              final cubit = context.read<LocationCubit>();
                              if (!loc.isBranchExplorerActive) {
                                cubit.toggleBranchExplorer();
                                if (loc.companyBranches.isNotEmpty) {
                                  _recenter(loc.activeMapBranch.geozones.first.coordinates);
                                }
                              } else {
                                _showCompanyBranchesSheet(context, loc);
                              }
                            },
                          ),
                          const SizedBox(height: 6),

                          // Alternar visibilidad de geocercas
                          _buildGlassIconButton(
                            icon: loc.showAllGeozones
                                ? Icons.layers_rounded
                                : Icons.layers_clear_rounded,
                            color: loc.showAllGeozones ? AppColors.accent : Colors.white70,
                            tooltip: 'Mostrar/Ocultar Geozonas',
                            onTap: () => context.read<LocationCubit>().toggleGeozonesVisibility(),
                          ),
                          const SizedBox(height: 6),

                          // Sincronizar ubicacion del hardware GPS
                          _buildGlassIconButton(
                            icon: Icons.sync_rounded,
                            tooltip: 'Sincronizar Ubicación GPS',
                            onTap: () {
                              context.read<LocationCubit>().syncDeviceLocation();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Ubicación GPS sincronizada en tiempo real'),
                                  duration: Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Barra inferior dinamica de marcacion de asistencia
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: SafeArea(
                      child: AttendanceActionDock(
                        phase: attendanceState is AttendanceLoaded
                            ? attendanceState.currentPhase
                            : ShiftPhase.notStarted,
                        todayRecords: attendanceState is AttendanceLoaded
                            ? attendanceState.todayRecords
                            : [],
                        lastRecord: attendanceState is AttendanceLoaded
                            ? attendanceState.lastRecord
                            : null,
                        isInsideGeozone: loc.isInsideGeozone,
                        onPrimaryActionPressed: () {
                          final currentPhase = attendanceState is AttendanceLoaded
                              ? attendanceState.currentPhase
                              : ShiftPhase.notStarted;
                          final nextType = currentPhase.nextExpectedAttendance;
                          if (nextType == null) return;

                          // Evaluacion de seguridad anti fake GPS
                          if (loc.isBlockedBySecurity) {
                            _showMockGpsSecurityDialog(context, loc);
                            return;
                          }

                          // Evaluacion de radio de geocerca autorizada
                          if (!loc.isInsideGeozone) {
                            _showGeozoneRestrictionDialog(context, loc, nextType);
                            return;
                          }

                          // Apertura del modal simplificado de asistencia
                          _openAttendanceModal(
                            context: context,
                            type: nextType,
                            locationState: loc,
                            userId: userId,
                          );
                        },
                        onSecondaryActionPressed: () {
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
                              AttendanceType.checkOut,
                            );
                            return;
                          }

                          // Apertura del modal para salida anticipada
                          _openAttendanceModal(
                            context: context,
                            type: AttendanceType.checkOut,
                            locationState: loc,
                            userId: userId,
                          );
                        },
                      ),
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

  Widget _buildGlassIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return IconButton(
      icon: Icon(icon, color: color, size: 20),
      tooltip: tooltip,
      constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
    );
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
            border: isDark ? Border.all(color: const Color(0x33FFFFFF), width: 0.8) : null,
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
                      color: loc.selectedCompany.primaryColor.withValues(alpha: 0.18),
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
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${loc.companyBranches.length} sedes registradas en Lima',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.textMuted : AppColors.textSecondary,
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
                        color: isCurrent
                            ? AppColors.accent.withValues(alpha: 0.12)
                            : (isDark ? const Color(0xFF0D131F) : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCurrent
                              ? AppColors.accent
                              : (isDark ? const Color(0x22FFFFFF) : AppColors.borderLight),
                          width: isCurrent ? 1.5 : 0.8,
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.location_city_rounded,
                          color: isCurrent ? AppColors.accent : (isDark ? Colors.white60 : AppColors.textSecondary),
                        ),
                        title: Text(
                          branch.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isCurrent ? AppColors.accent : (isDark ? Colors.white : AppColors.textPrimary),
                          ),
                        ),
                        subtitle: Text(
                          '${branch.address} • ${branch.geozones.length} centros autorizados',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                          ),
                        ),
                        trailing: isCurrent
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.2),
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
                            : const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 14),
                        onTap: () {
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
