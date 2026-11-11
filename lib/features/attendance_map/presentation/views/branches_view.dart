import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/haptic_feedback_service.dart';
import '../../../../core/widgets/asis_shimmer.dart';
import '../../../../core/widgets/asis_skeletons.dart';
import '../../domain/branch_model.dart';
import '../cubit/location_cubit.dart';
import '../cubit/location_state.dart';

/// Lista de eleccion unica de empresa. Tocar una fila selecciona la empresa;
/// la flecha de cada fila despliega sus sucursales para elegir una sede concreta.
class BranchesView extends StatefulWidget {
  final Function(Branch branch)? onBranchSelected;

  const BranchesView({super.key, this.onBranchSelected});

  @override
  State<BranchesView> createState() => _BranchesViewState();
}

class _BranchesViewState extends State<BranchesView> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _expandedCompanyId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _select(Company company, {Branch? branch}) {
    HapticFeedbackService.shared.selectionClick();
    context.read<LocationCubit>().selectCompany(company, initialBranch: branch);
    widget.onBranchSelected?.call(branch ?? company.branches.first);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Seleccionar empresa'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: false,
      ),
      body: BlocBuilder<LocationCubit, LocationState>(
        builder: (context, state) {
          if (state is! LocationLoaded) {
            return const AsisLoadingOverlay(
              skeleton: AsisBranchesSkeleton(),
              message: 'Cargando empresas y sucursales...',
            );
          }

          final query = _query.trim().toLowerCase();
          final companies =
              state.allCompanies
                  .where(
                    (c) =>
                        query.isEmpty ||
                        c.name.toLowerCase().contains(query) ||
                        c.shortName.toLowerCase().contains(query),
                  )
                  .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Buscar empresa',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon:
                        _query.isEmpty
                            ? null
                            : IconButton(
                              icon: const Icon(Icons.close_rounded),
                              tooltip: 'Borrar búsqueda',
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            ),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.borderLight,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child:
                    companies.isEmpty
                        ? const Center(
                          child: Text(
                            'No hay empresas que coincidan con la búsqueda.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                        : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          itemCount: companies.length,
                          separatorBuilder:
                              (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final company = companies[index];
                            return _CompanyTile(
                              company: company,
                              isActive: company.id == state.selectedCompany.id,
                              isExpanded: company.id == _expandedCompanyId,
                              activeBranchId: state.activeMapBranch.id,
                              onSelect: () => _select(company),
                              onSelectBranch:
                                  (branch) => _select(company, branch: branch),
                              onToggleExpand:
                                  () => setState(() {
                                    _expandedCompanyId =
                                        company.id == _expandedCompanyId
                                            ? null
                                            : company.id;
                                  }),
                            );
                          },
                        ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CompanyTile extends StatelessWidget {
  final Company company;
  final bool isActive;
  final bool isExpanded;
  final String activeBranchId;
  final VoidCallback onSelect;
  final ValueChanged<Branch> onSelectBranch;
  final VoidCallback onToggleExpand;

  const _CompanyTile({
    required this.company,
    required this.isActive,
    required this.isExpanded,
    required this.activeBranchId,
    required this.onSelect,
    required this.onSelectBranch,
    required this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    final branchCount = company.branches.length;
    final monogram =
        company.shortName.length > 4
            ? company.shortName.substring(0, 3)
            : company.shortName;

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isActive ? AppColors.primary : AppColors.borderLight,
          width: isActive ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Fila principal: tocarla selecciona la empresa
          Semantics(
            selected: isActive,
            button: true,
            child: InkWell(
              onTap: onSelect,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        monogram,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            company.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$branchCount ${branchCount == 1 ? 'sucursal' : 'sucursales'}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isActive)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                          size: 24,
                          semanticLabel: 'Empresa seleccionada',
                        ),
                      ),
                    // Boton explicito para desplegar las sucursales
                    IconButton(
                      onPressed: onToggleExpand,
                      tooltip:
                          isExpanded ? 'Ocultar sucursales' : 'Ver sucursales',
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      icon: AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textSecondary,
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Sucursales de la empresa
          if (isExpanded) ...[
            const Divider(height: 1, color: AppColors.borderLight),
            for (final branch in company.branches)
              _BranchRow(
                branch: branch,
                isActive: isActive && branch.id == activeBranchId,
                onTap: () => onSelectBranch(branch),
              ),
          ],
        ],
      ),
    );
  }
}

class _BranchRow extends StatelessWidget {
  final Branch branch;
  final bool isActive;
  final VoidCallback onTap;

  const _BranchRow({
    required this.branch,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: isActive,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          color: isActive ? AppColors.accentLight : null,
          padding: const EdgeInsets.fromLTRB(26, 8, 16, 8),
          child: Row(
            children: [
              Icon(
                Icons.location_city_rounded,
                size: 20,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branch.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            isActive
                                ? AppColors.primary
                                : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      branch.address,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                const Icon(
                  Icons.check_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
