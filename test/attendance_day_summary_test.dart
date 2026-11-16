import 'package:asisgo/features/attendance_map/domain/attendance_record.dart';
import 'package:asisgo/features/attendance_map/domain/shift_phase.dart';
import 'package:asisgo/features/calendar_history/domain/attendance_day_summary.dart';
import 'package:flutter_test/flutter_test.dart';

AttendanceRecord _punch(AttendanceType type, DateTime at) => AttendanceRecord(
  id: '${type.name}-${at.toIso8601String()}',
  userId: 'USR-TEST',
  type: type,
  timestamp: at,
  branchId: 'BR-01',
  branchName: 'Sede',
  latitude: 0,
  longitude: 0,
  distanceToGeozone: 0,
  isInsideGeozone: true,
);

void main() {
  final day = DateTime(2026, 9, 21);
  DateTime at(int h, int m) => DateTime(2026, 9, 21, h, m);
  final now = DateTime(2026, 11, 11, 12, 0);

  group('AttendanceDaySummary', () {
    test('jornada completa a tiempo descuenta el refrigerio', () {
      final s = AttendanceDaySummary.fromRecords(day, [
        _punch(AttendanceType.checkIn, at(8, 30)),
        _punch(AttendanceType.lunchStart, at(13, 0)),
        _punch(AttendanceType.lunchEnd, at(14, 0)),
        _punch(AttendanceType.checkOut, at(18, 0)),
      ], shiftStartTime: '08:30', now: now)!;

      expect(s.status, DayStatus.complete);
      expect(s.worked, const Duration(hours: 8, minutes: 30));
      expect(s.needsJustification, isFalse);
    });

    test('entrada despues de la tolerancia marca tardanza', () {
      final s = AttendanceDaySummary.fromRecords(day, [
        _punch(AttendanceType.checkIn, at(8, 36)),
        _punch(AttendanceType.checkOut, at(18, 0)),
      ], shiftStartTime: '08:30', now: now)!;

      expect(s.status, DayStatus.late);
      expect(s.needsJustification, isTrue);
    });

    test('la tardanza usa la hora de entrada del colaborador', () {
      final s = AttendanceDaySummary.fromRecords(day, [
        _punch(AttendanceType.checkIn, at(9, 4)),
        _punch(AttendanceType.checkOut, at(18, 30)),
      ], shiftStartTime: '09:00', now: now)!;

      expect(s.status, DayStatus.complete);
    });

    test('un dia pasado sin salida queda incompleto y no suma horas', () {
      final s = AttendanceDaySummary.fromRecords(day, [
        _punch(AttendanceType.checkIn, at(14, 46)),
      ], shiftStartTime: '08:30', now: now)!;

      expect(s.status, DayStatus.incomplete);
      expect(s.worked, Duration.zero);
      expect(s.needsJustification, isTrue);
    });

    test('la jornada de hoy sin salida esta en curso', () {
      final today = DateTime(2026, 11, 11);
      final s = AttendanceDaySummary.fromRecords(today, [
        _punch(AttendanceType.checkIn, DateTime(2026, 11, 11, 8, 0)),
      ], shiftStartTime: '08:30', now: now)!;

      expect(s.status, DayStatus.inProgress);
      expect(s.worked, const Duration(hours: 4));
    });
  });

  test('MonthSummary solo suma horas de jornadas cerradas del mes', () {
    final complete = AttendanceDaySummary.fromRecords(day, [
      _punch(AttendanceType.checkIn, at(8, 0)),
      _punch(AttendanceType.checkOut, at(16, 0)),
    ], shiftStartTime: '08:30', now: now)!;
    final incomplete = AttendanceDaySummary.fromRecords(
      DateTime(2026, 9, 22),
      [_punch(AttendanceType.checkIn, DateTime(2026, 9, 22, 9, 0))],
      shiftStartTime: '08:30',
      now: now,
    )!;
    final otherMonth = AttendanceDaySummary.fromRecords(
      DateTime(2026, 10, 1),
      [
        _punch(AttendanceType.checkIn, DateTime(2026, 10, 1, 8, 0)),
        _punch(AttendanceType.checkOut, DateTime(2026, 10, 1, 17, 0)),
      ],
      shiftStartTime: '08:30',
      now: now,
    )!;

    final m = MonthSummary.from(DateTime(2026, 9), [
      complete,
      incomplete,
      otherMonth,
    ]);

    expect(m.daysAttended, 2);
    expect(m.lateDays, 0);
    expect(m.worked, const Duration(hours: 8));
  });
}
