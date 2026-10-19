import 'package:flutter_test/flutter_test.dart';
import 'package:moss/features/tasks/domain/task.dart';

void main() {
  group('ChecklistItem', () {
    test('serialization round-trip toMap and fromMap', () {
      const item = ChecklistItem(id: 'check-1', title: 'ขั้นที่ 1', done: true);
      final map = item.toMap();
      expect(map['id'], 'check-1');
      expect(map['title'], 'ขั้นที่ 1');
      expect(map['done'], true);

      final revived = ChecklistItem.fromMap(map);
      expect(revived, equals(item));
      expect(revived.done, isTrue);
    });

    test('copyWith updates fields correctly', () {
      const item = ChecklistItem(id: 'c1', title: 'เก่า', done: false);
      final updated = item.copyWith(done: true, title: 'ใหม่');
      expect(updated.id, 'c1');
      expect(updated.title, 'ใหม่');
      expect(updated.done, isTrue);
    });
  });

  group('Task checklist & priority', () {
    test('defaults to normal priority and empty checklist', () {
      final now = DateTime.utc(2026, 10, 15);
      final task = Task(
        id: 't1',
        title: 'งานตัวอย่าง',
        durationMin: 30,
        createdAt: now,
        updatedAt: now,
      );

      expect(task.priority, 2);
      expect(task.checklist, isEmpty);
      expect(task.checklistDone, 0);
    });

    test('calculates checklistDone correctly', () {
      final now = DateTime.utc(2026, 10, 15);
      final task = Task(
        id: 't2',
        title: 'งานหลายขั้นตอน',
        durationMin: 45,
        priority: 3,
        checklist: const [
          ChecklistItem(id: 'c1', title: '1', done: true),
          ChecklistItem(id: 'c2', title: '2', done: false),
          ChecklistItem(id: 'c3', title: '3', done: true),
        ],
        createdAt: now,
        updatedAt: now,
      );

      expect(task.checklist.length, 3);
      expect(task.checklistDone, 2);
    });

    test('copyWith retains or updates checklist', () {
      final now = DateTime.utc(2026, 10, 15);
      final task = Task(
        id: 't3',
        title: 'งาน',
        durationMin: 30,
        checklist: const [ChecklistItem(id: 'c1', title: '1', done: false)],
        createdAt: now,
        updatedAt: now,
      );

      final updated = task.copyWith(
        checklist: const [
          ChecklistItem(id: 'c1', title: '1', done: true),
          ChecklistItem(id: 'c2', title: '2', done: false),
        ],
      );

      expect(updated.checklist.length, 2);
      expect(updated.checklistDone, 1);
    });
  });
}
