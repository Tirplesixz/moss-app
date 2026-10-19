import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../../tasks/domain/task.dart';
import '../../tasks/domain/block.dart';
import '../domain/lockscreen_config.dart';

/// Renders a deterministic 1080×2400 wallpaper without requiring a widget tree.
class LockScreenImageRenderer {
  const LockScreenImageRenderer();

  static Future<void>? _fontReady;

  static Future<void> _ensureFontLoaded() => _fontReady ??= (() async {
    final bytes = await rootBundle.load(
      'assets/fonts/NotoSansThai-Variable.ttf',
    );
    final loader = FontLoader('NotoSansThai')
      ..addFont(Future<ByteData>.value(bytes));
    await loader.load();
  })();

  Future<Uint8List> render({
    required LockScreenConfig config,
    required List<Task> tasks,
    List<Block> blocks = const [],
    DateTime? now,
  }) async {
    await _ensureFontLoaded();
    const width = 1080.0;
    const height = 2400.0;
    final date = now ?? DateTime.now();
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final bounds = const ui.Rect.fromLTWH(0, 0, width, height);
    final isWeekFlow = config.templateId == 'weekflow';
    canvas.drawRect(
      bounds,
      ui.Paint()
        ..shader = ui.Gradient.linear(
          ui.Offset.zero,
          const ui.Offset(0, height),
          isWeekFlow
              ? const [
                  ui.Color(0xFFC6501B),
                  ui.Color(0xFF7A174B),
                  ui.Color(0xFF071D36),
                ]
              : [ui.Color(config.gradientStart), ui.Color(config.gradientEnd)],
          isWeekFlow ? const [0, 0.48, 1] : null,
        ),
    );

    var y = (isWeekFlow ? 620.0 : 160.0) + config.verticalOffset;
    for (final module in config.moduleOrder) {
      switch (module) {
        case 'clock' when config.showClock:
          _text(
            canvas,
            _dateLabel(date),
            width / 2,
            y,
            size: 42,
            color: const ui.Color(0xCCFFFFFF),
            center: true,
          );
          y += 55;
          _text(
            canvas,
            '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
            width / 2,
            y,
            size: 164,
            weight: ui.FontWeight.w700,
            center: true,
          );
          y += 210;
        case 'countdown' when config.showCountdown:
          DateTime? target;
          if (config.countdownDate != null && config.countdownDate!.isNotEmpty) {
            target = DateTime.tryParse(config.countdownDate!);
          }
          target ??= DateTime(date.year, 12, 31);
          final today = DateTime(date.year, date.month, date.day);
          final targetDay = DateTime(target.year, target.month, target.day);
          final diff = targetDay.difference(today).inDays;
          _panel(canvas, y, 160);
          _text(
            canvas,
            '⏳ ${config.countdownTitle}',
            104,
            y + 36,
            size: 36,
            weight: ui.FontWeight.w600,
          );
          final diffText = diff == 0
              ? 'วันนี้ 🎉'
              : (diff > 0 ? 'อีก $diff วัน' : 'ผ่านมา ${diff.abs()} วัน');
          _text(
            canvas,
            diffText,
            976,
            y + 36,
            size: 42,
            weight: ui.FontWeight.w700,
            alignRight: true,
            color: diff == 0
                ? const ui.Color(0xFFFFD54F)
                : const ui.Color(0xFFFFFFFF),
          );
          _text(
            canvas,
            'เป้าหมาย: ${target.day}/${target.month}/${target.year + 543}',
            104,
            y + 98,
            size: 28,
            color: const ui.Color(0x99FFFFFF),
          );
          y += 192;
        case 'note' when config.showPinnedNote && config.pinnedNoteText.isNotEmpty:
          _panel(canvas, y, 160);
          _text(
            canvas,
            '📌 บันทึกปักหมุด',
            104,
            y + 34,
            size: 34,
            weight: ui.FontWeight.w700,
          );
          _text(
            canvas,
            config.pinnedNoteText,
            104,
            y + 88,
            size: 32,
            maxWidth: 872,
            color: const ui.Color(0xE6FFFFFF),
          );
          y += 192;
        case 'progress' when config.showProgress:
          final start = DateTime(date.year, 1, 1);
          final end = DateTime(date.year + 1, 1, 1);
          final progress =
              (date.difference(start).inMinutes /
                      end.difference(start).inMinutes)
                  .clamp(0.0, 1.0);
          _panel(canvas, y, 190);
          _text(canvas, 'ปี ${date.year + 543}', 104, y + 42, size: 38);
          _text(
            canvas,
            '${(progress * 100).floor()}%',
            976,
            y + 42,
            size: 38,
            alignRight: true,
          );
          canvas.drawRRect(
            ui.RRect.fromRectAndRadius(
              ui.Rect.fromLTWH(104, y + 112, 872, 14),
              const ui.Radius.circular(7),
            ),
            ui.Paint()..color = const ui.Color(0x33FFFFFF),
          );
          canvas.drawRRect(
            ui.RRect.fromRectAndRadius(
              ui.Rect.fromLTWH(104, y + 112, 872 * progress, 14),
              const ui.Radius.circular(7),
            ),
            ui.Paint()..color = const ui.Color(0xFFFFFFFF),
          );
          y += 222;
        case 'tasks' when config.showTasks:
          final visible = tasks.take(config.taskLimit).toList();
          final panelHeight = 120.0 + visible.length * 78;
          _panel(canvas, y, panelHeight);
          _text(
            canvas,
            'โฟกัสวันนี้',
            104,
            y + 38,
            size: 44,
            weight: ui.FontWeight.w700,
          );
          var rowY = y + 112;
          if (visible.isEmpty) {
            _text(
              canvas,
              'วันนี้ยังไม่มีงาน',
              104,
              rowY,
              size: 34,
              color: const ui.Color(0xB3FFFFFF),
            );
          }
          for (final task in visible) {
            final isPast = config.dimPastEvents &&
                task.deadlineAt != null &&
                task.deadlineAt!.isBefore(date);
            final itemColor = isPast
                ? const ui.Color(0x55FFFFFF)
                : const ui.Color(0xCCFFFFFF);
            final textColor = isPast
                ? const ui.Color(0x66FFFFFF)
                : const ui.Color(0xFFFFFFFF);
            canvas.drawCircle(
              ui.Offset(119, rowY + 20),
              16,
              ui.Paint()
                ..style = ui.PaintingStyle.stroke
                ..strokeWidth = 4
                ..color = itemColor,
            );
            _text(
              canvas,
              task.title,
              158,
              rowY,
              size: 35,
              maxWidth: 650,
              weight: ui.FontWeight.w600,
              color: textColor,
            );
            _text(
              canvas,
              '${task.durationMin} นาที',
              976,
              rowY + 3,
              size: 26,
              color: isPast
                  ? const ui.Color(0x44FFFFFF)
                  : const ui.Color(0x99FFFFFF),
              alignRight: true,
            );
            rowY += 78;
          }
          y += panelHeight + 32;
        case 'calendar' when config.showCalendar:
          if (config.templateId == 'weekflow') {
            final taskMap = {for (final task in tasks) task.id: task};
            _weekTimeline(
              canvas,
              y: y,
              date: date,
              blocks: blocks,
              tasksById: taskMap,
            );
            y += 1532;
            break;
          }
          _panel(canvas, y, 230);
          _text(
            canvas,
            'สัปดาห์นี้',
            width / 2,
            y + 38,
            size: 42,
            weight: ui.FontWeight.w700,
            center: true,
          );
          for (var offset = -3; offset <= 3; offset++) {
            final x = 150.0 + (offset + 3) * 130;
            if (offset == 0) {
              canvas.drawRRect(
                ui.RRect.fromRectAndRadius(
                  ui.Rect.fromLTWH(x - 40, y + 112, 80, 80),
                  const ui.Radius.circular(24),
                ),
                ui.Paint()..color = const ui.Color(0xFFFFFFFF),
              );
            }
            _text(
              canvas,
              '${date.add(Duration(days: offset)).day}',
              x,
              y + 130,
              size: 32,
              color: offset == 0
                  ? const ui.Color(0xFF111111)
                  : const ui.Color(0xCCFFFFFF),
              center: true,
              weight: ui.FontWeight.w700,
            );
          }
          y += 262;
      }
    }
    _text(
      canvas,
      'MOSS',
      width / 2,
      height - 105,
      size: 28,
      color: const ui.Color(0x77FFFFFF),
      center: true,
      weight: ui.FontWeight.w700,
      letterSpacing: 10,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    picture.dispose();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null) throw StateError('Unable to encode lock screen image');
    return data.buffer.asUint8List();
  }

