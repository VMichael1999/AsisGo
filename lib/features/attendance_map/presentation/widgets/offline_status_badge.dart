import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/asis_glass_card.dart';

class OfflineStatusBadge extends StatefulWidget {
  final bool isOffline;
  final int pendingSyncCount;
  final bool isSyncing;
  final VoidCallback? onSyncTap;

  const OfflineStatusBadge({
    super.key,
    required this.isOffline,
    required this.pendingSyncCount,
    this.isSyncing = false,
    this.onSyncTap,
  });

  @override
  State<OfflineStatusBadge> createState() => _OfflineStatusBadgeState();
}

class _OfflineStatusBadgeState extends State<OfflineStatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    if (widget.isSyncing) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant OfflineStatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSyncing != oldWidget.isSyncing) {
      if (widget.isSyncing) {
        _rotationController.repeat();
      } else {
        _rotationController.stop();
        _rotationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si esta en linea y no hay marcas pendientes, ocultar
    if (!widget.isOffline && widget.pendingSyncCount == 0 && !widget.isSyncing) {
      return const SizedBox.shrink();
    }

    final isOffline = widget.isOffline;
    final badgeColor = isOffline ? const Color(0xFFF59E0B) : AppColors.accent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: AsisGlassCard(
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDark: true,
        customBackground: isOffline ? const Color(0xEE1E160C) : const Color(0xEE0B1A28),
        customBorderColor: badgeColor.withValues(alpha: 0.4),
        child: Row(
          children: [
            // Icono animado o estatico
            if (widget.isSyncing)
              RotationTransition(
                turns: _rotationController,
                child: Icon(Icons.sync_rounded, color: badgeColor, size: 18),
              )
            else
              Icon(
                isOffline ? Icons.wifi_off_rounded : Icons.cloud_upload_outlined,
                color: badgeColor,
                size: 18,
              ),
            const SizedBox(width: 10),

            // Textos informativos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isOffline
                        ? 'MODO SIN CONEXIÓN'
                        : widget.isSyncing
                            ? 'SINCRONIZANDO MARCAS...'
                            : 'MARCAS PENDIENTES',
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    isOffline
                        ? (widget.pendingSyncCount > 0
                            ? '${widget.pendingSyncCount} marca(s) guardada(s) localmente'
                            : 'Marcas se guardarán y enviarán al volver la red')
                        : '${widget.pendingSyncCount} registro(s) por sincronizar con el servidor',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Boton de sincronizacion manual si no esta sincronizando
            if (!isOffline && widget.pendingSyncCount > 0 && !widget.isSyncing) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: widget.onSyncTap,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sync_rounded, size: 13, color: AppColors.accent),
                      SizedBox(width: 4),
                      Text(
                        'Sincronizar',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
