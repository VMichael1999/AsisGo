import 'package:equatable/equatable.dart';
import 'package:asisgo/features/attendance_map/domain/attendance_record.dart';
import 'package:asisgo/features/calendar_history/domain/attendance_day_summary.dart';

abstract class CalendarState extends Equatable {
  const CalendarState();

  @override
  List<Object?> get props => [];
}

class CalendarInitial extends CalendarState {}

class CalendarLoading extends CalendarState {}

class CalendarLoaded extends CalendarState {
  final DateTime selectedDay;
  final DateTime focusedDay;
  final List<AttendanceRecord> allRecords;

  /// Resumen por dia, con clave `yyyy-m-d`.
  final Map<String, AttendanceDaySummary> daySummaries;

  /// Totales del mes visible en el calendario.
  final MonthSummary monthSummary;

  const CalendarLoaded({
    required this.selectedDay,
    required this.focusedDay,
    required this.allRecords,
    required this.daySummaries,
    required this.monthSummary,
  });

  static String keyOf(DateTime day) => '${day.year}-${day.month}-${day.day}';

  AttendanceDaySummary? summaryFor(DateTime day) => daySummaries[keyOf(day)];

  AttendanceDaySummary? get selectedDaySummary => summaryFor(selectedDay);

  List<AttendanceRecord> get selectedDayRecords =>
      selectedDaySummary?.records ?? const [];

  CalendarLoaded copyWith({
    DateTime? selectedDay,
    DateTime? focusedDay,
    MonthSummary? monthSummary,
  }) {
    return CalendarLoaded(
      selectedDay: selectedDay ?? this.selectedDay,
      focusedDay: focusedDay ?? this.focusedDay,
      allRecords: allRecords,
      daySummaries: daySummaries,
      monthSummary: monthSummary ?? this.monthSummary,
    );
  }

  @override
  List<Object?> get props => [
    selectedDay,
    focusedDay,
    allRecords,
    daySummaries,
    monthSummary.month,
    monthSummary.daysAttended,
    monthSummary.lateDays,
    monthSummary.worked,
  ];
}

class CalendarError extends CalendarState {
  final String message;

  const CalendarError(this.message);

  @override
  List<Object?> get props => [message];
}
