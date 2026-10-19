import 'package:flutter/foundation.dart';

import '../../tasks/domain/task.dart';
import '../data/device_calendar_service.dart';
import '../domain/device_calendar_event.dart';

class DeviceCalendarViewModel extends ChangeNotifier {
  DeviceCalendarViewModel(this._service);
  final DeviceCalendarService _service;

  CalendarAccessStatus? _status;
  List<DeviceCalendarEvent> _events = const [];
  Set<String> _deselectedCalendarNames = const {};
  bool _loading = false;
  Object? _error;
  DateTime? _lastLoadedMonth;

  CalendarAccessStatus? get status => _status;
  List<DeviceCalendarEvent> get events => List.unmodifiable(_events);
  bool get loading => _loading;
  Object? get error => _error;
  bool get hasAccess => _status == CalendarAccessStatus.granted;
  bool get isDenied => _status == CalendarAccessStatus.denied;

  Set<String> get availableCalendarNames =>
      _events.map((e) => e.calendarName).where((name) => name.isNotEmpty).toSet();
  Set<String> get deselectedCalendarNames => _deselectedCalendarNames;

  bool isCalendarVisible(String name) => !_deselectedCalendarNames.contains(name);

  void toggleCalendarVisibility(String name) {
    final next = Set<String>.from(_deselectedCalendarNames);
    if (next.contains(name)) {
      next.remove(name);
    } else {
      next.add(name);
    }
    _deselectedCalendarNames = next;
    notifyListeners();
  }

  void showAllCalendars() {
    _deselectedCalendarNames = const {};
    notifyListeners();
  }

  /// Silently checks permission on screen load.
  /// If already granted, immediately fetches events for [around].
  Future<void> checkAndLoadSilently(
    DateTime around, {
    Future<void> Function()? onGranted,
  }) async {
    try {
      final currentStatus = await _service.checkAccess();
      _status = currentStatus;
      notifyListeners();
      if (currentStatus == CalendarAccessStatus.granted) {
        await loadMonth(around);
        if (onGranted != null) {
          await onGranted();
        }
      }
    } catch (_) {
      // Ignore background check errors
    }
  }

  /// Explicitly requests permission and loads events.
  /// Returns the resulting [CalendarAccessStatus].
  Future<CalendarAccessStatus> connectAndLoad(
    DateTime around, {
    Future<void> Function()? onGranted,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _status = await _service.requestAccess();
      if (_status == CalendarAccessStatus.granted) {
        await loadMonth(around, force: true);
        if (onGranted != null) {
          await onGranted();
        }
      }
      return _status ?? CalendarAccessStatus.unsupported;
    } catch (error) {
      _error = error;
      return CalendarAccessStatus.unsupported;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> openAppSettings() => _service.openAppSettings();

  /// Loads events for the month of [around] with 7-day padding on both ends.
  Future<void> loadMonth(DateTime around, {bool force = false}) async {
    if (_status != CalendarAccessStatus.granted) return;
    final targetMonth = DateTime(around.year, around.month, 1);
    if (!force &&
        _lastLoadedMonth != null &&
        _lastLoadedMonth!.year == targetMonth.year &&
        _lastLoadedMonth!.month == targetMonth.month &&
        _events.isNotEmpty) {
      return;
    }

    _loading = true;
    notifyListeners();
    try {
      // 7 days padding before start of month to 7 days after end of month
      final start = targetMonth.subtract(const Duration(days: 7));
      final end = DateTime(
        around.year,
        around.month + 1,
        1,
      ).add(const Duration(days: 7));
      _events = await _service.fetchEvents(start, end);
      _lastLoadedMonth = targetMonth;
      _error = null;
    } catch (error) {
      _error = error;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Returns sorted events for a specific day.
  List<DeviceCalendarEvent> eventsForDay(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return _events.where((event) {
      if (event.calendarName.isNotEmpty &&
          _deselectedCalendarNames.contains(event.calendarName)) {
        return false;
      }
      final start = event.start.toLocal();
      final end = event.end.toLocal();
      return start.isBefore(dayEnd) && end.isAfter(dayStart);
    }).toList()..sort((a, b) => a.start.compareTo(b.start));
  }

  /// Returns true if the day contains at least one calendar event.
  bool hasEventsOnDay(DateTime day) {
    return eventsForDay(day).isNotEmpty;
  }

  /// Checks if an active task's scheduled window conflicts with any calendar event.
  /// Returns the first conflicting event or null if no conflict.
  DeviceCalendarEvent? findConflict(Task task) {
    if (task.isCompleted || task.deadlineAt == null) return null;
    final taskEnd = task.deadlineAt!.toLocal();
    final duration = task.durationMin > 0 ? task.durationMin : 30;
    final taskStart = taskEnd.subtract(Duration(minutes: duration));

    final dayEvents = eventsForDay(taskEnd);
    for (final event in dayEvents) {
      if (_sameExternalEvent(event.id, task.calendarEventId)) continue;
      if (event.allDay) continue;
      final eventStart = event.start.toLocal();
      final eventEnd = event.end.toLocal();

      // Overlap: task starts before event ends and task ends after event starts
      if (taskStart.isBefore(eventEnd) && taskEnd.isAfter(eventStart)) {
        return event;
      }
    }
    return null;
  }

  static bool _sameExternalEvent(String eventId, String? storedId) {
    if (storedId == null) return false;
    String normalize(String value) => value.split('/').last;
    return normalize(eventId) == normalize(storedId);
  }
}
