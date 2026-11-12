import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/haptic_feedback_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/theme/asis_palette.dart';

/// Estado de los permisos que usa el seguimiento de la jornada, con la accion
/// que corresponde a cada caso. Se actualiza al volver desde Ajustes.
class PermissionsCard extends StatefulWidget {
  const PermissionsCard({super.key});

  @override
  State<PermissionsCard> createState() => _PermissionsCardState();
}

class _PermissionsCardState extends State<PermissionsCard>
    with WidgetsBindingObserver {
  late final IPermissionService _service = context.read<IPermissionService>();
  PermissionSnapshot? _snapshot;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // El usuario cambia los permisos en Ajustes y vuelve a la app.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final snapshot = await _service.snapshot();
    if (mounted) setState(() => _snapshot = snapshot);
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    HapticFeedbackService.shared.selectionClick();
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
      await _refresh();
    }
  }

  Future<void> _showInstructions(String title, String steps) async {
    final open = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(title),
            content: Text(steps),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Ahora no'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Abrir Ajustes'),
              ),
            ],
          ),
    );
    if (open == true) await _service.openSettings();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = _snapshot;

    return Material(
      color: p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: p.border),
      ),
      clipBehavior: Clip.antiAlias,
      child:
          s == null
              ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
              : Column(
                children: [
                  _locationTile(s),
                  Divider(height: 1, indent: 16, color: p.border),
                  _backgroundRefreshTile(s),
                  Divider(height: 1, indent: 16, color: p.border),
                  _motionTile(s),
                ],
              ),
    );
  }

  // --- Ubicacion -----------------------------------------------------------

  Widget _locationTile(PermissionSnapshot s) {
    final p = context.palette;
    if (!s.locationServicesEnabled &&
        s.location != LocationAccess.notDetermined) {
      return _tile(
        title: 'Ubicación',
        status: 'Servicios de ubicación apagados',
        color: p.danger,
        detail:
            'Actívalos en Ajustes > Privacidad y seguridad > Localización para poder registrar tu asistencia.',
        action: 'Abrir Ajustes',
        onTap: () => _run(() async => _service.openSettings()),
      );
    }
    return switch (s.location) {
      LocationAccess.always => _tile(
        title: 'Ubicación',
        status: 'Siempre',
        color: p.success,
        detail: 'Tu jornada se registra aunque la app esté en segundo plano.',
      ),
      LocationAccess.whileInUse => _tile(
        title: 'Ubicación',
        status: 'Al usar la app',
        color: p.warning,
        detail:
            'Para registrar tu jornada con la app en segundo plano, elige "Siempre".',
        action: 'Permitir siempre',
        onTap:
            () => _run(() async {
              final result = await _service.requestAlways();
              // iOS solo muestra el aviso una vez; si no cambió, guía a Ajustes.
              if (result != LocationAccess.always && mounted) {
                await _showInstructions(
                  'Permitir ubicación "Siempre"',
                  'iOS solo ofrece esta opción una vez. Para activarla:\n\n'
                      '1. Abre Ajustes > AsisGo > Ubicación.\n'
                      '2. Elige "Siempre".\n\n'
                      'Solo se registra durante tu jornada y se detiene al marcar tu salida.',
                );
              }
            }),
      ),
      LocationAccess.denied => _tile(
        title: 'Ubicación',
        status: 'Denegada',
        color: p.danger,
        detail: 'Sin ubicación no se puede validar tu asistencia en la sede.',
        action: 'Abrir Ajustes',
        onTap:
            () => _run(
              () => _showInstructions(
                'Activar la ubicación',
                '1. Abre Ajustes > AsisGo > Ubicación.\n'
                    '2. Elige "Al usar la app" o "Siempre".',
              ),
            ),
      ),
      LocationAccess.restricted => _tile(
        title: 'Ubicación',
        status: 'Restringida por el sistema',
        color: p.danger,
        detail:
            'Un control parental o de empresa bloquea la ubicación. Consulta con tu administrador.',
      ),
      LocationAccess.notDetermined => _tile(
        title: 'Ubicación',
        status: 'Sin configurar',
        color: p.textSecondary,
        detail: 'Permite la ubicación para registrar tu asistencia.',
        action: 'Permitir',
        onTap: () => _run(() async => _service.requestWhenInUse()),
      ),
    };
  }

  // --- Actualizacion en segundo plano --------------------------------------

  Widget _backgroundRefreshTile(PermissionSnapshot s) {
    final p = context.palette;
    return switch (s.backgroundRefresh) {
      BackgroundRefresh.available => _tile(
        title: 'Actualización en segundo plano',
        status: 'Activada',
        color: p.success,
        detail: 'La app puede sincronizar tus marcaciones sin estar abierta.',
      ),
      BackgroundRefresh.denied => _tile(
        title: 'Actualización en segundo plano',
        status: 'Desactivada',
        color: p.warning,
        detail:
            'Sin ella el sistema puede detener la app en segundo plano antes de tiempo.',
        action: 'Cómo activarla',
        onTap:
            () => _run(
              () => _showInstructions(
                'Activar la actualización en segundo plano',
                'Esta opción solo se cambia desde el iPhone:\n\n'
                    '1. Abre Ajustes > General > Actualización en segundo plano.\n'
                    '2. Activa "Actualización en 2.º plano" y también AsisGo.\n\n'
                    'Si está en "Solo Wi-Fi" o el modo de bajo consumo está activo, '
                    'también puede limitarse.',
              ),
            ),
      ),
      BackgroundRefresh.restricted => _tile(
        title: 'Actualización en segundo plano',
        status: 'Restringida por el sistema',
        color: p.danger,
        detail: 'No se puede activar en este dispositivo.',
      ),
      BackgroundRefresh.unknown => _tile(
        title: 'Actualización en segundo plano',
        status: 'No disponible',
        color: p.textSecondary,
        detail: 'No se pudo consultar su estado.',
      ),
    };
  }

  // --- Movimiento y condicion fisica ---------------------------------------

  Widget _motionTile(PermissionSnapshot s) {
    final p = context.palette;
    return switch (s.motion) {
      SimplePermission.granted => _tile(
        title: 'Movimiento y condición física',
        status: 'Permitido',
        color: p.success,
        detail: 'Ayuda a saber si estás en movimiento y a cuidar la batería.',
      ),
      SimplePermission.denied => _tile(
        title: 'Movimiento y condición física',
        status: 'Denegado',
        color: p.warning,
        detail:
            'Es opcional: el seguimiento funciona sin él, con algo más de batería.',
        action: 'Abrir Ajustes',
        onTap:
            () => _run(
              () => _showInstructions(
                'Permitir movimiento y condición física',
                '1. Abre Ajustes > AsisGo.\n2. Activa "Movimiento y forma física".',
              ),
            ),
      ),
      SimplePermission.restricted => _tile(
        title: 'Movimiento y condición física',
        status: 'Restringido por el sistema',
        color: p.textSecondary,
        detail: 'Es opcional; el seguimiento funciona sin él.',
      ),
      SimplePermission.notDetermined => _tile(
        title: 'Movimiento y condición física',
        status: 'Sin configurar',
        color: p.textSecondary,
        detail: 'Opcional. Ayuda a cuidar la batería durante tu jornada.',
        action: 'Permitir',
        onTap: () => _run(() async => _service.requestMotion()),
      ),
    };
  }

  // --- Pieza comun -----------------------------------------------------------

  Widget _tile({
    required String title,
    required String status,
    required Color color,
    required String detail,
    String? action,
    VoidCallback? onTap,
  }) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(fontSize: 13, color: p.textSecondary),
                ),
              ],
            ),
          ),
          if (action != null && onTap != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: _busy ? null : onTap,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: Text(
                action,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
