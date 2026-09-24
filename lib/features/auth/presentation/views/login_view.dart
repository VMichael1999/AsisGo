import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/auth_repository.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../../../../core/widgets/asis_shimmer.dart';
import '../../../../core/widgets/asis_skeletons.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController =
      TextEditingController(text: 'carlos.mendoza@asisgo.com');
  final TextEditingController _passwordController =
      TextEditingController(text: '12345678');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.obsidianCanvas : AppColors.backgroundLight,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.checkOutColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Stack(
            children: [
              SafeArea(
                child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logotipo corporativo de la aplicacion
                    Center(
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF131926) : AppColors.primary,
                          borderRadius: BorderRadius.circular(22),
                          border: isDark ? Border.all(color: const Color(0x33FFFFFF)) : null,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.2),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_city_rounded,
                          size: 40,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'AsisGo',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        'Control de Asistencia & Geozonas Corporativas',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (state is Unauthenticated && state.message != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF3F1414) : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? const Color(0xFFEF4444) : const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.timer_off_rounded, color: AppColors.checkOutColor, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                state.message!,
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF991B1B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),

                    // Campo de correo electronico
                    Text(
                      'Correo Electrónico Corporativo',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.email_outlined, size: 20, color: isDark ? AppColors.textMuted : null),
                        hintText: 'ejemplo@empresa.com',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Campo de contrasena
                    Text(
                      'Contraseña',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.lock_outline_rounded, size: 20, color: isDark ? AppColors.textMuted : null),
                        hintText: '••••••••',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: isDark ? AppColors.textMuted : null,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Boton de envio de credenciales
                    ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              context.read<AuthCubit>().login(
                                    email: _emailController.text,
                                    password: _passwordController.text,
                                  );
                            },
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Iniciar Sesión'),
                    ),
                    const SizedBox(height: 12),

                    // Boton de acceso biometrico
                    OutlinedButton.icon(
                      onPressed: isLoading
                          ? null
                          : () => context.read<AuthCubit>().loginWithBiometrics(),
                      icon: const Icon(Icons.fingerprint_rounded, color: AppColors.accent),
                      label: Text(
                        'Acceder con Huella o Face ID',
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: isDark ? const Color(0x33FFFFFF) : AppColors.borderLight,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Selector de cuentas de prueba rapida
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF131926) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: isDark ? Border.all(color: const Color(0x22FFFFFF)) : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cuentas de demostración rápida:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: AuthRepository.demoUsers.map((user) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ActionChip(
                                  avatar: const Icon(Icons.person, size: 16),
                                  backgroundColor: isDark ? const Color(0xFF1E283D) : Colors.white,
                                  side: BorderSide(color: isDark ? const Color(0x33FFFFFF) : AppColors.borderLight),
                                  label: Text(
                                    user.fullName.split(' ').first,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white : AppColors.textPrimary,
                                    ),
                                  ),
                                  onPressed: () {
                                    _emailController.text = user.email;
                                    context.read<AuthCubit>().login(
                                          email: user.email,
                                          password: 'password123',
                                        );
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isLoading)
            const Positioned.fill(
              child: AsisLoadingOverlay(
                skeleton: AsisLoginSkeleton(),
                message: 'Iniciando sesión en AsisGo...',
              ),
            ),
        ],
      );
        },
      ),
    );
  }
}
