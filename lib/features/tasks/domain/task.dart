import 'package:flutter/foundation.dart';
import '../../../core/utils/time_utils.dart';

/// Task status options defined in PLAN.md Section 5.
enum TaskStatus {
  todo('todo'),
  done('done'),
  dropped('dropped');

  final String value;
  const TaskStatus(this.value);

  static TaskStatus fromString(String val) {
    return TaskStatus.values.firstWhere(
      (e) => e.value == val,
      orElse: () => TaskStatus.todo,
    );
  }
}

/// Task entity as specified in PLAN.md Section 5.
@immutable
class Task {
  final String id;
  final String title;
  final int durationMin;
  final DateTime? deadlineAt; // UTC
  final int priority; // 1-3, default 2
  final String? projectName;
  final TaskStatus status;
  final DateTime createdAt; // UTC
  final DateTime updatedAt; // UTC
  final DateTime? deletedAt; // UTC for soft delete

  const Task({
    required this.id,
    required this.title,
    required this.durationMin,
    this.deadlineAt,
    this.priority = 2,
    this.projectName,
    this.status = TaskStatus.todo,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;
  bool get isCompleted => status == TaskStatus.done;

  Task copyWith({
    String? id,
    String? title,
    int? durationMin,
    DateTime? Function()? deadlineAt,
    int? priority,
    String? Function()? projectName,
    TaskStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? Function()? deletedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      durationMin: durationMin ?? this.durationMin,
      deadlineAt: deadlineAt != null ? deadlineAt() : this.deadlineAt,
      priority: priority ?? this.priority,
      projectName: projectName != null ? projectName() : this.projectName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt != null ? deletedAt() : this.deletedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'durationMin': durationMin,
      'deadlineAt': deadlineAt != null
          ? TimeUtils.toUtcIsoString(deadlineAt!)
          : null,
      'priority': priority,
      'projectName': projectName,
      'status': status.value,
      'createdAt': TimeUtils.toUtcIsoString(createdAt),
      'updatedAt': TimeUtils.toUtcIsoString(updatedAt),
      'deletedAt': deletedAt != null
          ? TimeUtils.toUtcIsoString(deletedAt!)
          : null,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      durationMin: map['durationMin'] as int,
      deadlineAt: map['deadlineAt'] != null
          ? TimeUtils.parseUtc(map['deadlineAt'] as String)
          : null,
      priority: map['priority'] as int? ?? 2,
      projectName: map['projectName'] as String?,
      status: TaskStatus.fromString(map['status'] as String? ?? 'todo'),
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
      other is Task &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          durationMin == other.durationMin &&
          deadlineAt == other.deadlineAt &&
          priority == other.priority &&
          projectName == other.projectName &&
          status == other.status &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      durationMin.hashCode ^
      deadlineAt.hashCode ^
      priority.hashCode ^
      projectName.hashCode ^
      status.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      deletedAt.hashCode;
}
