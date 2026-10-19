import 'package:flutter/services.dart';

import '../domain/device_calendar_event.dart';

enum CalendarAccessStatus { granted, denied, undetermined, unsupported }

class DeviceCalendarService {
  const DeviceCalendarService();
  static const _channel = MethodChannel('com.moss.moss/calendar');

  Future<CalendarAccessStatus> checkAccess() async {
    try {
      final value = await _channel.invokeMethod<String>('checkAccess');
      return switch (value) {
        'granted' => CalendarAccessStatus.granted,
        'denied' => CalendarAccessStatus.denied,
        'undetermined' => CalendarAccessStatus.undetermined,
        _ => CalendarAccessStatus.unsupported,
      };
    } on MissingPluginException {
      return CalendarAccessStatus.unsupported;
    } on PlatformException {
      return CalendarAccessStatus.unsupported;
    }
  }

  Future<CalendarAccessStatus> requestAccess() async {
    try {
      final value = await _channel.invokeMethod<String>('requestAccess');
      return switch (value) {
        'granted' => CalendarAccessStatus.granted,
        'denied' => CalendarAccessStatus.denied,
        'undetermined' => CalendarAccessStatus.undetermined,
        _ => CalendarAccessStatus.unsupported,
      };
    } on MissingPluginException {
      return CalendarAccessStatus.unsupported;
    } on PlatformException {
      return CalendarAccessStatus.unsupported;
    }
  }

  Future<List<DeviceCalendarEvent>> fetchEvents(
    DateTime start,
    DateTime end,
  ) async {
    final raw = await _channel.invokeListMethod<dynamic>('fetchEvents', {
      'start': start.millisecondsSinceEpoch,
      'end': end.millisecondsSinceEpoch,
    });
    return [
      for (final item in raw ?? const [])
        _fromMap(Map<Object?, Object?>.from(item as Map)),
    ];
  }

  Future<String?> addCompletedTask({
    required String title,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      return await upsertTaskEvent(
        title: title,
        start: start,
        end: end,
        completed: true,
      );
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<String?> upsertTaskEvent({
    String? eventId,
    required String title,
    required DateTime start,
    required DateTime end,
    bool completed = false,
    String? notes,
  }) async {
    try {
      return await _channel.invokeMethod<String>('upsertTaskEvent', {
        'eventId': eventId,
        'title': title,
        'start': start.millisecondsSinceEpoch,
        'end': end.millisecondsSinceEpoch,
        'completed': completed,
        'notes': notes,
      });
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<bool> deleteEvent(String eventId) async {
    try {
      return await _channel.invokeMethod<bool>('deleteEvent', {
            'eventId': eventId,
          }) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> openAppSettings() async {
    try {
      return await _channel.invokeMethod<bool>('openAppSettings') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  DeviceCalendarEvent _fromMap(Map<Object?, Object?> map) =>
      DeviceCalendarEvent(
        id: map['id'] as String,
        title: map['title'] as String? ?? 'ไม่มีชื่อ',
        start: DateTime.fromMillisecondsSinceEpoch(map['start'] as int),
        end: DateTime.fromMillisecondsSinceEpoch(map['end'] as int),
        allDay: map['allDay'] as bool? ?? false,
        calendarName: map['calendarName'] as String? ?? '',
        colorValue: map['color'] as int?,
        location: map['location'] as String?,
        description: map['description'] as String?,
      );
}
