/// Pure budget calculations. Everything is derived from authoritative records
/// at call time; the only frozen values are closed-cycle snapshots.
library;

import 'cycle_resolver.dart';

/// A closed cycle's frozen snapshot.
class ClosedCycleSnapshot {
  const ClosedCycleSnapshot({
    required this.finalExpenseTotal,
    required this.finalRemaining,
  });

  final int finalExpenseTotal;
  final int finalRemaining;
}

/// Live calculations for an open cycle.
///
/// All amounts are integer minor units.
class BudgetCalculator {
  /// Total spent inside [window]: the caller supplies the sum of active
  /// expenses whose spent date falls within the window (minor units).
  ///
  /// Available = initial + carry-over (may be negative after overspending).
  static int available({
    required int initialAmount,
    required int carryOverAmount,
  }) =>
      initialAmount + carryOverAmount;

  static int remaining({
    required int initialAmount,
    required int carryOverAmount,
    required int spentInCycle,
  }) =>
      initialAmount + carryOverAmount - spentInCycle;

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

  /// Carry-over for a NEW cycle, per the explicit rule: transfer directly from
  /// the last closed cycle's snapshot when carry-over is enabled for the new
  /// cycle; otherwise 0 (fresh start — negative remainders are not secretly
  /// forgiven, they are simply not transferred).
  static int carryOverAmount({
    required bool carryOverEnabled,
    required ClosedCycleSnapshot? lastClosed,
  }) {
    if (!carryOverEnabled || lastClosed == null) return 0;
    return lastClosed.finalRemaining;
  }
}
