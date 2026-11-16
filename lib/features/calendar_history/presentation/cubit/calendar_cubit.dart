import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asisgo/core/constants/app_constants.dart';
import 'package:asisgo/features/attendance_map/data/attendance_repository.dart';
import 'package:asisgo/features/attendance_map/domain/attendance_record.dart';
import 'package:asisgo/features/calendar_history/domain/attendance_day_summary.dart';
import 'calendar_state.dart';

class CalendarCubit extends Cubit<CalendarState> {
  final AttendanceRepository _attendanceRepository;

  /// Hora de entrada del colaborador, usada para calcular tardanzas.
  String _shiftStartTime = AppConstants.standardShiftStart;

  CalendarCubit({required AttendanceRepository attendanceRepository})
    : _attendanceRepository = attendanceRepository,
      super(CalendarInitial());

  Future<void> loadCalendarData(
    String userId, {
    DateTime? targetDate,
    String? shiftStartTime,
  }) async {
    if (shiftStartTime != null) _shiftStartTime = shiftStartTime;
    final previous = state is CalendarLoaded ? state as CalendarLoaded : null;
    emit(CalendarLoading());
    try {
      final allRecords = await _attendanceRepository.getAllRecords(userId);
      final selected = targetDate ?? previous?.selectedDay ?? DateTime.now();
      final focused = targetDate ?? previous?.focusedDay ?? selected;
      emit(_buildState(allRecords, selected, focused));
    } catch (e) {
      emit(
        CalendarError('No se pudo cargar tu historial. Inténtalo de nuevo.'),
      );
    }
  }

  Future<void> selectDay(
    DateTime selectedDay,
    DateTime focusedDay, [
    String? userId,
  ]) async {
    final current = state;
    if (current is CalendarLoaded && userId == null) {
      emit(
        current.copyWith(
          selectedDay: selectedDay,
          focusedDay: focusedDay,
          monthSummary: _monthSummary(current.daySummaries.values, focusedDay),
        ),
      );
      return;
    }
    final allRecords =
        userId != null
            ? await _attendanceRepository.getAllRecords(userId)
            : <AttendanceRecord>[];
    emit(_buildState(allRecords, selectedDay, focusedDay));
  }

  /// Al deslizar a otro mes/semana se recalcula el resumen del mes visible.
  void updateFocusedDay(DateTime focusedDay) {
    final current = state;
    if (current is CalendarLoaded) {
      emit(
        current.copyWith(
          focusedDay: focusedDay,
          monthSummary: _monthSummary(current.daySummaries.values, focusedDay),
        ),
      );
    }
  }

  CalendarLoaded _buildState(
    List<AttendanceRecord> allRecords,
    DateTime selected,
    DateTime focused,
  ) {
    final byDay = <String, List<AttendanceRecord>>{};
    for (final r in allRecords) {
      final local = r.timestamp.toLocal();
      byDay.putIfAbsent(CalendarLoaded.keyOf(local), () => []).add(r);
    }

    final summaries = <String, AttendanceDaySummary>{};
    byDay.forEach((key, records) {
      final t = records.first.timestamp.toLocal();
      final summary = AttendanceDaySummary.fromRecords(
        DateTime(t.year, t.month, t.day),
        records,
        shiftStartTime: _shiftStartTime,
      );
      if (summary != null) summaries[key] = summary;
    });

    return CalendarLoaded(
      selectedDay: selected,
      focusedDay: focused,
      allRecords: allRecords,
      daySummaries: summaries,
      monthSummary: _monthSummary(summaries.values, focused),
    );
  }

  MonthSummary _monthSummary(
    Iterable<AttendanceDaySummary> days,
    DateTime focused,
  ) => MonthSummary.from(DateTime(focused.year, focused.month), days);
}
