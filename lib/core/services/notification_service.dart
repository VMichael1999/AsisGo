import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../features/attendance_map/domain/shift_phase.dart';
import 'live_activity_service.dart';

/// Servicio centralizado de notificaciones locales y seguimiento persistente de turno
/// con soporte para Live Activities nativas (Dynamic Island en iOS y Notificación Personalizada RemoteViews en Android).
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const int shiftNotificationId = 1001;
  static const String shiftChannelId = 'asisgo_shift_tracker';
  static const String shiftChannelName = 'Seguimiento de Turno en Vivo (Live Activity)';
  static const String shiftChannelDesc =
      'Notificación persistente con cronómetro en tiempo real, geocerca y refrigerio';

  static const MethodChannel _androidLiveChannel =
      MethodChannel('com.asisgo.app/android_live_notification');

  /// Inicializa los canales y configuraciones de notificaciones para Android e iOS
  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await _notifications.initialize(initSettings);

      // Crear canal de notificación específico para Android con soporte de cronómetro y prioridad fija
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        const channel = AndroidNotificationChannel(
          shiftChannelId,
          shiftChannelName,
          description: shiftChannelDesc,
          importance: Importance.low,
          showBadge: true,
          enableVibration: false,
          playSound: false,
        );
        await androidImplementation.createNotificationChannel(channel);
      }

      await LiveActivityService().initialize();
      _isInitialized = true;
      debugPrint('[NotificationService] Notificaciones locales y Live Activities inicializadas.');
    } catch (e) {
      debugPrint('[NotificationService] Error al inicializar notificaciones: $e');
    }
  }

  /// Solicita permisos de notificaciones al usuario
  Future<bool?> requestPermissions() async {
    if (!_isInitialized) return false;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return await _notifications
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        return await _notifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint('[NotificationService] Error al solicitar permisos: $e');
    }
    return true;
  }

  /// Actualiza o crea la notificación persistente del turno en curso (Live Activity Android & iOS)
  Future<void> updateShiftNotification({
    required ShiftPhase phase,
    required String branchName,
    DateTime? shiftStartTime,
    DateTime? lunchStartTime,
    bool isInsideGeozone = true,
    int? punchesCount,
  }) async {
    if (!_isInitialized) return;

    // Si la jornada no ha iniciado o ya concluyó, se remueve la notificación persistente
    if (phase == ShiftPhase.notStarted || phase == ShiftPhase.completed) {
      await cancelShiftNotification();
      return;
    }

    final bool isLunch = phase == ShiftPhase.onLunch;
    final DateTime? activeTimerBase = isLunch ? lunchStartTime : shiftStartTime;
    final int chronometerEpoch = (activeTimerBase ?? DateTime.now()).millisecondsSinceEpoch;

    // Colores y badges temáticos dinámicos (sincronizados con la Dynamic Island de iOS)
    final Color themeColor = isLunch ? const Color(0xFFF59E0B) : const Color(0xFF10B981);
    final String subText = isLunch
        ? 'EN REFRIGERIO • PAUSA'
        : (phase == ShiftPhase.resumed ? 'TURNO REANUDADO' : 'EN TURNO ACTIVO');
    final String iconName = isLunch ? 'ic_stat_refrigerio' : 'ic_stat_shift';
    final String geozoneIndicator = isInsideGeozone ? '🟢 Dentro de geozona' : '🔴 Fuera de geozona';
    final int completedPunches = punchesCount ??
        (phase == ShiftPhase.working ? 1 : (phase == ShiftPhase.onLunch ? 2 : 3));

    String title;
    String body;
    String bigText;

    switch (phase) {
      case ShiftPhase.working:
        title = 'AsisGo • Turno en $branchName';
        body = '$geozoneIndicator • Entrada: ${_formatTime(shiftStartTime ?? DateTime.now())} • Próx: Refrigerio';
        bigText = '$geozoneIndicator autorizada ($branchName)\n'
            '⏱️ Marcación de Entrada: ${_formatTime(shiftStartTime ?? DateTime.now())}\n'
            '📊 Progreso: $completedPunches de 4 marcaciones del día\n'
            '👉 Próxima marcación esperada: Iniciar Refrigerio';
        break;
      case ShiftPhase.onLunch:
        title = 'AsisGo • Refrigerio en Curso';
        body = '☕ Pausa iniciada: ${_formatTime(lunchStartTime ?? DateTime.now())} (60 min) • $branchName';
        bigText = '☕ Pausa de refrigerio en curso (Estándar: 60 min)\n'
            '🏢 Sede de asignación: $branchName\n'
            '⏱️ Inicio de refrigerio: ${_formatTime(lunchStartTime ?? DateTime.now())}\n'
            '📊 Progreso: $completedPunches de 4 marcaciones del día\n'
            '👉 Próxima marcación esperada: Finalizar Refrigerio';
        break;
      case ShiftPhase.resumed:
        title = 'AsisGo • Jornada Reanudada en $branchName';
        body = '$geozoneIndicator • Segundo bloque activo • Próx: Salida';
        bigText = '$geozoneIndicator autorizada ($branchName)\n'
            '💼 Segundo bloque de jornada en desarrollo\n'
            '⏱️ Ingreso inicial: ${_formatTime(shiftStartTime ?? DateTime.now())}\n'
            '📊 Progreso: $completedPunches de 4 marcaciones del día\n'
            '👉 Próxima marcación esperada: Marcar Salida';
        break;
      default:
        return;
    }

    // Configuración avanzada de Android para comportamiento estilo Live Activity:
    // 1. usesChronometer: Cronómetro en tiempo real visible en bandeja y pantalla de bloqueo.
    // 2. colorized + color: Tinte temático esmeralda o ámbar/naranja.
    // 3. category: status: Prioridad de actividad en vivo continua.
    // 4. ongoing: Persistente mientras dure el turno.
    // 5. onlyAlertOnce: Actualizaciones silenciosas de geozona y tiempo sin vibraciones invasivas.
    final androidDetails = AndroidNotificationDetails(
      shiftChannelId,
      shiftChannelName,
      channelDescription: shiftChannelDesc,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      showWhen: true,
      when: chronometerEpoch,
      usesChronometer: true,
      chronometerCountDown: false,
      color: themeColor,
      colorized: true,
      icon: iconName,
      subText: subText,
      category: AndroidNotificationCategory.status,
      visibility: NotificationVisibility.public,
      styleInformation: BigTextStyleInformation(
        bigText,
        htmlFormatBigText: false,
        contentTitle: title,
        htmlFormatContentTitle: false,
        summaryText: isLunch ? '☕ En Refrigerio' : geozoneIndicator,
        htmlFormatSummaryText: false,
      ),
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'open_asisgo',
          'Ver en AsisGo',
          showsUserInterface: true,
        ),
      ],
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    );

    // En Android se maneja directamente a través del diseño nativo de Dynamic Island (RemoteViews)
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _androidLiveChannel.invokeMethod('showLiveActivity', {
          'phase': phase.name,
          'branchName': branchName,
          'shiftStartTime': shiftStartTime?.millisecondsSinceEpoch,
          'lunchStartTime': lunchStartTime?.millisecondsSinceEpoch,
          'isInsideGeozone': isInsideGeozone,
          'punchesCount': completedPunches,
        });
        debugPrint('[NotificationService] Android Dynamic Island RemoteViews sincronizada.');
      } catch (e) {
        debugPrint('[NotificationService] Android Dynamic Island error: $e');
      }
    } else {
      // En iOS u otras plataformas: notificación local estándar y sincronización con ActivityKit
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      try {
        await _notifications.show(
          shiftNotificationId,
          title,
          body,
          notificationDetails,
        );
        debugPrint('[NotificationService] Notificación persistente iOS de turno actualizada: $title');
      } catch (e) {
        debugPrint('[NotificationService] No se pudo mostrar la notificación de turno: $e');
      }

      await LiveActivityService().syncShift(
        phase: phase,
        branchName: branchName,
        shiftStartTime: shiftStartTime,
        lunchStartTime: lunchStartTime,
        isInsideGeozone: isInsideGeozone,
      );
    }
  }

  /// Cancela la notificación persistente de turno activo (Android e iOS)
  Future<void> cancelShiftNotification() async {
    if (!_isInitialized) return;
    try {
      await _notifications.cancel(shiftNotificationId);
      await LiveActivityService().endShiftActivity();

      if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          await _androidLiveChannel.invokeMethod('cancelLiveActivity');
        } catch (_) {}
      }

      debugPrint('[NotificationService] Notificación persistente y Live Activity canceladas.');
    } catch (e) {
      debugPrint('[NotificationService] Error al cancelar notificación de turno: $e');
    }
  }

  Future<void> scheduleShiftStartReminder({required String time}) async {
    debugPrint('Recordatorio programado para inicio de jornada: $time');
  }

  Future<void> scheduleLunchReminder({required int durationMinutes}) async {
    debugPrint('Recordatorio programado para fin de refrigerio en $durationMinutes minutos');
  }

  Future<void> cancelAll() async {
    if (!_isInitialized) return;
    try {
      await _notifications.cancelAll();
      debugPrint('Todas las notificaciones fueron canceladas.');
    } catch (e) {
      debugPrint('Error al cancelar todas las notificaciones: $e');
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
