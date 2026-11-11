import '../../../../core/theme/asis_palette.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/haptic_feedback_service.dart';
import '../../domain/branch_model.dart';
import '../../domain/shift_phase.dart';
import 'selfie_capture_widget.dart';

/// Dialogo centrado "Asistencia": tipo de marcacion, comentario opcional,
/// selfie de validacion (solo en la entrada) y envio.
class AttendanceModalSheet extends StatefulWidget {
  /// Marcaciones permitidas en la fase actual; la primera es la sugerida.
  final List<AttendanceType> options;
  final Branch branch;
  final Geozone geozone;
  final bool isOffline;
  final void Function(AttendanceType type, String? note, String? selfiePath)
  onConfirm;

  const AttendanceModalSheet({
    super.key,
    required this.options,
    required this.branch,
    required this.geozone,
    this.isOffline = false,
    required this.onConfirm,
  });

  static Future<void> show({
    required BuildContext context,
    required List<AttendanceType> options,
    required Branch branch,
    required Geozone geozone,
    bool isOffline = false,
    required void Function(
      AttendanceType type,
      String? note,
      String? selfiePath,
    )
    onConfirm,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder:
          (ctx) => AttendanceModalSheet(
            options: options,
            branch: branch,
            geozone: geozone,
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
  late AttendanceType _selectedType = widget.options.first;
  String? _capturedSelfiePath;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: color),
  );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.palette.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Encabezado: titulo y boton de cierre
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Asistencia',
                    style: TextStyle(
                      color: context.palette.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Material(
                  color: AppColors.primaryLight,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.pop(context),
                    child: const Padding(
                      padding: EdgeInsets.all(5),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Divider(color: context.palette.primary, thickness: 1.2, height: 22),

            // Tipo de marcacion
            DropdownButtonFormField<AttendanceType>(
              initialValue: _selectedType,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              decoration: InputDecoration(
                filled: true,
                fillColor: context.palette.surface,
                prefixIcon: Icon(
                  Icons.location_on_outlined,
                  color: context.palette.textSecondary,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                border: _border(context.palette.textMuted),
                enabledBorder: _border(context.palette.textMuted),
                focusedBorder: _border(context.palette.primary),
              ),
              items: [
                for (final type in widget.options)
                  DropdownMenuItem(
                    value: type,
                    child: Text(
                      type.title,
                      style: TextStyle(
                        fontSize: 16,
                        color: context.palette.textPrimary,
                      ),
                    ),
                  ),
              ],
              onChanged: (type) {
                if (type != null) setState(() => _selectedType = type);
              },
            ),
            const SizedBox(height: 12),

            // Comentario opcional
            TextField(
              controller: _noteController,
              maxLines: 2,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Comentario (opcional)',
                hintStyle: TextStyle(
                  fontSize: 16,
                  color: context.palette.textSecondary,
                ),
                filled: true,
                fillColor: context.palette.surfaceAlt,
                border: _border(context.palette.border),
                enabledBorder: _border(context.palette.border),
                focusedBorder: _border(context.palette.primary),
              ),
            ),
            const SizedBox(height: 12),

            // Selfie de validacion: solo al marcar la entrada de la jornada
            if (_selectedType == AttendanceType.checkIn) ...[
              SelfieCaptureWidget(
                onImageCaptured: (path) {
                  setState(() => _capturedSelfiePath = path);
                },
              ),
              const SizedBox(height: 10),
            ],

            // Sede y geocerca donde se registra la marca
            Text(
              '${widget.branch.name} • ${widget.geozone.name}'
              '${widget.isOffline ? '\nSin conexión: se sincronizará al recuperar señal.' : ''}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: context.palette.textSecondary,
              ),
            ),
            Divider(color: context.palette.border, height: 24),

            Center(
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedbackService.shared.selectionClick();
                  final note = _noteController.text.trim();
                  widget.onConfirm(
                    _selectedType,
                    note.isEmpty ? null : note,
                    _capturedSelfiePath,
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.palette.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(150, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Enviar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
