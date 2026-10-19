import 'package:characters/characters.dart';

abstract final class InputLimits {
  static const taskTitle = 120;
  static const taskNote = 4000;
  static const projectName = 80;
  static const checklistItem = 200;
  static const noteTitle = 120;
  static const noteContent = 10000;

  static void requireNonBlank(String value, String field) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, field, 'must not be blank');
    }
  }

  static void requireAtMost(String value, int limit, String field) {
    if (value.characters.length > limit) {
      throw ArgumentError.value(
        value,
        field,
        'must be at most $limit characters',
      );
    }
  }
}
