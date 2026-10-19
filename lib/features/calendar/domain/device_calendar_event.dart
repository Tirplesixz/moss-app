import 'package:flutter/foundation.dart';

@immutable
class DeviceCalendarEvent {
  const DeviceCalendarEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    this.allDay = false,
    this.calendarName = '',
    this.colorValue,
    this.location,
    this.description,
  });

  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final bool allDay;
  final String calendarName;
  final int? colorValue;
  final String? location;
  final String? description;
}
