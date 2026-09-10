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

    test('close creates snapshot; carry-over transfers to the new cycle',
        () async {
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

      final cycles = await container
          .read(budgetCycleRepositoryProvider)
          .watchHistory()
          .first;
      expect(cycles.length, 2);

      final today =
          CalendarDate.fromDateTime(DateTime.now());
      final closed = cycles.firstWhere((c) => c.isClosed);
      // The closed cycle keeps today as its LAST day (books include it).
      expect(closed.endDate, today);
      expect(closed.finalExpenseTotal, 200000);
      expect(closed.finalRemaining, 1300000);

      final open = cycles.firstWhere((c) => c.isOpen);
      // The new cycle starts TOMORROW — today cannot belong to two cycles.
      expect(open.startDate, today.addDays(1));
      expect(open.previousCycleId, closed.id);
      // Direct transfer from the last closed cycle (G.5).
      expect(open.carryOverAmount, 1300000);
      expect(open.available, 1500000 + 1300000);

      // No double counting: today's expense belongs to the closed cycle only.
      final summary = await controller.currentSummary();
      expect(summary!.spent, 0);
      expect(summary.remaining, open.available);
    });

    test('re-activation while a cycle is open closes it and starts tomorrow',
        () async {
      await container.read(appSettingsProvider.future);
      await activate();
      final controller = container.read(budgetControllerProvider);
      // Re-activate with a new default amount while the first cycle is open.
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
      final closed = cycles.firstWhere((c) => c.isClosed);
      final open = cycles.firstWhere((c) => c.isOpen);
      final today = CalendarDate.fromDateTime(DateTime.now());
      expect(closed.endDate, today);
      expect(closed.finalRemaining, 1500000);
      expect(open.startDate, today.addDays(1));
      expect(open.initialAmount, 2000000);
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
