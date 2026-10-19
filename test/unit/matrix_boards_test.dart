import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moss/features/tasks/data/board_repository.dart';
import 'package:moss/features/tasks/domain/matrix_board.dart';
import 'package:moss/features/tasks/presentation/matrix_boards_controller.dart';

import '../helpers/test_database.dart';

void main() {
  group('MatrixBoard Domain & Repository Tests', () {
    test('creates and serializes default boards correctly', () {
      final defaults = MatrixBoard.createDefaults();
      expect(defaults.length, 4);
      final myMatrix = defaults.first;
      expect(myMatrix.name, 'เมทริกซ์ของฉัน');
      expect(myMatrix.isDefault, isTrue);

      final map = myMatrix.toMap();
      final fromMap = MatrixBoard.fromMap(map);
      expect(fromMap.id, myMatrix.id);
      expect(fromMap.name, myMatrix.name);
      expect(fromMap.q1Name, myMatrix.q1Name);
      expect(fromMap.q2Name, myMatrix.q2Name);
      expect(fromMap.q3Name, myMatrix.q3Name);
      expect(fromMap.q4Name, myMatrix.q4Name);
      expect(fromMap.isDefault, isTrue);
    });

    test('BoardRepository persists default boards and supports custom boards', () async {
      final appDb = await createTestDatabase();
      final repo = BoardRepository(appDb);

      final initialBoards = await repo.getAllBoards();
      expect(initialBoards.length, 4);

      final now = DateTime.now().toUtc();
      final customBoard = MatrixBoard(
        id: 'board_freelance',
        name: 'งานฟรีแลนซ์',
        iconCode: Icons.rocket_launch_outlined.codePoint,
        colorValue: 0xFFFF9F0A,
        q1Name: 'ส่งงานด่วน',
        q2Name: 'เริ่มโปรเจกต์ใหม่',
        q3Name: 'ตอบอีเมลลูกค้า',
        q4Name: 'เขียนบล็อก',
        createdAt: now,
        updatedAt: now,
      );

      await repo.saveBoard(customBoard);
      final all = await repo.getAllBoards();
      expect(all.length, 5);

      final found = await repo.getBoardById('board_freelance');
      expect(found, isNotNull);
      expect(found!.name, 'งานฟรีแลนซ์');
      expect(found.q1Name, 'ส่งงานด่วน');

      // Update quadrant titles
      final updated = found.copyWith(q1Name: 'ส่งมอบงานภายใน 2 ชม.');
      await repo.updateBoard(updated);

      final reloaded = await repo.getBoardById('board_freelance');
      expect(reloaded!.q1Name, 'ส่งมอบงานภายใน 2 ชม.');

      // Soft delete
      await repo.deleteBoard('board_freelance');
      final afterDelete = await repo.getAllBoards();
      expect(afterDelete.length, 4);
    });

    test('MatrixBoardsController manages active board and CRUD transitions', () async {
      final appDb = await createTestDatabase();
      final repo = BoardRepository(appDb);
      final controller = MatrixBoardsController(repo);

      await controller.load();
      expect(controller.state.boards.length, 4);
      expect(controller.state.activeBoard.name, 'เมทริกซ์ของฉัน');

      // Select another board
      final workBoard = controller.state.boards.firstWhere((b) => b.name == 'งานและออฟฟิศ');
      controller.selectBoard(workBoard);
      expect(controller.state.activeBoard.id, workBoard.id);

      // Create board via controller
      final newBoard = await controller.createBoard(
        name: 'ธุรกิจส่วนตัว',
        iconCode: Icons.star_outline_rounded.codePoint,
        colorValue: 0xFFAF52DE,
        q1Name: 'แก้ไขบั๊กวิกฤต',
        q2Name: 'วางกลยุทธ์ไตรมาส',
        q3Name: 'จัดเอกสารภาษี',
        q4Name: 'ศึกษาคู่แข่ง',
      );

      expect(controller.state.activeBoard.id, newBoard.id);
      expect(controller.state.boards.length, 5);

      // Update via controller
      await controller.updateBoard(newBoard.copyWith(name: 'ธุรกิจสตาร์ทอัพ'));
      expect(controller.state.activeBoard.name, 'ธุรกิจสตาร์ทอัพ');

      // Delete active board via controller: should fallback to first board
      await controller.deleteBoard(newBoard.id);
      expect(controller.state.boards.length, 4);
      expect(controller.state.activeBoard.isDefault, isTrue);
    });
  });
}
