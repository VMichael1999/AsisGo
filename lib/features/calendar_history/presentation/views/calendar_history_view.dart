import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:asisgo/core/constants/app_colors.dart';
import 'package:asisgo/core/utils/date_formatter.dart';
import 'package:asisgo/core/services/haptic_feedback_service.dart';
import 'package:asisgo/core/widgets/asis_shimmer.dart';
import 'package:asisgo/core/widgets/asis_skeletons.dart';
import 'package:asisgo/features/attendance_map/domain/attendance_record.dart';
import 'package:asisgo/features/attendance_map/domain/shift_phase.dart';
import 'package:asisgo/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:asisgo/features/calendar_history/domain/attendance_day_summary.dart';
import 'package:asisgo/features/calendar_history/presentation/cubit/calendar_cubit.dart';
import 'package:asisgo/features/calendar_history/presentation/cubit/calendar_state.dart';
import 'package:asisgo/features/justifications/presentation/views/justifications_view.dart';
import 'package:asisgo/features/justifications/presentation/widgets/new_justification_sheet.dart';

/// Colores y textos de cada estado de jornada (siempre acompanados de texto).
extension DayStatusStyle on DayStatus {
  Color get color => switch (this) {
    DayStatus.complete => const Color(0xFF047857),
    DayStatus.late => const Color(0xFFB45309),
    DayStatus.incomplete => AppColors.checkOutColor,
    DayStatus.inProgress => AppColors.primary,
  };

  String get label => switch (this) {
    DayStatus.complete => 'Completa',
    DayStatus.late => 'Con tardanza',
    DayStatus.incomplete => 'Incompleta',
    DayStatus.inProgress => 'En curso',
  };
}

class CalendarHistoryView extends StatefulWidget {
  const CalendarHistoryView({super.key});

  @override
  State<CalendarHistoryView> createState() => _CalendarHistoryViewState();
}

