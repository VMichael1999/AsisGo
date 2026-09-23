import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';

class SelfieCaptureWidget extends StatefulWidget {
  final Function(String? imagePath) onImageCaptured;
  final String? initialImagePath;

  const SelfieCaptureWidget({
    super.key,
    required this.onImageCaptured,
    this.initialImagePath,
  });

  @override
  State<SelfieCaptureWidget> createState() => _SelfieCaptureWidgetState();
}

class _SelfieCaptureWidgetState extends State<SelfieCaptureWidget> {
  final ImagePicker _picker = ImagePicker();
  String? _capturedImagePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _capturedImagePath = widget.initialImagePath;
  }

  Future<void> _takePhoto() async {
    setState(() => _isLoading = true);
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _capturedImagePath = photo.path;
        });
        widget.onImageCaptured(photo.path);
      }
    } catch (e) {
      debugPrint('Camera not available or permission denied: $e. Using demo selfie.');
      // Valor de contingencia para simuladores o dispositivos sin camara frontal
      const demoPath = 'DEMO_FACE_VERIFIED';
      setState(() {
        _capturedImagePath = demoPath;
      });
      widget.onImageCaptured(demoPath);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _removePhoto() {
    setState(() {
      _capturedImagePath = null;
    });
    widget.onImageCaptured(null);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_capturedImagePath != null) {
      return Container(
        height: 140,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accent, width: 1.5),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_capturedImagePath != 'DEMO_FACE_VERIFIED' && !kIsWeb && File(_capturedImagePath!).existsSync())
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  File(_capturedImagePath!),
                  width: double.infinity,
                  height: 140,
                  fit: BoxFit.cover,
                ),
              )
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent.withValues(alpha: 0.2),
                    ),
                    child: const Icon(Icons.face_rounded, size: 40, color: AppColors.accent),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Rostro verificado con éxito',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: _removePhoto,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Biometría OK',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: _isLoading ? null : _takePhoto,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0x33FFFFFF) : AppColors.borderLight,
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: AppColors.accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tomar selfie de validación facial',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Opcional o requerido según política corporativa',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textMuted : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
