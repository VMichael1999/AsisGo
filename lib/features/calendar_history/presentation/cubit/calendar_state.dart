import 'package:equatable/equatable.dart';
import 'package:asisgo/features/attendance_map/domain/attendance_record.dart';

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
  final List<AttendanceRecord> selectedDayRecords;
  final Duration totalWorkedDuration;
  final int totalDaysWorkedThisMonth;
  final double punctualityRate;

  const CalendarLoaded({
    required this.selectedDay,
    required this.focusedDay,
    required this.allRecords,
    required this.selectedDayRecords,
    required this.totalWorkedDuration,
    required this.totalDaysWorkedThisMonth,
    required this.punctualityRate,
  });

  CalendarLoaded copyWith({
    DateTime? selectedDay,
    DateTime? focusedDay,
    List<AttendanceRecord>? allRecords,
    List<AttendanceRecord>? selectedDayRecords,
    Duration? totalWorkedDuration,
    int? totalDaysWorkedThisMonth,
    double? punctualityRate,
  }) {
    return CalendarLoaded(
      selectedDay: selectedDay ?? this.selectedDay,
      focusedDay: focusedDay ?? this.focusedDay,
      allRecords: allRecords ?? this.allRecords,
      selectedDayRecords: selectedDayRecords ?? this.selectedDayRecords,
      totalWorkedDuration: totalWorkedDuration ?? this.totalWorkedDuration,
      totalDaysWorkedThisMonth: totalDaysWorkedThisMonth ?? this.totalDaysWorkedThisMonth,
      punctualityRate: punctualityRate ?? this.punctualityRate,
    );
  }

  @override
  List<Object?> get props => [
        selectedDay,
        focusedDay,
        allRecords,
        selectedDayRecords,
        totalWorkedDuration,
        totalDaysWorkedThisMonth,
        punctualityRate,
      ];
}

class CalendarError extends CalendarState {
  final String message;

  const CalendarError(this.message);

  @override
  List<Object?> get props => [message];
}
