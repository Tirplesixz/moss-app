import 'package:flutter/foundation.dart';
import '../../../core/utils/time_utils.dart';

/// Application settings as specified in PLAN.md Section 5.
@immutable
class AppSettings {
  final String id;
  final String workdayStart; // '09:00'
  final String workdayEnd; // '18:00'
  final int bufferMin; // e.g. 5 min
  final String timezone; // e.g. 'Asia/Bangkok'
  final bool onboardingComplete;
  final int paywallInterestCount;

  /// Persisted visual preference: system, light, or dark.
  final String appearanceMode;
  final bool saveCompletedToCalendar;
  final DateTime updatedAt; // UTC
  final DateTime? deletedAt; // UTC for soft delete

  const AppSettings({
    required this.id,
    this.workdayStart = '09:00',
    this.workdayEnd = '18:00',
    this.bufferMin = 5,
    this.timezone = 'Asia/Bangkok',
    this.onboardingComplete = false,
    this.paywallInterestCount = 0,
    this.appearanceMode = 'system',
    this.saveCompletedToCalendar = true,
    required this.updatedAt,
    this.deletedAt,
  });

  static AppSettings createDefault({String id = 'default_settings'}) {
    final now = TimeUtils.nowUtc();
    return AppSettings(
      id: id,
      workdayStart: '09:00',
      workdayEnd: '18:00',
      bufferMin: 5,
      timezone: 'Asia/Bangkok',
      onboardingComplete: false,
      paywallInterestCount: 0,
      appearanceMode: 'system',
      saveCompletedToCalendar: true,
      updatedAt: now,
    );
  }

  bool get isDeleted => deletedAt != null;

  AppSettings copyWith({
    String? id,
    String? workdayStart,
    String? workdayEnd,
    int? bufferMin,
    String? timezone,
    bool? onboardingComplete,
    int? paywallInterestCount,
    String? appearanceMode,
    bool? saveCompletedToCalendar,
    DateTime? updatedAt,
    DateTime? Function()? deletedAt,
  }) {
    return AppSettings(
      id: id ?? this.id,
      workdayStart: workdayStart ?? this.workdayStart,
      workdayEnd: workdayEnd ?? this.workdayEnd,
      bufferMin: bufferMin ?? this.bufferMin,
      timezone: timezone ?? this.timezone,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      paywallInterestCount: paywallInterestCount ?? this.paywallInterestCount,
      appearanceMode: appearanceMode ?? this.appearanceMode,
      saveCompletedToCalendar:
          saveCompletedToCalendar ?? this.saveCompletedToCalendar,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt != null ? deletedAt() : this.deletedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workdayStart': workdayStart,
      'workdayEnd': workdayEnd,
      'bufferMin': bufferMin,
      'timezone': timezone,
      'onboardingComplete': onboardingComplete,
      'paywallInterestCount': paywallInterestCount,
      'appearanceMode': appearanceMode,
      'saveCompletedToCalendar': saveCompletedToCalendar,
      'updatedAt': TimeUtils.toUtcIsoString(updatedAt),
      'deletedAt': deletedAt != null
          ? TimeUtils.toUtcIsoString(deletedAt!)
          : null,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      id: map['id'] as String,
      workdayStart: map['workdayStart'] as String? ?? '09:00',
      workdayEnd: map['workdayEnd'] as String? ?? '18:00',
      bufferMin: map['bufferMin'] as int? ?? 5,
      timezone: map['timezone'] as String? ?? 'Asia/Bangkok',
      onboardingComplete: map['onboardingComplete'] as bool? ?? false,
      paywallInterestCount: map['paywallInterestCount'] as int? ?? 0,
      appearanceMode: map['appearanceMode'] as String? ?? 'system',
      saveCompletedToCalendar: map['saveCompletedToCalendar'] as bool? ?? false,
      updatedAt: TimeUtils.parseUtc(map['updatedAt'] as String),
      deletedAt: map['deletedAt'] != null
          ? TimeUtils.parseUtc(map['deletedAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workdayStart == other.workdayStart &&
          workdayEnd == other.workdayEnd &&
          bufferMin == other.bufferMin &&
          timezone == other.timezone &&
          onboardingComplete == other.onboardingComplete &&
          paywallInterestCount == other.paywallInterestCount &&
          appearanceMode == other.appearanceMode &&
          saveCompletedToCalendar == other.saveCompletedToCalendar &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      workdayStart.hashCode ^
      workdayEnd.hashCode ^
      bufferMin.hashCode ^
      timezone.hashCode ^
      onboardingComplete.hashCode ^
      paywallInterestCount.hashCode ^
      appearanceMode.hashCode ^
      saveCompletedToCalendar.hashCode ^
      updatedAt.hashCode ^
      deletedAt.hashCode;
}
