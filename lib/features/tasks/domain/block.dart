import 'package:flutter/foundation.dart';
import '../../../core/utils/time_utils.dart';

enum BlockKind {
  task('task'),
  fixed('fixed');

  final String value;
  const BlockKind(this.value);

  static BlockKind fromString(String val) {
    return BlockKind.values.firstWhere(
      (e) => e.value == val,
      orElse: () => BlockKind.task,
    );
  }
}

/// Block entity as specified in PLAN.md Section 5.
@immutable
class Block {
  final String id;
  final BlockKind kind; // 'task' | 'fixed'
  final String? taskId; // references Task.id, nullable
  final String? title; // fixed block title or override
  final DateTime startAt; // UTC
  final DateTime endAt; // UTC
  final bool locked; // whether block is pinned
  final String source; // 'local' | 'google'
  final String? externalId;
  final DateTime createdAt; // UTC
  final DateTime updatedAt; // UTC
  final DateTime? deletedAt; // UTC for soft delete

  const Block({
    required this.id,
    required this.kind,
    this.taskId,
    this.title,
    required this.startAt,
    required this.endAt,
    this.locked = false,
    this.source = 'local',
    this.externalId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;
  bool get isFixed => kind == BlockKind.fixed;
  bool get isTask => kind == BlockKind.task;

  int get durationMin => endAt.difference(startAt).inMinutes;

  Block copyWith({
    String? id,
    BlockKind? kind,
    String? Function()? taskId,
    String? Function()? title,
    DateTime? startAt,
    DateTime? endAt,
    bool? locked,
    String? source,
    String? Function()? externalId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? Function()? deletedAt,
  }) {
    return Block(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      taskId: taskId != null ? taskId() : this.taskId,
      title: title != null ? title() : this.title,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      locked: locked ?? this.locked,
      source: source ?? this.source,
      externalId: externalId != null ? externalId() : this.externalId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt != null ? deletedAt() : this.deletedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kind': kind.value,
      'taskId': taskId,
      'title': title,
      'startAt': TimeUtils.toUtcIsoString(startAt),
      'endAt': TimeUtils.toUtcIsoString(endAt),
      'locked': locked ? 1 : 0,
      'source': source,
      'externalId': externalId,
      'createdAt': TimeUtils.toUtcIsoString(createdAt),
      'updatedAt': TimeUtils.toUtcIsoString(updatedAt),
      'deletedAt': deletedAt != null
          ? TimeUtils.toUtcIsoString(deletedAt!)
          : null,
    };
  }

  factory Block.fromMap(Map<String, dynamic> map) {
    return Block(
      id: map['id'] as String,
      kind: BlockKind.fromString(map['kind'] as String? ?? 'task'),
      taskId: map['taskId'] as String?,
      title: map['title'] as String?,
      startAt: TimeUtils.parseUtc(map['startAt'] as String),
      endAt: TimeUtils.parseUtc(map['endAt'] as String),
      locked: (map['locked'] as int? ?? 0) == 1,
      source: map['source'] as String? ?? 'local',
      externalId: map['externalId'] as String?,
      createdAt: TimeUtils.parseUtc(map['createdAt'] as String),
      updatedAt: TimeUtils.parseUtc(map['updatedAt'] as String),
      deletedAt: map['deletedAt'] != null
          ? TimeUtils.parseUtc(map['deletedAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Block &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          kind == other.kind &&
          taskId == other.taskId &&
          title == other.title &&
          startAt == other.startAt &&
          endAt == other.endAt &&
          locked == other.locked &&
          source == other.source &&
          externalId == other.externalId &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      kind.hashCode ^
      taskId.hashCode ^
      title.hashCode ^
      startAt.hashCode ^
      endAt.hashCode ^
      locked.hashCode ^
      source.hashCode ^
      externalId.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      deletedAt.hashCode;
}
