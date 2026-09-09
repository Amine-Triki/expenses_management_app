import 'package:flutter_test/flutter_test.dart';
import 'package:expenses_management_app/domain/cycle_resolver.dart';

void main() {
  group('cycleContaining — flexible start days', () {
    test('start day 1 aligns with calendar month', () {
      final w = CycleResolver.cycleContaining(1, CalendarDate(2026, 9, 8));
      expect(w.start, CalendarDate(2026, 9, 1));
      expect(w.end, CalendarDate(2026, 9, 30));
    });

    test('start day 15 splits the month', () {
      final w = CycleResolver.cycleContaining(15, CalendarDate(2026, 1, 8));
      expect(w.start, CalendarDate(2025, 12, 15));
      expect(w.end, CalendarDate(2026, 1, 14));

      final w2 = CycleResolver.cycleContaining(15, CalendarDate(2026, 1, 15));
      expect(w2.start, CalendarDate(2026, 1, 15));
      expect(w2.end, CalendarDate(2026, 2, 14));
    });

    test('start day 25 splits the month', () {
      final w = CycleResolver.cycleContaining(25, CalendarDate(2026, 3, 10));
      expect(w.start, CalendarDate(2026, 2, 25));
      expect(w.end, CalendarDate(2026, 3, 24));
    });

    test('start day 31 clamps to February end', () {
      // Feb 2026 has 28 days.
      final w = CycleResolver.cycleContaining(31, CalendarDate(2026, 2, 28));
      expect(w.start, CalendarDate(2026, 2, 28));
      expect(w.end, CalendarDate(2026, 3, 30));

      final w2 = CycleResolver.cycleContaining(31, CalendarDate(2026, 3, 5));
      expect(w2.start, CalendarDate(2026, 2, 28));
      expect(w2.end, CalendarDate(2026, 3, 30));
    });

    test('start day 31 in leap February', () {
      final w = CycleResolver.cycleContaining(31, CalendarDate(2028, 2, 29));
      expect(w.start, CalendarDate(2028, 2, 29));
      expect(w.end, CalendarDate(2028, 3, 30));
    });

    test('start day 1 in February handles 28/29 days', () {
      final w = CycleResolver.cycleContaining(1, CalendarDate(2026, 2, 10));
      expect(w.start, CalendarDate(2026, 2, 1));
      expect(w.end, CalendarDate(2026, 2, 28));

      final wLeap = CycleResolver.cycleContaining(1, CalendarDate(2028, 2, 10));
      expect(wLeap.end, CalendarDate(2028, 2, 29));
    });

    test('cycle ends just before the next clamped start', () {
      // start 30: January start = 30, February start = 28.
      final w = CycleResolver.cycleContaining(30, CalendarDate(2026, 1, 31));
      expect(w.start, CalendarDate(2026, 1, 30));
      expect(w.end, CalendarDate(2026, 2, 27));
    });

    test('no cycles overlap or leave gaps across months', () {
      for (final startDay in [1, 5, 15, 25, 28, 30, 31]) {
        var cursor = CalendarDate(2026, 1, 1);
        var previousEnd = CalendarDate(2025, 12, 31);
        var first = true;
        for (var i = 0; i < 14; i++) {
          final w = CycleResolver.cycleContaining(startDay, cursor);
          if (!first) {
            expect(
              previousEnd.daysUntil(w.start),
              1,
              reason: 'cycle must start the day after the previous ends '
                  '(startDay=$startDay)',
            );
          }
          first = false;
          previousEnd = w.end;
          cursor = w.end.addDays(1);
        }
      }
    });
  });

  group('firstCycleWindow', () {
    test('retroactive activation covers the current period', () {
      final w = CycleResolver.firstCycleWindow(
        1,
        CalendarDate(2026, 9, 12),
      );
      expect(w.start, CalendarDate(2026, 9, 1));
      expect(w.end, CalendarDate(2026, 9, 30));
    });

    test('start-from-today creates a partial cycle to the period end', () {
      final w = CycleResolver.firstCycleWindow(
        1,
        CalendarDate(2026, 9, 12),
        startFromToday: true,
      );
      expect(w.start, CalendarDate(2026, 9, 12));
      expect(w.end, CalendarDate(2026, 9, 30));
    });
  });

  group('nextWindowAfter', () {
    test('follows the configured rhythm', () {
      final w = CycleResolver.nextWindowAfter(
        15,
        const CycleWindow(
          start: CalendarDate(2026, 1, 15),
          end: CalendarDate(2026, 2, 14),
        ),
      );
      expect(w.start, CalendarDate(2026, 2, 15));
      expect(w.end, CalendarDate(2026, 3, 14));
    });

    test('next after a clamped cycle keeps the stored intent', () {
      // Cycle clamped to start 2026-02-28 (startDay 31); the next cycle starts
      // on March 31, not on the 28th of March.
      final w = CycleResolver.nextWindowAfter(
        31,
        const CycleWindow(
          start: CalendarDate(2026, 2, 28),
          end: CalendarDate(2026, 3, 30),
        ),
      );
      expect(w.start, CalendarDate(2026, 3, 31));
      expect(w.end, CalendarDate(2026, 4, 29));
    });
  });

  test('CalendarDate parsing and formatting', () {
    expect(CalendarDate.tryParse('2026-09-08'), CalendarDate(2026, 9, 8));
    expect(CalendarDate.tryParse('2026-02-30'), isNull);
    expect(CalendarDate.tryParse('nonsense'), isNull);
    expect(CalendarDate(2026, 9, 8).iso, '2026-09-08');
  });
}
