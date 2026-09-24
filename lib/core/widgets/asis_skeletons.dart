import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'asis_shimmer.dart';

/// Esqueleto estructurado para la pantalla de inicio de sesion (Login).
class AsisLoginSkeleton extends StatelessWidget {
  const AsisLoginSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logotipo corporativo
              const Center(
                child: AsisSkeletonBox(
                  width: 76,
                  height: 76,
                  borderRadius: 22,
                ),
              ),
              const SizedBox(height: 20),

              // Titulo de la aplicacion
              const Center(
                child: AsisSkeletonLine(
                  width: 130,
                  height: 26,
                  borderRadius: 8,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitulo descriptivo
              const Center(
                child: AsisSkeletonLine(
                  width: 250,
                  height: 12,
                  borderRadius: 6,
                ),
              ),
              const SizedBox(height: 36),

              // Campo de correo corporativo
              const AsisSkeletonLine(width: 190, height: 13),
              const SizedBox(height: 8),
              const AsisSkeletonBox(height: 52, borderRadius: 14),
              const SizedBox(height: 18),

              // Campo de contrasena
              const AsisSkeletonLine(width: 90, height: 13),
              const SizedBox(height: 8),
              const AsisSkeletonBox(height: 52, borderRadius: 14),
              const SizedBox(height: 26),

              // Boton principal de inicio de sesion
              const AsisSkeletonBox(height: 52, borderRadius: 14),
              const SizedBox(height: 14),

              // Boton secundario de biometria
              const AsisSkeletonBox(height: 48, borderRadius: 14),
              const SizedBox(height: 32),

              // Contenedor de cuentas de prueba
              const AsisSkeletonBox(height: 84, borderRadius: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Esqueleto estructurado para la lista de empresas y sucursales.
class AsisBranchesSkeleton extends StatelessWidget {
  const AsisBranchesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // Banner de encabezado informativo
        const AsisSkeletonBox(height: 64, borderRadius: 14),
        const SizedBox(height: 16),

        // Tarjetas simuladas de empresas y sedes
        for (int i = 0; i < 4; i++) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF131926)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0x334A628A)
                    : const Color(0x1F000000),
              ),
            ),
            child: const Row(
              children: [
                AsisSkeletonBox(width: 44, height: 44, borderRadius: 12),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AsisSkeletonLine(width: 140, height: 15),
                      SizedBox(height: 8),
                      AsisSkeletonLine(width: 200, height: 12),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                AsisSkeletonBox(width: 28, height: 28, borderRadius: 8),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Esqueleto estructurado para la pantalla de calendario e historial.
class AsisCalendarSkeleton extends StatelessWidget {
  const AsisCalendarSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Cabecera del mes
        const AsisSkeletonBox(height: 48, borderRadius: 12),
        const SizedBox(height: 14),

        // Cabecera de dias de la semana
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            AsisSkeletonBox(width: 32, height: 14, borderRadius: 4),
            AsisSkeletonBox(width: 32, height: 14, borderRadius: 4),
            AsisSkeletonBox(width: 32, height: 14, borderRadius: 4),
            AsisSkeletonBox(width: 32, height: 14, borderRadius: 4),
            AsisSkeletonBox(width: 32, height: 14, borderRadius: 4),
            AsisSkeletonBox(width: 32, height: 14, borderRadius: 4),
            AsisSkeletonBox(width: 32, height: 14, borderRadius: 4),
          ],
        ),
        const SizedBox(height: 16),

        // Rejilla de dias del calendario
        for (int row = 0; row < 4; row++) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (int col = 0; col < 7; col++)
                  const AsisSkeletonBox(width: 36, height: 36, borderRadius: 18),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),

        // Tarjeta de resumen de asistencia
        const AsisSkeletonBox(height: 80, borderRadius: 16),
        const SizedBox(height: 14),

        // Registros diarios simulados
        const AsisSkeletonBox(height: 72, borderRadius: 14),
        const SizedBox(height: 10),
        const AsisSkeletonBox(height: 72, borderRadius: 14),
      ],
    );
  }
}

