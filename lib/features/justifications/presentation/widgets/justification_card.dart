import '../../../../core/theme/asis_palette.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../domain/incident_justification.dart';

class JustificationCard extends StatelessWidget {
  final IncidentJustification item;
  final VoidCallback? onTap;

  const JustificationCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(context, item.status);
    final isPdf = item.attachmentType?.contains('pdf') == true;

    return Material(
      color: context.palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.palette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titulo + estado
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      color: context.palette.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _StatusPill(label: item.status.label, color: statusColor),
              ],
            ),
            const SizedBox(height: 6),

            // Tipo y fecha como metadato
            Row(
              children: [
                Icon(
                  _getTypeIcon(item.type),
                  size: 16,
                  color: context.palette.textSecondary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '${item.type.label} · ${_formatDate(item.incidentDate)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.palette.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Motivo
            Text(
              item.reason,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: context.palette.textPrimary,
              ),
            ),

            // Adjunto
            if (item.hasAttachment) ...[
              const SizedBox(height: 12),
              Material(
                color: context.palette.background,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _showAttachmentPreview(context),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Icon(
                            isPdf
                                ? Icons.picture_as_pdf_outlined
                                : Icons.image_outlined,
                            size: 20,
                            color: context.palette.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.attachmentName ?? 'Archivo adjunto',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: context.palette.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item.fileSizeBytes != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '${(item.fileSizeBytes! / 1024).toStringAsFixed(0)} KB',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.palette.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: context.palette.textMuted,
                            semanticLabel: 'Ver adjunto',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // Respuesta de RR. HH.
            if (item.reviewerNotes != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border(
                    left: BorderSide(color: statusColor, width: 3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Respuesta de RR. HH.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.palette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.reviewerNotes!,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: context.palette.textPrimary,
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
    final isImage =
        item.attachmentType?.contains('image') == true ||
        item.attachmentPath?.endsWith('.jpg') == true ||
        item.attachmentPath?.endsWith('.png') == true;

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: context.palette.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Row(
              children: [
                Icon(
                  isImage ? Icons.image_rounded : Icons.picture_as_pdf_rounded,
                  color: isImage ? context.palette.primary : Colors.redAccent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.attachmentName ?? 'Adjunto de Justificación',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isImage &&
                    item.attachmentPath != null &&
                    File(item.attachmentPath!).existsSync())
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
                      color: context.palette.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.palette.border),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isImage
                              ? Icons.image_rounded
                              : Icons.description_rounded,
                          size: 48,
                          color:
                              isImage
                                  ? context.palette.primary
                                  : Colors.redAccent,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item.attachmentName ?? 'Documento Adjunto',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
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

  Color _getStatusColor(BuildContext context, JustificationStatus status) {
    final p = context.palette;
    switch (status) {
      case JustificationStatus.pending:
        return p.warning;
      case JustificationStatus.approved:
        return p.success;
      case JustificationStatus.rejected:
        return p.danger;
    }
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
