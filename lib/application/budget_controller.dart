import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/budget_cycle_repository.dart';
import '../data/repositories/expense_repository.dart';
import '../domain/budget_calculator.dart';
import '../domain/cycle_resolver.dart';
import '../domain/models.dart';
import 'providers.dart';
import 'settings_controller.dart';

/// Owns the lazy budget-cycle lifecycle:
/// live current cycle → close (snapshot) → new current cycle.
/// No future rows, no empty backfilled cycles; carry-over transfers directly
/// from the last closed cycle (planning document C.6 / G.5).
class BudgetController {
  BudgetController(this._ref);

  final Ref _ref;

  ExpenseRepository get _expenses => _ref.read(expenseRepositoryProvider);
  BudgetCycleRepository get _cycles =>
      _ref.read(budgetCycleRepositoryProvider);

  /// Called at app start and on resume: closes an expired open cycle (with a
  /// frozen snapshot) and materializes the cycle containing today, if needed.
  /// The open cycle ALWAYS contains today afterwards.
  Future<void> ensureCurrentCycle() async {
    final settings = _ref.read(appSettingsProvider).value;
    if (settings == null || !settings.budgetEnabled) return;
    final today = CalendarDate.fromDateTime(DateTime.now());

    final open = await _cycles.getOpen();
    if (open != null && open.window.containsDate(today)) return;

    BudgetCycle? lastClosed = await _cycles.getLastClosed();
    if (open != null) {
      if (today.isAfter(open.startDate)) {
        // Expired cycle: closes at its natural end.
        lastClosed =
            await _closeCycle(open, effectiveEnd: _cutOffDay(open, today));
      } else {
        // Never start a cycle in the future (legacy junk): abort it.
        await _cycles.softDelete(open.id);
      }
    }

    final snapshot = lastClosed == null
        ? null
        : ClosedCycleSnapshot(
            finalExpenseTotal: lastClosed.finalExpenseTotal ?? 0,
            finalRemaining: lastClosed.finalRemaining ?? 0,
          );
    final carryOver = BudgetCalculator.carryOverAmount(
      carryOverEnabled: settings.budgetCarryOver,
      lastClosed: snapshot,
    );
    // The new cycle is the one containing today — never backfilled empty
    // cycles for the gap; carry-over transfers directly from the last closed.
    await _cycles.create(
      startDay: settings.budgetStartDay,
      window: _partialFrom(settings.budgetStartDay, today),
      initialAmount: settings.budgetDefaultAmount,
      carryOverAmount: carryOver,
      carryOverEnabled: settings.budgetCarryOver,
      previousCycleId: lastClosed?.id,
    );
  }

  /// Closes the open cycle, writing its frozen snapshot once. [effectiveEnd]
  /// overrides the cycle's last day (a manual early restart cuts the period
  /// at today inclusive) so the books cover exactly the window's days —
  /// no calendar day may belong to two cycles.
  Future<BudgetCycle> _closeCycle(BudgetCycle open,
      {CalendarDate? effectiveEnd}) async {
    final lastDay = effectiveEnd ?? open.endDate;
    final from = open.window.start.toLocalDateTime().millisecondsSinceEpoch;
    final to = lastDay.toLocalEndOfDay().millisecondsSinceEpoch;
    final spent = await _expenses.sumBetween(from, to);
    final remaining = open.available - spent;
    await _cycles.close(
      open.id,
      finalExpenseTotal: spent,
      finalRemaining: remaining,
      endDateOverride: lastDay.iso,
    );
    return BudgetCycle(
      id: open.id,
      startDay: open.startDay,
      startDate: open.startDate,
      endDate: lastDay,
      initialAmount: open.initialAmount,
      carryOverAmount: open.carryOverAmount,
      carryOverEnabled: open.carryOverEnabled,
      previousCycleId: open.previousCycleId,
      closedAtMs: DateTime.now().millisecondsSinceEpoch,
      finalExpenseTotal: spent,
      finalRemaining: remaining,
      createdAtMs: open.createdAtMs,
      updatedAtMs: open.updatedAtMs,
    );
  }

