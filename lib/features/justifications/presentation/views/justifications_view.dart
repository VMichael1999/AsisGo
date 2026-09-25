import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/haptic_feedback_service.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/incident_justification.dart';
import '../cubit/justification_cubit.dart';
import '../cubit/justification_state.dart';
import '../widgets/justification_card.dart';
import '../widgets/new_justification_sheet.dart';

class JustificationsView extends StatefulWidget {
  const JustificationsView({super.key});

  static Route route() {
    return MaterialPageRoute(builder: (_) => const JustificationsView());
  }

  @override
  State<JustificationsView> createState() => _JustificationsViewState();
}

class _JustificationsViewState extends State<JustificationsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthCubit>().state;
      final userId = authState.currentUser?.id ?? 'USR-001';
      context.read<JustificationCubit>().loadJustifications(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<JustificationCubit, JustificationState>(
      listener: (context, state) {
        if (state is JustificationLoaded && state.feedbackMessage != null) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    state.isSuccessMessage ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                    color: state.isSuccessMessage ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.feedbackMessage!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF0F172A),
              behavior: SnackBarBehavior.floating,
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: state.isSuccessMessage ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  width: 1.2,
                ),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
          context.read<JustificationCubit>().clearFeedback();
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: isDark ? AppColors.obsidianCanvas : AppColors.backgroundLight,
          appBar: AppBar(
            title: const Text('Mis Justificaciones'),
            backgroundColor: isDark ? AppColors.obsidianCanvas : Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Actualizar',
                onPressed: () {
                  final authState = context.read<AuthCubit>().state;
                  final userId = authState.currentUser?.id ?? 'USR-001';
                  context.read<JustificationCubit>().loadJustifications(userId);
                },
              ),
            ],
          ),
          body: _buildBody(context, state, isDark),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              HapticFeedbackService.shared.selectionClick();
              await NewJustificationSheet.show(context);
            },
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Nueva Justificación', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, JustificationState state, bool isDark) {
    if (state is JustificationLoading || state is JustificationInitial) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (state is JustificationError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 48),
              const SizedBox(height: 12),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final authState = context.read<AuthCubit>().state;
                  final userId = authState.currentUser?.id ?? 'USR-001';
                  context.read<JustificationCubit>().loadJustifications(userId);
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final loaded = state as JustificationLoaded;

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () async {
        final authState = context.read<AuthCubit>().state;
        final userId = authState.currentUser?.id ?? 'USR-001';
        await context.read<JustificationCubit>().loadJustifications(userId);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        children: [
          // 1. Tarjetas de métricas
          _buildMetricsRow(loaded, isDark),
          const SizedBox(height: 16),

          // 2. Filtro por estado
          _buildFilterChips(context, loaded, isDark),
          const SizedBox(height: 14),

          // 3. Lista de Justificaciones
          if (loaded.filteredJustifications.isEmpty)
            _buildEmptyState(isDark)
          else
            ...loaded.filteredJustifications.map((item) {
              return JustificationCard(item: item);
            }),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(JustificationLoaded loaded, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            label: 'Total',
            value: '${loaded.totalCount}',
            color: const Color(0xFF3B82F6),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            label: 'Pendientes',
            value: '${loaded.pendingCount}',
            color: const Color(0xFFF59E0B),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            label: 'Aprobadas',
            value: '${loaded.approvedCount}',
            color: const Color(0xFF10B981),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            label: 'Rechazadas',
            value: '${loaded.rejectedCount}',
            color: const Color(0xFFEF4444),
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131926) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0x22FFFFFF) : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textMuted : AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, JustificationLoaded loaded, bool isDark) {
    final cubit = context.read<JustificationCubit>();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChip(
            label: 'Todas (${loaded.totalCount})',
            isSelected: loaded.filterStatus == null,
            color: AppColors.accent,
            onTap: () => cubit.setFilter(null),
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'Pendientes (${loaded.pendingCount})',
            isSelected: loaded.filterStatus == JustificationStatus.pending,
            color: const Color(0xFFF59E0B),
            onTap: () => cubit.setFilter(JustificationStatus.pending),
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'Aprobadas (${loaded.approvedCount})',
            isSelected: loaded.filterStatus == JustificationStatus.approved,
            color: const Color(0xFF10B981),
            onTap: () => cubit.setFilter(JustificationStatus.approved),
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'Rechazadas (${loaded.rejectedCount})',
            isSelected: loaded.filterStatus == JustificationStatus.rejected,
            color: const Color(0xFFEF4444),
            onTap: () => cubit.setFilter(JustificationStatus.rejected),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : color,
        ),
      ),
      backgroundColor: isSelected ? color.withValues(alpha: 0.85) : color.withValues(alpha: 0.1),
      side: BorderSide(
        color: isSelected ? color : color.withValues(alpha: 0.3),
        width: 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onPressed: () {
        HapticFeedbackService.shared.selectionClick();
        onTap();
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2638) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.done_all_rounded,
              size: 40,
              color: isDark ? AppColors.textMuted : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin Justificaciones Registradas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No hay incidencias que coincidan con el filtro seleccionado.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textMuted : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
