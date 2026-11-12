import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:intl/intl.dart';
import 'package:live_island_kit/live_island_kit.dart';
import '../../features/attendance_map/domain/shift_phase.dart';

/// Dynamic Island y pantalla de bloqueo del turno (iOS), con live_island_kit.
///
/// Se muestra durante la jornada: entrada, inicio y fin de refrigerio. Al
/// marcar la salida la actividad se retira, porque ya no aporta nada al
/// colaborador. Android sigue usando su notificacion propia.
class LiveActivityService {
  static final LiveActivityService _instance = LiveActivityService._internal();
  factory LiveActivityService() => _instance;
  LiveActivityService._internal();

  /// Id propio: si ya hay una actividad viva, `start` la actualiza.
  static const String _activityId = 'asisgo-turno';

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
    // Sin jornada en curso (no iniciada o ya terminada) no se muestra nada
    if (phase == ShiftPhase.notStarted || phase == ShiftPhase.completed) {
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
    } catch (e) {
      debugPrint('[LiveActivityService] No se pudo actualizar la isla: $e');
    }
  }

  /// Retira la actividad del turno de inmediato.
  Future<void> endShiftActivity() async {
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
      ShiftPhase.onLunch => ('refrigerio', 'Refrigerio iniciado', 'Duración'),
      ShiftPhase.resumed => (
        'finRefrigerio',
        'Refrigerio finalizado',
        'Regreso a labores',
      ),
      _ => ('entrada', 'Entrada registrada', 'Jornada laboral'),
    };
    return {
      'fase': fase,
      'titulo': titulo,
      'detalle': detalle,
      'hora': DateFormat('h:mm a', 'es').format(punchTime),
      'iniciales': _initials,
      'refrigerioDesde': lunchStartTime ?? punchTime,
    };
  }

  // ---------------------------------------------------------------------------
  // Diseño (viaja una vez al iniciar; cada cambio solo envia el estado)
  // ---------------------------------------------------------------------------

  static const _green = Color(0xFF34C759);
  static const _orange = Color(0xFFFF9F0A);
  static const _teal = Color(0xFF30D5C8);

  static LiveCondition _is(String fase) => bind('fase').equals(fase);

  /// Elige un nodo segun la fase del turno.
  static LiveNode _byPhase({
    required LiveNode entrada,
    required LiveNode refrigerio,
    required LiveNode finRefrigerio,
  }) => LiveIf(
    _is('entrada'),
    then: entrada,
    otherwise: LiveIf(
      _is('refrigerio'),
      then: refrigerio,
      otherwise: finRefrigerio,
    ),
  );

  static const _checkIcon = LiveIcon.symbol(
    'checkmark.circle.fill',
    size: 20,
    color: _green,
  );
  static const _forkIcon = LiveIcon.symbol(
    'fork.knife',
    size: 18,
    color: _orange,
  );

  static LiveNode _compactLabel(LiveNode icon, String text) => LiveRow([
    icon,
    LiveText.literal(text, size: 14, weight: 600),
  ], gap: 4);

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
    ),
    minimal: _byPhase(
      entrada: const LiveIcon.symbol('checkmark.circle.fill', color: _green),
      refrigerio: _forkIcon,
      finRefrigerio: _forkIcon,
    ),
    // Isla expandida y pantalla de bloqueo, en tres columnas que ocupan todo
    // el ancho: avatar | titulo y detalle | hora de la marcacion.
    expanded: LiveExpanded(
      leading: LiveAvatar.bound(bind('iniciales'), size: 46),
      center: LiveColumn([
        LiveRow([
          _byPhase(
            entrada: _checkIcon,
            refrigerio: _forkIcon,
            finRefrigerio: _forkIcon,
          ),
          LiveText(bind('titulo'), size: 16, weight: 700, lines: 1),
        ], gap: 6),
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
            label: 'Duración',
          ),
          finRefrigerio: _detailRow(
            const LiveIcon.symbol(
              'checkmark.circle.fill',
              size: 13,
              color: _teal,
            ),
            LiveText(bind('detalle'), size: 13, muted: true),
          ),
        ),
      ], gap: 4, align: LiveAlign.start),
      trailing: LiveColumn([
        LiveText(bind('hora'), size: 17, weight: 700, tabular: true),
        const LiveText.literal('Hoy', size: 12, muted: true),
      ], gap: 2, align: LiveAlign.end),
    ),
    lockScreen: const LiveLockScreen.sameAsExpanded(),
    // Android usa su notificacion propia; este bloque solo completa el diseño
    android: LiveAndroid(
      title: bind('titulo'),
      text: const LiveText.format('Hoy, {hora} · {detalle}'),
    ),
  );
}
