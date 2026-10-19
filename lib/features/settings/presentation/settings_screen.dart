import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_providers.dart';
import '../../../../core/providers/notification_providers.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../lockscreen/domain/lockscreen_config.dart';
import '../../lockscreen/presentation/lockscreen_editor_screen.dart';
import '../../stats/presentation/stats_screen.dart';
import '../../today/presentation/today_controller.dart';
import '../domain/app_settings.dart';

/// Settings only exposes features that are implemented and persisted.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  AppSettings? _settings;
  bool _lockScreenAutoUpdate = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final values = await Future.wait([
      ref.read(settingsRepositoryProvider).getSettings(),
      ref.read(lockScreenRepositoryProvider).loadActive(),
    ]);
    if (!mounted) return;
    setState(() {
      _settings = values[0] as AppSettings;
      _lockScreenAutoUpdate = (values[1] as LockScreenConfig).autoUpdate;
    });
  }

  Future<void> _saveSettings(AppSettings value) async {
    setState(() => _busy = true);
    try {
      await ref.read(settingsRepositoryProvider).updateSettings(value);
      if (mounted) setState(() => _settings = value);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setCalendarSync(bool value) async {
    final current = _settings;
    if (current == null) return;
    if (value) {
      final calendar = ref.read(deviceCalendarViewModelProvider);
      if (calendar.isDenied) {
        await calendar.openAppSettings();
        return;
      }
      await calendar.connectAndLoad(DateTime.now());
      if (!calendar.hasAccess) return;
    }
    await _saveSettings(current.copyWith(saveCompletedToCalendar: value));
    final sync = ref.read(calendarTaskSyncServiceProvider);
    if (value) {
      await sync.syncAllTodoTasks();
      await ref.read(todayControllerProvider.notifier).load();
      await ref
          .read(deviceCalendarViewModelProvider)
          .loadMonth(DateTime.now(), force: true);
    } else {
      await sync.removeAllTaskEvents();
    }
  }

  Future<void> _setLockScreenAutoUpdate(bool value) async {
    setState(() => _lockScreenAutoUpdate = value);
    final repository = ref.read(lockScreenRepositoryProvider);
    final config = await repository.loadActive();
    await repository.save(config.copyWith(autoUpdate: value));
    if (value) {
      unawaited(
        ref.read(lockScreenSyncServiceProvider).syncIfEnabled(force: true),
      );
    }
  }

  Future<void> _pickWorkTime({required bool start}) async {
    final current = _settings;
    if (current == null) return;
    final raw = start ? current.workdayStart : current.workdayEnd;
    final parts = raw.split(':').map(int.parse).toList();
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: parts[0], minute: parts[1]),
      helpText: start ? 'เวลาเริ่มวันทำงาน' : 'เวลาสิ้นสุดวันทำงาน',
    );
    if (selected == null) return;
    final value =
        '${selected.hour.toString().padLeft(2, '0')}:'
        '${selected.minute.toString().padLeft(2, '0')}';
    await _saveSettings(
      start
          ? current.copyWith(workdayStart: value)
          : current.copyWith(workdayEnd: value),
    );
  }

  Future<void> _pickBuffer() async {
    final current = _settings;
    if (current == null) return;
    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('เวลาพักระหว่างงาน'),
              subtitle: Text('ช่วยลดการจัดตารางติดกันจนเกินไป'),
            ),
            for (final minutes in const [0, 5, 10, 15, 30])
              ListTile(
                leading: Icon(
                  minutes == current.bufferMin
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                ),
                title: Text(minutes == 0 ? 'ไม่เว้นเวลา' : '$minutes นาที'),
                onTap: () => Navigator.pop(context, minutes),
              ),
          ],
        ),
      ),
    );
    if (selected != null) {
      await _saveSettings(current.copyWith(bufferMin: selected));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    final calendar = ref.watch(deviceCalendarViewModelProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'การตั้งค่า',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const ThemeToggleButton(),
                  ],
                ),
                const SizedBox(height: 20),
                const _SectionTitle('รูปลักษณ์'),
                const _SettingsCard(
                  children: [
                    _InfoRow(
                      icon: Icons.brightness_medium_rounded,
                      title: 'ธีมของแอป',
                      subtitle: 'เลือกตามระบบ สว่าง หรือมืด',
                      trailing: ThemeSegmentedSelector(),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const _SectionTitle('ตารางงาน'),
                _SettingsCard(
                  children: [
                    _ActionRow(
                      icon: Icons.wb_sunny_outlined,
                      title: 'เริ่มวันทำงาน',
                      value: settings?.workdayStart ?? '—',
                      onTap: _busy ? null : () => _pickWorkTime(start: true),
                    ),
                    _ActionRow(
                      icon: Icons.nights_stay_outlined,
                      title: 'สิ้นสุดวันทำงาน',
                      value: settings?.workdayEnd ?? '—',
                      onTap: _busy ? null : () => _pickWorkTime(start: false),
                    ),
                    _ActionRow(
                      icon: Icons.hourglass_bottom_rounded,
                      title: 'เวลาพักระหว่างงาน',
                      value: settings == null
                          ? '—'
                          : '${settings.bufferMin} นาที',
                      onTap: _busy ? null : _pickBuffer,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const _SectionTitle('ปฏิทินและการแจ้งเตือน'),
                _SettingsCard(
                  children: [
                    SwitchListTile.adaptive(
                      secondary: const Icon(Icons.event_available_rounded),
                      title: const Text('ซิงก์งานกับปฏิทิน'),
                      subtitle: Text(
                        calendar.isDenied
                            ? 'ปฏิทินถูกปฏิเสธ แตะสวิตช์เพื่อเปิดการตั้งค่าระบบ'
                            : 'เพิ่ม แก้ไข และลบ Event ให้ตรงกับงานใน Moss โดยไม่สร้างรายการซ้ำ',
                      ),
                      value: settings?.saveCompletedToCalendar ?? false,
                      onChanged: _busy || settings == null
                          ? null
                          : _setCalendarSync,
                    ),
                    _ActionRow(
                      icon: Icons.calendar_month_rounded,
                      title: 'การเข้าถึงปฏิทิน',
                      value: calendar.hasAccess
                          ? 'เชื่อมต่อแล้ว'
                          : 'ยังไม่เชื่อมต่อ',
                      onTap: calendar.loading
                          ? null
                          : () async {
                              if (calendar.isDenied) {
                                await calendar.openAppSettings();
                              } else {
                                await calendar.connectAndLoad(DateTime.now());
                              }
                            },
                    ),
                    _ActionRow(
                      icon: Icons.notifications_active_outlined,
                      title: 'อนุญาตการแจ้งเตือน',
                      value: 'จัดการสิทธิ์',
                      onTap: () async {
                        final granted = await ref
                            .read(notificationServiceProvider)
                            .requestPermission();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              granted
                                  ? 'เปิดการแจ้งเตือนแล้ว'
                                  : 'ยังไม่ได้รับอนุญาต โปรดเปิดจากการตั้งค่าระบบ',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const _SectionTitle('หน้าจอล็อก'),
                _SettingsCard(
                  children: [
                    SwitchListTile.adaptive(
                      secondary: const Icon(Icons.sync_rounded),
                      title: const Text('อัปเดตอัตโนมัติ'),
                      subtitle: const Text(
                        'อัปเดตเมื่อข้อมูลเปลี่ยนและเมื่อกลับเข้าแอปบน Android',
                      ),
                      value: _lockScreenAutoUpdate,
                      onChanged: _setLockScreenAutoUpdate,
                    ),
                    _ActionRow(
                      icon: Icons.wallpaper_rounded,
                      title: 'ปรับแต่งหน้าจอล็อก',
                      value: 'เปิดตัวแก้ไข',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const LockScreenEditorScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const _SectionTitle('สถิติและผลงาน'),
                _SettingsCard(
                  children: [
                    _ActionRow(
                      icon: Icons.insights_rounded,
                      title: 'สถิติ & สรุปสัปดาห์',
                      value: 'ดูรายงานและแชร์',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const StatsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const _SectionTitle('ข้อมูลและกฎหมาย'),
                _SettingsCard(
                  children: [
                    _ActionRow(
                      icon: Icons.help_outline_rounded,
                      title: 'วิธีใช้ Moss',
                      value: 'อ่านคู่มือ',
                      onTap: () => _openDocument('วิธีใช้ Moss', _guideText),
                    ),
                    _ActionRow(
                      icon: Icons.privacy_tip_outlined,
                      title: 'นโยบายความเป็นส่วนตัว',
                      value: 'อ่าน',
                      onTap: () =>
                          _openDocument('นโยบายความเป็นส่วนตัว', _privacyText),
                    ),
                    _ActionRow(
                      icon: Icons.description_outlined,
                      title: 'ข้อกำหนดการใช้งาน',
                      value: 'อ่าน',
                      onTap: () =>
                          _openDocument('ข้อกำหนดการใช้งาน', _termsText),
                    ),
                    const _InfoRow(
                      icon: Icons.info_outline_rounded,
                      title: 'เวอร์ชัน',
                      subtitle: '1.1.0 (2)',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Moss เก็บงานและโน้ตไว้ในเครื่อง ไม่มี Cloud Backup หรือระบบสมาชิกในเวอร์ชันนี้',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openDocument(String title, String body) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _DocumentScreen(title: title, body: body),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          children[i],
          if (i != children.length - 1) const Divider(height: 1),
        ],
      ],
    ),
  );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    minVerticalPadding: 12,
    leading: Icon(icon),
    title: Text(title),
    trailing: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 190),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    ),
    onTap: onTap,
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
              ],
              if (trailing != null) ...[const SizedBox(height: 12), trailing!],
            ],
          ),
        ),
      ],
    ),
  );
}

class _DocumentScreen extends StatelessWidget {
  const _DocumentScreen({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: SelectableText(
            body,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(height: 1.65),
          ),
        ),
      ),
    ),
  );
}

const _guideText = '''
1. เพิ่มงานจากช่องเพิ่มด่วนหรืองานเข้า
2. กำหนดความสำคัญ ระยะเวลา และกำหนดส่ง
3. Moss จัดงานลงตารางตามเวลาทำงานและเวลาพักที่ตั้งไว้
4. เปิดหน้าวันนี้เพื่อดูงานตามเวลา หรือเปิด Matrix เพื่อจัดลำดับงาน
5. งานและโน้ตถูกเก็บไว้ในเครื่องนี้
''';

const _privacyText = '''
ปรับปรุงล่าสุด 17 ตุลาคม 2569

Moss เก็บงาน ตาราง การตั้งค่า และโน้ตไว้ในฐานข้อมูลภายในเครื่อง ไม่มีการอัปโหลดข้อมูลเหล่านี้ไปยังเซิร์ฟเวอร์ของ Moss ในเวอร์ชันนี้

การเข้าถึงปฏิทินและการแจ้งเตือนเกิดขึ้นเมื่อผู้ใช้อนุญาตเท่านั้น ปฏิทินถูกอ่านเพื่อแสดงตารางและตรวจเวลาชน เมื่อเปิดการซิงก์ Moss จะสร้าง อัปเดต และลบกิจกรรมของงานในปฏิทินให้ตรงกับแอป

การลบแอปอาจลบข้อมูลภายในเครื่องทั้งหมด ปัจจุบันยังไม่มี Cloud Backup หรือการกู้คืนจากบัญชีออนไลน์
''';

const _termsText = '''
Moss เป็นเครื่องมือช่วยวางแผน ผู้ใช้ควรตรวจสอบตาราง กำหนดส่ง และการแจ้งเตือนที่สำคัญด้วยตนเอง

ฟีเจอร์หน้าจอล็อกทำงานแตกต่างกันตามระบบ: Android สามารถตั้งภาพได้โดยตรง ส่วน iOS เปิดเมนูแชร์เพื่อให้ผู้ใช้บันทึกและตั้งภาพเอง

ไม่มีการขายสมาชิก การคืนค่าการซื้อ หรือบริการ Cloud Backup ในเวอร์ชันนี้
''';
