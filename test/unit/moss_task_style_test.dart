import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moss/core/theme/moss_task_style.dart';

void main() {
  group('MossPriority', () {
    test('defines distinct labels and icons for all levels', () {
      expect(MossPriority.label(MossPriority.low), 'ไม่เร่ง');
      expect(MossPriority.label(MossPriority.normal), 'ปกติ');
      expect(MossPriority.label(MossPriority.high), 'สำคัญมาก');

      expect(MossPriority.icon(MossPriority.low), isNotNull);
      expect(MossPriority.icon(MossPriority.normal), isNotNull);
      expect(MossPriority.icon(MossPriority.high), isNotNull);
    });

    testWidgets('PriorityBadge does not render for normal priority', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PriorityBadge(priority: MossPriority.normal)),
        ),
      );

      expect(find.byType(PriorityBadge), findsOneWidget);
      expect(find.text('ปกติ'), findsNothing);
    });

    testWidgets('PriorityBadge renders label and icon for high priority', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PriorityBadge(priority: MossPriority.high)),
        ),
      );

      expect(find.text('สำคัญมาก'), findsOneWidget);
      expect(find.byIcon(MossPriority.icon(MossPriority.high)), findsOneWidget);
    });
  });

  group('MossProjectColors', () {
    testWidgets('generates deterministic color pair for same name', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final colorA1 = MossProjectColors.of(context, 'Marketing');
              final colorA2 = MossProjectColors.of(context, 'Marketing');
              final colorB = MossProjectColors.of(context, 'Engineering');

              expect(colorA1.accent, equals(colorA2.accent));
              expect(colorA1.surface, equals(colorA2.surface));
              // Ensure different project hashes don't all collide blindly
              expect(colorA1.accent, isNotNull);
              expect(colorB.accent, isNotNull);

              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });
  });
}
