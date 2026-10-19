import 'package:flutter/foundation.dart';

@immutable
class LockScreenConfig {
  const LockScreenConfig({
    required this.templateId,
    required this.gradientStart,
    required this.gradientEnd,
    this.showClock = true,
    this.showProgress = true,
    this.showTasks = true,
    this.showCalendar = false,
    this.autoUpdate = false,
    this.taskLimit = 4,
    this.moduleOrder = const [
      'clock',
      'countdown',
      'progress',
      'year_progress',
      'tasks',
      'calendar',
      'note',
    ],
    this.verticalOffset = 0.0,
    this.showCountdown = false,
    this.countdownTitle = 'วันสำคัญ',
    this.countdownDate,
    this.showPinnedNote = false,
    this.pinnedNoteText = '',
    this.dimPastEvents = false,
    this.showYearProgress = false,
    this.paperStyle = 'plain',
    required this.updatedAt,
    this.lastRenderedAt,
  });

  static const activeId = 'active';

  final String templateId;
  final int gradientStart;
  final int gradientEnd;
  final bool showClock;
  final bool showProgress;
  final bool showTasks;
  final bool showCalendar;
  final bool autoUpdate;
  final int taskLimit;
  final List<String> moduleOrder;
  final double verticalOffset;
  final bool showCountdown;
  final String countdownTitle;
  final String? countdownDate;
  final bool showPinnedNote;
  final String pinnedNoteText;
  final bool dimPastEvents;
  final bool showYearProgress;
  final String paperStyle;
  final DateTime updatedAt;
  final DateTime? lastRenderedAt;

  factory LockScreenConfig.initial() => LockScreenConfig(
    templateId: 'midnight',
    gradientStart: 0xFF203B5E,
    gradientEnd: 0xFF0B1524,
    updatedAt: DateTime.now().toUtc(),
  );

  LockScreenConfig copyWith({
    String? templateId,
    int? gradientStart,
    int? gradientEnd,
    bool? showClock,
    bool? showProgress,
    bool? showTasks,
    bool? showCalendar,
    bool? autoUpdate,
    int? taskLimit,
    List<String>? moduleOrder,
    double? verticalOffset,
    bool? showCountdown,
    String? countdownTitle,
    String? countdownDate,
    bool? showPinnedNote,
    String? pinnedNoteText,
    bool? dimPastEvents,
    bool? showYearProgress,
    String? paperStyle,
    DateTime? updatedAt,
    DateTime? Function()? lastRenderedAt,
  }) => LockScreenConfig(
    templateId: templateId ?? this.templateId,
    gradientStart: gradientStart ?? this.gradientStart,
    gradientEnd: gradientEnd ?? this.gradientEnd,
    showClock: showClock ?? this.showClock,
    showProgress: showProgress ?? this.showProgress,
    showTasks: showTasks ?? this.showTasks,
    showCalendar: showCalendar ?? this.showCalendar,
    autoUpdate: autoUpdate ?? this.autoUpdate,
    taskLimit: taskLimit ?? this.taskLimit,
    moduleOrder: moduleOrder ?? this.moduleOrder,
    verticalOffset: verticalOffset ?? this.verticalOffset,
    showCountdown: showCountdown ?? this.showCountdown,
    countdownTitle: countdownTitle ?? this.countdownTitle,
    countdownDate: countdownDate ?? this.countdownDate,
    showPinnedNote: showPinnedNote ?? this.showPinnedNote,
    pinnedNoteText: pinnedNoteText ?? this.pinnedNoteText,
    dimPastEvents: dimPastEvents ?? this.dimPastEvents,
    showYearProgress: showYearProgress ?? this.showYearProgress,
    paperStyle: paperStyle ?? this.paperStyle,
    updatedAt: updatedAt ?? this.updatedAt,
    lastRenderedAt: lastRenderedAt != null
        ? lastRenderedAt()
        : this.lastRenderedAt,
  );

