import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expenses_management_app/application/expense_controller.dart'
    show budgetControllerProvider, expenseControllerProvider;
import 'package:expenses_management_app/application/providers.dart';
import 'package:expenses_management_app/application/settings_controller.dart';
import 'package:expenses_management_app/application/shopping_controller.dart';
import 'package:expenses_management_app/data/database/app_database.dart';
import 'package:expenses_management_app/data/repositories/settings_repository.dart';
import 'package:expenses_management_app/domain/cycle_resolver.dart';
import 'package:expenses_management_app/domain/models.dart';

void main() {
  late ProviderContainer container;
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
    ]);
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
  });

  group('expense repository', () {
    test('add, live sum, soft delete affects sums', () async {
      await container.read(categoryRepositoryProvider).seedBuiltins();
      final repo = container.read(expenseRepositoryProvider);
      final now = DateTime.now().millisecondsSinceEpoch;

      await repo.add(
          name: 'Milk',
          amount: 4500,
          spentAtMs: now,
          source: ExpenseSource.manual);
      await repo.add(
          name: 'Bread',
          amount: 2000,
          spentAtMs: now,
          source: ExpenseSource.manual);

      expect(await repo.sumBetween(0, now + 1), 6500);

      final all = await repo.watchAll().first;
      expect(all.length, 2);
      final milk = all.firstWhere((e) => e.name == 'Milk');

      await repo.softDelete(milk.id);
      expect(await repo.sumBetween(0, now + 1), 2000);

      // Soft delete keeps the record physically.
      final row = await (db.select(db.expenses)
            ..where((e) => e.id.equals(milk.id)))
          .getSingle();
      expect(row.deletedAt, isNotNull);
    });

    test('update changes updated_at, never created_at', () async {
      final repo = container.read(expenseRepositoryProvider);
      final now = DateTime.now().millisecondsSinceEpoch;
      final e = await repo.add(
          name: 'Coffee',
          amount: 3500,
          spentAtMs: now,
          source: ExpenseSource.manual);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await repo.update(e, amount: 4000);

      final row = await (db.select(db.expenses)
            ..where((x) => x.id.equals(e.id)))
          .getSingle();
      expect(row.amount, 4000);
      expect(row.createdAt, e.createdAtMs);
      expect(row.updatedAt, greaterThan(e.updatedAtMs));
    });
  });

  group('budget lifecycle (lazy materialization)', () {
    Future<void> activate({bool carryOver = true, int amount = 1500000}) {
      return container
          .read(budgetControllerProvider)
          .activateBudget(
            defaultAmountMinor: amount,
            startDay: 1,
            carryOver: carryOver,
          );
    }

    test('activation materializes the current cycle only', () async {
      await container.read(appSettingsProvider.future);
      await activate();

      final open = await container
          .read(budgetCycleRepositoryProvider)
          .getOpen();
      expect(open, isNotNull);
      expect(
        open!.window
            .containsDate(CalendarDate.fromDateTime(DateTime.now())),
        isTrue,
      );
      expect(open.available, 1500000);

      // ensureCurrentCycle is a no-op while the cycle contains today.
      await container
          .read(budgetControllerProvider)
          .ensureCurrentCycle();
      final history =
          await container.read(budgetCycleRepositoryProvider).watchHistory().first;
      expect(history.length, 1);
    });

    test('manual restart: closed ends YESTERDAY, new starts TODAY', () async {
      await container.read(appSettingsProvider.future);
      await activate();
      final now = DateTime.now().millisecondsSinceEpoch;
      await container.read(expenseRepositoryProvider).add(
          name: 'Groceries',
          amount: 200000,
          spentAtMs: now,
          source: ExpenseSource.manual);

      final controller = container.read(budgetControllerProvider);
      await controller.closeAndStartNewNow();

      final today = CalendarDate.fromDateTime(DateTime.now());
      final yesterday = today.addDays(-1);
      final cycles = await container
          .read(budgetCycleRepositoryProvider)
          .watchHistory()
          .first;
      expect(cycles.length, 2);

      final closed = cycles.firstWhere((c) => c.isClosed);
      // The closed cycle keeps a full-day window ending yesterday.
      expect(closed.endDate, yesterday);
      // Today's expense is NOT in the closed books — it belongs to the new
      // cycle, so nothing is counted twice and nothing is lost.
      expect(closed.finalExpenseTotal, 0);
      expect(closed.finalRemaining, 1500000);

      final open = cycles.firstWhere((c) => c.isOpen);
      expect(open.startDate, today);
      expect(open.previousCycleId, closed.id);
      expect(open.carryOverAmount, 1500000);
      expect(open.available, 3000000);

      // The open cycle MUST contain today — otherwise every app open would
      // re-close and re-create cycles, re-attributing all old expenses.
      expect(open.window.containsDate(today), isTrue);
      final summary = await controller.currentSummary();
      expect(summary!.spent, 200000);
      expect(summary.remaining, 3000000 - 200000);
    });

    test('repeated restarts never double-count or go negative', () async {
      await container.read(appSettingsProvider.future);
      await activate();
      final now = DateTime.now().millisecondsSinceEpoch;
      final controller = container.read(budgetControllerProvider);
      await container.read(expenseRepositoryProvider).add(
          name: 'A', amount: 200000, spentAtMs: now, source: ExpenseSource.manual);
      await controller.closeAndStartNewNow();
      await container.read(expenseRepositoryProvider).add(
          name: 'B', amount: 100000, spentAtMs: now, source: ExpenseSource.manual);
      await controller.closeAndStartNewNow();
      await container.read(expenseRepositoryProvider).add(
          name: 'C', amount: 50000, spentAtMs: now, source: ExpenseSource.manual);

      final summary = await controller.currentSummary();
      final today = CalendarDate.fromDateTime(DateTime.now());
      final open = summary!.cycle;
      expect(open.window.containsDate(today), isTrue);

      // Every expense counted EXACTLY once across the books: the closed
      // snapshots own nothing of today (their windows end yesterday), and
      // the open cycle owns all of today's expenses. No double counting,
      // no negative remaining from re-attributed history.
      final cycles = await container
          .read(budgetCycleRepositoryProvider)
          .watchHistory()
          .first;
      final closedSpent = cycles
          .where((c) => c.isClosed)
          .fold<int>(0, (s, c) => s + (c.finalExpenseTotal ?? 0));
      expect(closedSpent, 0);
      expect(summary.spent, 350000);
      expect(summary.remaining, greaterThan(0));
    });

    test('re-activation while a retroactive cycle is open closes it',
        () async {
      await container.read(appSettingsProvider.future);
      await activate();
      final controller = container.read(budgetControllerProvider);
      await controller.activateBudget(
        defaultAmountMinor: 2000000,
        startDay: 1,
        carryOver: false,
      );

      final cycles = await container
          .read(budgetCycleRepositoryProvider)
          .watchHistory()
          .first;
      expect(cycles.length, 2);
      final today = CalendarDate.fromDateTime(DateTime.now());
      final closed = cycles.firstWhere((c) => c.isClosed);
      expect(closed.endDate, today.addDays(-1));
      expect(closed.finalExpenseTotal, 0);
      final open = cycles.firstWhere((c) => c.isOpen);
      expect(open.startDate, today);
      expect(open.initialAmount, 2000000);
      expect(open.window.containsDate(today), isTrue);
    });

    test('expiry: natural end kept, carry transfers, new cycle holds today',
        () async {
      await container.read(appSettingsProvider.future);
      // Budget must be ON with carry-over enabled before the gap simulation.
      await container
          .read(appSettingsProvider.notifier)
          .setBudgetEnabled(true);
      await container
          .read(appSettingsProvider.notifier)
          .setBudgetCarryOver(true);
      // Simulate a long absence: a cycle created two months ago with an
      // expense inside it, then the app opens today.
      final now = DateTime.now();
      final twoMonthsAgo =
          CalendarDate.fromDateTime(DateTime(now.year, now.month - 2, 3));
      final oldWindow = CycleResolver.cycleContaining(1, twoMonthsAgo);
      final repo = container.read(expenseRepositoryProvider);
      await repo.add(
        name: 'Old',
        amount: 300000,
        spentAtMs: oldWindow.start
            .addDays(1)
            .toLocalDateTime()
            .millisecondsSinceEpoch,
        source: ExpenseSource.manual,
      );
      await container
          .read(budgetCycleRepositoryProvider)
          .create(
            startDay: 1,
            window: oldWindow,
            initialAmount: 1500000,
            carryOverAmount: 0,
            carryOverEnabled: true,
          );
      // The app opens today: ensureCurrentCycle closes the gap.
      final controller = container.read(budgetControllerProvider);
      await controller.ensureCurrentCycle();

      final cycles = await container
          .read(budgetCycleRepositoryProvider)
          .watchHistory()
          .first;
      final closed = cycles.firstWhere((c) => c.isClosed);
      expect(closed.endDate, oldWindow.end); // natural end preserved
      expect(closed.finalExpenseTotal, 300000);
      expect(closed.finalRemaining, 1200000);

      final open = cycles.firstWhere((c) => c.isOpen);
      final today = CalendarDate.fromDateTime(DateTime.now());
      expect(open.window.containsDate(today), isTrue);
      expect(open.carryOverAmount, 1200000);
      final summary = await controller.currentSummary();
      expect(summary!.spent, 0); // old expense belongs to the closed cycle
    });

    test('carry-over disabled starts fresh', () async {
      await container.read(appSettingsProvider.future);
      await activate(carryOver: false);
      final now = DateTime.now().millisecondsSinceEpoch;
      await container.read(expenseRepositoryProvider).add(
          name: 'X',
          amount: 500000,
          spentAtMs: now,
          source: ExpenseSource.manual);

      await container
          .read(budgetControllerProvider)
          .closeAndStartNewNow();
      final open = await container
          .read(budgetCycleRepositoryProvider)
          .getOpen();
      expect(open!.carryOverAmount, 0);
      expect(open.available, 1500000);
    });

    test('deactivation stops the lifecycle; history is kept', () async {
      await container.read(appSettingsProvider.future);
      await activate();
      await container.read(budgetControllerProvider).deactivateBudget();
      await container
          .read(budgetControllerProvider)
          .ensureCurrentCycle();
      final history = await container
          .read(budgetCycleRepositoryProvider)
          .watchHistory()
          .first;
      expect(history.length, 1); // nothing new materialized
    });
  });

  group('shopping purchase → expense conversion (K.4, E.5)', () {
    test('item-by-item conversion uses the ACTUAL amount', () async {
      final shopping = container.read(shoppingControllerProvider);
      final listId = await shopping.createList('Weekly');

      final item = await shopping.addItem(
        listId: listId,
        name: 'Milk',
        quantityScaled: 2000, // 2
        estimatedUnitPriceMinor: 4500, // 4.500
      );
      // Derived estimate = 2 × 4.500 = 9.000 (display-time only).
      expect(item.estimatedAmount, 9000);

      await shopping.purchaseItem(
        item,
        actualAmountMinor: 5000, // 5.000 actual
        recordAsExpense: true,
      );

      final expenses =
          await container.read(expenseRepositoryProvider).watchAll().first;
      expect(expenses.length, 1);
      expect(expenses.first.amount, 5000); // ACTUAL, not estimated
      expect(expenses.first.source, ExpenseSource.shoppingList);

      final items =
          await container.read(shoppingRepositoryProvider).watchItems(listId).first;
      expect(items.first.purchased, isTrue);
      expect(items.first.expenseId, expenses.first.id);
      expect(items.first.actualAmount, 5000);
    });

    test('purchase without conversion keeps actual_amount only', () async {
      final shopping = container.read(shoppingControllerProvider);
      final listId = await shopping.createList('Quick');
      final item = await shopping.addItem(
        listId: listId,
        name: 'Water',
        quantityScaled: 1000,
        estimatedUnitPriceMinor: 1000,
      );
      await shopping.purchaseItem(item,
          actualAmountMinor: 1200, recordAsExpense: false);

      final expenses =
          await container.read(expenseRepositoryProvider).watchAll().first;
      expect(expenses, isEmpty);
      final items =
          await container.read(shoppingRepositoryProvider).watchItems(listId).first;
      expect(items.first.actualAmount, 1200);
      expect(items.first.expenseId, isNull);
    });
  });

  group('purchase groups (same receipt)', () {
    test('items share one group; totals derive from members, no double count',
        () async {
      final controller = container.read(expenseControllerProvider);
      final repo = container.read(expenseRepositoryProvider);
      final now = DateTime.now().millisecondsSinceEpoch;

      final groupId = await controller.startGroup('Corner shop');
      await controller.addExpense(
          name: 'Milk', amountMinor: 1500, groupId: groupId, spentAtMs: now);
      await controller.addExpense(
          name: 'Soap', amountMinor: 800, groupId: groupId, spentAtMs: now);
      await controller.addExpense(
          name: 'Water', amountMinor: 400, groupId: groupId, spentAtMs: now);

      final all = await repo.watchAll().first;
      expect(all.length, 3);
      expect(all.every((e) => e.groupId == groupId), isTrue);
      final names = await repo.groupNamesFor([groupId]);
      expect(names[groupId], 'Corner shop');
      // Budget sums include every member exactly once.
      expect(await repo.sumBetween(0, now + 1), 2700);
    });
  });

  group('settings & wipe', () {
    test('wipe removes everything and resets to first run', () async {
      await container.read(categoryRepositoryProvider).seedBuiltins();
      final settings = container.read(settingsRepositoryProvider);
      await settings.set(SettingsRepository.keyCurrency, 'TND');
      await container.read(expenseRepositoryProvider).add(
          name: 'A',
          amount: 100,
          spentAtMs: DateTime.now().millisecondsSinceEpoch,
          source: ExpenseSource.manual);

      await settings.wipeAllData();
      await container.read(categoryRepositoryProvider).seedBuiltins();

      final cats = await container
          .read(categoryRepositoryProvider)
          .watchAll()
          .first;
      expect(cats.length, 7); // reseeded
      final expenses =
          await container.read(expenseRepositoryProvider).watchAll().first;
      expect(expenses, isEmpty);
      expect(await settings.get(SettingsRepository.keyCurrency), isNull);
    });
  });
}