  void _weekTimeline(
    ui.Canvas canvas, {
    required double y,
    required DateTime date,
    required List<Block> blocks,
    required Map<String, Task> tasksById,
  }) {
    const panelX = 48.0;
    const panelWidth = 984.0;
    const panelHeight = 1500.0;
    const labelWidth = 70.0;
    const headerHeight = 132.0;
    const startHour = 8;
    const endHour = 22;
    const dayLabels = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];
    const colors = [
      ui.Color(0xFF42B7A5),
      ui.Color(0xFF5A8DEE),
      ui.Color(0xFFE59E39),
      ui.Color(0xFFB965D7),
      ui.Color(0xFFDC5368),
      ui.Color(0xFF7A9F48),
    ];

    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(panelX, y, panelWidth, panelHeight),
        const ui.Radius.circular(42),
      ),
      ui.Paint()..color = const ui.Color(0x42000000),
    );
    _text(
      canvas,
      'ตารางสัปดาห์',
      panelX + 34,
      y + 28,
      size: 40,
      weight: ui.FontWeight.w700,
    );

    final day = DateTime(date.year, date.month, date.day);
    final weekStart = day.subtract(
      Duration(days: day.weekday - DateTime.monday),
    );
    final gridLeft = panelX + labelWidth;
    final gridTop = y + headerHeight;
    final gridWidth = panelWidth - labelWidth - 22;
    final gridHeight = panelHeight - headerHeight - 30;
    final dayWidth = gridWidth / 7;
    final linePaint = ui.Paint()
      ..color = const ui.Color(0x30FFFFFF)
      ..strokeWidth = 2;

    for (var dayIndex = 0; dayIndex < 7; dayIndex++) {
      final current = weekStart.add(Duration(days: dayIndex));
      final x = gridLeft + dayIndex * dayWidth;
      canvas.drawLine(
        ui.Offset(x, gridTop),
        ui.Offset(x, gridTop + gridHeight),
        linePaint,
      );
      _text(
        canvas,
        '${dayLabels[dayIndex]} ${current.day}',
        x + dayWidth / 2,
        y + 84,
        size: 25,
        center: true,
        maxWidth: dayWidth,
        weight: ui.FontWeight.w700,
      );
    }
    canvas.drawLine(
      ui.Offset(gridLeft + gridWidth, gridTop),
      ui.Offset(gridLeft + gridWidth, gridTop + gridHeight),
      linePaint,
    );

    for (var hour = startHour; hour <= endHour; hour++) {
      final fraction = (hour - startHour) / (endHour - startHour);
      final lineY = gridTop + fraction * gridHeight;
      canvas.drawLine(
        ui.Offset(gridLeft, lineY),
        ui.Offset(gridLeft + gridWidth, lineY),
        linePaint,
      );
      if (hour.isEven) {
        _text(
          canvas,
          hour.toString().padLeft(2, '0'),
          gridLeft - 16,
          lineY - 13,
          size: 20,
          color: const ui.Color(0x99FFFFFF),
          alignRight: true,
          maxWidth: 50,
        );
      }
    }

    for (final block in blocks) {
      final start = block.startAt.toLocal();
      final end = block.endAt.toLocal();
      final blockDay = DateTime(start.year, start.month, start.day);
      final dayIndex = blockDay.difference(weekStart).inDays;
      if (dayIndex < 0 || dayIndex > 6) continue;
      final startMinute = start.hour * 60 + start.minute;
      final endMinute = end.hour * 60 + end.minute;
      final visibleStart = startMinute.clamp(startHour * 60, endHour * 60);
      final visibleEnd = endMinute.clamp(startHour * 60, endHour * 60);
      if (visibleEnd <= visibleStart) continue;

      final blockX = gridLeft + dayIndex * dayWidth + 4;
      final blockY =
          gridTop +
          ((visibleStart - startHour * 60) / ((endHour - startHour) * 60)) *
              gridHeight;
      final blockHeight =
          (((visibleEnd - visibleStart) / ((endHour - startHour) * 60)) *
                  gridHeight)
              .clamp(28.0, gridHeight);
      final rect = ui.Rect.fromLTWH(
        blockX,
        blockY + 3,
        dayWidth - 8,
        blockHeight - 6,
      );
      final color = colors[block.id.hashCode.abs() % colors.length];
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(rect, const ui.Radius.circular(9)),
        ui.Paint()..color = color.withValues(alpha: 0.92),
      );
      final title = block.title ?? tasksById[block.taskId]?.title ?? 'งาน';
      _text(
        canvas,
        title,
        rect.left + 8,
        rect.top + 6,
        size: 18,
        maxWidth: rect.width - 16,
        weight: ui.FontWeight.w600,
      );
    }

    final todayIndex = day.difference(weekStart).inDays;
    final nowMinute = date.hour * 60 + date.minute;
    if (todayIndex >= 0 &&
        todayIndex <= 6 &&
        nowMinute >= startHour * 60 &&
        nowMinute <= endHour * 60) {
      final lineY =
          gridTop +
          ((nowMinute - startHour * 60) / ((endHour - startHour) * 60)) *
              gridHeight;
      final lineX = gridLeft + todayIndex * dayWidth;
      canvas.drawLine(
        ui.Offset(lineX, lineY),
        ui.Offset(lineX + dayWidth, lineY),
        ui.Paint()
          ..color = const ui.Color(0xFFFF6B6B)
          ..strokeWidth = 4,
      );
    }
  }

  void _panel(ui.Canvas canvas, double y, double height) {
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(72, y, 936, height),
        const ui.Radius.circular(46),
      ),
      ui.Paint()..color = const ui.Color(0x3D000000),
    );
  }

  void _text(
    ui.Canvas canvas,
    String value,
    double x,
    double y, {
    double size = 36,
    ui.Color color = const ui.Color(0xFFFFFFFF),
    ui.FontWeight weight = ui.FontWeight.w400,
    bool center = false,
    bool alignRight = false,
    double maxWidth = 880,
    double letterSpacing = 0,
  }) {
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        fontFamily: 'NotoSansThai',
        fontSize: size,
        fontWeight: weight,
        maxLines: 1,
        ellipsis: '…',
        textAlign: center
            ? ui.TextAlign.center
            : alignRight
            ? ui.TextAlign.right
            : ui.TextAlign.left,
      ),
    )..pushStyle(ui.TextStyle(color: color, letterSpacing: letterSpacing));
    builder.addText(value);
    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: maxWidth));
    final left = center
        ? x - maxWidth / 2
        : alignRight
        ? x - maxWidth
        : x;
    canvas.drawParagraph(paragraph, ui.Offset(left, y));
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
