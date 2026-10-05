import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../../core/utils/time_utils.dart';
import '../../domain/block.dart';
import '../../domain/task.dart';

enum DeadlinePreset {
  none('ไม่มีกำหนดส่ง'),
  thisEvening('เย็นนี้ (18:00)'),
  tomorrow('พรุ่งนี้ (18:00)'),
  custom('เลือกวันเอง');

  final String label;
  const DeadlinePreset(this.label);
}

/// Screen for adding or editing a Task or a Fixed Block (PLAN.md Section 5 & 7.2).
class AddTaskScreen extends StatefulWidget {
  final String? initialTitle;
  final Task? editTask;
  final Block? editBlock;

  const AddTaskScreen({
    super.key,
    this.initialTitle,
    this.editTask,
    this.editBlock,
  });

  static Future<dynamic> show(
    BuildContext context, {
    String? initialTitle,
    Task? editTask,
    Block? editBlock,
  }) {
    return showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTaskScreen(
        initialTitle: initialTitle,
        editTask: editTask,
        editBlock: editBlock,
      ),
    );
  }

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  static const _uuid = Uuid();
  late final TextEditingController _titleController;

  bool _isFixed = false;

  // Task fields
  int _selectedDurationMin = 30;
  bool _isCustomDuration = false;
  DeadlinePreset _selectedDeadlinePreset = DeadlinePreset.none;
  DateTime? _customDeadline;

  final List<int> _presetDurations = [15, 30, 60, 90];

  // Fixed Block fields
  late DateTime _fixedDate;
  late TimeOfDay _fixedStartTime;
  late TimeOfDay _fixedEndTime;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _fixedDate = DateTime(now.year, now.month, now.day);
    final roundedMinute = ((now.minute / 5).ceil() * 5) % 60;
    _fixedStartTime = TimeOfDay(hour: now.hour, minute: roundedMinute);
    _fixedEndTime = TimeOfDay(hour: (now.hour + 1) % 24, minute: roundedMinute);

    if (widget.editBlock != null) {
      final b = widget.editBlock!;
      _titleController = TextEditingController(text: b.title ?? '');
      _isFixed = b.isFixed;
      final startLocal = b.startAt.toLocal();
      final endLocal = b.endAt.toLocal();
      _fixedDate = DateTime(startLocal.year, startLocal.month, startLocal.day);
      _fixedStartTime = TimeOfDay(
        hour: startLocal.hour,
        minute: startLocal.minute,
      );
      _fixedEndTime = TimeOfDay(hour: endLocal.hour, minute: endLocal.minute);
      _selectedDurationMin = b.durationMin;
      _isCustomDuration = !_presetDurations.contains(b.durationMin);
    } else if (widget.editTask != null) {
      final t = widget.editTask!;
      _titleController = TextEditingController(text: t.title);
      _isFixed = false;
      _selectedDurationMin = t.durationMin;
      _isCustomDuration = !_presetDurations.contains(t.durationMin);
      if (t.deadlineAt != null) {
        _customDeadline = t.deadlineAt!.toLocal();
        _selectedDeadlinePreset = DeadlinePreset.custom;
      }
    } else {
      _titleController = TextEditingController(text: widget.initialTitle ?? '');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  DateTime? _computeDeadline() {
    final now = DateTime.now();
    switch (_selectedDeadlinePreset) {
      case DeadlinePreset.none:
        return null;
      case DeadlinePreset.thisEvening:
        return DateTime(now.year, now.month, now.day, 18, 0).toUtc();
      case DeadlinePreset.tomorrow:
        final tmr = now.add(const Duration(days: 1));
        return DateTime(tmr.year, tmr.month, tmr.day, 18, 0).toUtc();
      case DeadlinePreset.custom:
        return _customDeadline?.toUtc();
    }
  }

  Future<void> _pickCustomDuration() async {
    final controller = TextEditingController(
      text: _selectedDurationMin.toString(),
    );
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) {
        final theme = ctx.mossTheme;
        return AlertDialog(
          backgroundColor: theme.background,
          title: Text(
            'กำหนดระยะเวลาเอง',
            style: TextStyle(color: theme.onBackground, fontSize: 18),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              suffixText: 'นาที',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('ยกเลิก', style: TextStyle(color: theme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                final val = int.tryParse(controller.text.trim());
                if (val != null && val > 0) {
                  Navigator.pop(ctx, val);
                }
              },
              child: const Text('ตกลง'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedDurationMin = result;
        _isCustomDuration = !_presetDurations.contains(result);
      });
    }
  }

  Future<void> _pickCustomDeadline() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 18, minute: 0),
    );

    if (pickedTime == null || !mounted) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      _customDeadline = combined;
      _selectedDeadlinePreset = DeadlinePreset.custom;
    });
  }

  Future<void> _pickFixedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fixedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) {
      setState(() {
        _fixedDate = picked;
      });
    }
  }

  Future<void> _pickFixedStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _fixedStartTime,
    );
    if (picked != null) {
      setState(() {
        _fixedStartTime = picked;
      });
    }
  }

  Future<void> _pickFixedEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _fixedEndTime,
    );
    if (picked != null) {
      setState(() {
        _fixedEndTime = picked;
      });
    }
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final nowUtc = TimeUtils.nowUtc();

    if (_isFixed) {
      // Create or update Fixed Block
      final startLocal = DateTime(
        _fixedDate.year,
        _fixedDate.month,
        _fixedDate.day,
        _fixedStartTime.hour,
        _fixedStartTime.minute,
      );
      final endLocal = DateTime(
        _fixedDate.year,
        _fixedDate.month,
        _fixedDate.day,
        _fixedEndTime.hour,
        _fixedEndTime.minute,
      );

      final fixedBlock = Block(
        id: widget.editBlock?.id ?? _uuid.v4(),
        kind: BlockKind.fixed,
        taskId: widget.editBlock?.taskId,
        title: title,
        startAt: startLocal.toUtc(),
        endAt: endLocal.toUtc(),
        locked: true,
        source: widget.editBlock?.source ?? 'local',
        createdAt: widget.editBlock?.createdAt ?? nowUtc,
        updatedAt: nowUtc,
      );

      Navigator.pop(context, fixedBlock);
    } else {
      // Create or update Task
      final task = Task(
        id: widget.editTask?.id ?? widget.editBlock?.taskId ?? _uuid.v4(),
        title: title,
        durationMin: _selectedDurationMin,
        deadlineAt: _computeDeadline(),
        priority: widget.editTask?.priority ?? 2,
        status: widget.editTask?.status ?? TaskStatus.todo,
        createdAt: widget.editTask?.createdAt ?? nowUtc,
        updatedAt: nowUtc,
      );

      Navigator.pop(context, task);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    final isEditing = widget.editTask != null || widget.editBlock != null;

    return Container(
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing
                      ? 'แก้ไขข้อมูล'
                      : (_isFixed ? 'เพิ่มนัดหมาย (ล็อกเวลา)' : 'เพิ่มงานใหม่'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: theme.onBackground,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: theme.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Type Segmented selector (Task vs Fixed Block)
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(
                      child: Text('งานทั่วไป (จัดตารางอัตโนมัติ)'),
                    ),
                    selected: !_isFixed,
                    onSelected: (val) {
                      if (val) setState(() => _isFixed = false);
                    },
                    selectedColor: theme.nowFill,
                    backgroundColor: theme.cardBackground,
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: !_isFixed
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: !_isFixed
                          ? theme.onBackground
                          : theme.textSecondary,
                    ),
                    side: BorderSide(
                      color: !_isFixed ? theme.nowBorder : theme.borderSubtle,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('นัดหมาย (กำหนดเวลาเอง)')),
                    selected: _isFixed,
                    onSelected: (val) {
                      if (val) setState(() => _isFixed = true);
                    },
                    selectedColor: theme.nowFill,
                    backgroundColor: theme.cardBackground,
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: _isFixed
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: _isFixed
                          ? theme.onBackground
                          : theme.textSecondary,
                    ),
                    side: BorderSide(
                      color: _isFixed ? theme.nowBorder : theme.borderSubtle,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 1. Title Input
            Text(
              _isFixed ? 'ชื่องาน / นัดหมาย' : 'ชื่องาน',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: theme.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.borderSubtle),
              ),
              child: TextField(
                controller: _titleController,
                autofocus: true,
                style: TextStyle(
                  fontSize: 16,
                  color: theme.onBackground,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: _isFixed
                      ? 'เช่น ประชุมฝ่ายการตลาด, นัดหมอ...'
                      : 'เช่น สรุปงานส่งลูกค้า, เขียนรายงาน...',
                  hintStyle: TextStyle(fontSize: 15, color: theme.textMuted),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (_isFixed) ...[
              // Fixed Block Date and Time Pickers
              Text(
                'วันและเวลานัดหมาย',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: OutlinedButton.icon(
                      onPressed: _pickFixedDate,
                      icon: Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: theme.primary,
                      ),
                      label: Text(
                        ThaiDateFormatter.formatFullDate(_fixedDate),
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.onBackground,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: theme.cardBackground,
                        side: BorderSide(color: theme.borderSubtle),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickFixedStartTime,
                      icon: Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: theme.textSecondary,
                      ),
                      label: Text(
                        'เริ่ม: ${_fixedStartTime.format(context)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.onBackground,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: theme.cardBackground,
                        side: BorderSide(color: theme.borderSubtle),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickFixedEndTime,
                      icon: Icon(
                        Icons.access_time_filled_rounded,
                        size: 16,
                        color: theme.textSecondary,
                      ),
                      label: Text(
                        'สิ้นสุด: ${_fixedEndTime.format(context)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.onBackground,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: theme.cardBackground,
                        side: BorderSide(color: theme.borderSubtle),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Task Duration Chips
              Text(
                'ใช้เวลาประมาณ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._presetDurations.map((duration) {
                    final isSelected =
                        !_isCustomDuration && _selectedDurationMin == duration;
                    return ChoiceChip(
                      label: Text('$duration นาที'),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedDurationMin = duration;
                            _isCustomDuration = false;
                          });
                        }
                      },
                      selectedColor: theme.nowFill,
                      backgroundColor: theme.cardBackground,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? theme.onBackground
                            : theme.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? theme.nowBorder
                            : theme.borderSubtle,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    );
                  }),
                  ChoiceChip(
                    label: Text(
                      _isCustomDuration
                          ? '$_selectedDurationMin นาที'
                          : 'กำหนดเอง',
                    ),
                    selected: _isCustomDuration,
                    onSelected: (_) => _pickCustomDuration(),
                    selectedColor: theme.nowFill,
                    backgroundColor: theme.cardBackground,
                    labelStyle: TextStyle(
                      color: _isCustomDuration
                          ? theme.onBackground
                          : theme.textSecondary,
                      fontWeight: _isCustomDuration
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: _isCustomDuration
                          ? theme.nowBorder
                          : theme.borderSubtle,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Task Deadline Chips
              Text(
                'กำหนดส่ง (ถ้ามี)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('ไม่มีกำหนดส่ง'),
                    selected: _selectedDeadlinePreset == DeadlinePreset.none,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedDeadlinePreset = DeadlinePreset.none;
                        });
                      }
                    },
                    selectedColor: theme.nowFill,
                    backgroundColor: theme.cardBackground,
                    labelStyle: TextStyle(
                      color: _selectedDeadlinePreset == DeadlinePreset.none
                          ? theme.onBackground
                          : theme.textSecondary,
                      fontWeight: _selectedDeadlinePreset == DeadlinePreset.none
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: _selectedDeadlinePreset == DeadlinePreset.none
                          ? theme.nowBorder
                          : theme.borderSubtle,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  ChoiceChip(
                    label: const Text('เย็นนี้ (18:00)'),
                    selected:
                        _selectedDeadlinePreset == DeadlinePreset.thisEvening,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedDeadlinePreset = DeadlinePreset.thisEvening;
                        });
                      }
                    },
                    selectedColor: theme.nowFill,
                    backgroundColor: theme.cardBackground,
                    labelStyle: TextStyle(
                      color:
                          _selectedDeadlinePreset == DeadlinePreset.thisEvening
                          ? theme.onBackground
                          : theme.textSecondary,
                      fontWeight:
                          _selectedDeadlinePreset == DeadlinePreset.thisEvening
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color:
                          _selectedDeadlinePreset == DeadlinePreset.thisEvening
                          ? theme.nowBorder
                          : theme.borderSubtle,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  ChoiceChip(
                    label: const Text('พรุ่งนี้ (18:00)'),
                    selected:
                        _selectedDeadlinePreset == DeadlinePreset.tomorrow,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedDeadlinePreset = DeadlinePreset.tomorrow;
                        });
                      }
                    },
                    selectedColor: theme.nowFill,
                    backgroundColor: theme.cardBackground,
                    labelStyle: TextStyle(
                      color: _selectedDeadlinePreset == DeadlinePreset.tomorrow
                          ? theme.onBackground
                          : theme.textSecondary,
                      fontWeight:
                          _selectedDeadlinePreset == DeadlinePreset.tomorrow
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: _selectedDeadlinePreset == DeadlinePreset.tomorrow
                          ? theme.nowBorder
                          : theme.borderSubtle,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  ChoiceChip(
                    label: Text(
                      _selectedDeadlinePreset == DeadlinePreset.custom &&
                              _customDeadline != null
                          ? '${_customDeadline!.day}/${_customDeadline!.month} ${ThaiDateFormatter.formatTime(_customDeadline!)}'
                          : 'เลือกวันเอง...',
                    ),
                    selected: _selectedDeadlinePreset == DeadlinePreset.custom,
                    onSelected: (_) => _pickCustomDeadline(),
                    selectedColor: theme.nowFill,
                    backgroundColor: theme.cardBackground,
                    labelStyle: TextStyle(
                      color: _selectedDeadlinePreset == DeadlinePreset.custom
                          ? theme.onBackground
                          : theme.textSecondary,
                      fontWeight:
                          _selectedDeadlinePreset == DeadlinePreset.custom
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: _selectedDeadlinePreset == DeadlinePreset.custom
                          ? theme.nowBorder
                          : theme.borderSubtle,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 28),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isEditing
                      ? 'บันทึกการแก้ไข'
                      : (_isFixed
                            ? 'บันทึกนัดหมาย (ล็อกเวลา)'
                            : 'เพิ่มงานและจัดตาราง'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
