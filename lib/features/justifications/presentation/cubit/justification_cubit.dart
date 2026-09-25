import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/haptic_feedback_service.dart';
import '../../data/justification_repository.dart';
import '../../domain/incident_justification.dart';
import 'justification_state.dart';

class JustificationCubit extends Cubit<JustificationState> {
  final IJustificationRepository _repository;
  final HapticFeedbackService _hapticService;
  String? _currentUserId;

  JustificationCubit({
    required IJustificationRepository repository,
    HapticFeedbackService? hapticService,
  })  : _repository = repository,
        _hapticService = hapticService ?? HapticFeedbackService.shared,
        super(JustificationInitial());

  Future<void> loadJustifications(String userId) async {
    _currentUserId = userId;
    emit(JustificationLoading());
    try {
      final list = await _repository.getJustifications(userId);
      emit(JustificationLoaded(justifications: list));
    } catch (e) {
      emit(JustificationError('Error al cargar justificaciones: ${e.toString()}'));
    }
  }

  void setFilter(JustificationStatus? status) {
    final current = state;
    if (current is JustificationLoaded) {
      emit(current.copyWith(filterStatus: () => status));
    }
  }

  Future<bool> submitJustification({
    required IncidentType type,
    required String title,
    required DateTime incidentDate,
    String? incidentTime,
    required String reason,
    String? attachmentPath,
    String? attachmentName,
    String? attachmentType,
    int? fileSizeBytes,
  }) async {
    final userId = _currentUserId ?? 'USR-001';
    final current = state;

    if (current is JustificationLoaded) {
      emit(current.copyWith(isSubmitting: true));
    }

    try {
      final newRecord = await _repository.submitJustification(
        userId: userId,
        type: type,
        title: title,
        incidentDate: incidentDate,
        incidentTime: incidentTime,
        reason: reason,
        attachmentPath: attachmentPath,
        attachmentName: attachmentName,
        attachmentType: attachmentType,
        fileSizeBytes: fileSizeBytes,
      );

      _hapticService.punchSuccess();

      if (current is JustificationLoaded) {
        final updatedList = [newRecord, ...current.justifications];
        emit(current.copyWith(
          justifications: updatedList,
          isSubmitting: false,
          feedbackMessage: '¡Justificación enviada con éxito! Está en revisión por RRHH.',
          isSuccessMessage: true,
        ));
      } else {
        await loadJustifications(userId);
      }
      return true;
    } catch (e) {
      _hapticService.securityAlert();
      if (current is JustificationLoaded) {
        emit(current.copyWith(
          isSubmitting: false,
          feedbackMessage: 'Error al registrar justificación: ${e.toString()}',
          isSuccessMessage: false,
        ));
      } else {
        emit(JustificationError(e.toString()));
      }
      return false;
    }
  }

  void clearFeedback() {
    final current = state;
    if (current is JustificationLoaded) {
      emit(current.copyWith(feedbackMessage: null));
    }
  }
}
