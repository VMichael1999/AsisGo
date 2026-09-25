import 'package:equatable/equatable.dart';

/// Tipos de incidencia laboral permitidos en AsisGo
enum IncidentType {
  tardiness,       // Tardanza en la hora de entrada
  earlyDeparture,  // Salida anticipada justificada
  omission,        // Omisión o error en la marcación
  medical,         // Cita o descanso médico (con receta/certificado)
  personalLeave,   // Permiso personal / asunto familiar
  fieldWork,       // Trabajo fuera de oficina / comisión externa
  other,           // Otros motivos excepcionales
}

extension IncidentTypeExtension on IncidentType {
  String get label {
    switch (this) {
      case IncidentType.tardiness:
        return 'Tardanza al Ingreso';
      case IncidentType.earlyDeparture:
        return 'Salida Anticipada';
      case IncidentType.omission:
        return 'Omisión de Marcación';
      case IncidentType.medical:
        return 'Descanso / Cita Médica';
      case IncidentType.personalLeave:
        return 'Permiso Personal';
      case IncidentType.fieldWork:
        return 'Comisión de Servicios / Campo';
      case IncidentType.other:
        return 'Otro Motivo';
    }
  }

  String get defaultTitle {
    switch (this) {
      case IncidentType.tardiness:
        return 'Justificación por retraso involuntario';
      case IncidentType.earlyDeparture:
        return 'Solicitud de retiro temprano';
      case IncidentType.omission:
        return 'Regularización de marca de asistencia';
      case IncidentType.medical:
        return 'Atención médica / Certificado ESSALUD';
      case IncidentType.personalLeave:
        return 'Asuntos de índole personal / familiar';
      case IncidentType.fieldWork:
        return 'Reunión externa con cliente';
      case IncidentType.other:
        return 'Incidencia laboral extraordinaria';
    }
  }
}

/// Estados del flujo de aprobación de la justificación
enum JustificationStatus {
  pending,  // En revisión por supervisor / RRHH
  approved, // Aprobada y regularizada
  rejected, // Rechazada con observaciones
}

extension JustificationStatusExtension on JustificationStatus {
  String get label {
    switch (this) {
      case JustificationStatus.pending:
        return 'Pendiente';
      case JustificationStatus.approved:
        return 'Aprobada';
      case JustificationStatus.rejected:
        return 'Rechazada';
    }
  }
}

/// Modelo de dominio que representa una Justificación de Incidencia Laboral
class IncidentJustification extends Equatable {
  final String id;
  final String userId;
  final IncidentType type;
  final String title;
  final DateTime incidentDate;
  final String? incidentTime;
  final String reason;
  final String? attachmentPath;
  final String? attachmentName;
  final String? attachmentType; // ej: 'image/jpeg', 'application/pdf'
  final int? fileSizeBytes;
  final JustificationStatus status;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewerNotes;

  const IncidentJustification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.incidentDate,
    this.incidentTime,
    required this.reason,
    this.attachmentPath,
    this.attachmentName,
    this.attachmentType,
    this.fileSizeBytes,
    this.status = JustificationStatus.pending,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewerNotes,
  });

  bool get hasAttachment => attachmentPath != null && attachmentPath!.isNotEmpty;

  IncidentJustification copyWith({
    String? id,
    String? userId,
    IncidentType? type,
    String? title,
    DateTime? incidentDate,
    String? incidentTime,
    String? reason,
    String? attachmentPath,
    String? attachmentName,
    String? attachmentType,
    int? fileSizeBytes,
    JustificationStatus? status,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewerNotes,
  }) {
    return IncidentJustification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      incidentDate: incidentDate ?? this.incidentDate,
      incidentTime: incidentTime ?? this.incidentTime,
      reason: reason ?? this.reason,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      attachmentName: attachmentName ?? this.attachmentName,
      attachmentType: attachmentType ?? this.attachmentType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewerNotes: reviewerNotes ?? this.reviewerNotes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'title': title,
      'incidentDate': incidentDate.toIso8601String(),
      'incidentTime': incidentTime,
      'reason': reason,
      'attachmentPath': attachmentPath,
      'attachmentName': attachmentName,
      'attachmentType': attachmentType,
      'fileSizeBytes': fileSizeBytes,
      'status': status.name,
      'submittedAt': submittedAt.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewerNotes': reviewerNotes,
    };
  }

  factory IncidentJustification.fromJson(Map<String, dynamic> json) {
    return IncidentJustification(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: IncidentType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => IncidentType.other,
      ),
      title: json['title'] as String? ?? 'Incidencia de Asistencia',
      incidentDate: DateTime.parse(json['incidentDate'] as String),
      incidentTime: json['incidentTime'] as String?,
      reason: json['reason'] as String? ?? '',
      attachmentPath: json['attachmentPath'] as String?,
      attachmentName: json['attachmentName'] as String?,
      attachmentType: json['attachmentType'] as String?,
      fileSizeBytes: json['fileSizeBytes'] as int?,
      status: JustificationStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => JustificationStatus.pending,
      ),
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'] as String)
          : null,
      reviewerNotes: json['reviewerNotes'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        title,
        incidentDate,
        incidentTime,
        reason,
        attachmentPath,
        attachmentName,
        attachmentType,
        fileSizeBytes,
        status,
        submittedAt,
        reviewedAt,
        reviewerNotes,
      ];
}