  /// The last day an open cycle should cover when cut short manually:
  /// today (inclusive) — or its natural end when it already expired.
  CalendarDate _cutOffDay(BudgetCycle open, CalendarDate today) =>
      today.isAfter(open.endDate) ? open.endDate : today;

  /// Partial window from [start] to the natural end of the period
  /// containing it (K.11 pattern).
  CycleWindow _partialFrom(int startDay, CalendarDate start) {
    final containing = CycleResolver.cycleContaining(startDay, start);
    return CycleWindow(start: start, end: containing.end);
  }

  /// Activates budget mode and materializes the first cycle (retroactive by
  /// default, or a partial cycle from today — decision K.11). If a cycle is
  /// still open (re-activation after turning budget off), it is ended per
  /// the invariant rule — never two open cycles.
  Future<void> activateBudget({
    required int defaultAmountMinor,
    required int startDay,
    required bool carryOver,
    bool startFromToday = false,
  }) async {
    final notifier = _ref.read(appSettingsProvider.notifier);
    await notifier.setBudgetDefaultAmount(defaultAmountMinor);
    await notifier.setBudgetStartDay(startDay);
    await notifier.setBudgetCarryOver(carryOver);
    await notifier.setBudgetEnabled(true);

    final today = CalendarDate.fromDateTime(DateTime.now());
    final open = await _cycles.getOpen();
    if (open != null) {
      await _endOpenCycle(open, today);
    }

    final window = open == null
        ? CycleResolver.firstCycleWindow(startDay, today,
            startFromToday: startFromToday)
        : _partialFrom(startDay, today);
    await _cycles.create(
      startDay: startDay,
      window: window,
      initialAmount: defaultAmountMinor,
      carryOverAmount: 0,
      carryOverEnabled: carryOver,
      previousCycleId: null,
    );
  }

  /// Turns budget mode off; past cycles remain as history snapshots.
  Future<void> deactivateBudget() async {
    await _ref.read(appSettingsProvider.notifier).setBudgetEnabled(false);
  }

  /// Edits the current cycle's AVAILABLE amount (owner feedback): the value
  /// the user enters is what REMAINS from now on, so
  /// `initial = entered + spent so far`. It never touches the default (K.9).
  Future<void> editCurrentAmount(int availableMinor) async {
    final open = await _cycles.getOpen();
    if (open == null) return;
    final from = open.window.start.toLocalDateTime().millisecondsSinceEpoch;
    final to = open.window.end.toLocalEndOfDay().millisecondsSinceEpoch;
    final spent = await _expenses.sumBetween(from, to);
    await _cycles
        .updateInitialAmount(open.id, availableMinor + spent);
  }

  /// THE INVARIANT: the open cycle always contains today. Every lifecycle
  /// operation preserves it — otherwise every app open re-runs close/create
  /// and old expenses get re-attributed to the new cycle (negative amounts).
  ///
  /// Ends the open cycle without violating the invariant:
  /// - cycle started before today → closes with YESTERDAY as its last day
  ///   (end_date rewritten; snapshot covers [start..yesterday]);
  /// - cycle started today → aborted (tombstoned), returning the carry it
  ///   inherited so no money is silently lost.
  /// Returns the effective closed snapshot for carry-over, or null.
  Future<ClosedCycleSnapshot?> _endOpenCycle(
    BudgetCycle open,
    CalendarDate today,
  ) async {
    if (!today.isAfter(open.startDate)) {
      await _cycles.softDelete(open.id);
      return ClosedCycleSnapshot(
        finalExpenseTotal: 0,
        finalRemaining: open.carryOverAmount,
      );
    }
    final closed = await _closeCycle(open, effectiveEnd: today.addDays(-1));
    return ClosedCycleSnapshot(
      finalExpenseTotal: closed.finalExpenseTotal ?? 0,
      finalRemaining: closed.finalRemaining ?? 0,
    );
  }

