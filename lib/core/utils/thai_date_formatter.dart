/// Helper for formatting Thai dates, times, and durations.
class ThaiDateFormatter {
  ThaiDateFormatter._();

  static const List<String> _thaiDays = [
    'วันจันทร์',
    'วันอังคาร',
    'วันพุธ',
    'วันพฤหัสบดี',
    'วันศุกร์',
    'วันเสาร์',
    'วันอาทิตย์',
  ];

  static const List<String> _thaiMonths = [
    'มกราคม',
    'กุมภาพันธ์',
    'มีนาคม',
    'เมษายน',
    'พฤษภาคม',
    'มิถุนายน',
    'กรกฎาคม',
    'สิงหาคม',
    'กันยายน',
    'ตุลาคม',
    'พฤศจิกายน',
    'ธันวาคม',
  ];

  /// Formats date to e.g. "วันพุธที่ 30 กันยายน"
  static String formatFullDate(DateTime date) {
    final dayName = _thaiDays[date.weekday - 1];
    final monthName = _thaiMonths[date.month - 1];
    return '$dayNameที่ ${date.day} $monthName';
  }

  /// Formats time to "HH:mm น."
  static String formatTime(DateTime dateTime) {
    final h = dateTime.hour.toString().padLeft(2, '0');
    final m = dateTime.minute.toString().padLeft(2, '0');
    return '$h:$m น.';
  }

  /// Formats time range to "HH:mm – HH:mm น."
  static String formatTimeRange(DateTime start, DateTime end) {
    final sH = start.hour.toString().padLeft(2, '0');
    final sM = start.minute.toString().padLeft(2, '0');
    final eH = end.hour.toString().padLeft(2, '0');
    final eM = end.minute.toString().padLeft(2, '0');
    return '$sH:$sM – $eH:$eM น.';
  }

  /// Formats remaining minutes to "เหลืออีก X นาที" or "เหลืออีก X ชม. Y น."
  static String formatRemainingTime(int minutes) {
    if (minutes <= 0) return 'หมดเวลาแล้ว';
    if (minutes < 60) return 'เหลืออีก $minutes นาที';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return 'เหลืออีก $hours ชม.';
    return 'เหลืออีก $hours ชม. $mins น.';
  }

  /// Formats free gap duration into "ว่าง X ชม. Y น." per PLAN.md Section 7.1
  static String formatGap(int minutes) {
    if (minutes < 60) {
      return 'ว่าง $minutes น.';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) {
      return 'ว่าง $hours ชม.';
    }
    return 'ว่าง $hours ชม. $mins น.';
  }
}
