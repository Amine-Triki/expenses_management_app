/// Pure budget calculations. Everything is derived from authoritative records
/// at call time; the only frozen values are closed-cycle snapshots.
library;

import 'cycle_resolver.dart';

/// Live calculations for an open cycle.
///
/// All amounts are integer minor units.
class BudgetCalculator {
  /// Total spent inside [window]: the caller supplies the sum of active
  /// expenses whose spent date falls within the window (minor units).
  ///
  /// Available is the amount explicitly assigned to this cycle.
  static int available({required int initialAmount}) => initialAmount;

  static int remaining({
    required int initialAmount,
    required int spentInCycle,
  }) => initialAmount - spentInCycle;

  /// Days left in the cycle, counting today as an available spending day.
  /// Returns 0 when [today] is after the cycle end.
  static int remainingDays(CycleWindow window, CalendarDate today) {
    if (today.isBefore(window.start)) return window.totalDays;
    if (today.isAfter(window.end)) return 0;
    return today.daysUntil(window.end) + 1;
  }

  /// Daily available amount — informational only, never a limit.
  /// Returns null outside a cycle (e.g. between close and next open) where a
  /// division by zero days would be meaningless.
  static double? dailyAvailable({
    required int remainingMinor,
    required int remainingDays,
  }) {
    if (remainingDays <= 0) return null;
    return remainingMinor / remainingDays;
  }
}
