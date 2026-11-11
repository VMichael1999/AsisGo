import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/incident_justification.dart';

class JustificationCard extends StatelessWidget {
  final IncidentJustification item;
  final VoidCallback? onTap;

  const JustificationCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(item.status);
    final isPdf = item.attachmentType?.contains('pdf') == true;

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderLight),
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      color: AppColors.textPrimary,
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
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '${item.type.label} · ${_formatDate(item.incidentDate)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Motivo
            Text(
              item.reason,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: AppColors.textPrimary,
              ),
            ),

            // Adjunto
            if (item.hasAttachment) ...[
              const SizedBox(height: 12),
              Material(
                color: AppColors.backgroundLight,
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
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.attachmentName ?? 'Archivo adjunto',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item.fileSizeBytes != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '${(item.fileSizeBytes! / 1024).toStringAsFixed(0)} KB',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: AppColors.textMuted,
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
                    const Text(
                      'Respuesta de RR. HH.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.reviewerNotes!,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.textPrimary,
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
    final isImage =
        item.attachmentType?.contains('image') == true ||
        item.attachmentPath?.endsWith('.jpg') == true ||
        item.attachmentPath?.endsWith('.png') == true;

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF131926) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
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
                      color:
                          isDark
                              ? const Color(0xFF1E2638)
                              : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isDark
                                ? const Color(0x33FFFFFF)
                                : AppColors.borderLight,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isImage
                              ? Icons.image_rounded
                              : Icons.description_rounded,
                          size: 48,
                          color: isImage ? AppColors.accent : Colors.redAccent,
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

  Color _getStatusColor(JustificationStatus status) {
    switch (status) {
      case JustificationStatus.pending:
        return const Color(
          0xFFB45309,
        ); // ambar oscuro: contraste AA sobre fondo claro
      case JustificationStatus.approved:
        return const Color(0xFF047857); // verde oscuro
      case JustificationStatus.rejected:
        return AppColors.checkOutColor;
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