class _CalendarHistoryViewState extends State<CalendarHistoryView> {
  // Deslizar el calendario arriba/abajo alterna entre estas vistas.
  CalendarFormat _calendarFormat = CalendarFormat.twoWeeks;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() {
    final user = context.read<AuthCubit>().state.currentUser;
    return context.read<CalendarCubit>().loadCalendarData(
      user?.id ?? 'USR-001',
      shiftStartTime: user?.shiftStartTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Historial'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_outlined),
            tooltip: 'Mis justificaciones',
            onPressed: () {
              HapticFeedbackService.shared.selectionClick();
              Navigator.push(context, JustificationsView.route());
            },
          ),
        ],
      ),
      body: BlocBuilder<CalendarCubit, CalendarState>(
        builder: (context, state) {
          if (state is CalendarLoading || state is CalendarInitial) {
            return const AsisLoadingOverlay(
              skeleton: AsisCalendarSkeleton(),
              message: 'Cargando tu historial...',
            );
          }

          if (state is CalendarError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                      onPressed: _reload,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = state as CalendarLoaded;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _MonthSummaryCard(summary: data.monthSummary),
                const SizedBox(height: 12),
                _buildCalendarCard(context, data),
                const SizedBox(height: 20),
                _DayDetail(
                  day: data.selectedDay,
                  summary: data.selectedDaySummary,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalendarCard(BuildContext context, CalendarLoaded data) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Column(
          children: [
            TableCalendar<AttendanceDaySummary>(
              locale: 'es',
              firstDay: DateTime.utc(2025, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: data.focusedDay,
              calendarFormat: _calendarFormat,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Mes',
                CalendarFormat.twoWeeks: '2 semanas',
                CalendarFormat.week: 'Semana',
              },
              startingDayOfWeek: StartingDayOfWeek.monday,
              selectedDayPredicate: (day) => isSameDay(day, data.selectedDay),
              onDaySelected: (selectedDay, focusedDay) {
                HapticFeedbackService.shared.selectionClick();
                context.read<CalendarCubit>().selectDay(
                  selectedDay,
                  focusedDay,
                );
              },
              onFormatChanged: (format) {
                setState(() => _calendarFormat = format);
              },
              onPageChanged: (focusedDay) {
                context.read<CalendarCubit>().updateFocusedDay(focusedDay);
              },
              eventLoader: (day) {
                final summary = data.summaryFor(day);
                return summary == null ? const [] : [summary];
              },
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonShowsNext: false,
                titleTextFormatter:
                    (date, locale) => toBeginningOfSentenceCase(
                      DateFormat('MMMM yyyy', locale).format(date),
                    ),
                titleTextStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                formatButtonDecoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                formatButtonTextStyle: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                leftChevronIcon: const Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.textPrimary,
                ),
                rightChevronIcon: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textPrimary,
                ),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                weekendStyle: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              calendarStyle: CalendarStyle(
                defaultTextStyle: const TextStyle(color: AppColors.textPrimary),
                weekendTextStyle: const TextStyle(
                  color: AppColors.textSecondary,
                ),
                outsideTextStyle: const TextStyle(color: AppColors.textMuted),
                // Seleccionado: relleno. Hoy: solo borde.
                selectedDecoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                todayDecoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                todayTextStyle: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              calendarBuilders: CalendarBuilders<AttendanceDaySummary>(
                markerBuilder: (context, date, events) {
                  if (events.isEmpty) return null;
                  return Positioned(
                    bottom: 4,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: events.first.status.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // Leyenda de los puntos de estado
            const Wrap(
              spacing: 16,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                _LegendItem(status: DayStatus.complete),
                _LegendItem(status: DayStatus.late),
                _LegendItem(status: DayStatus.incomplete),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthSummaryCard extends StatelessWidget {
  final MonthSummary summary;

  const _MonthSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final monthName = toBeginningOfSentenceCase(
      DateFormat('MMMM', 'es').format(summary.month),
    );

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen de $monthName',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(
                children: [
                  _Stat(
                    value: '${summary.daysAttended}',
                    label: 'Días asistidos',
                  ),
                  const VerticalDivider(
                    color: AppColors.borderLight,
                    width: 24,
                  ),
                  _Stat(value: '${summary.lateDays}', label: 'Tardanzas'),
                  const VerticalDivider(
                    color: AppColors.borderLight,
                    width: 24,
                  ),
                  _Stat(
                    value: _formatHours(summary.worked),
                    label: 'Horas trabajadas',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatHours(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  if (h == 0) return '$m min';
  return m == 0 ? '$h h' : '$h h $m min';
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final DayStatus status;

  const _LegendItem({required this.status});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: status.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          status.label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// Detalle del dia seleccionado como linea de tiempo de la jornada.
class _DayDetail extends StatelessWidget {
  final DateTime day;
  final AttendanceDaySummary? summary;

  const _DayDetail({required this.day, required this.summary});

  static const _steps = [
    AttendanceType.checkIn,
    AttendanceType.lunchStart,
    AttendanceType.lunchEnd,
    AttendanceType.checkOut,
  ];

  @override
  Widget build(BuildContext context) {
    final title = toBeginningOfSentenceCase(DateFormatter.formatFullDate(day));
    final s = summary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (s != null) _StatusChip(status: s.status),
          ],
        ),
        const SizedBox(height: 10),
        Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.borderLight),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child:
                s == null
                    ? const _EmptyDay()
                    : Column(
                      children: [
                        for (var i = 0; i < _steps.length; i++)
                          _TimelineStep(
                            type: _steps[i],
                            record: s.recordOf(_steps[i]),
                            isLast: i == _steps.length - 1,
                          ),
                        const Divider(color: AppColors.borderLight, height: 20),
                        Row(
                          children: [
                            const Text(
                              'Horas trabajadas',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              s.status == DayStatus.incomplete
                                  ? '—'
                                  : s.status == DayStatus.inProgress
                                  ? '${_formatHours(s.worked)} (en curso)'
                                  : _formatHours(s.worked),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
          ),
        ),
        // Justificar directamente desde un dia con problemas
        if (s != null && s.needsJustification) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                HapticFeedbackService.shared.selectionClick();
                NewJustificationSheet.show(context, initialDate: day);
              },
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text('Justificar este día'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final DayStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: status.color,
        ),
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 36,
              color: AppColors.textMuted,
            ),
            SizedBox(height: 8),
            Text(
              'Sin marcaciones este día',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final AttendanceType type;
  final AttendanceRecord? record;
  final bool isLast;

  const _TimelineStep({
    required this.type,
    required this.record,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final r = record;
    final done = r != null;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Punto y linea de la linea de tiempo
          SizedBox(
            width: 20,
            child: Column(
              children: [
                const SizedBox(height: 4),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? AppColors.primary : Colors.white,
                    border: Border.all(
                      color: done ? AppColors.primary : AppColors.textMuted,
                      width: 2,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: AppColors.borderLight),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          type.shortName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color:
                                done
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Text(
                        done
                            ? DateFormatter.formatTime(r.timestamp)
                            : 'Sin marcar',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: done ? FontWeight.w700 : FontWeight.w400,
                          color:
                              done
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  if (done) ...[
                    const SizedBox(height: 2),
                    Text(
                      [
                        r.geozoneName ?? r.branchName,
                        if (!r.isInsideGeozone) 'Fuera de la geocerca',
                      ].join(' · '),
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            r.isInsideGeozone
                                ? AppColors.textSecondary
                                : const Color(0xFFB45309),
                      ),
                    ),
                    if (r.note != null && r.note!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '“${r.note!}”',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
