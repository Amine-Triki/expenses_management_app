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
  Future<void> ensureCurrentCycle() async {
    final settings = _ref.read(appSettingsProvider).value;
    if (settings == null || !settings.budgetEnabled) return;
    final today = CalendarDate.fromDateTime(DateTime.now());

    final open = await _cycles.getOpen();
    if (open != null && open.window.containsDate(today)) return;

    BudgetCycle? lastClosed = await _cycles.getLastClosed();
    if (open != null) {
      lastClosed = await _closeCycle(open);
    }

    // The new current cycle is the one containing today — never backfilled
    // empty cycles for the gap; carry-over transfers directly.
    final window =
        CycleResolver.cycleContaining(settings.budgetStartDay, today);
    final carryOver = BudgetCalculator.carryOverAmount(
      carryOverEnabled: settings.budgetCarryOver,
      lastClosed: lastClosed == null
          ? null
          : ClosedCycleSnapshot(
              finalExpenseTotal: lastClosed.finalExpenseTotal ?? 0,
              finalRemaining: lastClosed.finalRemaining ?? 0,
            ),
    );
    await _cycles.create(
      startDay: settings.budgetStartDay,
      window: window,
      initialAmount: settings.budgetDefaultAmount,
      carryOverAmount: carryOver,
      carryOverEnabled: settings.budgetCarryOver,
      previousCycleId: lastClosed?.id,
    );
  }

  /// Closes the open cycle, writing its frozen snapshot once.
  Future<BudgetCycle> _closeCycle(BudgetCycle open) async {
    final from = open.window.start.toLocalDateTime().millisecondsSinceEpoch;
    final to = open.window.end.toLocalEndOfDay().millisecondsSinceEpoch;
    final spent = await _expenses.sumBetween(from, to);
    final remaining = open.available - spent;
    await _cycles.close(
      open.id,
      finalExpenseTotal: spent,
      finalRemaining: remaining,
    );
    return BudgetCycle(
      id: open.id,
      startDay: open.startDay,
      startDate: open.startDate,
      endDate: open.endDate,
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

  /// Activates budget mode and materializes the first cycle (retroactive by
  /// default, or a partial cycle from today — decision K.11).
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
    final window = CycleResolver.firstCycleWindow(
      startDay,
      today,
      startFromToday: startFromToday,
    );
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

  /// Edits the CURRENT cycle amount only — never the default (K.9).
  Future<void> editCurrentAmount(int newAmountMinor) async {
    final open = await _cycles.getOpen();
    if (open == null) return;
    await _cycles.updateInitialAmount(open.id, newAmountMinor);
  }

  /// Manual advanced action: close now and materialize the current cycle.
  Future<void> closeAndStartNewNow() async {
    final open = await _cycles.getOpen();
    if (open == null) return;
    await _closeCycle(open);
    await ensureCurrentCycle();
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
  if (open == null) return const Stream.empty();
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
