import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/haptic_feedback_service.dart';
import '../../attendance_map/presentation/cubit/attendance_cubit.dart';
import '../../attendance_map/presentation/cubit/attendance_state.dart';
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

              // Configuración de notificaciones y recordatorios
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

              // Configuración de seguridad y biometría
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
                                    'Detección estricta de suplantación de GPS para garantizar la integridad.',
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

              // Sincronización de Marcaciones
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
                  child: BlocBuilder<AttendanceCubit, AttendanceState>(
                    builder: (context, attState) {
                      final isLoaded = attState is AttendanceLoaded;
                      final pendingCount = isLoaded ? attState.pendingSyncCount : 0;
                      final isSyncing = isLoaded && attState.isSyncing;
                      final isOffline = isLoaded && attState.isOffline;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.cloud_sync_rounded, color: AppColors.accent, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Sincronización de Marcaciones',
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
                            'Si registraste tu asistencia sin conexión a internet, las marcas se sincronizan automáticamente al recuperar señal de red, o puedes sincronizarlas manualmente.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: pendingCount > 0
                                  ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                                  : const Color(0xFF10B981).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: pendingCount > 0
                                    ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
                                    : const Color(0xFF10B981).withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  pendingCount > 0 ? Icons.pending_actions_rounded : Icons.check_circle_rounded,
                                  size: 20,
                                  color: pendingCount > 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pendingCount > 0
                                            ? '$pendingCount marcación(es) pendiente(s)'
                                            : 'Marcaciones al día',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: pendingCount > 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        pendingCount > 0
                                            ? 'Guardadas de manera local en el teléfono. Pendientes de envío.'
                                            : 'Todas las marcas están sincronizadas con el servidor.',
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
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: isSyncing
                                  ? null
                                  : () async {
                                      HapticFeedbackService.shared.selectionClick();
                                      if (isOffline) {
                                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Row(
                                              children: [
                                                Icon(Icons.wifi_off_rounded, color: Color(0xFFF59E0B), size: 20),
                                                SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    'Sin conexión a internet. Conéctate a Wi-Fi o datos para sincronizar.',
                                                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            backgroundColor: const Color(0xFF0F172A),
                                            duration: const Duration(seconds: 3),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(14),
                                              side: const BorderSide(color: Color(0xFFF59E0B), width: 1.2),
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      if (pendingCount == 0) {
                                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Row(
                                              children: [
                                                Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                                                SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    'Todas tus marcaciones ya están sincronizadas.',
                                                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            backgroundColor: const Color(0xFF0F172A),
                                            duration: const Duration(seconds: 2),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(14),
                                              side: const BorderSide(color: Color(0xFF10B981), width: 1.2),
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      await context.read<AttendanceCubit>().syncPendingNow();
                                    },
                              icon: isSyncing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.sync_rounded, size: 18),
                              label: Text(
                                isSyncing ? 'Sincronizando marcaciones...' : 'Sincronizar Marcaciones',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botón para cerrar sesión (Fondo rojo sólido y letras blancas)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.read<AuthCubit>().logout(),
                  icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                  label: const Text(
                    'Cerrar Sesión',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626), // Rojo empresarial sólido
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
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
}
