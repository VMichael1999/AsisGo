import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/main_navigation_shell.dart';
import 'core/contracts/i_security_service.dart';
import 'core/security/security_service.dart';
import 'core/services/location_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/storage_service.dart';
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

  // Inicializacion de repositorios de datos
  final authRepository = AuthRepository(storageService);
  final branchRepository = BranchRepository(locationService);
  final attendanceRepository = AttendanceRepository(storageService);
  await attendanceRepository.init();

  runApp(
    AsisGoApp(
      authRepository: authRepository,
      branchRepository: branchRepository,
      attendanceRepository: attendanceRepository,
      locationService: locationService,
      securityService: securityService,
    ),
  );
}

class AsisGoApp extends StatelessWidget {
  final AuthRepository authRepository;
  final BranchRepository branchRepository;
  final AttendanceRepository attendanceRepository;
  final LocationService locationService;
  final ISecurityService securityService;

  const AsisGoApp({
    super.key,
    required this.authRepository,
    required this.branchRepository,
    required this.attendanceRepository,
    required this.locationService,
    required this.securityService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: branchRepository),
        RepositoryProvider.value(value: attendanceRepository),
        RepositoryProvider.value(value: locationService),
        RepositoryProvider<ISecurityService>.value(value: securityService),
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
            ),
          ),
          BlocProvider<CalendarCubit>(
            create: (ctx) => CalendarCubit(
              attendanceRepository: attendanceRepository,
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
                  body: Center(
                    child: CircularProgressIndicator(),
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
