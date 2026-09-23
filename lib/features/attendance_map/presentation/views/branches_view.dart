import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/branch_model.dart';
import '../cubit/location_cubit.dart';
import '../cubit/location_state.dart';

class BranchesView extends StatefulWidget {
  final Function(Branch branch, Geozone geozone)? onGeozoneSelected;
  final Function(Branch branch)? onBranchSelected;

  const BranchesView({
    super.key,
    this.onGeozoneSelected,
    this.onBranchSelected,
  });

  @override
  State<BranchesView> createState() => _BranchesViewState();
}

class _BranchesViewState extends State<BranchesView> {
  String? _expandedCompanyId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.obsidianCanvas : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Empresas & Sucursales',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: isDark ? AppColors.obsidianCanvas : Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: BlocBuilder<LocationCubit, LocationState>(
        builder: (context, state) {
          if (state is! LocationLoaded) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          }

          final companies = state.allCompanies;
          final activeCompany = state.selectedCompany;
          final activeBranchId = state.activeMapBranch.id;

          // Expandir unicamente si el usuario interactua de forma directa
          final currentExpandedId = _expandedCompanyId;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              // Banner de encabezado informativo
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131926) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0x22FFFFFF) : AppColors.borderLight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.corporate_fare_rounded, color: AppColors.accent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gestión Corporativa de Sedes',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Selecciona una empresa para explorar y aislar en el mapa únicamente sus sucursales autorizadas.',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Lista de corporaciones registradas
              ...companies.map((company) {
                final isCompanyActive = company.id == activeCompany.id;
                final isExpanded = company.id == currentExpandedId;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF131926) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isCompanyActive
                          ? AppColors.accent
                          : (isDark ? const Color(0x22FFFFFF) : AppColors.borderLight),
                      width: isCompanyActive ? 2.0 : 1.0,
                    ),
                    boxShadow: [
                      if (isCompanyActive)
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Encabezado de la tarjeta corporativa (expandible)
                      InkWell(
                        borderRadius: BorderRadius.vertical(
                          top: const Radius.circular(20),
                          bottom: isExpanded ? Radius.zero : const Radius.circular(20),
                        ),
                        onTap: () {
                          setState(() {
                            _expandedCompanyId = company.id;
                          });
                          // Seleccionar empresa activa en cubit
                          context.read<LocationCubit>().selectCompany(company);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Logotipo con iniciales corporativas
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: company.primaryColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: company.primaryColor.withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    company.shortName.length > 4
                                        ? company.shortName.substring(0, 3)
                                        : company.shortName,
                                    style: TextStyle(
                                      color: company.primaryColor,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Informacion corporativa
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            company.name,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? Colors.white : AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Text(
                                          'RUC: ${company.ruc}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontFamily: 'monospace',
                                            color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '•  ${company.branches.length} sucursales',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isCompanyActive ? AppColors.accent : (isDark ? Colors.white70 : AppColors.textPrimary),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        if (isCompanyActive)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppColors.accent.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 12),
                                                SizedBox(width: 4),
                                                Text(
                                                  'EMPRESA ACTIVA EN MAPA',
                                                  style: TextStyle(
                                                    color: AppColors.accent,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 9,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF1E283D) : const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            company.industry,
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white70 : AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Flecha de expansion y colapso
                              IconButton(
                                icon: Icon(
                                  isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _expandedCompanyId = isExpanded ? '' : company.id;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Seccion de sucursales desplegadas
                      if (isExpanded) ...[
                        Divider(
                          height: 1,
                          color: isDark ? const Color(0x22FFFFFF) : AppColors.borderLight,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Sucursales de ${company.shortName}:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    'Toca una sede para verla en el mapa',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Lista de sucursales de la empresa
                              ...company.branches.map((branch) {
                                final isBranchSelected = isCompanyActive && branch.id == activeBranchId;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: isBranchSelected
                                        ? AppColors.accent.withValues(alpha: 0.12)
                                        : (isDark ? const Color(0xFF0D131F) : const Color(0xFFF8FAFC)),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isBranchSelected
                                          ? AppColors.accent.withValues(alpha: 0.6)
                                          : (isDark ? const Color(0x22FFFFFF) : AppColors.borderLight),
                                      width: isBranchSelected ? 1.5 : 0.8,
                                    ),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () {
                                      context.read<LocationCubit>().selectCompany(company, initialBranch: branch);
                                      widget.onBranchSelected?.call(branch);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.location_city_rounded,
                                            size: 20,
                                            color: isBranchSelected ? AppColors.accent : (isDark ? Colors.white60 : AppColors.textSecondary),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        branch.name,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w700,
                                                          color: isBranchSelected ? AppColors.accent : (isDark ? Colors.white : AppColors.textPrimary),
                                                        ),
                                                      ),
                                                    ),
                                                    if (isBranchSelected)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: AppColors.accent.withValues(alpha: 0.2),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: const Text(
                                                          'ACTIVA',
                                                          style: TextStyle(
                                                            color: AppColors.accent,
                                                            fontSize: 9,
                                                            fontWeight: FontWeight.w800,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  branch.address,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(Icons.radar_rounded, size: 11, color: AppColors.accent.withValues(alpha: 0.8)),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        '${branch.geozones.length} centros autorizados (${branch.geozones.map((g) => g.name).join(", ")})',
                                                        style: TextStyle(
                                                          fontSize: 9,
                                                          color: isDark ? Colors.white54 : AppColors.textSecondary,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 13,
                                            color: isBranchSelected ? AppColors.accent : (isDark ? Colors.white38 : AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),

                              const SizedBox(height: 4),
                              // Boton para ver la empresa directamente en el mapa
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: isCompanyActive ? AppColors.accent : Colors.white,
                                    side: BorderSide(
                                      color: isCompanyActive ? AppColors.accent : (isDark ? Colors.white30 : AppColors.borderLight),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.map_rounded, size: 16),
                                  label: Text(
                                    isCompanyActive ? 'Ver ${company.shortName} en el Mapa' : 'Seleccionar ${company.shortName} y Ver en Mapa',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                  onPressed: () {
                                    context.read<LocationCubit>().selectCompany(company);
                                    widget.onBranchSelected?.call(company.branches.first);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
