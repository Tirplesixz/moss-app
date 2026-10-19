import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../utils/moss_haptics.dart';
import '../utils/thai_date_formatter.dart';

/// Shows an iOS-style calendar date picker popup matching Image 3.
Future<DateTime?> showIosDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  MossHaptics.selection();
  return showGeneralDialog<DateTime>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withValues(alpha: 0.65),
    transitionDuration: Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: _IosCalendarCard(
            initialDate: initialDate,
            firstDate: firstDate ?? DateTime(2020),
            lastDate: lastDate ?? DateTime(2035),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Shows an iOS-style drum wheel time picker popup matching Image 2.
Future<TimeOfDay?> showIosTimePicker(
  BuildContext context, {
  required TimeOfDay initialTime,
}) {
  MossHaptics.selection();
  return showGeneralDialog<TimeOfDay>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withValues(alpha: 0.65),
    transitionDuration: Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: _IosWheelTimeCard(initialTime: initialTime),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

// -----------------------------------------------------------------------------
// iOS Calendar Date Card (Image 3)
// -----------------------------------------------------------------------------
class _IosCalendarCard extends StatefulWidget {
  const _IosCalendarCard({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_IosCalendarCard> createState() => _IosCalendarCardState();
}

class _IosCalendarCardState extends State<_IosCalendarCard> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;

  static final _weekdayNames = [
    'อาทิตย์',
    'จันทร์',
    'อังคาร',
    'พุธ',
    'พฤหัส',
    'ศุกร์',
    'เสาร์',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _currentMonth = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      1,
    );
  }

  void _prevMonth() {
    MossHaptics.selection();
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    MossHaptics.selection();
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final thaiMonthYear =
        '${ThaiDateFormatter.thaiMonthName(_currentMonth.month)} ${_currentMonth.year + 543}';

    // Calculate calendar grid
    final firstWeekday =
        DateTime(_currentMonth.year, _currentMonth.month, 1).weekday %
        7; // 0 = Sunday
    final daysInMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;

    return Container(
      width: 330,
      padding: EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: Color(0xFF1E2330),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Color(0xFF323B50), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: "ตุลาคม 2569 >" + "<" ">" controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    thaiMonthYear,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 18,
                  ),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: _prevMonth,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(0xFF282F40),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 20,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  GestureDetector(
                    onTap: _nextMonth,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(0xFF282F40),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),

          // Weekdays row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _weekdayNames.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      color: Color(0xFF8A93A6),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 12),

          // Days Grid (7 columns)
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: firstWeekday + daysInMonth,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 4,
              mainAxisSpacing: 6,
            ),
            itemBuilder: (context, index) {
              if (index < firstWeekday) {
                return SizedBox.shrink();
              }
              final dayNumber = index - firstWeekday + 1;
              final date = DateTime(
                _currentMonth.year,
                _currentMonth.month,
                dayNumber,
              );
              final isSelected =
                  date.year == _selectedDate.year &&
                  date.month == _selectedDate.month &&
                  date.day == _selectedDate.day;

              return GestureDetector(
                onTap: () {
                  MossHaptics.selection();
                  setState(() => _selectedDate = date);
                  Future.delayed(Duration(milliseconds: 140), () {
                    if (context.mounted) Navigator.pop(context, date);
                  });
                },
                child: Center(
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 150),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$dayNumber',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.black
                            : Theme.of(context).colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// iOS Wheel Time Picker Card (Image 2)
// -----------------------------------------------------------------------------
class _IosWheelTimeCard extends StatefulWidget {
  const _IosWheelTimeCard({required this.initialTime});

  final TimeOfDay initialTime;

  @override
  State<_IosWheelTimeCard> createState() => _IosWheelTimeCardState();
}

class _IosWheelTimeCardState extends State<_IosWheelTimeCard> {
  late int _selectedHour;
  late int _selectedMinute;

  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialTime.hour;
    _selectedMinute = widget.initialTime.minute;
    _hourController = FixedExtentScrollController(initialItem: _selectedHour);
    _minuteController = FixedExtentScrollController(
      initialItem: _selectedMinute,
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 250,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Color(0xFF1E2330),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Color(0xFF323B50), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Center highlight pill bar matching Image 2
          Center(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: Color(0xFF2C3446),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // Two Wheels (Hours : Minutes)
          Row(
            children: [
              // Hours Wheel (00-23)
              Expanded(
                child: CupertinoPicker.builder(
                  scrollController: _hourController,
                  itemExtent: 42,
                  diameterRatio: 1.2,
                  selectionOverlay: SizedBox.shrink(),
                  onSelectedItemChanged: (index) {
                    MossHaptics.selection();
                    _selectedHour = index;
                  },
                  childCount: 24,
                  itemBuilder: (context, index) {
                    return Center(
                      child: Text(
                        index.toString().padLeft(2, '0'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Separator ":"
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  ':',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              // Minutes Wheel (00-59)
              Expanded(
                child: CupertinoPicker.builder(
                  scrollController: _minuteController,
                  itemExtent: 42,
                  diameterRatio: 1.2,
                  selectionOverlay: SizedBox.shrink(),
                  onSelectedItemChanged: (index) {
                    MossHaptics.selection();
                    _selectedMinute = index;
                  },
                  childCount: 60,
                  itemBuilder: (context, index) {
                    return Center(
                      child: Text(
                        index.toString().padLeft(2, '0'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Top right Done checkmark
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () {
                MossHaptics.success();
                Navigator.pop(
                  context,
                  TimeOfDay(hour: _selectedHour, minute: _selectedMinute),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'ตกลง',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
