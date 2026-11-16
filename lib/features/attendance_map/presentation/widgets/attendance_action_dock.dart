import '../../../../core/theme/asis_palette.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/haptic_feedback_service.dart';
import '../../domain/attendance_record.dart';
import '../../domain/shift_phase.dart';

/// Boton central "Registrar" del mapa. La marcacion que abre depende de la
/// fase del turno (entrada, refrigerio, salida).
class AttendanceActionDock extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isCompleted = phase == ShiftPhase.completed;
    final nextType = phase.nextExpectedAttendance;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Opcion secundaria: salida anticipada cuando el turno esta activo
        if (phase == ShiftPhase.working && onSecondaryActionPressed != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: context.palette.surface,
              elevation: 2,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  HapticFeedbackService.shared.selectionClick();
                  onSecondaryActionPressed!();
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Text(
                    '¿Deseas marcar salida anticipada?',
                    style: TextStyle(
                      color: context.palette.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Boton principal de marcacion
        ElevatedButton(
          onPressed:
              isCompleted
                  ? null
                  : () {
                    HapticFeedbackService.shared.selectionClick();
                    onPrimaryActionPressed();
                  },
          style: ElevatedButton.styleFrom(
            backgroundColor: context.palette.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.completedColor,
            disabledForegroundColor: Colors.white,
            elevation: 4,
            minimumSize: const Size(190, 56),
            padding: const EdgeInsets.symmetric(horizontal: 28),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isCompleted ? 'Jornada Finalizada' : 'Registrar',
                style: TextStyle(
                  fontSize: isCompleted ? 16 : 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (nextType != null)
                Text(
                  nextType.shortName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
