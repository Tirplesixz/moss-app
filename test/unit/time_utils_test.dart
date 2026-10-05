import 'package:flutter_test/flutter_test.dart';
import 'package:moss/core/utils/time_utils.dart';

void main() {
  group('TimeUtils tests', () {
    test('roundUpToInterval rounds up to next 5 minutes', () {
      final t1 = DateTime.utc(2026, 9, 30, 9, 2);
      final r1 = TimeUtils.roundUpToInterval(t1, minuteInterval: 5);
      expect(r1, DateTime.utc(2026, 9, 30, 9, 5));

      final t2 = DateTime.utc(2026, 9, 30, 9, 5);
      final r2 = TimeUtils.roundUpToInterval(t2, minuteInterval: 5);
      expect(r2, DateTime.utc(2026, 9, 30, 9, 5));

      final t3 = DateTime.utc(2026, 9, 30, 9, 59);
      final r3 = TimeUtils.roundUpToInterval(t3, minuteInterval: 5);
      expect(r3, DateTime.utc(2026, 9, 30, 10, 0));
    });

    test('toUtcIsoString and parseUtc preserve exact UTC instant', () {
      final nowUtc = DateTime.utc(2026, 9, 30, 14, 30, 0);
      final iso = TimeUtils.toUtcIsoString(nowUtc);
      final parsed = TimeUtils.parseUtc(iso);
      expect(parsed.isUtc, isTrue);
      expect(parsed, nowUtc);
    });

    test(
      'parseTimeOnDate correctly combines date with HH:mm and converts to UTC',
      () {
        final date = DateTime(2026, 9, 30);
        final utcTime = TimeUtils.parseTimeOnDate(date, '09:00');
        expect(utcTime.isUtc, isTrue);
        // When converted back to local, hour should be 9, minute 0
        final local = utcTime.toLocal();
        expect(local.hour, 9);
        expect(local.minute, 0);
      },
    );
  });
}
