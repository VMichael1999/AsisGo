import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/haptic_feedback_service.dart';
import '../../attendance_map/presentation/cubit/attendance_cubit.dart';
import '../../attendance_map/presentation/cubit/attendance_state.dart';
import '../../attendance_map/domain/shift_phase.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';
import '../../auth/presentation/cubit/auth_state.dart';
import '../../justifications/presentation/views/justifications_view.dart';
import '../../justifications/presentation/widgets/new_justification_sheet.dart';
import '../../../../core/widgets/asis_shimmer.dart';
import '../../../../core/widgets/asis_skeletons.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool _shiftStartAlert = true;
  bool _lunchAlert = true;
  bool _shiftEndAlert = true;
  bool _liveActivityEnabled = true;
  bool _biometricLogin = true;
  bool _hapticEnabled = true;
  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    _hapticEnabled = HapticFeedbackService.shared.isHapticEnabled;
    _soundEnabled = HapticFeedbackService.shared.isSoundEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.obsidianCanvas : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: isDark ? AppColors.obsidianCanvas : Colors.white,
        elevation: 0,
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final user = state.currentUser;

          if (user == null) {
            return const AsisLoadingOverlay(
              skeleton: AsisProfileSkeleton(),
              message: 'Cargando información del colaborador...',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Tarjeta de perfil del usuario
              Card(
                color: isDark ? const Color(0xFF131926) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark ? const Color(0x33FFFFFF) : AppColors.borderLight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.accent, AppColors.indigoAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            user.fullName.isNotEmpty ? user.fullName[0] : 'U',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.role,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark ? const Color(0x22FFFFFF) : Colors.transparent,
                                ),
                              ),
                              child: Text(
                                'DNI/ID: ${user.documentNumber}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tarjeta de horario laboral asignado
              Card(
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
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded, color: AppColors.accent, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Horario Laboral Asignado',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSchedulePill('Entrada', user.shiftStartTime, AppColors.checkInColor, isDark),
                          Icon(Icons.arrow_forward_rounded, size: 16, color: isDark ? Colors.white30 : AppColors.textMuted),
                          _buildSchedulePill('Refrigerio', '60 min', AppColors.lunchColor, isDark),
                          Icon(Icons.arrow_forward_rounded, size: 16, color: isDark ? Colors.white30 : AppColors.textMuted),
                          _buildSchedulePill('Salida', user.shiftEndTime, AppColors.checkOutColor, isDark),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Configuracion de notificaciones y recordatorios
              Card(
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
                      Row(
                        children: [
                          const Icon(Icons.notifications_active_rounded, color: AppColors.accent, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Notificaciones & Recordatorios',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Alerta 15 min antes de la entrada', style: TextStyle(fontSize: 13, color: isDark ? Colors.white : AppColors.textPrimary)),
                        subtitle: Text('Te avisa para evitar tardanzas', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMuted : AppColors.textSecondary)),
                        value: _shiftStartAlert,
                        activeColor: AppColors.accent,
                        onChanged: (v) => setState(() => _shiftStartAlert = v),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Alerta de fin de refrigerio', style: TextStyle(fontSize: 13, color: isDark ? Colors.white : AppColors.textPrimary)),
                        subtitle: Text('Recordatorio al cumplirse la hora', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMuted : AppColors.textSecondary)),
                        value: _lunchAlert,
                        activeColor: AppColors.accent,
                        onChanged: (v) => setState(() => _lunchAlert = v),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Alerta de fin de jornada', style: TextStyle(fontSize: 13, color: isDark ? Colors.white : AppColors.textPrimary)),
                        subtitle: Text('Notificación para marcar salida', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMuted : AppColors.textSecondary)),
                        value: _shiftEndAlert,
                        activeColor: AppColors.accent,
                        onChanged: (v) => setState(() => _shiftEndAlert = v),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Live Activities & Dynamic Island', style: TextStyle(fontSize: 13, color: isDark ? Colors.white : AppColors.textPrimary)),
                        subtitle: Text('Seguimiento del turno en vivo y notificación persistente', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMuted : AppColors.textSecondary)),
                        value: _liveActivityEnabled,
                        activeColor: AppColors.accent,
                        onChanged: (v) => setState(() => _liveActivityEnabled = v),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Configuracion de seguridad y biometria
              Card(
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
                      Row(
                        children: [
                          const Icon(Icons.security_rounded, color: AppColors.accent, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Seguridad & Acceso',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Ingreso con Huella / Face ID', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary)),
                        subtitle: Text('Acceso biométrico rápido sin ingresar contraseña', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMuted : AppColors.textSecondary)),
                        value: _biometricLogin,
                        activeColor: AppColors.accent,
                        onChanged: (v) => setState(() => _biometricLogin = v),
                      ),
                      Divider(height: 20, color: isDark ? const Color(0x22FFFFFF) : AppColors.borderLight),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isDark ? const Color(0x22FFFFFF) : AppColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 18, color: AppColors.indigoAccent),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Permanencia y seguridad de sesión',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Cierre automático de seguridad por inactividad.',
                                    style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMuted : AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified_user_rounded, size: 18, color: AppColors.accent),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Seguridad de Ubicación Activa',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accent),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Detección estricta de suplantación de GPS.',
                                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Configuracion de Feedback Háptico y Sonidos de Confirmación
              Card(
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
                      Row(
                        children: [
                          const Icon(Icons.vibration_rounded, color: AppColors.accent, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Feedback Háptico & Sonidos',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Vibración Háptica Táctil',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'Respuesta táctil física al pulsar botones y registrar asistencia',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                          ),
                        ),
                        value: _hapticEnabled,
                        activeColor: AppColors.accent,
                        onChanged: (v) {
                          setState(() => _hapticEnabled = v);
                          HapticFeedbackService.shared.setHapticEnabled(v);
                          if (v) {
                            HapticFeedbackService.shared.selectionClick();
                          }
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Sonidos de Confirmación',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'Efectos sonoros sutiles al confirmar marcaciones, alertas y sincronizaciones',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                          ),
                        ),
                        value: _soundEnabled,
                        activeColor: AppColors.accent,
                        onChanged: (v) {
                          setState(() => _soundEnabled = v);
                          HapticFeedbackService.shared.setSoundEnabled(v);
                          if (v) {
                            HapticFeedbackService.shared.punchSuccess();
                          }
                        },
                      ),
                      Divider(height: 16, color: isDark ? const Color(0x22FFFFFF) : AppColors.borderLight),
                      Text(
                        'Probar respuestas sensoriales:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                HapticFeedbackService.shared.punchSuccess();
                              },
                              icon: const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.checkInColor),
                              label: const Text('Éxito', style: TextStyle(fontSize: 11)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                side: BorderSide(color: AppColors.checkInColor.withValues(alpha: 0.5)),
                                foregroundColor: AppColors.checkInColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                HapticFeedbackService.shared.securityAlert();
                              },
                              icon: const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFEF4444)),
                              label: const Text('Alerta', style: TextStyle(fontSize: 11)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                side: BorderSide(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                                foregroundColor: const Color(0xFFEF4444),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                HapticFeedbackService.shared.selectionClick();
                              },
                              icon: const Icon(Icons.touch_app_rounded, size: 14, color: AppColors.accent),
                              label: const Text('Toque', style: TextStyle(fontSize: 11)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                side: BorderSide(color: AppColors.accent.withValues(alpha: 0.5)),
                                foregroundColor: AppColors.accent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Gestión de Justificaciones e Incidencias Laborales
              Card(
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
                      Row(
                        children: [
                          const Icon(Icons.assignment_turned_in_rounded, color: AppColors.accent, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Justificación de Incidencias',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Registra tardanzas, salidas anticipadas o descansos médicos con comprobantes y fotos adjuntas.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                HapticFeedbackService.shared.selectionClick();
                                Navigator.push(context, JustificationsView.route());
                              },
                              icon: const Icon(Icons.list_alt_rounded, size: 16),
                              label: const Text('Ver Mis Solicitudes', style: TextStyle(fontSize: 12)),
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
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                HapticFeedbackService.shared.selectionClick();
                                NewJustificationSheet.show(context);
                              },
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('Nueva Solicitud', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Configuracion de modo offline y sincronizacion automatica
              Card(
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
                      Row(
                        children: [
                          const Icon(Icons.cloud_sync_rounded, color: AppColors.accent, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Modo Offline & Sincronización',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Estado actual de conectividad
                      Builder(builder: (context) {
                        final connService = context.watch<ConnectivityService>();
                        final isOnline = connService.isOnline;
                        final isSimulated = connService.isSimulatedOffline;

                        return Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isOnline
                                    ? AppColors.accent.withValues(alpha: 0.1)
                                    : const Color(0xFFF59E0B).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isOnline
                                      ? AppColors.accent.withValues(alpha: 0.3)
                                      : const Color(0xFFF59E0B).withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                                    size: 18,
                                    color: isOnline ? AppColors.accent : const Color(0xFFF59E0B),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isOnline ? 'Conexión activa con el servidor' : 'Modo fuera de línea activo',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: isOnline ? AppColors.accent : const Color(0xFFF59E0B),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          isOnline
                                              ? 'Las marcas se registran y sincronizan en tiempo real.'
                                              : 'Las marcas se almacenan localmente y se enviarán al volver la red.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? Colors.white70 : AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Simular Modo Sin Conexión (Testing)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                'Permite validar la cola offline y auto-sincronización sin desconectar Wi-Fi',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                                ),
                              ),
                              value: isSimulated,
                              activeColor: const Color(0xFFF59E0B),
                              onChanged: (v) {
                                connService.setSimulatedOffline(v);
                              },
                            ),
                            Divider(height: 16, color: isDark ? const Color(0x22FFFFFF) : AppColors.borderLight),
                            Text(
                              'Simular Fase de Turno (Live Activity & Dynamic Island)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Prueba instantánea del color de Dynamic Island (Naranja en refrigerio, Verde en turno)',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            BlocBuilder<AttendanceCubit, AttendanceState>(
                              builder: (context, attState) {
                                final currentPhase = attState is AttendanceLoaded ? attState.currentPhase : ShiftPhase.notStarted;
                                return Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _buildPhaseChip(
                                      context,
                                      label: 'En Turno',
                                      phase: ShiftPhase.working,
                                      selected: currentPhase == ShiftPhase.working,
                                      color: const Color(0xFF10B981),
                                    ),
                                    _buildPhaseChip(
                                      context,
                                      label: 'Refrigerio',
                                      phase: ShiftPhase.onLunch,
                                      selected: currentPhase == ShiftPhase.onLunch,
                                      color: Colors.orange,
                                    ),
                                    _buildPhaseChip(
                                      context,
                                      label: 'Reanudada',
                                      phase: ShiftPhase.resumed,
                                      selected: currentPhase == ShiftPhase.resumed,
                                      color: const Color(0xFF10B981),
                                    ),
                                    _buildPhaseChip(
                                      context,
                                      label: 'Finalizada',
                                      phase: ShiftPhase.completed,
                                      selected: currentPhase == ShiftPhase.completed,
                                      color: const Color(0xFF059669),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        );
                      }),
                      // Estado de marcas pendientes
                      BlocBuilder<AttendanceCubit, AttendanceState>(
                        builder: (context, state) {
                          if (state is! AttendanceLoaded) return const SizedBox.shrink();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Divider(height: 16, color: isDark ? const Color(0x22FFFFFF) : AppColors.borderLight),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Marcas pendientes de envío',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white : AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${state.pendingSyncCount} registro(s) en cola local',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (state.pendingSyncCount > 0)
                                    ElevatedButton.icon(
                                      onPressed: state.isSyncing
                                          ? null
                                          : () => context.read<AttendanceCubit>().syncPendingNow(),
                                      icon: state.isSyncing
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                            )
                                          : const Icon(Icons.sync_rounded, size: 16),
                                      label: Text(state.isSyncing ? 'Sincronizando...' : 'Sincronizar'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.accent,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Boton para cerrar sesion
              OutlinedButton.icon(
                onPressed: () => context.read<AuthCubit>().logout(),
                icon: const Icon(Icons.logout_rounded, color: AppColors.checkOutColor),
                label: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(color: AppColors.checkOutColor, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSchedulePill(String label, String value, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMuted : AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhaseChip(
    BuildContext context, {
    required String label,
    required ShiftPhase phase,
    required bool selected,
    required Color color,
  }) {
    return ActionChip(
      avatar: CircleAvatar(
        radius: 4,
        backgroundColor: color,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? Colors.white : color,
        ),
      ),
      backgroundColor: selected ? color.withValues(alpha: 0.85) : color.withValues(alpha: 0.12),
      side: BorderSide(
        color: selected ? color : color.withValues(alpha: 0.4),
        width: selected ? 1.5 : 1.0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onPressed: () {
        context.read<AttendanceCubit>().simulatePhaseForDemo(phase);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Fase simulada: $label actualizada en Dynamic Island',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: const Color(0xFF0F172A),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFF334155), width: 1),
            ),
          ),
        );
      },
    );
  }
}
