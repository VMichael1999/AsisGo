import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/haptic_feedback_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/asis_action_button.dart';
import '../../domain/branch_model.dart';
import '../../domain/shift_phase.dart';
import 'selfie_capture_widget.dart';

class AttendanceModalSheet extends StatefulWidget {
  final AttendanceType type;
  final Branch branch;
  final Geozone geozone;
  final double distanceMeters;
  final bool isInside;
  final bool isSubmitting;
  final bool isOffline;
  final Function(String? note, String? selfiePath) onConfirm;

  const AttendanceModalSheet({
    super.key,
    required this.type,
    required this.branch,
    required this.geozone,
    required this.distanceMeters,
    required this.isInside,
    this.isSubmitting = false,
    this.isOffline = false,
    required this.onConfirm,
  });

  static Future<void> show({
    required BuildContext context,
    required AttendanceType type,
    required Branch branch,
    required Geozone geozone,
    required double distanceMeters,
    required bool isInside,
    bool isOffline = false,
    required Function(String? note, String? selfiePath) onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AttendanceModalSheet(
        type: type,
        branch: branch,
        geozone: geozone,
        distanceMeters: distanceMeters,
        isInside: isInside,
        isOffline: isOffline,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<AttendanceModalSheet> createState() => _AttendanceModalSheetState();
}

class _AttendanceModalSheetState extends State<AttendanceModalSheet> {
  final TextEditingController _noteController = TextEditingController();
  String? _capturedSelfiePath;
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131926) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: isDark ? Border.all(color: const Color(0x33FFFFFF), width: 0.8) : null,
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Indicador superior de arrastre
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Encabezado con distintivo del tipo de marcacion
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.type.color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.type.icon, color: widget.type.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.type.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        DateFormatter.formatFullDate(_currentTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Reloj digital en vivo con cifras monoespaciadas
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    DateFormatter.formatTime(_currentTime),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tarjeta de verificacion de geolocalizacion
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.isInside ? AppColors.accent : (isDark ? const Color(0x33FFFFFF) : AppColors.borderLight),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.isInside ? Icons.verified_rounded : Icons.location_on_rounded,
                    color: widget.isInside ? AppColors.accent : AppColors.lunchColor,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.branch.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          widget.isInside
                              ? 'Dentro de la geozona autorizada (${widget.distanceMeters.toStringAsFixed(0)} m)'
                              : 'A ${widget.distanceMeters.toStringAsFixed(0)} m de ${widget.geozone.name}',
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.isInside ? AppColors.accent : (isDark ? AppColors.textMuted : AppColors.textSecondary),
                            fontWeight: widget.isInside ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Verificacion facial y captura de selfie
            Text(
              'Fotografía Facial de Validación',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            SelfieCaptureWidget(
              onImageCaptured: (path) {
                setState(() => _capturedSelfiePath = path);
              },
            ),
            const SizedBox(height: 16),

            // Nota o descripcion opcional
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Observación o Comentario',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Opcional',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textMuted : Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noteController,
              maxLines: 2,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                hintText: 'Añade una descripción o puedes omitirla...',
                hintStyle: TextStyle(
                  color: isDark ? AppColors.textMuted : Colors.grey.shade500,
                  fontSize: 13,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? const Color(0x33FFFFFF) : AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? const Color(0x33FFFFFF) : AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (widget.isOffline) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.wifi_off_rounded, color: Color(0xFFF59E0B), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Modo sin conexión: Tu marcación quedará almacenada localmente y se enviará al servidor al detectar internet.',
                        style: TextStyle(
                          color: Color(0xFFFCD34D),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Botones de accion para confirmacion o cancelacion
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: () {
                      HapticFeedbackService.shared.selectionClick();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: isDark ? const Color(0x33FFFFFF) : AppColors.borderLight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: AsisActionButton(
                    label: 'Confirmar ${widget.type.shortName}',
                    icon: widget.type.icon,
                    backgroundColor: widget.type.color,
                    isLoading: widget.isSubmitting,
                    borderRadius: 14,
                    height: 52,
                    onPressed: () {
                      HapticFeedbackService.shared.selectionClick();
                      final note = _noteController.text.trim();
                      widget.onConfirm(
                        note.isEmpty ? null : note,
                        _capturedSelfiePath,
                      );
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
