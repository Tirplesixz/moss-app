import 'package:flutter_test/flutter_test.dart';
import 'package:moss/features/notes/data/note_repository.dart';
import 'package:moss/features/notes/domain/note.dart';

import '../helpers/test_database.dart';

void main() {
  test('notes persist independently and pinned notes sort first', () async {
    final database = await createTestDatabase();
    final repository = NoteRepository(database);
    final now = DateTime.utc(2026, 10, 17);

    await repository.save(
      Note(id: 'plain', title: 'ไอเดีย', createdAt: now, updatedAt: now),
    );
    await repository.save(
      Note(
        id: 'pinned',
        title: 'ข้อมูลสำคัญ',
        content: 'รายละเอียด',
        pinned: true,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final notes = await repository.getActiveNotes();
    expect(notes, hasLength(2));
    expect(notes.first.id, 'pinned');
    expect(notes.first.content, 'รายละเอียด');

    await repository.delete('pinned');
    expect((await repository.getActiveNotes()).single.id, 'plain');
  });
}
