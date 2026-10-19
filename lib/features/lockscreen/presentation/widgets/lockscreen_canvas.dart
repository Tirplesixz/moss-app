import 'package:flutter/material.dart';

import '../../../tasks/domain/task.dart';
import '../../../tasks/domain/block.dart';
import '../../domain/lockscreen_config.dart';

class LockScreenCanvas extends StatelessWidget {
  const LockScreenCanvas({
    super.key,
    required this.config,
    required this.tasks,
    this.blocks = const [],
    this.now,
    this.compact = false,
  });

  final LockScreenConfig config;
  final List<Task> tasks;
  final List<Block> blocks;
  final DateTime? now;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final date = now ?? DateTime.now();
    final scale = compact ? 0.54 : 1.0;
    return RepaintBoundary(
      child: AspectRatio(
        aspectRatio: 9 / 20,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: config.templateId == 'weekflow'
                  ? const [
                      Color(0xFFC6501B),
                      Color(0xFF7A174B),
                      Color(0xFF071D36),
                    ]
                  : [Color(config.gradientStart), Color(config.gradientEnd)],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24 * scale,
              (42 + config.verticalOffset * 0.22) * scale,
              24 * scale,
              28 * scale,
            ),
            child: DefaultTextStyle(
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'NotoSansThai',
                height: 1.25,
                fontSize: 15 * scale,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (config.templateId == 'weekflow') ...[
                    Text(
                      _dateLabel(date),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12 * scale,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 50 * scale,
                        height: 1.05,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -2 * scale,
                      ),
                    ),
                    SizedBox(height: 30 * scale),
                  ],
                  for (final module in config.moduleOrder)
                    ..._buildModule(module, date, scale),
                  if (!config.moduleOrder.contains('year_progress') &&
                      config.showYearProgress)
                    ..._buildModule('year_progress', date, scale),
                  const Spacer(),
                  Text(
                    'MOSS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.52),
                      fontSize: 10 * scale,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3 * scale,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildModule(String module, DateTime date, double scale) {
    switch (module) {
      case 'clock' when config.showClock:
        return [
          Text(
            _dateLabel(date),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14 * scale,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 58 * scale,
              height: 1.05,
              fontWeight: FontWeight.w700,
              letterSpacing: -2 * scale,
            ),
          ),
          SizedBox(height: 22 * scale),
        ];
      case 'countdown' when config.showCountdown:
        DateTime? target;
        if (config.countdownDate != null && config.countdownDate!.isNotEmpty) {
          target = DateTime.tryParse(config.countdownDate!);
        }
        target ??= DateTime(date.year, 12, 31);
        final diff = DateTime(target.year, target.month, target.day)
            .difference(DateTime(date.year, date.month, date.day))
            .inDays;
        final diffText = diff == 0
            ? 'วันนี้ 🎉'
            : (diff > 0 ? 'อีก $diff วัน' : 'ผ่านมา ${diff.abs()} วัน');
        return [
          _GlassPanel(
            scale: scale,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '⏳ ${config.countdownTitle}',
                      style: TextStyle(
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      diffText,
                      style: TextStyle(
                        fontSize: 15 * scale,
                        fontWeight: FontWeight.w700,
                        color: diff == 0 ? const Color(0xFFFFD54F) : Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4 * scale),
                Text(
                  'เป้าหมาย: ${target.day}/${target.month}/${target.year + 543}',
                  style: TextStyle(
                    fontSize: 11 * scale,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12 * scale),
        ];
      case 'note' when config.showPinnedNote && config.pinnedNoteText.isNotEmpty:
        Widget noteCard = _GlassPanel(
          scale: scale,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '📌 บันทึกปักหมุด',
                    style: TextStyle(
                      fontSize: 13 * scale,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (config.paperStyle != 'plain')
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 2 * scale),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4 * scale),
                      ),
                      child: Text(
                        config.paperStyle == 'tape'
                            ? 'TAPE'
                            : (config.paperStyle == 'lined' ? 'LINED' : 'GRID'),
                        style: TextStyle(
                          fontSize: 8 * scale,
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 6 * scale),
              Text(
                config.pinnedNoteText,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12 * scale,
                  color: Colors.white.withValues(alpha: 0.95),
                  height: config.paperStyle == 'lined' ? 1.45 : 1.25,
                ),
              ),
            ],
          ),
        );

        if (config.paperStyle == 'tape') {
          noteCard = Stack(
            clipBehavior: Clip.none,
            children: [
              noteCard,
              Positioned(
                top: -5 * scale,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 54 * scale,
                    height: 12 * scale,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.38),
                      borderRadius: BorderRadius.circular(2 * scale),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return [
          noteCard,
          SizedBox(height: 12 * scale),
        ];
      case 'year_progress' when config.showYearProgress:
        final startOfYear = DateTime(date.year, 1, 1);
        final dayOfYear = date.difference(startOfYear).inDays + 1;
        final isLeapYear = (date.year % 4 == 0 && date.year % 100 != 0) || (date.year % 400 == 0);
        final totalDays = isLeapYear ? 366 : 365;
        final daysLeft = totalDays - dayOfYear;
        final percent = (dayOfYear / totalDays * 100).clamp(0, 100);
        return [
          _GlassPanel(
            scale: scale,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '🌱 365 วัน · ปี ${date.year + 543}',
                      style: TextStyle(
                        fontSize: 13 * scale,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${percent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 13 * scale,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF68D391),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6 * scale),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: (dayOfYear / totalDays).clamp(0.0, 1.0),
                    minHeight: 5 * scale,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF68D391)),
                  ),
                ),
                SizedBox(height: 5 * scale),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ผ่านไป $dayOfYear วัน',
                      style: TextStyle(fontSize: 10 * scale, color: Colors.white70),
                    ),
                    Text(
                      'เหลืออีก $daysLeft วัน',
                      style: TextStyle(fontSize: 10 * scale, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 12 * scale),
        ];
      case 'progress' when config.showProgress:
        final start = DateTime(date.year, 1, 1);
        final end = DateTime(date.year + 1, 1, 1);
        final progress =
            date.difference(start).inMinutes / end.difference(start).inMinutes;
        return [
          _GlassPanel(
            scale: scale,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ปี ${date.year + 543}'),
                    Text('${(progress * 100).floor()}%'),
                  ],
                ),
                SizedBox(height: 8 * scale),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0, 1),
                    minHeight: 5 * scale,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12 * scale),
        ];
      case 'tasks' when config.showTasks:
        return [
          _GlassPanel(
            scale: scale,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'โฟกัสวันนี้',
                  style: TextStyle(
                    fontSize: 17 * scale,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8 * scale),
                if (tasks.isEmpty)
                  Text(
                    'วันนี้ยังไม่มีงาน',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13 * scale,
                    ),
                  )
                else
                  for (final task in tasks.take(config.taskLimit))
                    Builder(builder: (context) {
                      final isPast = config.dimPastEvents &&
                          task.deadlineAt != null &&
                          task.deadlineAt!.isBefore(date);
                      final circleColor = isPast ? Colors.white30 : Colors.white70;
                      final titleColor = isPast ? Colors.white38 : Colors.white;
                      final durColor = isPast ? Colors.white24 : Colors.white60;
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 5 * scale),
                        child: Row(
                          children: [
                            Container(
                              width: 14 * scale,
                              height: 14 * scale,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: circleColor,
                                  width: 1.4 * scale,
                                ),
                              ),
                            ),
                            SizedBox(width: 9 * scale),
                            Expanded(
                              child: Text(
                                task.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13 * scale,
                                  fontWeight: FontWeight.w600,
                                  color: titleColor,
                                ),
                              ),
                            ),
                            Text(
                              '${task.durationMin} นาที',
                              style: TextStyle(
                                color: durColor,
                                fontSize: 10 * scale,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
              ],
            ),
          ),
          SizedBox(height: 12 * scale),
        ];
      case 'calendar' when config.showCalendar:
        return [
          if (config.templateId == 'weekflow')
            _WeeklyTimeline(
              date: date,
              scale: scale,
              tasks: tasks,
              blocks: blocks,
            )
          else
            _MiniCalendar(date: date, scale: scale),
          SizedBox(height: 12 * scale),
        ];
      default:
        return const [];
    }
  }

  static String _dateLabel(DateTime date) {
    const days = [
      'จันทร์',
      'อังคาร',
      'พุธ',
      'พฤหัสบดี',
      'ศุกร์',
      'เสาร์',
      'อาทิตย์',
    ];
    const months = [
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];
    return 'วัน${days[date.weekday - 1]}ที่ ${date.day} ${months[date.month - 1]}';
  }
}

