import 'package:equatable/equatable.dart';
import '../../domain/incident_justification.dart';

abstract class JustificationState extends Equatable {
  const JustificationState();

  @override
  List<Object?> get props => [];
}

class JustificationInitial extends JustificationState {}

class JustificationLoading extends JustificationState {}

class JustificationLoaded extends JustificationState {
  final List<IncidentJustification> justifications;
  final JustificationStatus? filterStatus; // null representa ver 'Todas'
  final bool isSubmitting;
  final String? feedbackMessage;
  final bool isSuccessMessage;

  const JustificationLoaded({
    required this.justifications,
    this.filterStatus,
    this.isSubmitting = false,
    this.feedbackMessage,
    this.isSuccessMessage = true,
  });

  List<IncidentJustification> get filteredJustifications {
    if (filterStatus == null) return justifications;
    return justifications.where((j) => j.status == filterStatus).toList();
  }

  int get totalCount => justifications.length;
  int get pendingCount =>
      justifications.where((j) => j.status == JustificationStatus.pending).length;
  int get approvedCount =>
      justifications.where((j) => j.status == JustificationStatus.approved).length;
  int get rejectedCount =>
      justifications.where((j) => j.status == JustificationStatus.rejected).length;

  JustificationLoaded copyWith({
    List<IncidentJustification>? justifications,
    JustificationStatus? Function()? filterStatus,
    bool? isSubmitting,
    String? feedbackMessage,
    bool? isSuccessMessage,
  }) {
    return JustificationLoaded(
      justifications: justifications ?? this.justifications,
      filterStatus: filterStatus != null ? filterStatus() : this.filterStatus,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      feedbackMessage: feedbackMessage,
      isSuccessMessage: isSuccessMessage ?? this.isSuccessMessage,
    );
  }

  @override
  List<Object?> get props => [
        justifications,
        filterStatus,
        isSubmitting,
        feedbackMessage,
        isSuccessMessage,
      ];
}

class JustificationError extends JustificationState {
  final String message;
  const JustificationError(this.message);

  @override
  List<Object?> get props => [message];
}
