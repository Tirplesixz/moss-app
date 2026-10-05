import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifications/notification_service.dart';
import 'database_providers.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final notifRepo = ref.watch(notifRepositoryProvider);
  final service = NotificationService(notifRepository: notifRepo);
  return service;
});
