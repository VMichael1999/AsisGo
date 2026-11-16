import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:intl/intl.dart';
import 'package:live_island_kit/live_island_kit.dart';
import '../../features/attendance_map/domain/shift_phase.dart';
import '../constants/app_constants.dart';

/// Dynamic Island y pantalla de bloqueo de la jornada (iOS), con live_island_kit.
///
/// Muestra un contador de la jornada en curso ("En jornada") y, durante el
/// refrigerio, un contador de la pausa. Al marcar la salida la actividad se
/// retira. Los contadores los actualiza iOS por su cuenta, sin depender de
/// que la app este abierta. Android sigue usando su notificacion propia.
class LiveActivityService {
  static final LiveActivityService _instance = LiveActivityService._internal();
  factory LiveActivityService() => _instance;
  LiveActivityService._internal();

  /// Id propio: si ya hay una actividad viva, `start` la actualiza.
  static const String _activityId = 'asisgo-turno';

  String _shiftStart = AppConstants.standardShiftStart;
  String _shiftEnd = AppConstants.standardShiftEnd;

  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  /// Se mantiene por compatibilidad con la inicializacion de notificaciones.
  Future<void> initialize() async {}

  /// Horario asignado al colaborador ("08:30", "18:00").
  void setSchedule({
    required String shiftStartTime,
    required String shiftEndTime,
  }) {
    _shiftStart = shiftStartTime;
    _shiftEnd = shiftEndTime;
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

    final now = DateTime.now();
    final checkIn = shiftStartTime ?? lastPunchTime ?? now;
    final end = _todayAt(_shiftEnd, now);
    final fmt = DateFormat('h:mm a', 'es');
    final scheduleStart = _todayAt(_shiftStart, now);

    final state = <String, Object?>{
      'fase': phase == ShiftPhase.onLunch ? 'refrigerio' : 'jornada',
      'titulo': phase == ShiftPhase.onLunch ? 'En refrigerio' : 'En jornada',
      'horario': '${fmt.format(scheduleStart)} – ${fmt.format(end)}',
      'entradaTxt': fmt.format(checkIn),
      'salidaTxt': fmt.format(end),
      'entradaTs': checkIn,
      'finTs': end,
      'refrigerioDesde': lunchStartTime ?? lastPunchTime ?? now,
    };

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

  static DateTime _todayAt(String hhmm, DateTime now) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts.first) ?? 0;
    final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(now.year, now.month, now.day, h, m);
  }

  // ---------------------------------------------------------------------------
  // Diseño (viaja una vez al iniciar; cada cambio solo envia el estado)
  // ---------------------------------------------------------------------------

  static const _green = Color(0xFF4ADE80);
  static const _orange = Color(0xFFFF9F0A);

  /// Elige un nodo segun estemos en jornada o en refrigerio.
  static LiveNode _byPhase({
    required LiveNode jornada,
    required LiveNode refrigerio,
  }) => LiveIf(
    bind('fase').equals('refrigerio'),
    then: refrigerio,
    otherwise: jornada,
  );

  static const _briefcase = LiveIcon.symbol(
    'briefcase.fill',
    size: 18,
    color: _green,
  );
  static const _fork = LiveIcon.symbol('fork.knife', size: 18, color: _orange);

  /// Circulo con el icono de la fase (en lugar del anillo, que no se puede
  /// avanzar solo con la app en segundo plano).
  static LiveNode _badge({required double size}) => _byPhase(
    jornada: LiveBox(
      size: size,
      radius: size / 2,
      color: const Color(0x2E4ADE80),
      border: _green,
      borderWidth: 2.5,
      child: _briefcase,
    ),
    refrigerio: LiveBox(
      size: size,
      radius: size / 2,
      color: const Color(0x2EFF9F0A),
      border: _orange,
      borderWidth: 2.5,
      child: _fork,
    ),
  );

  /// Contador de la fase: tiempo de jornada o tiempo de refrigerio.
  static LiveNode _timer({required double size, bool white = false}) =>
      _byPhase(
        jornada: LiveText.stopwatch(
          bind('entradaTs'),
          size: size,
          weight: 700,
          tabular: true,
          color: white ? const Color(0xFFFFFFFF) : _green,
        ),
        refrigerio: LiveText.stopwatch(
          bind('refrigerioDesde'),
          size: size,
          weight: 700,
          tabular: true,
          color: white ? const Color(0xFFFFFFFF) : _orange,
        ),
      );

  static LiveNode _stat(String label, LiveNode value) => LiveColumn(
    [LiveText.literal(label, size: 12, muted: true), value],
    gap: 2,
    align: LiveAlign.center,
  );

  static final LiveLayout shiftLayout = LiveLayout(
    theme: const LiveTheme(accent: _green),
    // Isla compacta: icono a la izquierda y contador a la derecha
    compactLeading: _byPhase(
      jornada: const LiveIcon.symbol(
        'checkmark.circle',
        size: 18,
        color: _green,
      ),
      refrigerio: _fork,
    ),
    compactTrailing: _timer(size: 14),
    minimal: _byPhase(
      jornada: const LiveIcon.symbol('briefcase.fill', color: _green),
      refrigerio: _fork,
    ),
    // Isla expandida: icono | titulo y horario | contador
    expanded: LiveExpanded(
      center: LiveRow(
        [
          _badge(size: 46),
          LiveColumn(
            [
              LiveText(bind('titulo'), size: 17, weight: 700, lines: 1),
              LiveText(bind('horario'), size: 13, muted: true, lines: 1),
            ],
            gap: 2,
            align: LiveAlign.start,
          ),
          const LiveSpacer(),
          _timer(size: 26),
        ],
        gap: 12,
        align: LiveAlign.center,
      ),
    ),
    // Pantalla de bloqueo: contador grande y resumen Entrada / Faltan / Salida
    lockScreen: LiveLockScreen.custom(
      LiveColumn(
        [
          LiveRow([
            _badge(size: 52),
            LiveColumn(
              [
                LiveRow([
                  _byPhase(
                    jornada: const LiveIcon.symbol(
                      'circle.fill',
                      size: 7,
                      color: _green,
                    ),
                    refrigerio: const LiveIcon.symbol(
                      'circle.fill',
                      size: 7,
                      color: _orange,
                    ),
                  ),
                  _byPhase(
                    jornada: const LiveText.literal(
                      'En jornada',
                      size: 13,
                      weight: 600,
                      color: _green,
                    ),
                    refrigerio: const LiveText.literal(
                      'En refrigerio',
                      size: 13,
                      weight: 600,
                      color: _orange,
                    ),
                  ),
                ], gap: 5),
                _timer(size: 34, white: true),
              ],
              gap: 0,
              align: LiveAlign.start,
            ),
            const LiveSpacer(),
            const LiveText.literal('AsisGo', size: 12, muted: true),
          ], gap: 12),
          const LiveSpacer(size: 10),
          LiveRow([
            _stat(
              'Entrada',
              LiveText(bind('entradaTxt'), size: 15, weight: 700),
            ),
            const LiveSpacer(),
            _stat(
              'Faltan',
              LiveText.countdown(
                bind('finTs'),
                size: 15,
                weight: 700,
                tabular: true,
              ),
            ),
            const LiveSpacer(),
            _stat('Salida', LiveText(bind('salidaTxt'), size: 15, weight: 700)),
          ]),
        ],
        gap: 0,
        align: LiveAlign.start,
      ),
    ),
    // Android usa su notificacion propia; este bloque solo completa el diseño
    android: LiveAndroid(
      title: bind('titulo'),
      text: const LiveText.format('{horario}'),
    ),
  );
}
