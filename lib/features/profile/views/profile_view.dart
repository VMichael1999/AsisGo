import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/haptic_feedback_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/widgets/asis_shimmer.dart';
import '../../../../core/widgets/asis_skeletons.dart';
import '../../attendance_map/data/branch_repository.dart';
import '../../attendance_map/presentation/cubit/attendance_cubit.dart';
import '../../attendance_map/presentation/cubit/attendance_state.dart';
import '../../auth/domain/user_model.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';
import '../../auth/presentation/cubit/auth_state.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Mi perfil'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final user = state.currentUser;
          if (user == null) {
            return const AsisLoadingOverlay(
              skeleton: AsisProfileSkeleton(),
              message: 'Cargando tu perfil...',
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _ProfileHeader(user: user),
              const _SectionLabel('Mi horario'),
              _ScheduleCard(user: user),
              const _SectionLabel('Marcaciones'),
              const _SyncCard(),
              const _SectionLabel('Preferencias'),
              _PreferencesCard(
                onLiveTrackingChanged: (enabled) {
                  // Al reactivar, se vuelve a mostrar el turno en curso
                  if (enabled) {
                    context.read<AttendanceCubit>().loadDailyAttendance(
                      user.id,
                    );
                  }
                },
              ),
              const SizedBox(height: 32),
              Center(
                child: TextButton.icon(
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Cerrar sesión'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.checkOutColor,
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text(
                  '${AppConstants.appName} ${AppConstants.appVersion}',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    HapticFeedbackService.shared.selectionClick();
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('¿Cerrar sesión?'),
            content: const Text(
              'Tendrás que volver a ingresar tus credenciales para marcar asistencia.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.checkOutColor,
                ),
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
    );
    if (confirmed == true && context.mounted) {
      context.read<AuthCubit>().logout();
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _CardShell({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final User user;

  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final branch = context.read<BranchRepository>().getBranchById(
      user.assignedBranchId,
    );
    final workplace = [
      if (branch != null && branch.companyName.isNotEmpty) branch.companyName,
      if (branch != null) branch.name,
    ].join(' · ');

    return _CardShell(
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.accentLight,
            child: Text(
              user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.role,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (workplace.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    workplace,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'DNI ${user.documentNumber}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final User user;

  const _ScheduleCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: IntrinsicHeight(
        child: Row(
          children: [
            _ScheduleItem(label: 'Entrada', value: user.shiftStartTime),
            const VerticalDivider(color: AppColors.borderLight, width: 24),
            const _ScheduleItem(
              label: 'Refrigerio',
              value: '${AppConstants.lunchDurationMinutes} min',
            ),
            const VerticalDivider(color: AppColors.borderLight, width: 24),
            _ScheduleItem(label: 'Salida', value: user.shiftEndTime),
          ],
        ),
      ),
    );
  }
}

class _ScheduleItem extends StatelessWidget {
  final String label;
  final String value;

  const _ScheduleItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Estado de sincronizacion en una fila; el boton solo aparece si hay pendientes.
class _SyncCard extends StatelessWidget {
  const _SyncCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceCubit, AttendanceState>(
      builder: (context, state) {
        final loaded = state is AttendanceLoaded ? state : null;
        final pending = loaded?.pendingSyncCount ?? 0;
        final syncing = loaded?.isSyncing ?? false;
        final offline = loaded?.isOffline ?? false;

        final (IconData icon, Color color, String title, String subtitle) =
            syncing
                ? (
                  Icons.sync_rounded,
                  AppColors.primary,
                  'Sincronizando...',
                  'Enviando tus marcaciones al servidor',
                )
                : pending > 0
                ? (
                  Icons.cloud_upload_outlined,
                  const Color(0xFFB45309),
                  pending == 1
                      ? '1 marcación pendiente'
                      : '$pending marcaciones pendientes',
                  offline
                      ? 'Se enviarán al recuperar la conexión'
                      : 'Guardadas en el teléfono, aún sin enviar',
                )
                : (
                  Icons.cloud_done_outlined,
                  const Color(0xFF047857),
                  'Marcaciones al día',
                  offline
                      ? 'Sin conexión. Las nuevas marcas se guardarán en el teléfono'
                      : 'Todo está sincronizado con el servidor',
                );

        return _CardShell(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (pending > 0 && !syncing && !offline) ...[
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    HapticFeedbackService.shared.selectionClick();
                    context.read<AttendanceCubit>().syncPendingNow();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Sincronizar'),
                ),
              ],
              if (syncing)
                const Padding(
                  padding: EdgeInsets.all(10),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Solo preferencias que tienen efecto real y se guardan en el telefono.
class _PreferencesCard extends StatefulWidget {
  final ValueChanged<bool> onLiveTrackingChanged;

  const _PreferencesCard({required this.onLiveTrackingChanged});

  @override
  State<_PreferencesCard> createState() => _PreferencesCardState();
}

class _PreferencesCardState extends State<_PreferencesCard> {
  late final HapticFeedbackService _haptics =
      context.read<HapticFeedbackService>();
  final NotificationService _notifications = NotificationService();

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _PreferenceTile(
            title: 'Turno en vivo',
            subtitle:
                'Muestra tu jornada en la Dynamic Island y notificaciones',
            value: _notifications.isLiveTrackingEnabled,
            onChanged: (v) async {
              await _notifications.setLiveTrackingEnabled(v);
              widget.onLiveTrackingChanged(v);
              setState(() {});
            },
          ),
          const Divider(height: 1, indent: 16, color: AppColors.borderLight),
          _PreferenceTile(
            title: 'Vibración al marcar',
            subtitle: 'Confirma cada marcación con una vibración',
            value: _haptics.isHapticEnabled,
            onChanged: (v) async {
              await _haptics.setHapticEnabled(v);
              setState(() {});
            },
          ),
          const Divider(height: 1, indent: 16, color: AppColors.borderLight),
          _PreferenceTile(
            title: 'Sonido al marcar',
            subtitle: 'Reproduce un sonido de confirmación',
            value: _haptics.isSoundEnabled,
            onChanged: (v) async {
              await _haptics.setSoundEnabled(v);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PreferenceTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      activeTrackColor: AppColors.primary,
      contentPadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
    );
  }
}
