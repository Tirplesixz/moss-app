import 'package:flutter/foundation.dart';
import '../../../core/utils/time_utils.dart';

enum NotifType {
  start('start'),
  deadline('deadline');

  final String value;
  const NotifType(this.value);

  static NotifType fromString(String val) {
    return NotifType.values.firstWhere(
      (e) => e.value == val,
      orElse: () => NotifType.start,
    );
  }
}

/// Notification scheduling metadata entity as specified in PLAN.md Section 5.
@immutable
class Notif {
  final String id;
  final String blockId; // references Block.id
  final NotifType type; // 'start' | 'deadline'
  final DateTime fireAt; // UTC
  final int osNotifId;
  final DateTime createdAt; // UTC
  final DateTime updatedAt; // UTC
  final DateTime? deletedAt; // UTC for soft delete

  const Notif({
    required this.id,
    required this.blockId,
    required this.type,
    required this.fireAt,
    required this.osNotifId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Notif copyWith({
    String? id,
    String? blockId,
    NotifType? type,
    DateTime? fireAt,
    int? osNotifId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? Function()? deletedAt,
  }) {
    return Notif(
      id: id ?? this.id,
      blockId: blockId ?? this.blockId,
      type: type ?? this.type,
      fireAt: fireAt ?? this.fireAt,
      osNotifId: osNotifId ?? this.osNotifId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt != null ? deletedAt() : this.deletedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'blockId': blockId,
      'type': type.value,
      'fireAt': TimeUtils.toUtcIsoString(fireAt),
      'osNotifId': osNotifId,
      'createdAt': TimeUtils.toUtcIsoString(createdAt),
      'updatedAt': TimeUtils.toUtcIsoString(updatedAt),
      'deletedAt': deletedAt != null
          ? TimeUtils.toUtcIsoString(deletedAt!)
          : null,
    };
  }

  factory Notif.fromMap(Map<String, dynamic> map) {
    return Notif(
      id: map['id'] as String,
      blockId: map['blockId'] as String,
      type: NotifType.fromString(map['type'] as String? ?? 'start'),
      fireAt: TimeUtils.parseUtc(map['fireAt'] as String),
      osNotifId: map['osNotifId'] as int,
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
      other is Notif &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          blockId == other.blockId &&
          type == other.type &&
          fireAt == other.fireAt &&
          osNotifId == other.osNotifId &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      blockId.hashCode ^
      type.hashCode ^
      fireAt.hashCode ^
      osNotifId.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      deletedAt.hashCode;
}
