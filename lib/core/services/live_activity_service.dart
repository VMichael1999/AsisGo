import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:intl/intl.dart';
import 'package:live_island_kit/live_island_kit.dart';
import '../../features/attendance_map/domain/shift_phase.dart';

/// Dynamic Island y pantalla de bloqueo del turno (iOS), con live_island_kit.
///
/// Cada marcacion muestra su propio estado: entrada, refrigerio, fin de
/// refrigerio y salida. Android sigue usando su notificacion propia.
class LiveActivityService {
  static final LiveActivityService _instance = LiveActivityService._internal();
  factory LiveActivityService() => _instance;
  LiveActivityService._internal();

  /// Id propio: si ya hay una actividad viva, `start` la actualiza.
  static const String _activityId = 'asisgo-turno';

  /// Tras la salida la tarjeta queda visible este tiempo antes de retirarse.
  static const Duration _exitVisibleFor = Duration(minutes: 10);

  Timer? _exitTimer;
  String _initials = 'A';

  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  /// Se mantiene por compatibilidad con la inicializacion de notificaciones.
  Future<void> initialize() async {}

  /// Iniciales que se muestran en el avatar de la isla.
  void setCollaborator(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty);
    final initials = parts.take(2).map((p) => p[0].toUpperCase()).join();
    _initials = initials.isEmpty ? 'A' : initials;
  }

  /// Sincroniza la isla con la fase del turno.
  Future<void> syncShift({
    required ShiftPhase phase,
    required String branchName,
    DateTime? shiftStartTime,
    DateTime? lunchStartTime,
    DateTime? lastPunchTime,
    bool isInsideGeozone = true,
  }) async {
    if (!_isIOS) return;
    final exitIsOld =
        phase == ShiftPhase.completed &&
        (lastPunchTime == null ||
            DateTime.now().difference(lastPunchTime) > _exitVisibleFor);
    if (phase == ShiftPhase.notStarted || exitIsOld) {
      await endShiftActivity();
      return;
    }

    final state = _stateFor(
      phase,
      lunchStartTime: lunchStartTime,
      punchTime: lastPunchTime ?? DateTime.now(),
    );

    try {
      await LiveIsland.start(
        customId: _activityId,
        layout: shiftLayout,
        state: state,
        relevance: 100,
      );
      _exitTimer?.cancel();
      if (phase == ShiftPhase.completed) {
        // Iniciar el fin de la actividad la saca de la isla al instante, asi que
        // se mantiene viva y se retira pasado el tiempo.
        final elapsed = DateTime.now().difference(
          lastPunchTime ?? DateTime.now(),
        );
        _exitTimer = Timer(_exitVisibleFor - elapsed, endShiftActivity);
      }
    } catch (e) {
      debugPrint('[LiveActivityService] No se pudo actualizar la isla: $e');
    }
  }

  /// Retira la actividad del turno de inmediato.
  Future<void> endShiftActivity() async {
    _exitTimer?.cancel();
    if (!_isIOS) return;
    try {
      await LiveIsland.endAll();
    } catch (e) {
      debugPrint('[LiveActivityService] No se pudo finalizar la isla: $e');
    }
  }

  Map<String, Object?> _stateFor(
    ShiftPhase phase, {
    DateTime? lunchStartTime,
    required DateTime punchTime,
  }) {
    final (fase, titulo, detalle) = switch (phase) {
      ShiftPhase.working || ShiftPhase.notStarted => (
        'entrada',
        'Entrada registrada',
        'Jornada laboral',
      ),
      ShiftPhase.onLunch => ('refrigerio', 'Refrigerio iniciado', 'Duración'),
      ShiftPhase.resumed => (
        'finRefrigerio',
        'Refrigerio finalizado',
        'Regreso a labores',
      ),
      ShiftPhase.completed => (
        'salida',
        'Salida registrada',
        'Jornada finalizada',
      ),
    };
    return {
      'fase': fase,
      'titulo': titulo,
      'detalle': detalle,
      'hora': 'Hoy, ${DateFormat('h:mm a', 'es').format(punchTime)}',
      'iniciales': _initials,
      'refrigerioDesde': lunchStartTime ?? punchTime,
    };
  }

  // ---------------------------------------------------------------------------
  // Diseño (viaja una vez al iniciar; cada cambio solo envia el estado)
  // ---------------------------------------------------------------------------

  static const _green = Color(0xFF34C759);
  static const _orange = Color(0xFFFF9F0A);
  static const _red = Color(0xFFFF453A);
  static const _teal = Color(0xFF30D5C8);

  static LiveCondition _is(String fase) => bind('fase').equals(fase);

  /// Elige un nodo segun la fase del turno.
  static LiveNode _byPhase({
    required LiveNode entrada,
    required LiveNode refrigerio,
    required LiveNode finRefrigerio,
    required LiveNode salida,
  }) => LiveIf(
    _is('entrada'),
    then: entrada,
    otherwise: LiveIf(
      _is('refrigerio'),
      then: refrigerio,
      otherwise: LiveIf(
        _is('finRefrigerio'),
        then: finRefrigerio,
        otherwise: salida,
      ),
    ),
  );

  static const _forkIcon = LiveIcon.symbol('fork.knife', color: _orange);
  static const _exitIcon = LiveIcon.symbol(
    'rectangle.portrait.and.arrow.right',
    color: _red,
  );

  static LiveNode _compactLabel(LiveNode icon, String text) =>
      LiveRow([icon, LiveText.literal(text, size: 13, weight: 600)], gap: 4);

  static LiveNode _detailRow(LiveNode icon, LiveNode value, {String? label}) =>
      LiveRow([
        icon,
        if (label != null) LiveText.literal(label, size: 13, muted: true),
        value,
      ], gap: 6);

  static final LiveLayout shiftLayout = LiveLayout(
    theme: const LiveTheme(accent: Color(0xFF4A6CD4)),
    // Isla compacta: avatar a la izquierda, estado a la derecha
    compactLeading: LiveAvatar.bound(bind('iniciales'), size: 22),
    compactTrailing: _byPhase(
      entrada: _compactLabel(
        const LiveIcon.symbol('circle.fill', size: 8, color: _green),
        'Entrada',
      ),
      refrigerio: _compactLabel(_forkIcon, 'Refrigerio'),
      finRefrigerio: _compactLabel(_forkIcon, 'Fin refrigerio'),
      salida: _compactLabel(_exitIcon, 'Salida'),
    ),
    minimal: _byPhase(
      entrada: const LiveIcon.symbol('checkmark.circle.fill', color: _green),
      refrigerio: _forkIcon,
      finRefrigerio: _forkIcon,
      salida: _exitIcon,
    ),
    // Isla expandida y pantalla de bloqueo: avatar a la izquierda y, a su lado,
    // titulo, hora y detalle alineados a la izquierda.
    expanded: LiveExpanded(
      leading: LiveAvatar.bound(bind('iniciales'), size: 46),
      center: LiveRow([
        LiveColumn(
          [
            LiveRow([
              _byPhase(
                entrada: const LiveIcon.symbol(
                  'checkmark.circle.fill',
                  size: 20,
                  color: _green,
                ),
                refrigerio: _forkIcon,
                finRefrigerio: _forkIcon,
                salida: _exitIcon,
              ),
              LiveText(bind('titulo'), size: 18, weight: 700, lines: 1),
            ], gap: 8),
            LiveText(bind('hora'), size: 14, muted: true),
            const LiveSpacer(size: 4),
            _byPhase(
              entrada: _detailRow(
                const LiveIcon.symbol('calendar', size: 13),
                LiveText(bind('detalle'), size: 13, muted: true),
              ),
              refrigerio: _detailRow(
                const LiveIcon.symbol('clock', size: 13),
                LiveText.stopwatch(
                  bind('refrigerioDesde'),
                  size: 13,
                  muted: true,
                  tabular: true,
                ),
                label: 'Duración:',
              ),
              finRefrigerio: _detailRow(
                const LiveIcon.symbol(
                  'checkmark.circle.fill',
                  size: 13,
                  color: _teal,
                ),
                LiveText(bind('detalle'), size: 13, muted: true),
              ),
              salida: _detailRow(
                const LiveIcon.symbol(
                  'checkmark.circle.fill',
                  size: 13,
                  color: _teal,
                ),
                LiveText(bind('detalle'), size: 13, muted: true),
              ),
            ),
          ],
          gap: 3,
          align: LiveAlign.start,
        ),
        // Empuja el texto hacia el avatar en lugar de centrarlo
        const LiveSpacer(),
      ], gap: 0),
    ),
    lockScreen: const LiveLockScreen.sameAsExpanded(),
    // Android usa su notificacion propia; este bloque solo completa el diseño
    android: LiveAndroid(
      title: bind('titulo'),
      text: const LiveText.format('{hora} · {detalle}'),
    ),
  );
}
