import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/haptic_feedback_service.dart';
import '../../core/services/permission_service.dart';
import '../../core/theme/asis_palette.dart';
import '../../core/tracking/attendance_tracking_service.dart';

/// Pantalla previa al Home: explica para que se usan los permisos y los pide
/// justo despues del login. Solo aparece si falta algo por configurar.
///
/// "Ahora no" la omite durante esta sesion de la app; los permisos siguen
/// disponibles en Mi perfil.
class PermissionsGate extends StatefulWidget {
  const PermissionsGate({super.key, required this.child});

  final Widget child;

  // Se recuerda mientras la app siga abierta (no se insiste en cada login).
  static bool _skipped = false;

  @override
  State<PermissionsGate> createState() => _PermissionsGateState();
}

class _PermissionsGateState extends State<PermissionsGate> {
  late final IPermissionService _permissions =
      context.read<IPermissionService>();
  PermissionSnapshot? _snapshot;
  bool _alwaysOffered = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tracking = context.read<AttendanceTrackingService>();
    final snapshot = await _permissions.snapshot();
    final offered = await tracking.wasAlwaysOffered();
    if (!mounted) return;
    setState(() {
      _snapshot = snapshot;
      _alwaysOffered = offered;
    });
  }

  /// Hay algo que el usuario aun puede decidir desde la pantalla.
  bool _needsOnboarding(PermissionSnapshot s) {
    if (PermissionsGate._skipped) return false;
    final locationPending =
        s.location == LocationAccess.notDetermined ||
        // iOS solo ofrece "Siempre" una vez: no se insiste si ya se ofrecio.
        (s.location == LocationAccess.whileInUse && !_alwaysOffered);
    return locationPending || s.motion == SimplePermission.notDetermined;
  }

  @override
  Widget build(BuildContext context) {
    final s = _snapshot;
    if (s == null) {
      return Scaffold(backgroundColor: context.palette.background);
    }
    if (!_needsOnboarding(s)) return widget.child;
    return PermissionsOnboardingPage(
      snapshot: s,
      onFinished: (skipped) {
        if (skipped) PermissionsGate._skipped = true;
        _load();
      },
    );
  }
}

class PermissionsOnboardingPage extends StatefulWidget {
  const PermissionsOnboardingPage({
    super.key,
    required this.snapshot,
    required this.onFinished,
  });

  final PermissionSnapshot snapshot;
  final void Function(bool skipped) onFinished;

  @override
  State<PermissionsOnboardingPage> createState() =>
      _PermissionsOnboardingPageState();
}

class _PermissionsOnboardingPageState extends State<PermissionsOnboardingPage> {
  bool _busy = false;

  /// Pide en orden los permisos de iOS: "Al usar la app", luego "Siempre" y por
  /// ultimo movimiento. Cada aviso es el del sistema; no se muestran dialogos
  /// propios para cambiar ajustes.
  Future<void> _continue() async {
    if (_busy) return;
    HapticFeedbackService.shared.selectionClick();
    setState(() => _busy = true);
    final permissions = context.read<IPermissionService>();
    final tracking = context.read<AttendanceTrackingService>();
    try {
      var snapshot = await permissions.snapshot();
      if (snapshot.location == LocationAccess.notDetermined) {
        await permissions.requestWhenInUse();
        snapshot = await permissions.snapshot();
      }
      if (snapshot.location == LocationAccess.whileInUse) {
        // iOS solo ofrece "Siempre" una vez.
        await tracking.markAlwaysOffered();
        await permissions.requestAlways();
      }
      if (snapshot.motion == SimplePermission.notDetermined) {
        await permissions.requestMotion();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
      widget.onFinished(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: p.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.verified_user_rounded,
                      size: 36,
                      color: p.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Antes de empezar',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: p.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Para registrar tu asistencia necesitamos algunos permisos. '
                    'Solo se usan durante tu jornada.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: p.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _Reason(
                    icon: Icons.location_on_rounded,
                    title: 'Ubicación: "Siempre"',
                    body:
                        'Valida que marcas dentro de tu sede y registra tu '
                        'recorrido aunque la app esté en segundo plano. '
                        'Empieza con tu entrada y se detiene al marcar tu salida.',
                  ),
                  const _Reason(
                    icon: Icons.directions_walk_rounded,
                    title: 'Movimiento y condición física',
                    body:
                        'Detecta si estás en movimiento para gastar menos '
                        'batería. Es opcional.',
                  ),
                  const _Reason(
                    icon: Icons.privacy_tip_rounded,
                    title: 'Tu privacidad',
                    body:
                        'Nunca se recoge tu ubicación fuera de la jornada. '
                        'iOS te mostrará un indicador mientras se use.',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _busy ? null : _continue,
                      style: FilledButton.styleFrom(
                        backgroundColor: p.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child:
                          _busy
                              ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              )
                              : const Text(
                                'Continuar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                    ),
                  ),
                  TextButton(
                    onPressed: _busy ? null : () => widget.onFinished(true),
                    child: Text(
                      'Ahora no',
                      style: TextStyle(color: p.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Reason extends StatelessWidget {
  const _Reason({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: p.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: p.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: p.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
