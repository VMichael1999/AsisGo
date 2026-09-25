import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/main_navigation_shell.dart';
import 'core/contracts/i_security_service.dart';
import 'core/security/security_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/haptic_feedback_service.dart';
import 'core/services/location_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/offline_sync_service.dart';
import 'core/services/storage_service.dart';
import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/attendance_map/data/attendance_repository.dart';
import 'features/attendance_map/data/branch_repository.dart';
import 'features/attendance_map/presentation/cubit/attendance_cubit.dart';
import 'features/attendance_map/presentation/cubit/location_cubit.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/cubit/auth_state.dart';
import 'features/auth/presentation/views/login_view.dart';
import 'features/calendar_history/presentation/cubit/calendar_cubit.dart';
import 'features/justifications/data/justification_repository.dart';
import 'features/justifications/presentation/cubit/justification_cubit.dart';
import 'core/widgets/asis_shimmer.dart';
import 'core/widgets/asis_skeletons.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);

  // Inicializacion de servicios del sistema
  final storageService = await StorageService.init();
  final locationService = LocationService();
  final securityService = SecurityService(storageService);
  await securityService.init();

  final notificationService = NotificationService();
  await notificationService.initialize();

  final connectivityService = ConnectivityService();
  await connectivityService.init();

  // Inicializacion de repositorios de datos
  final authRepository = AuthRepository(storageService);
  if (storageService.getUserSession() == null) {
    await authRepository.loginWithCredentials(
      email: 'carlos.mendoza@asisgo.com',
      password: 'demo',
    );
  }
  final branchRepository = BranchRepository(locationService);
  final attendanceRepository = AttendanceRepository(storageService);
  await attendanceRepository.init();
  final justificationRepository = JustificationRepository(storageService);
  await justificationRepository.init();

  final offlineSyncService = OfflineSyncService(
    attendanceRepository: attendanceRepository,
    connectivityService: connectivityService,
  );
  offlineSyncService.init();

  final hapticFeedbackService = HapticFeedbackService(storageService);

  runApp(
    AsisGoApp(
      authRepository: authRepository,
      branchRepository: branchRepository,
      attendanceRepository: attendanceRepository,
      justificationRepository: justificationRepository,
      locationService: locationService,
      securityService: securityService,
      connectivityService: connectivityService,
      offlineSyncService: offlineSyncService,
      hapticFeedbackService: hapticFeedbackService,
    ),
  );
}

class AsisGoApp extends StatelessWidget {
  final AuthRepository authRepository;
  final BranchRepository branchRepository;
  final AttendanceRepository attendanceRepository;
  final JustificationRepository justificationRepository;
  final LocationService locationService;
  final ISecurityService securityService;
  final ConnectivityService connectivityService;
  final OfflineSyncService offlineSyncService;
  final HapticFeedbackService hapticFeedbackService;

  const AsisGoApp({
    super.key,
    required this.authRepository,
    required this.branchRepository,
    required this.attendanceRepository,
    required this.justificationRepository,
    required this.locationService,
    required this.securityService,
    required this.connectivityService,
    required this.offlineSyncService,
    required this.hapticFeedbackService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: branchRepository),
        RepositoryProvider.value(value: attendanceRepository),
        RepositoryProvider.value(value: justificationRepository),
        RepositoryProvider.value(value: locationService),
        RepositoryProvider<ISecurityService>.value(value: securityService),
        RepositoryProvider.value(value: connectivityService),
        RepositoryProvider.value(value: offlineSyncService),
        RepositoryProvider.value(value: hapticFeedbackService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>(
            create: (ctx) => AuthCubit(authRepository)..checkAuthStatus(),
          ),
          BlocProvider<LocationCubit>(
            create: (ctx) => LocationCubit(
              locationService: locationService,
              branchRepository: branchRepository,
              securityService: securityService,
            ),
          ),
          BlocProvider<AttendanceCubit>(
            create: (ctx) => AttendanceCubit(
              attendanceRepository: attendanceRepository,
              connectivityService: connectivityService,
              offlineSyncService: offlineSyncService,
              hapticFeedbackService: hapticFeedbackService,
            ),
          ),
          BlocProvider<CalendarCubit>(
            create: (ctx) => CalendarCubit(
              attendanceRepository: attendanceRepository,
            ),
          ),
          BlocProvider<JustificationCubit>(
            create: (ctx) => JustificationCubit(
              repository: justificationRepository,
              hapticService: hapticFeedbackService,
            ),
          ),
        ],
        child: MaterialApp(
          title: 'AsisGo',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              if (state is Authenticated || state is AuthSessionExpired) {
                return const MainNavigationShell();
              }
              if (state is AuthLoading) {
                return const Scaffold(
                  backgroundColor: AppColors.obsidianCanvas,
                  body: AsisLoadingOverlay(
                    skeleton: AsisLoginSkeleton(),
                    message: 'Iniciando sesión en AsisGo...',
                  ),
                );
              }
              return const LoginView();
            },
          ),
        ),
      ),
    );
  }
}