class _WeeklyTimeline extends StatelessWidget {
  const _WeeklyTimeline({
    required this.date,
    required this.scale,
    required this.tasks,
    required this.blocks,
  });

  final DateTime date;
  final double scale;
  final List<Task> tasks;
  final List<Block> blocks;

  @override
  Widget build(BuildContext context) {
    final day = DateTime(date.year, date.month, date.day);
    final weekStart = day.subtract(
      Duration(days: day.weekday - DateTime.monday),
    );
    return _GlassPanel(
      scale: scale,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ตารางสัปดาห์',
            style: TextStyle(fontSize: 16 * scale, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8 * scale),
          SizedBox(
            height: 292 * scale,
            width: double.infinity,
            child: CustomPaint(
              painter: _WeeklyTimelinePainter(
                now: date,
                weekStart: weekStart,
                scale: scale,
                blocks: blocks,
                tasksById: {for (final task in tasks) task.id: task},
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyTimelinePainter extends CustomPainter {
  const _WeeklyTimelinePainter({
    required this.now,
    required this.weekStart,
    required this.scale,
    required this.blocks,
    required this.tasksById,
  });

  static const _startHour = 8;
  static const _endHour = 22;
  static const _dayLabels = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];
  static const _eventColors = [
    Color(0xFF42B7A5),
    Color(0xFF5A8DEE),
    Color(0xFFE59E39),
    Color(0xFFB965D7),
    Color(0xFFDC5368),
    Color(0xFF7A9F48),
  ];

  final DateTime now;
  final DateTime weekStart;
  final double scale;
  final List<Block> blocks;
  final Map<String, Task> tasksById;

  @override
  void paint(Canvas canvas, Size size) {
    final labelWidth = 27 * scale;
    final headerHeight = 28 * scale;
    final gridHeight = size.height - headerHeight;
    final dayWidth = (size.width - labelWidth) / 7;
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..strokeWidth = 0.7 * scale;

    for (var dayIndex = 0; dayIndex < 7; dayIndex++) {
      final day = weekStart.add(Duration(days: dayIndex));
      final x = labelWidth + dayIndex * dayWidth;
      canvas.drawLine(
        Offset(x, headerHeight),
        Offset(x, size.height),
        linePaint,
      );
      _paintText(
        canvas,
        '${_dayLabels[dayIndex]}\n${day.day}',
        Offset(x, 0),
        dayWidth,
        8 * scale,
        color: Colors.white.withValues(alpha: 0.88),
        align: TextAlign.center,
        maxLines: 2,
      );
    }
    canvas.drawLine(
      Offset(size.width, headerHeight),
      Offset(size.width, size.height),
      linePaint,
    );

    for (var hour = _startHour; hour <= _endHour; hour += 2) {
      final fraction = (hour - _startHour) / (_endHour - _startHour);
      final y = headerHeight + fraction * gridHeight;
      canvas.drawLine(Offset(labelWidth, y), Offset(size.width, y), linePaint);
      _paintText(
        canvas,
        hour.toString().padLeft(2, '0'),
        Offset(0, y - 5 * scale),
        labelWidth - 3 * scale,
        6.5 * scale,
        color: Colors.white.withValues(alpha: 0.55),
        align: TextAlign.right,
      );
    }

    for (final block in blocks) {
      final start = block.startAt.toLocal();
      final end = block.endAt.toLocal();
      final blockDay = DateTime(start.year, start.month, start.day);
      final dayIndex = blockDay.difference(weekStart).inDays;
      if (dayIndex < 0 || dayIndex > 6) continue;
      final startMinute = start.hour * 60 + start.minute;
      final endMinute = end.hour * 60 + end.minute;
      final visibleStart = startMinute.clamp(_startHour * 60, _endHour * 60);
      final visibleEnd = endMinute.clamp(_startHour * 60, _endHour * 60);
      if (visibleEnd <= visibleStart) continue;

      final x = labelWidth + dayIndex * dayWidth + 1.5 * scale;
      final y =
          headerHeight +
          ((visibleStart - _startHour * 60) / ((_endHour - _startHour) * 60)) *
              gridHeight;
      final height =
          (((visibleEnd - visibleStart) / ((_endHour - _startHour) * 60)) *
                  gridHeight)
              .clamp(9 * scale, gridHeight);
      final color = _eventColors[block.id.hashCode.abs() % _eventColors.length];
      final rect = Rect.fromLTWH(
        x,
        y + 1 * scale,
        dayWidth - 3 * scale,
        height - 2 * scale,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(3 * scale)),
        Paint()..color = color.withValues(alpha: 0.9),
      );
      final title = block.title ?? tasksById[block.taskId]?.title ?? 'งาน';
      _paintText(
        canvas,
        title,
        Offset(rect.left + 2.5 * scale, rect.top + 2 * scale),
        rect.width - 5 * scale,
        6.5 * scale,
        color: Colors.white,
        maxLines: height >= 23 * scale ? 2 : 1,
      );
    }

    final today = DateTime(now.year, now.month, now.day);
    final todayIndex = today.difference(weekStart).inDays;
    final nowMinute = now.hour * 60 + now.minute;
    if (todayIndex >= 0 &&
        todayIndex <= 6 &&
        nowMinute >= _startHour * 60 &&
        nowMinute <= _endHour * 60) {
      final y =
          headerHeight +
          ((nowMinute - _startHour * 60) / ((_endHour - _startHour) * 60)) *
              gridHeight;
      final x = labelWidth + todayIndex * dayWidth;
      canvas.drawLine(
        Offset(x, y),
        Offset(x + dayWidth, y),
        Paint()
          ..color = const Color(0xFFFF6B6B)
          ..strokeWidth = 1.4 * scale,
      );
    }
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset offset,
    double width,
    double fontSize, {
    Color color = Colors.white,
    TextAlign align = TextAlign.left,
    int maxLines = 1,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontFamily: 'NotoSansThai',
          fontSize: fontSize,
          height: 1.05,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
      maxLines: maxLines,
      ellipsis: '…',
    )..layout(maxWidth: width);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _WeeklyTimelinePainter oldDelegate) =>
      oldDelegate.now != now ||
      oldDelegate.weekStart != weekStart ||
      oldDelegate.scale != scale ||
      oldDelegate.blocks != blocks ||
      oldDelegate.tasksById != tasksById;
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child, required this.scale});
  final Widget child;
  final double scale;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(14 * scale),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.24),
      borderRadius: BorderRadius.circular(18 * scale),
      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
    ),
    child: child,
  );
}

class _MiniCalendar extends StatelessWidget {
  const _MiniCalendar({required this.date, required this.scale});
  final DateTime date;
  final double scale;

  @override
  Widget build(BuildContext context) => _GlassPanel(
    scale: scale,
    child: Column(
      children: [
        Text(
          'สัปดาห์นี้',
          style: TextStyle(fontSize: 16 * scale, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 10 * scale),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var offset = -3; offset <= 3; offset++)
              Container(
                width: 30 * scale,
                height: 38 * scale,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: offset == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10 * scale),
                ),
                child: Text(
                  '${date.add(Duration(days: offset)).day}',
                  style: TextStyle(
                    color: offset == 0 ? Colors.black : Colors.white70,
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}
