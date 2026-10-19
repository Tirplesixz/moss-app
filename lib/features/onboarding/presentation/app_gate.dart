import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_providers.dart';
import '../../calendar/data/device_calendar_service.dart';
import '../../today/presentation/screens/home_screen.dart';
import 'onboarding_screen.dart';

class AppGate extends ConsumerStatefulWidget {
  const AppGate({super.key});

  @override
  ConsumerState<AppGate> createState() => _AppGateState();
}

class _AppGateState extends ConsumerState<AppGate> {
  late Future<bool> _isOnboarded;

  @override
  void initState() {
    super.initState();
    _isOnboarded = _loadStatus();
  }

  Future<bool> _loadStatus() async {
    final settings = await ref.read(settingsRepositoryProvider).getSettings();
    return settings.onboardingComplete;
  }

  Future<void> _complete() async {
    final repository = ref.read(settingsRepositoryProvider);
    final settings = await repository.getSettings();

    // Automatically prompt for calendar consent without needing extra button taps.
    final calendarViewModel = ref.read(deviceCalendarViewModelProvider);
    final status = await calendarViewModel.connectAndLoad(DateTime.now());
    final hasCalendarAccess = status == CalendarAccessStatus.granted;

    await repository.updateSettings(
      settings.copyWith(
        onboardingComplete: true,
        saveCompletedToCalendar: hasCalendarAccess,
      ),
    );

    if (hasCalendarAccess) {
      await ref.read(calendarTaskSyncServiceProvider).syncAllTodoTasks();
    }

    await ref.read(eventLogRepositoryProvider).track('onboarding_completed');
    if (mounted) setState(() => _isOnboarded = Future.value(true));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isOnboarded,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data!
            ? const HomeScreen()
            : OnboardingScreen(onComplete: _complete);
      },
    );
  }
}
