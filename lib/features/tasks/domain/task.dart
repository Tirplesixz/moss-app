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

/// One sub-step inside a task's checklist.
@immutable
class ChecklistItem {
  final String id;
  final String title;
  final bool done;

  const ChecklistItem({
    required this.id,
    required this.title,
    this.done = false,
  });

  ChecklistItem copyWith({String? title, bool? done}) => ChecklistItem(
    id: id,
    title: title ?? this.title,
    done: done ?? this.done,
  );

  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'done': done};

  factory ChecklistItem.fromMap(Map<String, dynamic> map) => ChecklistItem(
    id: map['id'] as String,
    title: map['title'] as String,
    done: map['done'] as bool? ?? false,
  );

  @override
  bool operator ==(Object other) =>
      other is ChecklistItem &&
      other.id == id &&
      other.title == title &&
      other.done == done;

  @override
  int get hashCode => Object.hash(id, title, done);
}

/// Quadrant of the Eisenhower Matrix from reference screenshots.
enum MatrixQuadrant {
  urgentAndImportant(1, 'สำคัญและเร่งด่วน', 3),
  important(2, 'สำคัญ', 2),
  urgent(3, 'เร่งด่วน', 3),
  someday(4, 'สักวันหนึ่ง', 1);

  final int id;
  final String label;
  final int priority;
  const MatrixQuadrant(this.id, this.label, this.priority);

  static MatrixQuadrant fromId(int? id) {
    return MatrixQuadrant.values.firstWhere(
      (q) => q.id == id,
      orElse: () => MatrixQuadrant.urgentAndImportant,
    );
  }
}

/// Stable persistence values for recurrence. Thai labels belong to the UI;
/// accepting legacy labels here keeps existing databases backward compatible.
enum TaskRepeatRule {
  daily('daily', 'ทุกวัน'),
  weekdays('weekdays', 'วันธรรมดา (จ-ศ)'),
  weekly('weekly', 'ทุกสัปดาห์'),
  biweekly('biweekly', 'ทุก 2 สัปดาห์'),
  monthly('monthly', 'ทุกเดือน'),
  yearly('yearly', 'ทุกปี');

  const TaskRepeatRule(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static TaskRepeatRule? fromStored(String? value) {
    if (value == null ||
        value.isEmpty ||
        value == 'ไม่เคย' ||
        value == 'never') {
      return null;
    }
    for (final rule in values) {
      if (rule.storageValue == value || rule.label == value) return rule;
    }
    return null;
  }

  static TaskRepeatRule? fromLabel(String value) {
    for (final rule in values) {
      if (rule.label == value) return rule;
    }
    return null;
  }

  static String? normalizeStored(String? value) =>
      fromStored(value)?.storageValue;
}

/// Task entity as specified in PLAN.md Section 5 and reference design.
@immutable
class Task {
  final String id;
  final String title;
  final String? note;
  final int durationMin;
  final DateTime? deadlineAt; // UTC
  final int priority; // 1-3, default 2
  final int quadrant; // 1-4 Eisenhower matrix quadrant
  final String? projectName;
  final List<ChecklistItem> checklist;
  final String? repeatRule;
  final String? calendarEventId;
  final TaskStatus status;
  final DateTime createdAt; // UTC
  final DateTime updatedAt; // UTC
  final DateTime? deletedAt; // UTC for soft delete

  const Task({
    required this.id,
    required this.title,
    this.note,
    required this.durationMin,
    this.deadlineAt,
    this.priority = 2,
    this.quadrant = 1,
    this.projectName,
    this.checklist = const [],
    this.repeatRule,
    this.calendarEventId,
    this.status = TaskStatus.todo,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;
  bool get isCompleted => status == TaskStatus.done;
  int get checklistDone => checklist.where((item) => item.done).length;

  Task copyWith({
    String? id,
    String? title,
    String? Function()? note,
    int? durationMin,
    DateTime? Function()? deadlineAt,
    int? priority,
    int? quadrant,
    String? Function()? projectName,
    List<ChecklistItem>? checklist,
    String? Function()? repeatRule,
    String? Function()? calendarEventId,
    TaskStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? Function()? deletedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note != null ? note() : this.note,
      durationMin: durationMin ?? this.durationMin,
      deadlineAt: deadlineAt != null ? deadlineAt() : this.deadlineAt,
      priority: priority ?? this.priority,
      quadrant: quadrant ?? this.quadrant,
      projectName: projectName != null ? projectName() : this.projectName,
      checklist: checklist ?? this.checklist,
      repeatRule: repeatRule != null ? repeatRule() : this.repeatRule,
      calendarEventId: calendarEventId != null
          ? calendarEventId()
          : this.calendarEventId,
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
      'note': note,
      'durationMin': durationMin,
      'deadlineAt': deadlineAt != null
          ? TimeUtils.toUtcIsoString(deadlineAt!)
          : null,
      'priority': priority,
      'quadrant': quadrant,
      'projectName': projectName,
      'checklist': checklist.map((item) => item.toMap()).toList(),
      'repeatRule': TaskRepeatRule.normalizeStored(repeatRule),
      'calendarEventId': calendarEventId,
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
      note: map['note'] as String?,
      durationMin: map['durationMin'] as int,
      deadlineAt: map['deadlineAt'] != null
          ? TimeUtils.parseUtc(map['deadlineAt'] as String)
          : null,
      priority: map['priority'] as int? ?? 2,
      quadrant:
          map['quadrant'] as int? ??
          (map['priority'] == 3 ? 1 : (map['priority'] == 1 ? 2 : 1)),
      projectName: map['projectName'] as String?,
      checklist: [
        for (final raw in (map['checklist'] as List<dynamic>? ?? const []))
          ChecklistItem.fromMap(Map<String, dynamic>.from(raw as Map)),
      ],
      repeatRule: TaskRepeatRule.normalizeStored(
        map['repeatRule'] as String? ?? map['repeat_rule'] as String?,
      ),
      calendarEventId:
          map['calendarEventId'] as String? ??
          map['calendar_event_id'] as String?,
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
          note == other.note &&
          durationMin == other.durationMin &&
          deadlineAt == other.deadlineAt &&
          priority == other.priority &&
          quadrant == other.quadrant &&
          projectName == other.projectName &&
          listEquals(checklist, other.checklist) &&
          repeatRule == other.repeatRule &&
          calendarEventId == other.calendarEventId &&
          status == other.status &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      (note?.hashCode ?? 0) ^
      durationMin.hashCode ^
      deadlineAt.hashCode ^
      priority.hashCode ^
      quadrant.hashCode ^
      projectName.hashCode ^
      Object.hashAll(checklist) ^
      (repeatRule?.hashCode ?? 0) ^
      (calendarEventId?.hashCode ?? 0) ^
      status.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      deletedAt.hashCode;
}
