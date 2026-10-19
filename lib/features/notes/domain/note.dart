import 'package:flutter/foundation.dart';

@immutable
class Note {
  const Note({
    required this.id,
    required this.title,
    this.content = '',
    this.colorValue = 0xFFFFFFFF,
    this.pinned = false,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String title;
  final String content;
  final int colorValue;
  final bool pinned;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Note copyWith({
    String? title,
    String? content,
    int? colorValue,
    bool? pinned,
    DateTime? updatedAt,
    DateTime? Function()? deletedAt,
  }) => Note(
    id: id,
    title: title ?? this.title,
    content: content ?? this.content,
    colorValue: colorValue ?? this.colorValue,
    pinned: pinned ?? this.pinned,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt == null ? this.deletedAt : deletedAt(),
  );
}
