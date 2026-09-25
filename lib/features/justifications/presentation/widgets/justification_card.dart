import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/incident_justification.dart';

class JustificationCard extends StatelessWidget {
  final IncidentJustification item;
  final VoidCallback? onTap;

  const JustificationCard({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final typeColor = _getTypeColor(item.type);
    final statusColor = _getStatusColor(item.status);
    final statusBgColor = statusColor.withValues(alpha: 0.15);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? const Color(0xFF131926) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0x33FFFFFF) : AppColors.borderLight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Icono + Tipo + Status Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getTypeIcon(item.type),
                    color: typeColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.type.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _formatDate(item.incidentDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge de Estado
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(radius: 3.5, backgroundColor: statusColor),
                      const SizedBox(width: 5),
                      Text(
                        item.status.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Título y Motivo
            Text(
              item.title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFE2E8F0) : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.reason,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                height: 1.35,
              ),
            ),

            // Adjunto de Archivo (si existe)
            if (item.hasAttachment) ...[
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _showAttachmentPreview(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2638) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0x33FFFFFF) : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.attachmentType?.contains('pdf') == true
                            ? Icons.picture_as_pdf_rounded
                            : Icons.image_rounded,
                        color: item.attachmentType?.contains('pdf') == true
                            ? Colors.redAccent
                            : AppColors.accent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.attachmentName ?? 'Archivo Adjunto',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (item.fileSizeBytes != null)
                              Text(
                                '${(item.fileSizeBytes! / 1024).toStringAsFixed(1)} KB • Toca para previsualizar',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.visibility_outlined,
                        size: 16,
                        color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Notas del Revisor (si fue evaluada)
            if (item.reviewerNotes != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.status == JustificationStatus.approved
                      ? const Color(0xFF10B981).withValues(alpha: 0.1)
                      : const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      item.status == JustificationStatus.approved
                          ? Icons.check_circle_outline_rounded
                          : Icons.info_outline_rounded,
                      size: 16,
                      color: statusColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.reviewerNotes!,
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: isDark ? Colors.white70 : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAttachmentPreview(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isImage = item.attachmentType?.contains('image') == true ||
        item.attachmentPath?.endsWith('.jpg') == true ||
        item.attachmentPath?.endsWith('.png') == true;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF131926) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(
              isImage ? Icons.image_rounded : Icons.picture_as_pdf_rounded,
              color: isImage ? AppColors.accent : Colors.redAccent,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.attachmentName ?? 'Adjunto de Justificación',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isImage && item.attachmentPath != null && File(item.attachmentPath!).existsSync())
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(item.attachmentPath!),
                  height: 260,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2638) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0x33FFFFFF) : AppColors.borderLight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isImage ? Icons.image_rounded : Icons.description_rounded,
                      size: 48,
                      color: isImage ? AppColors.accent : Colors.redAccent,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item.attachmentName ?? 'Documento Adjunto',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Documento oficial registrado en expediente RRHH',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(IncidentType type) {
    switch (type) {
      case IncidentType.tardiness:
        return const Color(0xFFF59E0B); // Amber
      case IncidentType.earlyDeparture:
        return const Color(0xFF8B5CF6); // Purple
      case IncidentType.omission:
        return const Color(0xFF3B82F6); // Blue
      case IncidentType.medical:
        return const Color(0xFF10B981); // Emerald
      case IncidentType.personalLeave:
        return const Color(0xFFEC4899); // Pink
      case IncidentType.fieldWork:
        return const Color(0xFF06B6D4); // Cyan
      case IncidentType.other:
        return const Color(0xFF64748B); // Slate
    }
  }

  IconData _getTypeIcon(IncidentType type) {
    switch (type) {
      case IncidentType.tardiness:
        return Icons.alarm_rounded;
      case IncidentType.earlyDeparture:
        return Icons.logout_rounded;
      case IncidentType.omission:
        return Icons.edit_calendar_rounded;
      case IncidentType.medical:
        return Icons.local_hospital_rounded;
      case IncidentType.personalLeave:
        return Icons.family_restroom_rounded;
      case IncidentType.fieldWork:
        return Icons.business_center_rounded;
      case IncidentType.other:
        return Icons.help_outline_rounded;
    }
  }

  Color _getStatusColor(JustificationStatus status) {
    switch (status) {
      case JustificationStatus.pending:
        return const Color(0xFFF59E0B);
      case JustificationStatus.approved:
        return const Color(0xFF10B981);
      case JustificationStatus.rejected:
        return const Color(0xFFEF4444);
    }
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
