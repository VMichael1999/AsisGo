import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asisgo/features/attendance_map/data/attendance_repository.dart';
import 'package:asisgo/features/attendance_map/domain/attendance_record.dart';
import 'package:asisgo/features/attendance_map/domain/shift_phase.dart';
import 'calendar_state.dart';

class CalendarCubit extends Cubit<CalendarState> {
  final AttendanceRepository _attendanceRepository;

  CalendarCubit({
    required AttendanceRepository attendanceRepository,
  })  : _attendanceRepository = attendanceRepository,
        super(CalendarInitial());

  Future<void> loadCalendarData(String userId, {DateTime? targetDate}) async {
    emit(CalendarLoading());
    try {
      final allRecords = await _attendanceRepository.getAllRecords(userId);
      final initialDate = targetDate ?? (state is CalendarLoaded ? (state as CalendarLoaded).selectedDay : DateTime.now());

      final selectedRecords = _filterRecordsForDay(allRecords, initialDate);
      final workedDuration = _calculateWorkedHours(selectedRecords);
      final monthlyDays = _calculateMonthlyDays(allRecords, initialDate);
      final punctuality = _calculatePunctuality(allRecords);

      emit(CalendarLoaded(
        selectedDay: initialDate,
        focusedDay: initialDate,
        allRecords: allRecords,
        selectedDayRecords: selectedRecords,
        totalWorkedDuration: workedDuration,
        totalDaysWorkedThisMonth: monthlyDays,
        punctualityRate: punctuality,
      ));
    } catch (e) {
      emit(CalendarError('Error al cargar historial: $e'));
    }
  }

  Future<void> selectDay(DateTime selectedDay, DateTime focusedDay, [String? userId]) async {
    List<AttendanceRecord> allRecords;
    if (userId != null) {
      allRecords = await _attendanceRepository.getAllRecords(userId);
    } else if (state is CalendarLoaded) {
      allRecords = (state as CalendarLoaded).allRecords;
    } else {
      allRecords = [];
    }

    final selectedRecords = _filterRecordsForDay(allRecords, selectedDay);
    final workedDuration = _calculateWorkedHours(selectedRecords);
    final monthlyDays = _calculateMonthlyDays(allRecords, focusedDay);
    final punctuality = _calculatePunctuality(allRecords);

    emit(CalendarLoaded(
      selectedDay: selectedDay,
      focusedDay: focusedDay,
      allRecords: allRecords,
      selectedDayRecords: selectedRecords,
      totalWorkedDuration: workedDuration,
      totalDaysWorkedThisMonth: monthlyDays,
      punctualityRate: punctuality,
    ));
  }

  void updateFocusedDay(DateTime focusedDay) {
    if (state is CalendarLoaded) {
      final current = state as CalendarLoaded;
      emit(current.copyWith(focusedDay: focusedDay));
    }
  }

  List<AttendanceRecord> _filterRecordsForDay(List<AttendanceRecord> records, DateTime day) {
    final targetLocal = day.toLocal();
    return records.where((r) {
      final recLocal = r.timestamp.toLocal();
      return recLocal.year == targetLocal.year &&
          recLocal.month == targetLocal.month &&
          recLocal.day == targetLocal.day;
    }).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Duration _calculateWorkedHours(List<AttendanceRecord> records) {
    if (records.isEmpty) return Duration.zero;

    DateTime? checkIn;
    DateTime? checkOut;
    DateTime? lunchStart;
    DateTime? lunchEnd;

    for (final r in records) {
      switch (r.type) {
        case AttendanceType.checkIn:
          checkIn = r.timestamp;
          break;
        case AttendanceType.lunchStart:
          lunchStart = r.timestamp;
          break;
        case AttendanceType.lunchEnd:
          lunchEnd = r.timestamp;
          break;
        case AttendanceType.checkOut:
          checkOut = r.timestamp;
          break;
      }
    }

    if (checkIn == null) return Duration.zero;

    final end = checkOut ?? DateTime.now();
    var totalMinutes = end.difference(checkIn).inMinutes;

    if (lunchStart != null && lunchEnd != null) {
      final lunchMinutes = lunchEnd.difference(lunchStart).inMinutes;
      totalMinutes -= lunchMinutes;
    } else if (lunchStart != null && checkOut == null) {
      // En curso durante el refrigerio
      final lunchSoFar = DateTime.now().difference(lunchStart).inMinutes;
      totalMinutes -= lunchSoFar;
    }

    if (totalMinutes < 0) totalMinutes = 0;
    return Duration(minutes: totalMinutes);
  }

  int _calculateMonthlyDays(List<AttendanceRecord> records, DateTime referenceDate) {
    final days = <String>{};
    final refLocal = referenceDate.toLocal();
    for (final r in records) {
      final rLocal = r.timestamp.toLocal();
      if (rLocal.year == refLocal.year && rLocal.month == refLocal.month) {
        days.add('${rLocal.year}-${rLocal.month}-${rLocal.day}');
      }
    }
    return days.length;
  }

  double _calculatePunctuality(List<AttendanceRecord> records) {
    final checkIns = records.where((r) => r.type == AttendanceType.checkIn).toList();
    if (checkIns.isEmpty) return 100.0;

    int onTimeCount = 0;
    for (final c in checkIns) {
      final cLocal = c.timestamp.toLocal();
      // Tolerancia de entrada puntual hasta las 08:35 AM
      final limit = DateTime(cLocal.year, cLocal.month, cLocal.day, 8, 35);
      if (cLocal.isBefore(limit) || cLocal.isAtSameMomentAs(limit)) {
        onTimeCount++;
      }
    }

    return (onTimeCount / checkIns.length) * 100;
  }
}
