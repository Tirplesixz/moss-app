import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../today/presentation/today_controller.dart';
import '../domain/app_settings.dart';
import 'mock_paywall_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late AppSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = ref.read(todayControllerProvider.notifier).settings;
  }

  TimeOfDay _parse(String value) {
    final parts = value.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _encode(TimeOfDay value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  Future<void> _pickStart() async {
    final value = await showTimePicker(
      context: context,
      initialTime: _parse(_settings.workdayStart),
    );
    if (value != null) {
      setState(
        () => _settings = _settings.copyWith(workdayStart: _encode(value)),
      );
    }
  }

  Future<void> _pickEnd() async {
    final value = await showTimePicker(
      context: context,
      initialTime: _parse(_settings.workdayEnd),
    );
    if (value != null) {
      setState(
        () => _settings = _settings.copyWith(workdayEnd: _encode(value)),
      );
    }
  }

  Future<void> _save() async {
    final start = _parse(_settings.workdayStart);
    final end = _parse(_settings.workdayEnd);
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เวลาจบวันต้องอยู่หลังเวลาเริ่มวัน')),
      );
      return;
    }
    await ref.read(todayControllerProvider.notifier).updateSettings(_settings);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('ตั้งค่า'),
        actions: [TextButton(onPressed: _save, child: const Text('บันทึก'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text('เวลาทำงาน', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          _SettingTile(
            icon: Icons.wb_sunny_outlined,
            title: 'เริ่มวัน',
            value: _settings.workdayStart,
            onTap: _pickStart,
          ),
          _SettingTile(
            icon: Icons.nights_stay_outlined,
            title: 'จบวัน',
            value: _settings.workdayEnd,
            onTap: _pickEnd,
          ),
          const SizedBox(height: 18),
          Text(
            'เวลาพักระหว่างงาน',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('ไม่มี')),
              ButtonSegment(value: 5, label: Text('5 นาที')),
              ButtonSegment(value: 10, label: Text('10 นาที')),
              ButtonSegment(value: 15, label: Text('15 นาที')),
            ],
            selected: {_settings.bufferMin},
            onSelectionChanged: (value) {
              setState(
                () => _settings = _settings.copyWith(bufferMin: value.first),
              );
            },
          ),
          const SizedBox(height: 30),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            tileColor: theme.nowFill,
            leading: Icon(Icons.auto_awesome_rounded, color: theme.primary),
            title: const Text('ดู Moss Plus'),
            subtitle: const Text('ช่วยเราประเมินความสนใจก่อนเปิดขายจริง'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const MockPaywallScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    return Card(
      elevation: 0,
      color: theme.cardBackground,
      child: ListTile(
        leading: Icon(icon, color: theme.primary),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        onTap: onTap,
      ),
    );
  }
}
