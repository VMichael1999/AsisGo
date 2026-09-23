import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/attendance_repository.dart';
import '../../domain/shift_phase.dart';
import 'attendance_state.dart';

class AttendanceCubit extends Cubit<AttendanceState> {
  final AttendanceRepository _attendanceRepository;

  AttendanceCubit({
    required AttendanceRepository attendanceRepository,
  })  : _attendanceRepository = attendanceRepository,
        super(AttendanceInitial());

  Future<void> loadDailyAttendance(String userId) async {
    emit(AttendanceLoading());
    try {
      final records = await _attendanceRepository.getTodayRecords(userId);
      final phase = await _attendanceRepository.getCurrentShiftPhase(userId);
      final last = records.isNotEmpty ? records.last : null;

      emit(AttendanceLoaded(
        currentPhase: phase,
        todayRecords: records,
        lastRecord: last,
      ));
    } catch (e) {
      emit(AttendanceError('Error al cargar la asistencia: ${e.toString()}'));
    }
  }

  Future<void> registerPunch({
    required String userId,
    required AttendanceType type,
    required String branchId,
    required String branchName,
    String? geozoneId,
    String? geozoneName,
    required double latitude,
    required double longitude,
    required double distanceToGeozone,
    required bool isInsideGeozone,
    bool isMockedLocation = false,
    String? note,
    String? selfiePath,
  }) async {
    final currentState = state;
    if (currentState is AttendanceLoaded) {
      emit(currentState.copyWith(isSubmitting: true));
    }

    try {
      final newRecord = await _attendanceRepository.registerAttendance(
        userId: userId,
        type: type,
        branchId: branchId,
        branchName: branchName,
        geozoneId: geozoneId,
        geozoneName: geozoneName,
        latitude: latitude,
        longitude: longitude,
        distanceToGeozone: distanceToGeozone,
        isInsideGeozone: isInsideGeozone,
        isMockedLocation: isMockedLocation,
        note: note,
        selfiePath: selfiePath,
      );

      final nextPhase = _determineNextPhase(type);
      final updatedRecords = await _attendanceRepository.getTodayRecords(userId);

      emit(AttendanceLoaded(
        currentPhase: nextPhase,
        todayRecords: updatedRecords,
        lastRecord: newRecord,
        isSubmitting: false,
        feedbackMessage: '${type.title} registrada exitosamente.',
      ));
    } catch (e) {
      emit(AttendanceError('Error al registrar la asistencia: ${e.toString()}'));
      // Reload current state
      await loadDailyAttendance(userId);
    }
  }

  ShiftPhase _determineNextPhase(AttendanceType punchedType) {
    switch (punchedType) {
      case AttendanceType.checkIn:
        return ShiftPhase.working;
      case AttendanceType.lunchStart:
        return ShiftPhase.onLunch;
      case AttendanceType.lunchEnd:
        return ShiftPhase.resumed;
      case AttendanceType.checkOut:
        return ShiftPhase.completed;
    }
  }
}
