import '../core/theme/asis_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/services/haptic_feedback_service.dart';
import '../core/widgets/asis_session_expired_dialog.dart';
import '../features/attendance_map/presentation/views/branches_view.dart';
import '../features/attendance_map/presentation/views/map_home_view.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/auth/presentation/cubit/auth_state.dart';
import '../features/calendar_history/presentation/cubit/calendar_cubit.dart';
import '../features/calendar_history/presentation/views/calendar_history_view.dart';
import '../features/profile/views/profile_view.dart';
import '../features/attendance_map/presentation/cubit/location_cubit.dart';
import '../features/attendance_map/presentation/cubit/location_state.dart';
import '../core/widgets/asis_shimmer.dart';
import '../core/widgets/asis_skeletons.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  bool _isSessionDialogShowing = false;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const MapHomeView(),
      const CalendarHistoryView(),
      BranchesView(
        onBranchSelected: (branch) {
          setState(() => _currentIndex = 0);
        },
      ),
      const ProfileView(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthSessionExpired && !_isSessionDialogShowing) {
          _isSessionDialogShowing = true;
          // Mantener al usuario en la vista de mapa durante el dialogo
          if (_currentIndex != 0) {
            setState(() => _currentIndex = 0);
          }
          AsisSessionExpiredDialog.show(
            context: context,
            message: state.message,
            onDismissAndLogin: () {
              _isSessionDialogShowing = false;
              context.read<AuthCubit>().confirmLogoutAfterExpiration();
            },
          );
        }
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: BlocBuilder<LocationCubit, LocationState>(
          builder: (context, locationState) {
            final isMapLoading =
                (locationState is LocationLoading ||
                    locationState is LocationInitial) &&
                _currentIndex == 0;

            if (isMapLoading) {
              return const IgnorePointer(
                ignoring: true,
                child: AsisShimmer(child: AsisBottomNavSkeleton()),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: context.palette.surface,
                border: Border(
                  top: BorderSide(color: context.palette.border, width: 0.8),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: NavigationBar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) {
                    HapticFeedbackService.shared.selectionClick();
                    setState(() => _currentIndex = index);
                    if (index == 1) {
                      // Recargar datos del calendario al cambiar de pestana
                      final authState = context.read<AuthCubit>().state;
                      final userId = authState.currentUser?.id ?? 'USR-001';
                      context.read<CalendarCubit>().loadCalendarData(userId);
                    }
                  },
                  elevation: 0,
                  destinations: [
                    NavigationDestination(
                      icon: Icon(
                        Icons.map_outlined,
                        color: context.palette.textSecondary,
                      ),
                      selectedIcon: Icon(
                        Icons.map_rounded,
                        color: context.palette.primary,
                      ),
                      label: 'Asistencia',
                    ),
                    NavigationDestination(
                      icon: Icon(
                        Icons.calendar_month_outlined,
                        color: context.palette.textSecondary,
                      ),
                      selectedIcon: Icon(
                        Icons.calendar_month_rounded,
                        color: context.palette.primary,
                      ),
                      label: 'Calendario',
                    ),
                    NavigationDestination(
                      icon: Icon(
                        Icons.apartment_outlined,
                        color: context.palette.textSecondary,
                      ),
                      selectedIcon: Icon(
                        Icons.apartment_rounded,
                        color: context.palette.primary,
                      ),
                      label: 'Sucursales',
                    ),
                    NavigationDestination(
                      icon: Icon(
                        Icons.person_outline_rounded,
                        color: context.palette.textSecondary,
                      ),
                      selectedIcon: Icon(
                        Icons.person_rounded,
                        color: context.palette.primary,
                      ),
                      label: 'Mi Perfil',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
