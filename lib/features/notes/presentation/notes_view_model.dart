import 'package:flutter/foundation.dart';

import '../data/note_repository.dart';
import '../domain/note.dart';

class NotesViewModel extends ChangeNotifier {
  NotesViewModel(this._repository);
  final NoteRepository _repository;

  List<Note> _notes = const [];
  bool _loading = true;
  Object? _error;

  List<Note> get notes => List.unmodifiable(_notes);
  bool get loading => _loading;
  Object? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _notes = await _repository.getActiveNotes();
    } catch (error) {
      _error = error;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> save(Note note) async {
    await _repository.save(note);
    await load();
  }

  Future<void> delete(Note note) async {
    await _repository.delete(note.id);
    await load();
  }

  Future<void> restore(Note note) async {
    await _repository.restore(note.id);
    await load();
  }

  Future<void> togglePin(Note note) =>
      save(note.copyWith(pinned: !note.pinned));
}
