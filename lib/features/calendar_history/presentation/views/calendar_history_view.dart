import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:asisgo/core/constants/app_colors.dart';
import 'package:asisgo/core/utils/date_formatter.dart';
import 'package:asisgo/features/attendance_map/domain/attendance_record.dart';
import 'package:asisgo/features/attendance_map/domain/shift_phase.dart';
import 'package:asisgo/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:asisgo/features/calendar_history/presentation/cubit/calendar_cubit.dart';
import 'package:asisgo/features/calendar_history/presentation/cubit/calendar_state.dart';
import 'package:asisgo/core/widgets/asis_shimmer.dart';
import 'package:asisgo/core/widgets/asis_skeletons.dart';

class CalendarHistoryView extends StatefulWidget {
  const CalendarHistoryView({super.key});

  @override
  State<CalendarHistoryView> createState() => _CalendarHistoryViewState();
}

class _CalendarHistoryViewState extends State<CalendarHistoryView> {
  CalendarFormat _calendarFormat = CalendarFormat.twoWeeks;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthCubit>().state;
      final userId = authState.currentUser?.id ?? 'USR-001';
      context.read<CalendarCubit>().loadCalendarData(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.obsidianCanvas : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Historial de Asistencia'),
        backgroundColor: isDark ? AppColors.obsidianCanvas : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
            onPressed: () {
              final authState = context.read<AuthCubit>().state;
              final userId = authState.currentUser?.id ?? 'USR-001';
              context.read<CalendarCubit>().loadCalendarData(userId);
            },
          ),
        ],
      ),
      body: BlocBuilder<CalendarCubit, CalendarState>(
        builder: (context, state) {
          if (state is CalendarLoading || state is CalendarInitial) {
            return const AsisLoadingOverlay(
              skeleton: AsisCalendarSkeleton(),
              message: 'Cargando historial de asistencias...',
            );
          }

          if (state is CalendarError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
                ),
              ),
            );
          }

          final calendarData = state as CalendarLoaded;

          return RefreshIndicator(
            color: AppColors.accent,
            onRefresh: () async {
              final authState = context.read<AuthCubit>().state;
              final userId = authState.currentUser?.id ?? 'USR-001';
              await context.read<CalendarCubit>().loadCalendarData(userId);
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                // Tarjetas de resumen de metricas clave (horas trabajadas, dias, puntualidad)
                _buildMetricsHeader(calendarData, isDark),
                const SizedBox(height: 16),

                // Tarjeta interactiva del calendario mensual
                Card(
                  clipBehavior: Clip.antiAlias,
                  color: isDark ? const Color(0xFF131926) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark ? const Color(0x33FFFFFF) : AppColors.borderLight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2025, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: calendarData.focusedDay,
                      calendarFormat: _calendarFormat,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      selectedDayPredicate: (day) {
                        final a = calendarData.selectedDay.toLocal();
                        final b = day.toLocal();
                        return a.year == b.year && a.month == b.month && a.day == b.day;
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        final authState = context.read<AuthCubit>().state;
                        final userId = authState.currentUser?.id ?? 'USR-001';
                        context.read<CalendarCubit>().selectDay(selectedDay, focusedDay, userId);
                      },
                      onFormatChanged: (format) {
                        setState(() => _calendarFormat = format);
                      },
                      onPageChanged: (focusedDay) {
                        context.read<CalendarCubit>().updateFocusedDay(focusedDay);
                      },
                      headerStyle: HeaderStyle(
                        formatButtonVisible: true,
                        titleCentered: true,
                        formatButtonShowsNext: false,
                        titleTextStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                        formatButtonDecoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E283D) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0x22FFFFFF) : Colors.transparent,
                          ),
                        ),
                        formatButtonTextStyle: TextStyle(
                          color: isDark ? AppColors.accent : AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        leftChevronIcon: Icon(
                          Icons.chevron_left_rounded,
                          color: isDark ? Colors.white70 : AppColors.textPrimary,
                        ),
                        rightChevronIcon: Icon(
                          Icons.chevron_right_rounded,
                          color: isDark ? Colors.white70 : AppColors.textPrimary,
                        ),
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                          color: isDark ? Colors.white70 : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        weekendStyle: TextStyle(
                          color: isDark ? Colors.white38 : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      calendarStyle: CalendarStyle(
                        defaultTextStyle: TextStyle(
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                        weekendTextStyle: TextStyle(
                          color: isDark ? Colors.white60 : AppColors.textSecondary,
                        ),
                        outsideTextStyle: TextStyle(
                          color: isDark ? Colors.white24 : AppColors.textMuted,
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                        selectedTextStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        todayDecoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.accent, width: 1),
                        ),
                        todayTextStyle: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      eventLoader: (day) {
                        final target = day.toLocal();
                        return calendarData.allRecords.where((r) {
                          final rLocal = r.timestamp.toLocal();
                          return rLocal.year == target.year &&
                              rLocal.month == target.month &&
                              rLocal.day == target.day;
                        }).toList();
                      },
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, date, events) {
                          if (events.isEmpty) return null;
                          final records = events.cast<AttendanceRecord>();
                          final hasCheckIn = records.any((r) => r.type == AttendanceType.checkIn);
                          final hasCheckOut = records.any((r) => r.type == AttendanceType.checkOut);

                          return Positioned(
                            bottom: 2,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (hasCheckIn)
                                  Container(
                                    width: 5,
                                    height: 5,
                                    margin: const EdgeInsets.symmetric(horizontal: 1),
                                    decoration: const BoxDecoration(
                                      color: AppColors.checkInColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                if (hasCheckOut)
                                  Container(
                                    width: 5,
                                    height: 5,
                                    margin: const EdgeInsets.symmetric(horizontal: 1),
                                    decoration: const BoxDecoration(
                                      color: AppColors.checkOutColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Encabezado del registro diario
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Detalle: ${DateFormatter.formatFullDate(calendarData.selectedDay)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${calendarData.selectedDayRecords.length} marcaciones',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Lista de marcaciones registradas para el dia seleccionado
                if (calendarData.selectedDayRecords.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131926) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0x33FFFFFF) : AppColors.borderLight,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.event_busy_rounded,
                            size: 44,
                            color: isDark ? Colors.white38 : AppColors.textMuted,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No se registraron marcaciones en esta fecha.',
                            style: TextStyle(
                              color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...calendarData.selectedDayRecords.map((record) {
                    return _buildRecordTimelineTile(record, isDark);
                  }),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricsHeader(CalendarLoaded data, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'Días Asistidos',
            value: '${data.totalDaysWorkedThisMonth}',
            icon: Icons.calendar_today_rounded,
            color: AppColors.accent,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            title: 'Puntualidad',
            value: '${data.punctualityRate.toStringAsFixed(0)}%',
            icon: Icons.access_time_filled_rounded,
            color: AppColors.indigoAccent,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            title: 'Tiempo Total',
            value: DateFormatter.formatDuration(data.totalWorkedDuration),
            icon: Icons.timelapse_rounded,
            color: AppColors.lunchColor,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131926) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0x33FFFFFF) : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
              ),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordTimelineTile(AttendanceRecord record, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131926) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0x33FFFFFF) : AppColors.borderLight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: record.type.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(record.type.icon, color: record.type.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      record.type.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      DateFormatter.formatTime(record.timestamp),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.accent : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${record.branchName} • ${record.geozoneName ?? "Geozona"}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                  ),
                ),
                if (record.note != null && record.note!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? const Color(0x1FFFFFFF) : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 12,
                          color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            record.note!,
                            style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: isDark ? Colors.white70 : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: record.isInsideGeozone
                            ? AppColors.accent.withValues(alpha: 0.15)
                            : (isDark ? const Color(0xFF3B2505) : const Color(0xFFFEF3C7)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: record.isInsideGeozone
                              ? AppColors.accent.withValues(alpha: 0.4)
                              : Colors.amber.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        record.isInsideGeozone ? 'En geozona' : 'Fuera de rango',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: record.isInsideGeozone
                              ? AppColors.accent
                              : (isDark ? Colors.amber.shade300 : const Color(0xFFB45309)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (record.selfiePath != null)
                      Row(
                        children: [
                          const Icon(Icons.face_retouching_natural_rounded, size: 13, color: AppColors.accent),
                          const SizedBox(width: 3),
                          Text(
                            'Rostro verificado',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
