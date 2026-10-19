import 'package:flutter_test/flutter_test.dart';
import 'package:moss/features/stats/domain/weekly_stats.dart';
import 'package:moss/features/tasks/domain/task.dart';

void main() {
  group('WeeklyStats', () {
    test('calculates zero state correctly when there are no tasks', () {
      final stats = WeeklyStats.calculate(const []);
      expect(stats.totalCompleted, 0);
      expect(stats.totalActive, 0);
      expect(stats.streakDays, 0);
      expect(stats.completionRate, 0.0);
      expect(stats.quadrantCounts[1], 0);
      expect(stats.quadrantCounts[2], 0);
      expect(stats.last7Days.length, 7);
      expect(stats.last7Days.last.isToday, isTrue);
    });

    test('calculates streak and 7-day history correctly', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 14, 0);
      final yesterday = today.subtract(const Duration(days: 1));
      final twoDaysAgo = today.subtract(const Duration(days: 2));

      final tasks = [
        Task(
          id: 't1',
          title: 'งานวันนี้ Q1',
          durationMin: 30,
          quadrant: 1,
          status: TaskStatus.done,
          createdAt: today.toUtc(),
          updatedAt: today.toUtc(),
        ),
        Task(
          id: 't2',
          title: 'งานวันนี้ Q2',
          durationMin: 45,
          quadrant: 2,
          status: TaskStatus.done,
          createdAt: today.toUtc(),
          updatedAt: today.toUtc(),
        ),
        Task(
          id: 't3',
          title: 'งานเมื่อวาน Q2',
          durationMin: 60,
          quadrant: 2,
          status: TaskStatus.done,
          createdAt: yesterday.toUtc(),
          updatedAt: yesterday.toUtc(),
        ),
        Task(
          id: 't4',
          title: 'งานสองวันก่อน Q3',
          durationMin: 20,
          quadrant: 3,
          status: TaskStatus.done,
          createdAt: twoDaysAgo.toUtc(),
          updatedAt: twoDaysAgo.toUtc(),
        ),
        Task(
          id: 't5',
          title: 'งานที่ยังไม่เสร็จ',
          durationMin: 30,
          quadrant: 1,
          status: TaskStatus.todo,
          createdAt: today.toUtc(),
          updatedAt: today.toUtc(),
        ),
      ];

      final stats = WeeklyStats.calculate(tasks);
      expect(stats.totalCompleted, 4);
      expect(stats.totalActive, 1);
      expect(stats.streakDays, 3); // today, yesterday, 2 days ago
      expect(stats.completionRate, 4 / 5);
      expect(stats.quadrantCounts[1], 1);
      expect(stats.quadrantCounts[2], 2);
      expect(stats.quadrantCounts[3], 1);
      expect(stats.quadrantCounts[4], 0);

      // Today's count in last7Days should be 2
      final todayRecord = stats.last7Days.last;
      expect(todayRecord.count, 2);
      expect(todayRecord.isToday, isTrue);

      // Best day should contain '(2 งาน)'
      expect(stats.bestDayName, contains('2 งาน'));
    });
  });
}
