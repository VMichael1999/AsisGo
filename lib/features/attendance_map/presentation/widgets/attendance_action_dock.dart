import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/haptic_feedback_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/asis_action_button.dart';
import '../../../../core/widgets/asis_glass_card.dart';
import '../../../../core/widgets/asis_status_badge.dart';
import '../../domain/attendance_record.dart';
import '../../domain/shift_phase.dart';

class AttendanceActionDock extends StatefulWidget {
  final ShiftPhase phase;
  final List<AttendanceRecord> todayRecords;
  final AttendanceRecord? lastRecord;
  final bool isInsideGeozone;
  final VoidCallback onPrimaryActionPressed;
  final VoidCallback? onSecondaryActionPressed;

  const AttendanceActionDock({
    super.key,
    required this.phase,
    required this.todayRecords,
    this.lastRecord,
    required this.isInsideGeozone,
    required this.onPrimaryActionPressed,
    this.onSecondaryActionPressed,
  });

  @override
  State<AttendanceActionDock> createState() => _AttendanceActionDockState();
}

class _AttendanceActionDockState extends State<AttendanceActionDock> {
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.phase == ShiftPhase.completed;

    return AsisGlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      borderRadius: 24,
      isDark: true,
      customBackground: const Color(0xEA0D131F),
      customBorderColor: const Color(0x33FFFFFF),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Encabezado del dock: indicador de fase actual y reloj digital en vivo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AsisStatusBadge(
                label: widget.phase.statusBadgeLabel.toUpperCase(),
                showRadar: !isCompleted,
                customColor: widget.phase.buttonColor,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    DateFormatter.formatTime(_currentTime),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Resumen de la ultima marcacion registrada
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.lastRecord != null
                    ? 'Último: ${widget.lastRecord!.type.shortName} (${DateFormatter.formatTime(widget.lastRecord!.timestamp)})'
                    : 'Sin marcas registradas hoy',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (widget.todayRecords.isNotEmpty)
                Text(
                  '${widget.todayRecords.length} / 4 marcas',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Boton principal de marcacion segun la fase del turno
          AsisActionButton(
            label: isCompleted ? 'Jornada Finalizada' : widget.phase.buttonLabel,
            icon: isCompleted
                ? Icons.check_circle_rounded
                : (widget.phase.nextExpectedAttendance?.icon ?? Icons.fingerprint_rounded),
            onPressed: isCompleted
                ? null
                : () {
                    HapticFeedbackService.shared.selectionClick();
                    widget.onPrimaryActionPressed();
                  },
            backgroundColor: widget.phase.buttonColor,
            disabledBackgroundColor: isCompleted ? const Color(0xFF059669) : null,
            disabledTextColor: Colors.white,
            borderSide: isCompleted
                ? const BorderSide(color: Color(0xFF34D399), width: 1.5)
                : null,
            height: 52,
            borderRadius: 16,
          ),

          // Opcion secundaria: salida anticipada cuando el turno esta activo
          if (widget.phase == ShiftPhase.working &&
              widget.onSecondaryActionPressed != null) ...[
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: () {
                HapticFeedbackService.shared.selectionClick();
                widget.onSecondaryActionPressed!();
              },
              icon: const Icon(Icons.exit_to_app_rounded, size: 15, color: Color(0xFFFCA5A5)),
              label: const Text(
                '¿Deseas marcar salida anticipada?',
                style: TextStyle(
                  color: Color(0xFFFCA5A5),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
