import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/haptic_feedback_service.dart';
import '../../domain/incident_justification.dart';
import '../cubit/justification_cubit.dart';
import '../cubit/justification_state.dart';

class NewJustificationSheet extends StatefulWidget {
  final DateTime? initialDate;

  const NewJustificationSheet({super.key, this.initialDate});

  static Future<bool?> show(BuildContext context, {DateTime? initialDate}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NewJustificationSheet(initialDate: initialDate),
    );
  }

  @override
  State<NewJustificationSheet> createState() => _NewJustificationSheetState();
}

class _NewJustificationSheetState extends State<NewJustificationSheet> {
  final _formKey = GlobalKey<FormState>();
  late IncidentType _selectedType;
  late DateTime _selectedDate;
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  String? _attachedFilePath;
  String? _attachedFileName;
  String? _attachedFileType;
  int? _attachedFileSize;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedType = IncidentType.tardiness;
    _selectedDate = widget.initialDate ?? DateTime.now();
    _timeController.text = '08:45 AM';
    _titleController.text = _selectedType.defaultTitle;
  }

  @override
  void dispose() {
    _timeController.dispose();
    _titleController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    HapticFeedbackService.shared.selectionClick();
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (file != null) {
        final length = await file.length();
        setState(() {
          _attachedFilePath = file.path;
          _attachedFileName = file.name;
          _attachedFileType = 'image/jpeg';
          _attachedFileSize = length;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al adjuntar imagen: $e',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
            ),
          ),
        );
      }
    }
  }

  void _attachDemoDocument(String docName, String docType) {
    HapticFeedbackService.shared.selectionClick();
    setState(() {
      _attachedFilePath = 'documents/$docName';
      _attachedFileName = docName;
      _attachedFileType = docType;
      _attachedFileSize = docName.contains('.pdf') ? 312000 : 850000;
    });
  }

  Future<void> _pickDate() async {
    HapticFeedbackService.shared.selectionClick();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 15)),
      helpText: 'Seleccionar fecha de la incidencia',
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedbackService.shared.securityAlert();
      return;
    }

    final cubit = context.read<JustificationCubit>();
    final success = await cubit.submitJustification(
      type: _selectedType,
      title: _titleController.text.trim().isEmpty
          ? _selectedType.defaultTitle
          : _titleController.text.trim(),
      incidentDate: _selectedDate,
      incidentTime: _timeController.text.trim(),
      reason: _reasonController.text.trim(),
      attachmentPath: _attachedFilePath,
      attachmentName: _attachedFileName,
      attachmentType: _attachedFileType,
      fileSizeBytes: _attachedFileSize,
    );

    if (success && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: keyboardPadding),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131926) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0x33FFFFFF) : AppColors.borderLight,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Manija de arrastre
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Título del Modal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.assignment_turned_in_rounded,
                            color: AppColors.accent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Nueva Justificación',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 1. Selector de Tipo de Incidencia
                Text(
                  'Tipo de Incidencia',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2638) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0x33FFFFFF) : AppColors.borderLight,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<IncidentType>(
                      value: _selectedType,
                      isExpanded: true,
                      dropdownColor: isDark ? const Color(0xFF1A2234) : Colors.white,
                      items: IncidentType.values.map((type) {
                        return DropdownMenuItem<IncidentType>(
                          value: type,
                          child: Text(
                            type.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          HapticFeedbackService.shared.selectionClick();
                          setState(() {
                            _selectedType = val;
                            if (_titleController.text.isEmpty ||
                                IncidentType.values
                                    .any((t) => t.defaultTitle == _titleController.text)) {
                              _titleController.text = val.defaultTitle;
                            }
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Fila: Fecha y Hora Afectada
                Row(
                  children: [
                    // Selector de Fecha
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fecha Afectada',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E2638) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? const Color(0x33FFFFFF) : AppColors.borderLight,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.accent),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Campo de Hora
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hora estimada',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _timeController,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF1E2638) : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark ? const Color(0x33FFFFFF) : AppColors.borderLight,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark ? const Color(0x33FFFFFF) : AppColors.borderLight,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 3. Título / Asunto Breve
                Text(
                  'Asunto de la Justificación',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _titleController,
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white : AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Ej. Retraso por bloqueo vehicular en Javier Prado',
                    hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E2638) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0x33FFFFFF) : AppColors.borderLight,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0x33FFFFFF) : AppColors.borderLight,
                      ),
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el asunto' : null,
                ),
                const SizedBox(height: 14),

                // 4. Motivo Detallado
                Text(
                  'Explicación / Motivo Detallado',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _reasonController,
                  maxLines: 3,
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white : AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Detalla lo acontecido para la evaluación de Recursos Humanos...',
                    hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E2638) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0x33FFFFFF) : AppColors.borderLight,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0x33FFFFFF) : AppColors.borderLight,
                      ),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().length < 8) ? 'Ingresa al menos 8 caracteres' : null,
                ),
                const SizedBox(height: 16),

                // 5. Adjuntar Comprobante o Archivo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Adjuntar Comprobante / Archivo',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                    if (_attachedFileName != null)
                      TextButton.icon(
                        onPressed: () {
                          HapticFeedbackService.shared.selectionClick();
                          setState(() {
                            _attachedFilePath = null;
                            _attachedFileName = null;
                            _attachedFileType = null;
                            _attachedFileSize = null;
                          });
                        },
                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                        label: const Text('Quitar', style: TextStyle(fontSize: 11, color: Colors.redAccent)),
                      ),
                  ],
                ),
                const SizedBox(height: 6),

                if (_attachedFileName != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _attachedFileType?.contains('pdf') == true
                              ? Icons.picture_as_pdf_rounded
                              : Icons.image_rounded,
                          color: _attachedFileType?.contains('pdf') == true
                              ? Colors.redAccent
                              : AppColors.accent,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _attachedFileName!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_attachedFileSize != null)
                                Text(
                                  '${(_attachedFileSize! / 1024).toStringAsFixed(1)} KB • Archivo adjunto listo',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 20),
                      ],
                    ),
                  )
                else
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickImage(ImageSource.camera),
                              icon: const Icon(Icons.photo_camera_rounded, size: 16),
                              label: const Text('Tomar Foto', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
                                side: BorderSide(
                                  color: isDark ? const Color(0x33FFFFFF) : AppColors.borderLight,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickImage(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_rounded, size: 16),
                              label: const Text('Galería', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
                                side: BorderSide(
                                  color: isDark ? const Color(0x33FFFFFF) : AppColors.borderLight,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _attachDemoDocument('Certificado_Medico_Oficial.pdf', 'application/pdf'),
                          icon: const Icon(Icons.picture_as_pdf_rounded, size: 16, color: Colors.redAccent),
                          label: const Text('Adjuntar Documento PDF / Certificado', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
                            side: BorderSide(
                              color: isDark ? const Color(0x33FFFFFF) : AppColors.borderLight,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),

                // 6. Botón de Enviar
                BlocBuilder<JustificationCubit, JustificationState>(
                  builder: (context, state) {
                    final isSubmitting = state is JustificationLoaded && state.isSubmitting;

                    return SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: isSubmitting ? null : _submit,
                        icon: isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send_rounded, size: 18),
                        label: Text(
                          isSubmitting ? 'Enviando Solicitud...' : 'Enviar a Recursos Humanos',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
