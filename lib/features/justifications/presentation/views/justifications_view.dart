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
    return BlocConsumer<JustificationCubit, JustificationState>(
      listener: (context, state) {
        if (state is JustificationLoaded && state.feedbackMessage != null) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    state.isSuccessMessage
                        ? Icons.check_circle_rounded
                        : Icons.error_outline_rounded,
                    color:
                        state.isSuccessMessage
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
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
                  color:
                      state.isSuccessMessage
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
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
          backgroundColor: AppColors.backgroundLight,
          appBar: AppBar(
            title: const Text('Mis justificaciones'),
            backgroundColor: AppColors.primary,
            elevation: 0,
          ),
          body: _buildBody(context, state),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              HapticFeedbackService.shared.selectionClick();
              await NewJustificationSheet.show(context);
            },
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Nueva justificación',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
      },
    );
  }

  Future<void> _reload(BuildContext context) async {
    final authState = context.read<AuthCubit>().state;
    final userId = authState.currentUser?.id ?? 'USR-001';
    await context.read<JustificationCubit>().loadJustifications(userId);
  }

  Widget _buildBody(BuildContext context, JustificationState state) {
    if (state is JustificationLoading || state is JustificationInitial) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state is JustificationError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.textSecondary,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _reload(context),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final loaded = state as JustificationLoaded;
    final items = loaded.filteredJustifications;

    return Column(
      children: [
        // Filtro por estado (los contadores van en cada opcion)
        _StatusFilterBar(loaded: loaded),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => _reload(context),
            child:
                items.isEmpty
                    ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [_buildEmptyState(loaded.filterStatus)],
                    )
                    : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      // Espacio inferior para que el boton flotante no tape la ultima tarjeta
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 104),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder:
                          (context, index) =>
                              JustificationCard(item: items[index]),
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(JustificationStatus? filter) {
    final (title, message) = switch (filter) {
      null => (
        'Aún no tienes justificaciones',
        'Cuando registres una tardanza, permiso o descanso médico aparecerá aquí.',
      ),
      JustificationStatus.pending => (
        'Nada pendiente',
        'No tienes justificaciones esperando revisión de RR. HH.',
      ),
      JustificationStatus.approved => (
        'Sin aprobadas',
        'Todavía no se ha aprobado ninguna de tus justificaciones.',
      ),
      JustificationStatus.rejected => (
        'Sin rechazadas',
        'Ninguna de tus justificaciones ha sido rechazada.',
      ),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 64, 32, 32),
      child: Column(
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra de filtros por estado: una sola fila desplazable, opciones neutras
/// y la seleccionada en el color de marca.
class _StatusFilterBar extends StatelessWidget {
  final JustificationLoaded loaded;

  const _StatusFilterBar({required this.loaded});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<JustificationCubit>();
    final options = <(String, int, JustificationStatus?)>[
      ('Todas', loaded.totalCount, null),
      ('Pendientes', loaded.pendingCount, JustificationStatus.pending),
      ('Aprobadas', loaded.approvedCount, JustificationStatus.approved),
      ('Rechazadas', loaded.rejectedCount, JustificationStatus.rejected),
    ];

    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (label, count, status) = options[index];
          final selected = loaded.filterStatus == status;
          return Semantics(
            selected: selected,
            button: true,
            child: Material(
              color: selected ? AppColors.primary : Colors.white,
              shape: StadiumBorder(
                side: BorderSide(
                  color: selected ? AppColors.primary : AppColors.borderLight,
                ),
              ),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () {
                  HapticFeedbackService.shared.selectionClick();
                  cubit.setFilter(status);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color:
                              selected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color:
                              selected
                                  ? Colors.white70
                                  : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