/// Esqueleto estructurado para la pantalla de perfil del usuario.
class AsisProfileSkeleton extends StatelessWidget {
  const AsisProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Tarjeta principal del usuario
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF131926)
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0x334A628A)
                  : const Color(0x1F000000),
            ),
          ),
          child: const Column(
            children: [
              AsisSkeletonCircle(size: 72),
              SizedBox(height: 14),
              AsisSkeletonLine(width: 160, height: 18),
              SizedBox(height: 8),
              AsisSkeletonLine(width: 220, height: 12),
              SizedBox(height: 12),
              AsisSkeletonBox(width: 130, height: 26, borderRadius: 8),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tarjeta de detalles del contrato y cargo
        const AsisSkeletonBox(height: 120, borderRadius: 16),
        const SizedBox(height: 14),

        // Tarjeta de seguridad y sesion
        const AsisSkeletonBox(height: 100, borderRadius: 16),
        const SizedBox(height: 24),

        // Boton de cierre de sesion
        const AsisSkeletonBox(height: 50, borderRadius: 14),
      ],
    );
  }
}

/// Esqueleto estructurado fiel a la pantalla del Mapa y Geozonas.
class AsisMapSkeleton extends StatelessWidget {
  const AsisMapSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // 1. Tarjeta superior de estado y geozona
        Positioned(
          top: 14,
          left: 16,
          right: 16,
          child: SafeArea(
            child: Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141D2B) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? const Color(0x444A628A) : AppColors.borderLight,
                ),
              ),
              child: const Row(
                children: [
                  AsisSkeletonCircle(size: 16),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AsisSkeletonLine(width: 140, height: 12),
                        SizedBox(height: 6),
                        AsisSkeletonLine(width: 220, height: 10),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  AsisSkeletonBox(width: 44, height: 26, borderRadius: 12),
                ],
              ),
            ),
          ),
        ),

        // 2. Anillos concentricos simulando el radar y geozona en el mapa
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 270,
                height: 270,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.22),
                    width: 1.5,
                  ),
                ),
              ),
              Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
              ),
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.5),
                    width: 2.0,
                  ),
                  color: AppColors.accent.withValues(alpha: 0.08),
                ),
              ),
              const AsisSkeletonCircle(size: 20),
            ],
          ),
        ),

        // 3. Botones flotantes de herramientas en el lado derecho
        Positioned(
          right: 16,
          top: 180,
          child: Column(
            children: const [
              AsisSkeletonCircle(size: 42, margin: EdgeInsets.only(bottom: 12)),
              AsisSkeletonCircle(size: 42, margin: EdgeInsets.only(bottom: 12)),
              AsisSkeletonCircle(size: 42, margin: EdgeInsets.only(bottom: 12)),
              AsisSkeletonCircle(size: 42),
            ],
          ),
        ),

        // 4. Panel inferior (Dock) con controles de asistencia
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: SafeArea(
            child: Container(
              height: 200,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141D2B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? const Color(0x444A628A) : AppColors.borderLight,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AsisSkeletonBox(width: 130, height: 26, borderRadius: 12),
                      AsisSkeletonBox(width: 80, height: 16, borderRadius: 6),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AsisSkeletonLine(width: 150, height: 12),
                      AsisSkeletonLine(width: 70, height: 12),
                    ],
                  ),
                  Spacer(),
                  AsisSkeletonBox(height: 52, borderRadius: 14),
                  SizedBox(height: 10),
                  Center(
                    child: AsisSkeletonLine(width: 180, height: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Esqueleto estructurado para la barra de navegacion inferior.
class AsisBottomNavSkeleton extends StatelessWidget {
  const AsisBottomNavSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D131F),
        border: Border(
          top: BorderSide(color: Color(0x22FFFFFF), width: 0.8),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              4,
              (index) => const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AsisSkeletonBox(width: 48, height: 26, borderRadius: 13),
                  SizedBox(height: 6),
                  AsisSkeletonLine(width: 44, height: 10, borderRadius: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
