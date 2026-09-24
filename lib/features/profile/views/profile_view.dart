import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';
import '../../auth/presentation/cubit/auth_state.dart';
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
}
