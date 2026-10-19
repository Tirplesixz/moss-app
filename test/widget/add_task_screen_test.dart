import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moss/core/theme/app_theme.dart';
import 'package:moss/features/tasks/domain/task.dart';
import 'package:moss/features/tasks/presentation/screens/add_task_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:timezone/data/latest_all.dart' as tz;

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tz.initializeTimeZones();
  });

  testWidgets(
    'AddTaskScreen renders modern iOS modal and creates task on confirm',
    (WidgetTester tester) async {
      Task? createdTask;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  createdTask = await AddTaskScreen.show(context) as Task?;
                },
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      // Tap to open modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Check header
      expect(find.text('งานใหม่'), findsOneWidget);

      // Enter title
      final titleField = find
          .descendant(
            of: find.byType(AddTaskScreen),
            matching: find.byType(TextField),
          )
          .first;
      await tester.enterText(titleField, 'ส่งสไลด์ให้ลูกค้า');
      await tester.pump();

      // Tap confirm checkmark button
      final checkmarkButton = find
          .descendant(
            of: find.byType(AddTaskScreen),
            matching: find.byIcon(Icons.check_rounded),
          )
          .first;
      await tester.tap(checkmarkButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(createdTask, isNotNull);
      expect(createdTask!.title, 'ส่งสไลด์ให้ลูกค้า');
    },
  );

  testWidgets(
    'AddTaskScreen loads prefill data and updates task in edit mode',
    (WidgetTester tester) async {
      Task? updatedTask;
      final existingTask = Task(
        id: 'test-edit-id',
        title: 'งานเดิมก่อนแก้ไข',
        note: 'โน้ตเดิม',
        durationMin: 30,
        quadrant: 2,
        priority: 2,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  updatedTask =
                      await AddTaskScreen.show(context, editTask: existingTask)
                          as Task?;
                },
                child: const Text('Open Edit Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Edit Modal'));
      await tester.pumpAndSettle();

      expect(find.text('แก้ไขงาน'), findsOneWidget);
      expect(find.text('งานเดิมก่อนแก้ไข'), findsOneWidget);

      final titleField = find
          .descendant(
            of: find.byType(AddTaskScreen),
            matching: find.byType(TextField),
          )
          .first;
      await tester.enterText(titleField, 'งานที่แก้ไขแล้ว');
      await tester.pump();

      final checkmarkButton = find
          .descendant(
            of: find.byType(AddTaskScreen),
            matching: find.byIcon(Icons.check_rounded),
          )
          .first;
      await tester.tap(checkmarkButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(updatedTask, isNotNull);
      expect(updatedTask!.id, 'test-edit-id');
      expect(updatedTask!.title, 'งานที่แก้ไขแล้ว');
    },
  );
}
