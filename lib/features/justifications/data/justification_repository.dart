import 'package:uuid/uuid.dart';
import '../../../core/services/storage_service.dart';
import '../domain/incident_justification.dart';

abstract class IJustificationRepository {
  Future<void> init();
  Future<List<IncidentJustification>> getJustifications(String userId);
  Future<IncidentJustification> submitJustification({
    required String userId,
    required IncidentType type,
    required String title,
    required DateTime incidentDate,
    String? incidentTime,
    required String reason,
    String? attachmentPath,
    String? attachmentName,
    String? attachmentType,
    int? fileSizeBytes,
  });
}

class JustificationRepository implements IJustificationRepository {
  final StorageService _storageService;
  final _uuid = const Uuid();

  List<IncidentJustification> _cached = [];
  bool _initialized = false;

  JustificationRepository(this._storageService);

  @override
  Future<void> init() async {
    if (_initialized) return;
    final stored = _storageService.getJustifications();
    if (stored.isNotEmpty) {
      _cached = stored.map((json) => IncidentJustification.fromJson(json)).toList();
    } else {
      _cached = _seedInitialJustifications();
      await _persist();
    }
    _initialized = true;
  }

  Future<void> _persist() async {
    await _storageService.saveJustifications(
      _cached.map((j) => j.toJson()).toList(),
    );
  }

  @override
  Future<List<IncidentJustification>> getJustifications(String userId) async {
    await init();
    return _cached.where((j) => j.userId == userId).toList()
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
  }

  @override
  Future<IncidentJustification> submitJustification({
    required String userId,
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
    await init();
    final newJustification = IncidentJustification(
      id: _uuid.v4(),
      userId: userId,
      type: type,
      title: title.trim().isEmpty ? type.defaultTitle : title.trim(),
      incidentDate: incidentDate,
      incidentTime: incidentTime,
      reason: reason.trim(),
      attachmentPath: attachmentPath,
      attachmentName: attachmentName,
      attachmentType: attachmentType,
      fileSizeBytes: fileSizeBytes,
      status: JustificationStatus.pending,
      submittedAt: DateTime.now(),
    );

    _cached.insert(0, newJustification);
    await _persist();
    return newJustification;
  }

  List<IncidentJustification> _seedInitialJustifications() {
    final now = DateTime.now();
    const userId = 'USR-001';

    return [
      IncidentJustification(
        id: 'just-001',
        userId: userId,
        type: IncidentType.medical,
        title: 'Certificado Médico - Consulta Oftalmológica',
        incidentDate: now.subtract(const Duration(days: 3)),
        incidentTime: '09:00 AM - 11:30 AM',
        reason: 'Atención médica en clínica San Borja por chequeo visual anual. Se adjunta descanso médico oficial.',
        attachmentPath: 'demo_certificado_medico.pdf',
        attachmentName: 'Certificado_Clinica_SanBorja.pdf',
        attachmentType: 'application/pdf',
        fileSizeBytes: 245000,
        status: JustificationStatus.approved,
        submittedAt: now.subtract(const Duration(days: 3, hours: 2)),
        reviewedAt: now.subtract(const Duration(days: 2)),
        reviewerNotes: 'Documento validado por Recursos Humanos. Horas regularizadas en planilla.',
      ),
      IncidentJustification(
        id: 'just-002',
        userId: userId,
        type: IncidentType.tardiness,
        title: 'Retraso por congestión Vía Expresa Javier Prado',
        incidentDate: now.subtract(const Duration(days: 1)),
        incidentTime: '08:42 AM',
        reason: 'Incidente de tránsito en cruce Javier Prado con Paseo de la República causó retraso de 15 minutos en el ingreso.',
        attachmentPath: 'demo_ticket_metropolitano.jpg',
        attachmentName: 'Foto_Trafico_Comprobante.jpg',
        attachmentType: 'image/jpeg',
        fileSizeBytes: 850000,
        status: JustificationStatus.pending,
        submittedAt: now.subtract(const Duration(days: 1, hours: 1)),
      ),
    ];
  }
}
