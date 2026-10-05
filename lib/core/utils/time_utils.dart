/// Utility functions for time handling and rounding in Moss.
/// All timestamps are stored in UTC. Local time is used for UI display only.
class TimeUtils {
  TimeUtils._();

  /// Converts a DateTime to UTC ISO8601 string for database storage.
  static String toUtcIsoString(DateTime dt) {
    return dt.toUtc().toIso8601String();
  }

  /// Parses an ISO8601 string from the database and returns a UTC DateTime.
  static DateTime parseUtc(String isoString) {
    return DateTime.parse(isoString).toUtc();
  }

  /// Converts a UTC DateTime to local DateTime for presentation.
  static DateTime toLocal(DateTime utcDt) {
    return utcDt.toLocal();
  }

  /// Returns current time in UTC.
  static DateTime nowUtc() {
    return DateTime.now().toUtc();
  }

  /// Rounds a DateTime up to the next multiple of [minuteInterval] minutes (default 5).
  /// If it is already exactly on the interval with 0 seconds and milliseconds, returns dt.
  static DateTime roundUpToInterval(DateTime dt, {int minuteInterval = 5}) {
    final utc = dt.toUtc();
    final remainder = utc.minute % minuteInterval;
    if (remainder == 0 &&
        utc.second == 0 &&
        utc.millisecond == 0 &&
        utc.microsecond == 0) {
      return utc;
    }
    final minutesToAdd = minuteInterval - remainder;
    final rounded = DateTime.utc(
      utc.year,
      utc.month,
      utc.day,
      utc.hour,
      utc.minute,
    ).add(Duration(minutes: minutesToAdd));
    return rounded;
  }

  /// Rounds a DateTime to nearest multiple of [minuteInterval] minutes (default 5).
  static DateTime roundToNearestInterval(
    DateTime dt, {
    int minuteInterval = 5,
  }) {
    final utc = dt.toUtc();
    final remainder = utc.minute % minuteInterval;
    final totalSeconds = remainder * 60 + utc.second;
    final halfIntervalSeconds = (minuteInterval * 60) / 2;
    final minutesToAdd = totalSeconds >= halfIntervalSeconds
        ? (minuteInterval - remainder)
        : -remainder;
    return DateTime.utc(
      utc.year,
      utc.month,
      utc.day,
      utc.hour,
      utc.minute,
    ).add(Duration(minutes: minutesToAdd));
  }

  /// Combines a date (in local time) with a 'HH:mm' time string, then converts to UTC.
  static DateTime parseTimeOnDate(DateTime localDate, String hhMm) {
    final parts = hhMm.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final combinedLocal = DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
      hour,
      minute,
    );
    return combinedLocal.toUtc();
  }

  /// Formats UTC DateTime as local 'HH:mm'.
  static String formatLocalHhMm(DateTime utcDt) {
    final local = utcDt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
