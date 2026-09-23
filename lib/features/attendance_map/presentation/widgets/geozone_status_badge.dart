import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/asis_glass_card.dart';
import '../../../../core/widgets/asis_radar_indicator.dart';
import '../../domain/branch_model.dart';

class GeozoneStatusBadge extends StatelessWidget {
  final bool isInside;
  final double distanceMeters;
  final Branch branch;
  final Geozone geozone;
  final bool isMocked;
  final bool isMockProtectionActive;

  const GeozoneStatusBadge({
    super.key,
    required this.isInside,
    required this.distanceMeters,
    required this.branch,
    required this.geozone,
    this.isMocked = false,
    this.isMockProtectionActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isInside ? AppColors.accent : AppColors.lunchColor;
    final formattedDistance = distanceMeters < 1000
        ? '${distanceMeters.toStringAsFixed(0)} m'
        : '${(distanceMeters / 1000).toStringAsFixed(1)} km';

    final isAttackBlocked = isMockProtectionActive && isMocked;

    return AsisGlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderRadius: 22,
      isDark: true,
      customBackground: const Color(0xDD0D131F),
      customBorderColor: isAttackBlocked
          ? AppColors.checkOutColor.withValues(alpha: 0.6)
          : isInside
              ? AppColors.accent.withValues(alpha: 0.35)
              : const Color(0x33FFFFFF),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Indicador pulsante de radar
              AsisRadarIndicator(
                color: isAttackBlocked ? AppColors.checkOutColor : statusColor,
                size: 9,
                isPulsing: true,
              ),
              const SizedBox(width: 8),

              // Titulo de estado y datos de la geozona
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAttackBlocked
                          ? 'GPS BLOQUEADO (MOCK)'
                          : isInside
                              ? 'DENTRO DE GEOZONA'
                              : 'FUERA DE GEOZONA',
                      style: TextStyle(
                        color: isAttackBlocked
                            ? AppColors.checkOutColor
                            : statusColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.6,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${branch.name} • ${geozone.name}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Distancia geodesica calculada
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isInside
                      ? AppColors.accent.withValues(alpha: 0.2)
                      : const Color(0x22FFFFFF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isInside
                        ? AppColors.accent.withValues(alpha: 0.4)
                        : const Color(0x33FFFFFF),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  formattedDistance,
                  style: TextStyle(
                    color: isInside ? AppColors.accent : Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),

          // Alerta visual cuando se detecta suplantacion de ubicacion
          if (isAttackBlocked) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.checkOutColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.checkOutColor.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.checkOutColor),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Fake GPS activo en Opciones de Desarrollador. Marcación bloqueada.',
                      style: TextStyle(
                        color: Color(0xFFFCA5A5),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
