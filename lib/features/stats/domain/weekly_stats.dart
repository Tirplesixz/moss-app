import 'package:flutter/foundation.dart';
import '../../tasks/domain/task.dart';

@immutable
class DayCompletion {
  const DayCompletion({
    required this.dayLabel,
    required this.date,
    required this.count,
    this.isToday = false,
  });

  final String dayLabel;
  final DateTime date;
  final int count;
  final bool isToday;
}

@immutable
class WeeklyStats {
  const WeeklyStats({
    required this.totalCompleted,
    required this.totalActive,
    required this.streakDays,
    required this.completionRate,
    required this.quadrantCounts,
    required this.last7Days,
    required this.bestDayName,
  });

  final int totalCompleted;
  final int totalActive;
  final int streakDays;
  final double completionRate;
  final Map<int, int> quadrantCounts; // quadrant 1..4 -> count
  final List<DayCompletion> last7Days;
  final String bestDayName;

  static WeeklyStats calculate(List<Task> allTasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final completedTasks = allTasks.where((t) => t.isCompleted).toList();
    final activeTasks = allTasks.where((t) => !t.isCompleted).toList();

    // 1. Calculate streak
    final datesWithCompleted = completedTasks
        .map((t) {
          final d = t.updatedAt.toLocal();
          return DateTime(d.year, d.month, d.day);
        })
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final yesterday = today.subtract(const Duration(days: 1));
    var streak = 0;
    if (datesWithCompleted.contains(today) || datesWithCompleted.contains(yesterday)) {
      var check = datesWithCompleted.contains(today) ? today : yesterday;
      while (datesWithCompleted.contains(check)) {
        streak++;
        check = check.subtract(const Duration(days: 1));
      }
    }

    // 2. 7-Day Completion history (last 7 days ending today)
    const dayLabels = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];
    final history = <DayCompletion>[];
    var maxDayCount = -1;
    var bestDay = 'ยังไม่มีข้อมูล';

    for (var i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final count = completedTasks.where((t) {
        final d = t.updatedAt.toLocal();
        return d.year == day.year && d.month == day.month && d.day == day.day;
      }).length;

      final label = dayLabels[day.weekday - 1];
      history.add(
        DayCompletion(
          dayLabel: label,
          date: day,
          count: count,
          isToday: i == 0,
        ),
      );

      if (count > maxDayCount && count > 0) {
        maxDayCount = count;
        bestDay = 'วัน${_thaiWeekdayFull(day.weekday)} ($count งาน)';
      }
    }

    // 3. Quadrant breakdown of completed tasks
    final qCounts = {1: 0, 2: 0, 3: 0, 4: 0};
    for (final task in completedTasks) {
      final q = task.quadrant.clamp(1, 4);
      qCounts[q] = (qCounts[q] ?? 0) + 1;
    }

    final totalAll = completedTasks.length + activeTasks.length;
    final rate = totalAll == 0 ? 0.0 : (completedTasks.length / totalAll);

    return WeeklyStats(
      totalCompleted: completedTasks.length,
      totalActive: activeTasks.length,
      streakDays: streak,
      completionRate: rate,
      quadrantCounts: qCounts,
      last7Days: history,
      bestDayName: bestDay,
    );
  }

  static String _thaiWeekdayFull(int weekday) => switch (weekday) {
    1 => 'จันทร์',
    2 => 'อังคาร',
    3 => 'พุธ',
    4 => 'พฤหัสบดี',
    5 => 'ศุกร์',
    6 => 'เสาร์',
    _ => 'อาทิตย์',
  };
}
