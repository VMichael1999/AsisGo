import '../../attendance_map/domain/attendance_record.dart';
import '../../attendance_map/domain/shift_phase.dart';

/// Estado de una jornada en el historial.
enum DayStatus {
  /// Entrada y salida registradas, entrada a tiempo.
  complete,

  /// Entrada y salida registradas, entrada fuera de la tolerancia.
  late,

  /// Dia pasado sin entrada o sin salida.
  incomplete,

  /// Jornada de hoy aun abierta (con entrada y sin salida).
  inProgress,
}

/// Resumen calculado de las marcaciones de un dia.
class AttendanceDaySummary {
  final DateTime day;
  final List<AttendanceRecord> records;
  final DayStatus status;

  /// Tiempo trabajado descontando el refrigerio. En una jornada en curso se
  /// calcula hasta [now]; en una jornada incompleta es cero.
  final Duration worked;

  const AttendanceDaySummary({
    required this.day,
    required this.records,
    required this.status,
    required this.worked,
  });

  /// Minutos de tolerancia sobre la hora de entrada antes de contar tardanza.
  static const int lateToleranceMinutes = 5;

  AttendanceRecord? recordOf(AttendanceType type) {
    for (final r in records) {
      if (r.type == type) return r;
    }
    return null;
  }

  bool get needsJustification =>
      status == DayStatus.incomplete || status == DayStatus.late;

  /// Devuelve null si el dia no tiene marcaciones.
  static AttendanceDaySummary? fromRecords(
    DateTime day,
    List<AttendanceRecord> dayRecords, {
    required String shiftStartTime,
    DateTime? now,
  }) {
    if (dayRecords.isEmpty) return null;
    final current = now ?? DateTime.now();
    final records = [...dayRecords]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    DateTime? first(AttendanceType type) {
      for (final r in records) {
        if (r.type == type) return r.timestamp;
      }
      return null;
    }

    final checkIn = first(AttendanceType.checkIn);
    final checkOut = first(AttendanceType.checkOut);
    final lunchStart = first(AttendanceType.lunchStart);
    final lunchEnd = first(AttendanceType.lunchEnd);
    final isToday = _sameDay(day, current);

    DayStatus status;
    DateTime? end;
    if (checkIn == null) {
      status = DayStatus.incomplete;
    } else if (checkOut == null) {
      status = isToday ? DayStatus.inProgress : DayStatus.incomplete;
      end = isToday ? current : null;
    } else {
      status =
          _isLate(checkIn, shiftStartTime)
              ? DayStatus.late
              : DayStatus.complete;
      end = checkOut;
    }

    var minutes = 0;
    if (checkIn != null && end != null) {
      minutes = end.difference(checkIn).inMinutes;
      if (lunchStart != null) {
        final lunchUntil = lunchEnd ?? end;
        minutes -= lunchUntil.difference(lunchStart).inMinutes;
      }
      if (minutes < 0) minutes = 0;
    }

    return AttendanceDaySummary(
      day: day,
      records: records,
      status: status,
      worked: Duration(minutes: minutes),
    );
  }

  static bool _isLate(DateTime checkIn, String shiftStartTime) {
    final parts = shiftStartTime.split(':');
    final hour = int.tryParse(parts.first) ?? 8;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final limit = DateTime(
      checkIn.year,
      checkIn.month,
      checkIn.day,
      hour,
      minute,
    ).add(const Duration(minutes: lateToleranceMinutes));
    return checkIn.isAfter(limit);
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Totales de un mes. Las horas solo suman jornadas cerradas.
class MonthSummary {
  final DateTime month;
  final int daysAttended;
  final int lateDays;
  final Duration worked;

  const MonthSummary({
    required this.month,
    required this.daysAttended,
    required this.lateDays,
    required this.worked,
  });

  factory MonthSummary.from(
    DateTime month,
    Iterable<AttendanceDaySummary> days,
  ) {
    var attended = 0;
    var late = 0;
    var worked = Duration.zero;
    for (final d in days) {
      if (d.day.year != month.year || d.day.month != month.month) continue;
      if (d.recordOf(AttendanceType.checkIn) != null) attended++;
      if (d.status == DayStatus.late) late++;
      if (d.status == DayStatus.complete || d.status == DayStatus.late) {
        worked += d.worked;
      }
    }
    return MonthSummary(
      month: month,
      daysAttended: attended,
      lateDays: late,
      worked: worked,
    );
  }
}