  /// Manual advanced action: end the current cycle as of YESTERDAY and start
  /// the new one TODAY (partial window to the period's natural end).
  /// Disjoint windows: every expense is counted exactly once, and the open
  /// cycle always contains today.
  Future<void> closeAndStartNewNow() async {
    final settings = _ref.read(appSettingsProvider).value;
    if (settings == null || !settings.budgetEnabled) return;
    final open = await _cycles.getOpen();
    if (open == null) return;

    final today = CalendarDate.fromDateTime(DateTime.now());
    final snapshot = await _endOpenCycle(open, today);

    final carryOver = BudgetCalculator.carryOverAmount(
      carryOverEnabled: settings.budgetCarryOver,
      lastClosed: snapshot,
    );
    await _cycles.create(
      startDay: settings.budgetStartDay,
      window: _partialFrom(settings.budgetStartDay, today),
      initialAmount: settings.budgetDefaultAmount,
      carryOverAmount: carryOver,
      carryOverEnabled: settings.budgetCarryOver,
      previousCycleId: open.id,
    );
  }

  /// Live summary for the open cycle.
  Future<OpenCycleSummary?> currentSummary() async {
    final settings = _ref.read(appSettingsProvider).value;
    final open = await _cycles.getOpen();
    if (settings == null || !settings.budgetEnabled || open == null) {
      return null;
    }
    final from = open.window.start.toLocalDateTime().millisecondsSinceEpoch;
    final to = open.window.end.toLocalEndOfDay().millisecondsSinceEpoch;
    final spent = await _expenses.sumBetween(from, to);
    final remaining = open.available - spent;
    final days = BudgetCalculator.remainingDays(
        open.window, CalendarDate.fromDateTime(DateTime.now()));
    return OpenCycleSummary(
      cycle: open,
      spent: spent,
      remaining: remaining,
      remainingDays: days,
      dailyAvailable: BudgetCalculator.dailyAvailable(
          remainingMinor: remaining, remainingDays: days),
    );
  }
}

class OpenCycleSummary {
  const OpenCycleSummary({
    required this.cycle,
    required this.spent,
    required this.remaining,
    required this.remainingDays,
    required this.dailyAvailable,
  });

  final BudgetCycle cycle;
  final int spent;
  final int remaining;
  final int remainingDays;
  final double? dailyAvailable;
}

final openCycleProvider = StreamProvider<BudgetCycle?>((ref) =>
    ref.watch(budgetCycleRepositoryProvider).watchOpen());

/// Live open-cycle summary: reacts to both the cycle row and expenses.
final openCycleSummaryProvider =
    StreamProvider.autoDispose<OpenCycleSummary?>((ref) {
  final open = ref.watch(openCycleProvider).value;
  if (open == null) {
    // Never leave the UI in a forever-loading state: null is a VALUE here
    // (budget on but cycle not materialized yet).
    return Stream.value(null);
  }
  final from = open.window.start.toLocalDateTime().millisecondsSinceEpoch;
  final to = open.window.end.toLocalEndOfDay().millisecondsSinceEpoch;
  return ref
      .watch(expenseRepositoryProvider)
      .watchSumBetween(from, to)
      .map((spent) {
    final today = CalendarDate.fromDateTime(DateTime.now());
    final remaining = open.available - spent;
    final days = BudgetCalculator.remainingDays(open.window, today);
    return OpenCycleSummary(
      cycle: open,
      spent: spent,
      remaining: remaining,
      remainingDays: days,
      dailyAvailable: BudgetCalculator.dailyAvailable(
          remainingMinor: remaining, remainingDays: days),
    );
  });
});

final budgetHistoryProvider = StreamProvider<List<BudgetCycle>>((ref) =>
    ref.watch(budgetCycleRepositoryProvider).watchHistory());