  @override
  bool operator ==(Object other) =>
      other is LockScreenConfig &&
      other.templateId == templateId &&
      other.gradientStart == gradientStart &&
      other.gradientEnd == gradientEnd &&
      other.showClock == showClock &&
      other.showProgress == showProgress &&
      other.showTasks == showTasks &&
      other.showCalendar == showCalendar &&
      other.autoUpdate == autoUpdate &&
      other.taskLimit == taskLimit &&
      other.verticalOffset == verticalOffset &&
      other.showCountdown == showCountdown &&
      other.countdownTitle == countdownTitle &&
      other.countdownDate == countdownDate &&
      other.showPinnedNote == showPinnedNote &&
      other.pinnedNoteText == pinnedNoteText &&
      other.dimPastEvents == dimPastEvents &&
      other.showYearProgress == showYearProgress &&
      other.paperStyle == paperStyle &&
      listEquals(other.moduleOrder, moduleOrder);

  @override
  int get hashCode => Object.hash(
    templateId,
    gradientStart,
    gradientEnd,
    showClock,
    showProgress,
    showTasks,
    showCalendar,
    autoUpdate,
    taskLimit,
    verticalOffset,
    showCountdown,
    countdownTitle,
    countdownDate,
    showPinnedNote,
    pinnedNoteText,
    dimPastEvents,
    showYearProgress,
    paperStyle,
    Object.hashAll(moduleOrder),
  );
}

@immutable
class LockScreenPreset {
  const LockScreenPreset({
    required this.id,
    required this.name,
    required this.gradientStart,
    required this.gradientEnd,
    required this.category,
    this.showClock = true,
    this.showProgress = true,
    this.showTasks = true,
    this.showCalendar = false,
  });

  final String id;
  final String name;
  final int gradientStart;
  final int gradientEnd;
  final String category;
  final bool showClock;
  final bool showProgress;
  final bool showTasks;
  final bool showCalendar;

  LockScreenConfig toConfig() => LockScreenConfig(
    templateId: id,
    gradientStart: gradientStart,
    gradientEnd: gradientEnd,
    showClock: showClock,
    showProgress: showProgress,
    showTasks: showTasks,
    showCalendar: showCalendar,
    updatedAt: DateTime.now().toUtc(),
  );
}

const lockScreenPresets = <LockScreenPreset>[
  LockScreenPreset(
    id: 'midnight',
    name: 'Midnight Focus',
    gradientStart: 0xFF203B5E,
    gradientEnd: 0xFF0B1524,
    category: 'งาน',
  ),
  LockScreenPreset(
    id: 'latte',
    name: 'Warm Plan',
    gradientStart: 0xFF806C61,
    gradientEnd: 0xFF251D1A,
    category: 'ทั้งหมด',
  ),
  LockScreenPreset(
    id: 'forest',
    name: 'Forest Day',
    gradientStart: 0xFF315B50,
    gradientEnd: 0xFF0E211D,
    category: 'ธรรมชาติ',
    showProgress: false,
  ),
  LockScreenPreset(
    id: 'violet',
    name: 'Violet Month',
    gradientStart: 0xFF67557C,
    gradientEnd: 0xFF211A2A,
    category: 'ปฏิทิน',
    showTasks: false,
    showCalendar: true,
  ),
  LockScreenPreset(
    id: 'sunset',
    name: 'Sunset Progress',
    gradientStart: 0xFF8A5E3C,
    gradientEnd: 0xFF2D1D12,
    category: 'ทั้งหมด',
  ),
  LockScreenPreset(
    id: 'slate',
    name: 'Slate Agenda',
    gradientStart: 0xFF36415F,
    gradientEnd: 0xFF111725,
    category: 'ปฏิทิน',
    showCalendar: true,
  ),
  LockScreenPreset(
    id: 'weekflow',
    name: 'Week Flow',
    gradientStart: 0xFFC6501B,
    gradientEnd: 0xFF071D36,
    category: 'ปฏิทิน',
    showClock: false,
    showProgress: false,
    showTasks: false,
    showCalendar: true,
  ),
  LockScreenPreset(
    id: 'amoled',
    name: 'AMOLED Pure',
    gradientStart: 0xFF141416,
    gradientEnd: 0xFF050505,
    category: 'มินิมอล',
  ),
  LockScreenPreset(
    id: 'rose',
    name: 'Rose Clay',
    gradientStart: 0xFF8B4F58,
    gradientEnd: 0xFF2C161B,
    category: 'ทั้งหมด',
  ),
  LockScreenPreset(
    id: 'nordic',
    name: 'Nordic Glacier',
    gradientStart: 0xFF2C4A52,
    gradientEnd: 0xFF101B20,
    category: 'ธรรมชาติ',
  ),
];
