import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/moss_haptics.dart';
import '../../domain/task.dart';

/// A sleek Pomodoro Focus Timer sheet for focused work sessions.
class PomodoroTimerSheet extends StatefulWidget {
  const PomodoroTimerSheet({
    super.key,
    required this.task,
    this.onTaskComplete,
  });

  final Task task;
  final ValueChanged<Task>? onTaskComplete;

  static Future<void> show(
    BuildContext context, {
    required Task task,
    ValueChanged<Task>? onTaskComplete,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          PomodoroTimerSheet(task: task, onTaskComplete: onTaskComplete),
    );
  }

  @override
  State<PomodoroTimerSheet> createState() => _PomodoroTimerSheetState();
}

class _PomodoroTimerSheetState extends State<PomodoroTimerSheet> {
  int _totalSeconds = 25 * 60;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    MossHaptics.selection();
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          setState(() => _remainingSeconds--);
        } else {
          _timer?.cancel();
          setState(() => _isRunning = false);
          MossHaptics.success();
          _showCompletionDialog();
        }
      });
    }
  }

  void _resetTimer([int minutes = 25]) {
    MossHaptics.light();
    _timer?.cancel();
    setState(() {
      _totalSeconds = minutes * 60;
      _remainingSeconds = minutes * 60;
      _isRunning = false;
    });
  }

  void _showCompletionDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Color(0xFF1E2330),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '🎉 โฟกัสสำเร็จ!',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'คุณทำช่วงเวลาโฟกัสสำหรับ "${widget.task.title}" สำเร็จแล้ว ต้องการทำเครื่องหมายว่างานนี้เสร็จสิ้นหรือไม่?',
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.72),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'ยังไม่เสร็จ',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.64),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              if (widget.onTaskComplete != null) {
                widget.onTaskComplete!(widget.task);
              }
              Navigator.of(context).pop();
            },
            child: Text(
              'เสร็จสิ้นงานนี้ ✓',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int totalSec) {
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final quadrant = MatrixQuadrant.fromId(widget.task.quadrant);
    final progress = _totalSeconds > 0
        ? (_remainingSeconds / _totalSeconds)
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF141720),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.quadrantFor(
                        quadrant.id,
                      ).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.quadrantFor(
                          quadrant.id,
                        ).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      quadrant.label,
                      style: TextStyle(
                        color: AppColors.quadrantFor(quadrant.id),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'โฟกัสไทม์เมอร์ ⏱️',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.close_rounded,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
          SizedBox(height: 6),

          // Task title
          Text(
            widget.task.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 24),

          // Glowing Circular Progress Timer
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Soft background glow
                Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.quadrantFor(
                          quadrant.id,
                        ).withValues(alpha: _isRunning ? 0.35 : 0.15),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
                // Circular Progress Indicator
                SizedBox(
                  width: 190,
                  height: 190,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.quadrantFor(quadrant.id),
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                // Time Text
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(_remainingSeconds),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _isRunning ? 'กำลังโฟกัส...' : 'แตะเพื่อเริ่ม',
                      style: TextStyle(
                        color: _isRunning
                            ? AppColors.quadrantFor(quadrant.id)
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.72),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 28),

          // Preset duration pills
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPresetPill(15, '15 นาที'),
              SizedBox(width: 8),
              _buildPresetPill(25, '25 นาที (Pomodoro)'),
              SizedBox(width: 8),
              _buildPresetPill(45, '45 นาที'),
            ],
          ),
          SizedBox(height: 24),

          // Action Buttons: Play/Pause and Reset
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRunning
                        ? Color(0xFFE55745)
                        : Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _toggleTimer,
                  icon: Icon(
                    _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 22,
                  ),
                  label: Text(
                    _isRunning ? 'พักการโฟกัส' : 'เริ่มโฟกัสทันที',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
              ),
              SizedBox(width: 12),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: EdgeInsets.all(14),
                ),
                onPressed: () => _resetTimer(_totalSeconds ~/ 60),
                icon: Icon(
                  Icons.refresh_rounded,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetPill(int minutes, String label) {
    final isSelected = _totalSeconds == minutes * 60;
    return GestureDetector(
      onTap: () => _resetTimer(minutes),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Color(0xFF2C3446)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Color(0xFF60A5FA)
                : Theme.of(context).colorScheme.outlineVariant,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Color(0xFF60A5FA)
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.72),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
