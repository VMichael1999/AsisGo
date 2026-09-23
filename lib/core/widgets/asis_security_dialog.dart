import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum AsisSecurityDialogType {
  mockGpsDetected,
  outsideGeozone,
  policyWarning,
}

class AsisSecurityDialog extends StatelessWidget {
  final AsisSecurityDialogType type;
  final String title;
  final String description;
  final String? badgeLabel;
  final Map<String, String>? auditDetails;
  final VoidCallback? onDismiss;

  const AsisSecurityDialog({
    super.key,
    required this.type,
    required this.title,
    required this.description,
    this.badgeLabel,
    this.auditDetails,
    this.onDismiss,
  });

  static Future<void> show({
    required BuildContext context,
    required AsisSecurityDialogType type,
    required String title,
    required String description,
    String? badgeLabel,
    Map<String, String>? auditDetails,
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AsisSecurityDialog(
        type: type,
        title: title,
        description: description,
        badgeLabel: badgeLabel,
        auditDetails: auditDetails,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    IconData iconData;
    String defaultBadge;

    switch (type) {
      case AsisSecurityDialogType.mockGpsDetected:
        iconColor = AppColors.checkOutColor;
        iconData = Icons.security_update_warning_rounded;
        defaultBadge = 'ALERTA DE SEGURIDAD & AUDITORÍA';
        break;
      case AsisSecurityDialogType.outsideGeozone:
        iconColor = AppColors.lunchColor;
        iconData = Icons.wrong_location_rounded;
        defaultBadge = 'RESTRICCIÓN DE COBERTURA';
        break;
      case AsisSecurityDialogType.policyWarning:
        iconColor = AppColors.indigoAccent;
        iconData = Icons.shield_rounded;
        defaultBadge = 'POLÍTICA LABORAL';
        break;
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.08),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withValues(alpha: 0.15),
                border: Border.all(color: iconColor.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Icon(iconData, color: iconColor, size: 30),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badgeLabel ?? defaultBadge,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            if (auditDetails != null && auditDetails!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  children: auditDetails!.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              entry.value,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDismiss?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text(
              'Entendido',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}
