import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

enum AttendanceType {
  checkIn,
  lunchStart,
  lunchEnd,
  checkOut,
}

extension AttendanceTypeExtension on AttendanceType {
  String get title {
    switch (this) {
      case AttendanceType.checkIn:
        return 'Marcación de Entrada';
      case AttendanceType.lunchStart:
        return 'Inicio de Refrigerio';
      case AttendanceType.lunchEnd:
        return 'Fin de Refrigerio';
      case AttendanceType.checkOut:
        return 'Marcación de Salida';
    }
  }

  String get shortName {
    switch (this) {
      case AttendanceType.checkIn:
        return 'Entrada';
      case AttendanceType.lunchStart:
        return 'Inicio Refrigerio';
      case AttendanceType.lunchEnd:
        return 'Fin Refrigerio';
      case AttendanceType.checkOut:
        return 'Salida';
    }
  }

  IconData get icon {
    switch (this) {
      case AttendanceType.checkIn:
        return Icons.login_rounded;
      case AttendanceType.lunchStart:
        return Icons.restaurant_rounded;
      case AttendanceType.lunchEnd:
        return Icons.fastfood_rounded;
      case AttendanceType.checkOut:
        return Icons.logout_rounded;
    }
  }

  Color get color {
    switch (this) {
      case AttendanceType.checkIn:
        return AppColors.checkInColor;
      case AttendanceType.lunchStart:
        return AppColors.lunchColor;
      case AttendanceType.lunchEnd:
        return const Color(0xFF0284C7);
      case AttendanceType.checkOut:
        return AppColors.checkOutColor;
    }
  }
}

enum ShiftPhase {
  notStarted,
  working,
  onLunch,
  resumed,
  completed,
}

extension ShiftPhaseExtension on ShiftPhase {
  AttendanceType? get nextExpectedAttendance {
    switch (this) {
      case ShiftPhase.notStarted:
        return AttendanceType.checkIn;
      case ShiftPhase.working:
        return AttendanceType.lunchStart;
      case ShiftPhase.onLunch:
        return AttendanceType.lunchEnd;
      case ShiftPhase.resumed:
        return AttendanceType.checkOut;
      case ShiftPhase.completed:
        return null;
    }
  }

  String get buttonLabel {
    switch (this) {
      case ShiftPhase.notStarted:
        return 'Marcar Entrada';
      case ShiftPhase.working:
        return 'Iniciar Refrigerio';
      case ShiftPhase.onLunch:
        return 'Finalizar Refrigerio';
      case ShiftPhase.resumed:
        return 'Marcar Salida';
      case ShiftPhase.completed:
        return 'Jornada Finalizada';
    }
  }

  String get statusBadgeLabel {
    switch (this) {
      case ShiftPhase.notStarted:
        return 'Sin Iniciar';
      case ShiftPhase.working:
        return 'Jornada Activa';
      case ShiftPhase.onLunch:
        return 'En Refrigerio';
      case ShiftPhase.resumed:
        return 'Jornada Reanudada';
      case ShiftPhase.completed:
        return 'Completado';
    }
  }

  Color get buttonColor {
    switch (this) {
      case ShiftPhase.notStarted:
        return AppColors.checkInColor;
      case ShiftPhase.working:
        return AppColors.lunchColor;
      case ShiftPhase.onLunch:
        return const Color(0xFF0284C7);
      case ShiftPhase.resumed:
        return AppColors.checkOutColor;
      case ShiftPhase.completed:
        return AppColors.completedColor;
    }
  }
}
