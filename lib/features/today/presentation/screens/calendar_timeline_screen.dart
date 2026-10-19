import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/moss_haptics.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../../core/widgets/ios_picker_dialogs.dart';
import '../../../tasks/domain/task.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../calendar/data/device_calendar_service.dart';
import '../../../calendar/domain/device_calendar_event.dart';
import '../today_controller.dart';

/// The Calendar & Timeline screen for Moss.
/// Features full Device Calendar synchronization, chronological interleaving,
/// schedule conflict detection, and iOS HIG aesthetics.
class CalendarTimelineScreen extends ConsumerStatefulWidget {
  const CalendarTimelineScreen({
    super.key,
    required this.onOpenTask,
    required this.onAddTask,
    required this.onSelectedDayChanged,
  });

  final ValueChanged<Task> onOpenTask;
  final ValueChanged<DateTime> onAddTask;
  final ValueChanged<DateTime> onSelectedDayChanged;

  @override
  ConsumerState<CalendarTimelineScreen> createState() =>
      _CalendarTimelineScreenState();
}

class _CalendarTimelineScreenState
    extends ConsumerState<CalendarTimelineScreen> {
  late DateTime _selectedDay;
  int _viewMode =
      1; // 0: Compact, 1: Standard (Default), 2: Grouped by Quadrant

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initCalendarAndAutoSync();
    });
  }

  Future<void> _initCalendarAndAutoSync() async {
    final calendar = ref.read(deviceCalendarViewModelProvider);
    await calendar.checkAndLoadSilently(_selectedDay);
    if (calendar.status == CalendarAccessStatus.undetermined && mounted) {
      await _requestCalendarConsentAndSync();
    }
  }

  Future<void> _requestCalendarConsentAndSync() async {
    final calendar = ref.read(deviceCalendarViewModelProvider);
    final status = await calendar.connectAndLoad(_selectedDay);
    if (status == CalendarAccessStatus.granted && mounted) {
      final settingsRepo = ref.read(settingsRepositoryProvider);
      final currentSettings = await settingsRepo.getSettings();
      if (!currentSettings.saveCompletedToCalendar) {
        await settingsRepo.updateSettings(
          currentSettings.copyWith(saveCompletedToCalendar: true),
        );
      }
      await ref.read(calendarTaskSyncServiceProvider).syncAllTodoTasks();
      await ref.read(todayControllerProvider.notifier).load();
    }
  }

  void _handleDateChange(DateTime newDate) {
    final monthChanged =
        newDate.year != _selectedDay.year ||
        newDate.month != _selectedDay.month;
    setState(() => _selectedDay = newDate);
    widget.onSelectedDayChanged(newDate);
    if (monthChanged) {
      ref.read(deviceCalendarViewModelProvider).loadMonth(newDate);
    }
  }

  Future<void> _toggleTaskComplete(Task task) async {
    MossHaptics.success();
    if (task.isCompleted) {
      await ref.read(todayControllerProvider.notifier).uncompleteTask(task);
    } else {
      await ref.read(todayControllerProvider.notifier).completeTask(task);
    }
  }

  void _showEventDetails(DeviceCalendarEvent event) {
    MossHaptics.selection();
    final start = event.start.toLocal();
    final end = event.end.toLocal();
    final timeStr = event.allDay
        ? 'ทั้งวัน'
        : '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} – ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    final dateStr =
        '${start.day} ${ThaiDateFormatter.thaiMonthName(start.month)} ${start.year + 543}';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: event.colorValue != null
                        ? Color(event.colorValue!)
                        : Theme.of(context).colorScheme.tertiary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  event.calendarName.isNotEmpty
                      ? event.calendarName
                      : 'ปฏิทินของเครื่อง',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'นัดหมาย',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              event.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.72),
                ),
                const SizedBox(width: 8),
                Text(
                  '$dateStr · $timeStr',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (event.location != null &&
                event.location!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.location!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (event.description != null &&
                event.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  event.description!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onAddTask(_selectedDay);
                },
                icon: const Icon(Icons.add_task_rounded),
                label: const Text('สร้างงานเตรียมตัวใน Moss'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(todayControllerProvider);
    final deviceCalendar = ref.watch(deviceCalendarViewModelProvider);
    final allTasks = state.allTasks;

    // Filter tasks for selected day
    final tasksForDay = allTasks.where((t) {
      if (t.deadlineAt != null) {
        final d = t.deadlineAt!.toLocal();
        return d.year == _selectedDay.year &&
            d.month == _selectedDay.month &&
            d.day == _selectedDay.day;
      }
      final c = t.createdAt.toLocal();
      return c.year == _selectedDay.year &&
          c.month == _selectedDay.month &&
          c.day == _selectedDay.day;
    }).toList();

    // Query events from DeviceCalendarViewModel
    final syncedEventIds = allTasks
        .map((task) => task.calendarEventId)
        .whereType<String>()
        .map((id) => id.split('/').last)
        .toSet();
    final eventsForDay = deviceCalendar
        .eventsForDay(_selectedDay)
        .where((event) => !syncedEventIds.contains(event.id.split('/').last))
        .toList(growable: false);
    final allDayEvents = eventsForDay.where((e) => e.allDay).toList();
    final timedEvents = eventsForDay.where((e) => !e.allDay).toList();

    // Build unified chronological timeline entries
    final timelineEntries = <_TimelineEntry>[
      for (final task in tasksForDay)
        _TaskTimelineEntry(
          task: task,
          conflict: deviceCalendar.findConflict(task),
        ),
      for (final event in timedEvents) _EventTimelineEntry(event: event),
    ];

    // Sorting according to selected view mode
    if (_viewMode == 2) {
      timelineEntries.sort((a, b) {
        if (a is _TaskTimelineEntry && b is _TaskTimelineEntry) {
          final qComp = a.task.quadrant.compareTo(b.task.quadrant);
          if (qComp != 0) return qComp;
          return a.sortTime.compareTo(b.sortTime);
        }
        if (a is _EventTimelineEntry && b is _TaskTimelineEntry) return -1;
        if (a is _TaskTimelineEntry && b is _EventTimelineEntry) return 1;
        return a.sortTime.compareTo(b.sortTime);
      });
    } else {
      timelineEntries.sort((a, b) => a.sortTime.compareTo(b.sortTime));
    }

    final totalItems = timelineEntries.length;
    final totalCountDisplay = tasksForDay.length + eventsForDay.length;

    final thaiMonthYear =
        '${ThaiDateFormatter.thaiMonthName(_selectedDay.month)} ${_selectedDay.year + 543}';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Month Year Dropdown (interactive) + View Mode Switcher
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Month Year Dropdown
                  GestureDetector(
                    onTap: () async {
                      MossHaptics.selection();
                      final picked = await showIosDatePicker(
                        context,
                        initialDate: _selectedDay,
                      );
                      if (picked != null && mounted) {
                        _handleDateChange(picked);
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          thaiMonthYear,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 24,
                        ),
                      ],
                    ),
                  ),

                  // View mode switcher
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ViewModeIcon(
                          icon: Icons.notes_rounded,
                          isSelected: _viewMode == 0,
                          onTap: () {
                            MossHaptics.selection();
                            setState(() => _viewMode = 0);
                          },
                        ),
                        _ViewModeIcon(
                          icon: Icons.format_list_bulleted_rounded,
                          isSelected: _viewMode == 1,
                          onTap: () {
                            MossHaptics.selection();
                            setState(() => _viewMode = 1);
                          },
                        ),
                        _ViewModeIcon(
                          icon: Icons.view_agenda_outlined,
                          isSelected: _viewMode == 2,
                          onTap: () {
                            MossHaptics.selection();
                            setState(() => _viewMode = 2);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Horizontal Week Days Strip with dual dynamic indicators
            _WeekStrip(
              selectedDate: _selectedDay,
              allTasks: allTasks,
              calendarEvents: deviceCalendar.events,
              onSelectDate: (d) {
                MossHaptics.selection();
                _handleDateChange(d);
              },
            ),

            // Prompt only when device calendar permission has been explicitly denied.
            // When undetermined, system permission is requested automatically.
            // When granted, the timeline displays seamlessly without any prompt banner.
            if (deviceCalendar.status == CalendarAccessStatus.denied)
              _DeviceCalendarPrompt(
                loading: deviceCalendar.loading,
                denied: true,
                onConnect: () => deviceCalendar.openAppSettings(),
              ),

            const SizedBox(height: 18),

            // Section Header: วันนี้ {date}   {count} รายการ
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'วันนี้ ',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text:
                              '${_selectedDay.day} ${ThaiDateFormatter.thaiMonthName(_selectedDay.month)}',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.72),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$totalCountDisplay รายการ',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.72),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Timeline Card with vertical line & items
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      // All Day Events Header
                      if (allDayEvents.isNotEmpty)
                        _AllDayEventsSection(
                          events: allDayEvents,
                          onOpenEvent: _showEventDetails,
                        ),

                      Expanded(
                        child: totalItems == 0 && allDayEvents.isEmpty
                            ? Center(
                                child: SingleChildScrollView(
                                  physics: const NeverScrollableScrollPhysics(),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.event_available_rounded,
                                        size: 40,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.32),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'ไม่มีรายการงานหรือนัดหมายในวันนี้',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'แตะปุ่ม + ด้านล่างเพื่อเพิ่มงานใหม่',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.6),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.only(
                                  top: allDayEvents.isNotEmpty ? 8 : 4,
                                ),
                                itemCount: totalItems,
                                itemBuilder: (context, index) {
                                  final entry = timelineEntries[index];
                                  final isLast = index == totalItems - 1;

                                  if (entry is _EventTimelineEntry) {
                                    return _DeviceEventRow(
                                      event: entry.event,
                                      isLast: isLast,
                                      onTap: () =>
                                          _showEventDetails(entry.event),
                                    );
                                  }

                                  final taskEntry = entry as _TaskTimelineEntry;
                                  return _TimelineItemRow(
                                    task: taskEntry.task,
                                    conflict: taskEntry.conflict,
                                    isLast: isLast,
                                    compact: _viewMode == 0,
                                    onTap: () =>
                                        widget.onOpenTask(taskEntry.task),
                                    onToggleComplete: () =>
                                        _toggleTaskComplete(taskEntry.task),
                                    onOpenConflict: (conflict) =>
                                        _showEventDetails(conflict),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Sealed Timeline Entry model for unified chronological interleaving
sealed class _TimelineEntry {
  final DateTime sortTime;
  const _TimelineEntry(this.sortTime);
}

class _TaskTimelineEntry extends _TimelineEntry {
  final Task task;
  final DeviceCalendarEvent? conflict;
  _TaskTimelineEntry({required this.task, this.conflict})
    : super((task.deadlineAt ?? task.createdAt).toLocal());
}

class _EventTimelineEntry extends _TimelineEntry {
  final DeviceCalendarEvent event;
  _EventTimelineEntry({required this.event}) : super(event.start.toLocal());
}

/// All-Day events banner pinned at the top of the timeline
class _AllDayEventsSection extends StatelessWidget {
  const _AllDayEventsSection({required this.events, required this.onOpenEvent});

  final List<DeviceCalendarEvent> events;
  final ValueChanged<DeviceCalendarEvent> onOpenEvent;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.wb_sunny_outlined,
                size: 15,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'นัดหมายทั้งวัน (${events.length})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: events.map((event) {
              final color = event.colorValue != null
                  ? Color(event.colorValue!)
                  : Theme.of(context).colorScheme.tertiary;
              return InkWell(
                onTap: () => onOpenEvent(event),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        event.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _DeviceCalendarPrompt extends StatelessWidget {
  const _DeviceCalendarPrompt({
    required this.loading,
    required this.denied,
    required this.onConnect,
  });

  final bool loading;
  final bool denied;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxWidth < 390 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.25;
            final icon = Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 22,
              ),
            );
            final text = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  denied ? 'ยังไม่ได้รับสิทธิ์ปฏิทิน' : 'รวมปฏิทินของเครื่อง',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  denied
                      ? 'แตะลองใหม่หรือเปิดสิทธิ์ในการตั้งค่าระบบ'
                      : 'ดูนัดหมายและงานจริงในไทม์ไลน์เดียวกัน',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
            final button = FilledButton.tonal(
              onPressed: loading ? null : onConnect,
              child: loading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(denied ? 'เปิดการตั้งค่า' : 'เชื่อมต่อ'),
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      icon,
                      const SizedBox(width: 12),
                      Expanded(child: text),
                    ],
                  ),
                  const SizedBox(height: 12),
                  button,
                ],
              );
            }
            return Row(
              children: [
                icon,
                const SizedBox(width: 12),
                Expanded(child: text),
                const SizedBox(width: 8),
                button,
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _DeviceEventRow extends StatelessWidget {
  const _DeviceEventRow({
    required this.event,
    required this.isLast,
    required this.onTap,
  });

  final DeviceCalendarEvent event;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final start = event.start.toLocal();
    final end = event.end.toLocal();
    final timeStr = event.allDay
        ? 'ทั้งวัน'
        : '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} – ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    final eventColor = event.colorValue != null
        ? Color(event.colorValue!)
        : Theme.of(context).colorScheme.tertiary;

    return Semantics(
      label: 'นัดหมาย ${event.title}, $timeStr',
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time column
            SizedBox(
              width: 48,
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(
                  event.allDay
                      ? 'ทั้งวัน'
                      : '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.72),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Vertical Track and Event Dot
            Column(
              children: [
                const SizedBox(height: 18),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: eventColor,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Event Card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: eventColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: eventColor.withValues(alpha: 0.25),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Row(
                      children: [
                        // Accent colored left bar
                        Container(width: 4, height: 64, color: eventColor),
                        const SizedBox(width: 12),

                        // Calendar icon
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: eventColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: eventColor,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Event Title & Metadata
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 4,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  event.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      timeStr,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.72),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (event.calendarName.isNotEmpty) ...[
                                      Text(
                                        ' · ${event.calendarName}',
                                        style: TextStyle(
                                          color: eventColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (event.location != null &&
                                    event.location!.trim().isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '📍 ${event.location}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.55),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewModeIcon extends StatelessWidget {
  const _ViewModeIcon({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      selected: isSelected,
      label: 'เปลี่ยนรูปแบบปฏิทิน',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 40,
          height: 36,
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? Colors.white : Colors.black)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isSelected
                ? (isDark ? Colors.black : Colors.white)
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.72),
          ),
        ),
      ),
    );
  }
}

/// Weekly date strip matching user's reference design with dual indicators
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.selectedDate,
    required this.allTasks,
    required this.calendarEvents,
    required this.onSelectDate,
  });

  final DateTime selectedDate;
  final List<Task> allTasks;
  final List<DeviceCalendarEvent> calendarEvents;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    // Find the Sunday of this week
    final startOfWeek = selectedDate.subtract(
      Duration(days: selectedDate.weekday % 7),
    );
    final dayNames = ['อา', 'จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (i) {
          final date = startOfWeek.add(Duration(days: i));
          final isSelected =
              date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day;

          // Compute real active task presence for this day
          final hasActiveTasks = allTasks.any((t) {
            final d = (t.deadlineAt ?? t.createdAt).toLocal();
            return d.year == date.year &&
                d.month == date.month &&
                d.day == date.day &&
                t.status == TaskStatus.todo;
          });

          // Compute real device calendar event presence for this day
          final hasCalendarEvents = calendarEvents.any((e) {
            final d = e.start.toLocal();
            return d.year == date.year &&
                d.month == date.month &&
                d.day == date.day;
          });

          return Semantics(
            button: true,
            selected: isSelected,
            label: 'เลือกวันที่ ${date.day}',
            child: InkWell(
              onTap: () => onSelectDate(date),
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                width: 44,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dayNames[i],
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFFE5A93B)
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.72),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFE5A93B)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.black
                              : Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isSelected)
                      const Icon(
                        Icons.check,
                        size: 14,
                        color: AppColors.success,
                      )
                    else if (hasActiveTasks && hasCalendarEvents)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.tertiary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      )
                    else if (hasActiveTasks)
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      )
                    else if (hasCalendarEvents)
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.tertiary,
                          shape: BoxShape.circle,
                        ),
                      )
                    else
                      const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Single item in the timeline with vertical connector, quadrant colors, and conflict badge
class _TimelineItemRow extends StatelessWidget {
  const _TimelineItemRow({
    required this.task,
    this.conflict,
    required this.isLast,
    required this.compact,
    required this.onTap,
    required this.onToggleComplete,
    this.onOpenConflict,
  });

  final Task task;
  final DeviceCalendarEvent? conflict;
  final bool isLast;
  final bool compact;
  final VoidCallback onTap;
  final VoidCallback onToggleComplete;
  final ValueChanged<DeviceCalendarEvent>? onOpenConflict;

  @override
  Widget build(BuildContext context) {
    final quadrant = MatrixQuadrant.fromId(task.quadrant);
    final quadrantLabel = quadrant.label;

    // Dynamic local time formatted from deadline or creation timestamp
    final itemTime = (task.deadlineAt ?? task.createdAt).toLocal();
    final timeStr =
        '${itemTime.hour.toString().padLeft(2, '0')}:${itemTime.minute.toString().padLeft(2, '0')}';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time label
          SizedBox(
            width: 48,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                timeStr,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.72),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Timeline vertical track + dot
          Column(
            children: [
              const SizedBox(height: 18),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.quadrantFor(quadrant.id),
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Task Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.quadrantFor(
                      quadrant.id,
                    ).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.quadrantFor(
                        quadrant.id,
                      ).withValues(alpha: 0.20),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Row(
                    children: [
                      // Colored left accent bar
                      Container(
                        width: 4,
                        height: compact ? 48 : (conflict != null ? 80 : 64),
                        color: AppColors.quadrantFor(quadrant.id),
                      ),
                      const SizedBox(width: 12),

                      // Interactive Checkbox
                      GestureDetector(
                        onTap: onToggleComplete,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                          child: Container(
                            key: ValueKey<bool>(task.isCompleted),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: task.isCompleted
                                  ? AppColors.success
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                              border: task.isCompleted
                                  ? null
                                  : Border.all(
                                      color: AppColors.quadrantFor(quadrant.id),
                                      width: 2,
                                    ),
                            ),
                            child: task.isCompleted
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: Colors.black,
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Task Title & Subtitle + Conflict Badge
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 4,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                task.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: task.isCompleted
                                      ? Theme.of(context).colorScheme.onSurface
                                            .withValues(alpha: 0.64)
                                      : Theme.of(context).colorScheme.onSurface,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  decoration: task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              if (!compact) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '$quadrantLabel · ${task.projectName ?? "Moss"}',
                                  style: TextStyle(
                                    color: AppColors.quadrantFor(quadrant.id),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              // Conflict warning badge
                              if (conflict != null && !task.isCompleted) ...[
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () => onOpenConflict?.call(conflict!),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFF59E0B,
                                      ).withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(
                                          0xFFF59E0B,
                                        ).withValues(alpha: 0.45),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.warning_amber_rounded,
                                          size: 13,
                                          color: Color(0xFFF59E0B),
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            'ชนกับ: ${conflict!.title}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFFF59E0B),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
