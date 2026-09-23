import 'package:equatable/equatable.dart';
import '../../domain/attendance_record.dart';
import '../../domain/shift_phase.dart';

abstract class AttendanceState extends Equatable {
  const AttendanceState();

  @override
  List<Object?> get props => [];
}

class AttendanceInitial extends AttendanceState {}

class AttendanceLoading extends AttendanceState {}

class AttendanceLoaded extends AttendanceState {
  final ShiftPhase currentPhase;
  final List<AttendanceRecord> todayRecords;
  final AttendanceRecord? lastRecord;
  final bool isSubmitting;
  final String? feedbackMessage;

  const AttendanceLoaded({
    required this.currentPhase,
    required this.todayRecords,
    this.lastRecord,
    this.isSubmitting = false,
    this.feedbackMessage,
  });

  AttendanceLoaded copyWith({
    ShiftPhase? currentPhase,
    List<AttendanceRecord>? todayRecords,
    AttendanceRecord? lastRecord,
    bool? isSubmitting,
    String? feedbackMessage,
  }) {
    return AttendanceLoaded(
      currentPhase: currentPhase ?? this.currentPhase,
      todayRecords: todayRecords ?? this.todayRecords,
      lastRecord: lastRecord ?? this.lastRecord,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      feedbackMessage: feedbackMessage,
    );
  }

  @override
  List<Object?> get props => [
        currentPhase,
        todayRecords,
        lastRecord,
        isSubmitting,
        feedbackMessage,
      ];
}

class AttendanceSuccess extends AttendanceState {
  final AttendanceRecord record;

  const AttendanceSuccess(this.record);

  @override
  List<Object?> get props => [record];
}

class AttendanceError extends AttendanceState {
  final String message;

  const AttendanceError(this.message);

  @override
  List<Object?> get props => [message];
}
