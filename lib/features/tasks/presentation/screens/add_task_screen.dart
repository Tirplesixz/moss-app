import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/moss_haptics.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../../core/utils/time_utils.dart';
import '../../../../core/validation/input_limits.dart';
import '../../../../core/widgets/ios_picker_dialogs.dart';
import '../../domain/block.dart';
import '../../domain/task.dart';

part 'add_task_screen_widgets.dart';

/// Focused task editor with adaptive date and time pickers.
class AddTaskScreen extends StatefulWidget {
  final String? initialTitle;
  final Task? editTask;
  final Block? editBlock;
  final int? initialQuadrant;
  final DateTime? initialDate;
  final String? initialProject;

  const AddTaskScreen({
    super.key,
    this.initialTitle,
    this.editTask,
    this.editBlock,
    this.initialQuadrant,
    this.initialDate,
    this.initialProject,
  });

  static Future<Object?> show(
    BuildContext context, {
    String? initialTitle,
    Task? editTask,
    Block? editBlock,
    int? initialQuadrant,
    DateTime? initialDate,
    String? initialProject,
  }) {
    return showModalBottomSheet<Object?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxWidth: 720,
        maxHeight: MediaQuery.sizeOf(context).height,
      ),
      builder: (context) => AddTaskScreen(
        initialTitle: initialTitle,
        editTask: editTask,
        editBlock: editBlock,
        initialQuadrant: initialQuadrant,
        initialDate: initialDate,
        initialProject: initialProject,
      ),
    );
  }

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  static final _uuid = Uuid();
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;

  late int _selectedQuadrant;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  TaskRepeatRule? _repeatRule;
  String _reminderRule = 'ตรงเวลา';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text:
          widget.editTask?.title ??
          widget.editBlock?.title ??
          widget.initialTitle ??
          '',
    );
    _noteController = TextEditingController(text: widget.editTask?.note ?? '');

    if (widget.editTask != null) {
      _selectedQuadrant = widget.editTask!.quadrant;
      _selectedDate = widget.editTask!.deadlineAt?.toLocal();
      if (_selectedDate != null) {
        _selectedTime = TimeOfDay(
          hour: _selectedDate!.hour,
          minute: _selectedDate!.minute,
        );
      }
      _repeatRule = TaskRepeatRule.fromStored(widget.editTask!.repeatRule);
    } else {
      _selectedQuadrant = widget.initialQuadrant ?? 1;
      final initialDate = widget.initialDate;
      if (initialDate != null) {
        _selectedTime = const TimeOfDay(hour: 22, minute: 0);
        _selectedDate = DateTime(
          initialDate.year,
          initialDate.month,
          initialDate.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final pickedDate = await showIosDatePicker(
      context,
      initialDate: _selectedDate ?? now,
    );
    if (pickedDate == null || !mounted) return;
    setState(() {
      _selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        _selectedTime?.hour ?? 22,
        _selectedTime?.minute ?? 0,
      );
    });
  }

  Future<void> _pickTime() async {
    final pickedTime = await showIosTimePicker(
      context,
      initialTime: _selectedTime ?? TimeOfDay(hour: 22, minute: 0),
    );
    if (pickedTime == null || !mounted) return;
    setState(() {
      _selectedTime = pickedTime;
      final baseDate = _selectedDate ?? DateTime.now();
      _selectedDate = DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _pickRepeat() async {
    MossHaptics.selection();
    final options = [
      'ไม่เคย',
      ...TaskRepeatRule.values.map((rule) => rule.label),
    ];
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _IosSelectorSheet(
        title: 'ทำซ้ำ',
        options: options,
        selectedOption: _repeatRule?.label ?? 'ไม่เคย',
      ),
    );
    if (picked != null && mounted) {
      setState(() => _repeatRule = TaskRepeatRule.fromLabel(picked));
    }
  }

  Future<void> _pickReminder() async {
    MossHaptics.selection();
    final options = [
      'ไม่มี',
      'ตรงเวลา',
      '5 นาทีก่อน',
      '15 นาทีก่อน',
      '30 นาทีก่อน',
      '1 ชั่วโมงก่อน',
      '1 วันก่อน',
    ];
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _IosSelectorSheet(
        title: 'การแจ้งเตือน',
        options: options,
        selectedOption: _reminderRule,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _reminderRule = picked);
    }
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    MossHaptics.success();
    final now = TimeUtils.nowUtc();
    final deadlineUtc = _selectedDate?.toUtc();

    if (widget.editBlock != null && widget.editTask == null) {
      final block = widget.editBlock!;
      Navigator.of(
        context,
      ).pop(block.copyWith(title: () => title, updatedAt: now));
      return;
    }

    final task = (widget.editTask != null)
        ? widget.editTask!.copyWith(
            title: title,
            note: () => _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
            quadrant: _selectedQuadrant,
            priority: MatrixQuadrant.fromId(_selectedQuadrant).priority,
            deadlineAt: () => deadlineUtc,
            repeatRule: () => _repeatRule?.storageValue,
            updatedAt: now,
          )
        : Task(
            id: _uuid.v4(),
            title: title,
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
            durationMin: 30,
            quadrant: _selectedQuadrant,
            priority: MatrixQuadrant.fromId(_selectedQuadrant).priority,
            projectName: widget.initialProject,
            deadlineAt: deadlineUtc,
            repeatRule: _repeatRule?.storageValue,
            createdAt: now,
            updatedAt: now,
          );

    Navigator.of(context).pop(task);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final quadrant = MatrixQuadrant.fromId(_selectedQuadrant);

    return Container(
      height:
          mediaQuery.size.height *
          (mediaQuery.size.width > mediaQuery.size.height ? 0.96 : 0.9),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Compact editor header.
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton.filledTonal(
                  tooltip: 'ปิดหน้าสร้างงาน',
                  onPressed: () {
                    MossHaptics.light();
                    Navigator.of(context).pop();
                  },
                  icon: Icon(Icons.close_rounded),
                ),
                Text(
                  widget.editTask != null ? 'แก้ไขงาน' : 'งานใหม่',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _titleController,
                  builder: (context, value, child) {
                    final hasTitle = value.text.trim().isNotEmpty;
                    return IconButton.filled(
                      key: ValueKey<bool>(hasTitle),
                      tooltip: hasTitle ? 'บันทึกงาน' : 'กรอกชื่องานก่อนบันทึก',
                      onPressed: hasTitle ? _submit : null,
                      icon: Icon(Icons.check_rounded),
                    );
                  },
                ),
              ],
            ),
          ),
          Divider(color: Theme.of(context).dividerColor, height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                children: [
                  // Card 1: Title and Notes
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          label: 'ชื่องาน',
                          textField: true,
                          child: TextField(
                            controller: _titleController,
                            maxLength: InputLimits.taskTitle,
                            buildCounter:
                                (
                                  _, {
                                  required currentLength,
                                  required isFocused,
                                  maxLength,
                                }) => null,
                            autofocus: true,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: 'ชื่อ',
                              hintStyle: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.64),
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        Divider(
                          color: Theme.of(context).dividerColor,
                          height: 1,
                        ),
                        Semantics(
                          label: 'โน้ตงาน',
                          textField: true,
                          child: TextField(
                            controller: _noteController,
                            maxLength: InputLimits.taskNote,
                            buildCounter:
                                (
                                  _, {
                                  required currentLength,
                                  required isFocused,
                                  maxLength,
                                }) => null,
                            minLines: 2,
                            maxLines: 4,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 14,
                              height: 1.4,
                            ),
                            decoration: InputDecoration(
                              hintText: 'โน้ต',
                              hintStyle: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.64),
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Card 2: Date, Time, Repeat, Reminder matching Image 2 & 3
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Column(
                      children: [
                        // Row 1: วันที่
                        _CardOptionRow(
                          icon: Icons.calendar_today_rounded,
                          label: 'วันที่',
                          trailing: GestureDetector(
                            onTap: _pickDate,
                            child: _PillValueBadge(
                              text: _selectedDate == null
                                  ? 'เพิ่มวันที่'
                                  : '${_selectedDate!.day} ${ThaiDateFormatter.thaiShortMonthName(_selectedDate!.month)} ${_selectedDate!.year + 543}',
                              hasValue: _selectedDate != null,
                              onClear: () {
                                setState(() {
                                  _selectedDate = null;
                                  _selectedTime = null;
                                });
                              },
                            ),
                          ),
                        ),
                        Divider(
                          color: Theme.of(context).dividerColor,
                          height: 1,
                        ),

                        // Row 2: เวลา
                        _CardOptionRow(
                          icon: Icons.access_time_rounded,
                          label: 'เวลา',
                          trailing: GestureDetector(
                            onTap: _pickTime,
                            child: _PillValueBadge(
                              text: _selectedTime == null
                                  ? 'เพิ่มเวลา'
                                  : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                              hasValue: _selectedTime != null,
                              onClear: () {
                                setState(() {
                                  _selectedTime = null;
                                });
                              },
                            ),
                          ),
                        ),
                        Divider(
                          color: Theme.of(context).dividerColor,
                          height: 1,
                        ),

                        // Row 3: ทำซ้ำ
                        _CardOptionRow(
                          icon: Icons.repeat_rounded,
                          label: 'ทำซ้ำ',
                          trailing: GestureDetector(
                            onTap: _pickRepeat,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _repeatRule?.label ?? 'ไม่เคย',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.72),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.unfold_more_rounded,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.64),
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Divider(
                          color: Theme.of(context).dividerColor,
                          height: 1,
                        ),

                        // Row 4: การแจ้งเตือน
                        _CardOptionRow(
                          icon: Icons.notifications_none_rounded,
                          label: 'การแจ้งเตือน',
                          trailing: GestureDetector(
                            onTap: _pickReminder,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _reminderRule,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.72),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.unfold_more_rounded,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.64),
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // The matrix is the single source of truth for urgency and
                  // importance. Task.priority is derived from the selection.
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Matrix Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.grid_view_rounded,
                                  size: 18,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'เมทริกซ์',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            AnimatedSwitcher(
                              duration: Duration(milliseconds: 200),
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: Offset(0.1, 0),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  ),
                              child: Text(
                                quadrant.label,
                                key: ValueKey<int>(_selectedQuadrant),
                                style: TextStyle(
                                  color: AppColors.quadrantFor(quadrant.id),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth < 520 ? 2 : 4;
                            return GridView.count(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              crossAxisCount: columns,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              mainAxisExtent: 96,
                              children: [
                                for (final item
                                    in <
                                      ({
                                        String title,
                                        int corner,
                                        Color color,
                                        int quadrant,
                                      })
                                    >[
                                      (
                                        title: 'สำคัญและเร่งด่วน',
                                        corner: 0,
                                        color: AppColors.quadrant1,
                                        quadrant: 1,
                                      ),
                                      (
                                        title: 'สำคัญ',
                                        corner: 1,
                                        color: AppColors.quadrant2,
                                        quadrant: 2,
                                      ),
                                      (
                                        title: 'เร่งด่วน',
                                        corner: 2,
                                        color: AppColors.quadrant3,
                                        quadrant: 3,
                                      ),
                                      (
                                        title: 'สักวันหนึ่ง',
                                        corner: 3,
                                        color: AppColors.quadrant4,
                                        quadrant: 4,
                                      ),
                                    ])
                                  _QuadrantBox(
                                    title: item.title,
                                    activeCorner: item.corner,
                                    accentColor: item.color,
                                    isSelected:
                                        _selectedQuadrant == item.quadrant,
                                    onTap: () {
                                      MossHaptics.selection();
                                      setState(
                                        () => _selectedQuadrant = item.quadrant,
                                      );
                                    },
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
