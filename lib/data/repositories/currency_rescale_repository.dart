import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/money_math.dart';
import 'settings_repository.dart';
import '../database/app_database.dart';

class CurrencyRescaleRepository {
  CurrencyRescaleRepository(this._db);

  final AppDatabase _db;

  Future<bool> hasLossyValues({
    required int oldDigits,
    required int newDigits,
  }) async {
    if (newDigits >= oldDigits) return false;
    final factor = _pow10(oldDigits - newDigits);
    bool lossy(int value) => value.abs() % factor != 0;
    for (final row in await _db.select(_db.expenses).get()) {
      if (lossy(row.amount) ||
          (row.unitPrice != null && lossy(row.unitPrice!))) {
        return true;
      }
    }
    for (final row in await _db.select(_db.shoppingListItems).get()) {
      if ((row.estimatedUnitPrice != null && lossy(row.estimatedUnitPrice!)) ||
          (row.actualAmount != null && lossy(row.actualAmount!))) {
        return true;
      }
    }
    for (final row in await _db.select(_db.budgetCycles).get()) {
      if (lossy(row.initialAmount) ||
          lossy(row.carryOverAmount) ||
          (row.finalExpenseTotal != null && lossy(row.finalExpenseTotal!))) {
        return true;
      }
    }
    for (final row in await _db.select(_db.expenseTemplates).get()) {
      if (lossy(row.amount) ||
          (row.unitPrice != null && lossy(row.unitPrice!))) {
        return true;
      }
    }
    final setting =
        await (_db.select(_db.settingsItems)..where(
              (s) => s.key.equals(SettingsRepository.keyBudgetDefaultAmount),
            ))
            .getSingleOrNull();
    final value = int.tryParse(setting?.value ?? '');
    return value != null && lossy(value);
  }

  Future<void> rescale({
    required int oldDigits,
    required int newDigits,
    required String newCode,
  }) async {
    if (await hasLossyValues(oldDigits: oldDigits, newDigits: newDigits)) {
      final directory = await getApplicationDocumentsDirectory();
      final snapshot = File(
        p.join(directory.path, 'currency_rescale_snapshot.sqlite'),
      );
      if (await snapshot.exists()) await snapshot.delete();
      await _db.customStatement(
        "VACUUM INTO '${snapshot.path.replaceAll("'", "''")}'",
      );
    }
    await _db.transaction(() async {
      int? scaleValue(int? value) => value == null
          ? null
          : rescaleMinorUnitValue(value, oldDigits, newDigits);

      for (final row in await _db.select(_db.expenses).get()) {
        await (_db.update(
          _db.expenses,
        )..where((t) => t.id.equals(row.id))).write(
          ExpensesCompanion(
            amount: Value(
              rescaleMinorUnitValue(row.amount, oldDigits, newDigits),
            ),
            unitPrice: Value(scaleValue(row.unitPrice)),
          ),
        );
      }

      for (final row in await _db.select(_db.shoppingListItems).get()) {
        await (_db.update(
          _db.shoppingListItems,
        )..where((t) => t.id.equals(row.id))).write(
          ShoppingListItemsCompanion(
            estimatedUnitPrice: Value(scaleValue(row.estimatedUnitPrice)),
            actualAmount: Value(scaleValue(row.actualAmount)),
          ),
        );
      }
      for (final row in await _db.select(_db.budgetCycles).get()) {
        final initial = rescaleMinorUnitValue(
          row.initialAmount,
          oldDigits,
          newDigits,
        );
        final carry = rescaleMinorUnitValue(
          row.carryOverAmount,
          oldDigits,
          newDigits,
        );
        final total = scaleValue(row.finalExpenseTotal);
        final remaining = row.closedAt == null
            ? scaleValue(row.finalRemaining)
            : total == null
            ? null
            : initial + carry - total;
        await (_db.update(
          _db.budgetCycles,
        )..where((t) => t.id.equals(row.id))).write(
          BudgetCyclesCompanion(
            initialAmount: Value(initial),
            carryOverAmount: Value(carry),
            finalExpenseTotal: Value(total),
            finalRemaining: Value(remaining),
          ),
        );
      }
      for (final row in await _db.select(_db.expenseTemplates).get()) {
        await (_db.update(
          _db.expenseTemplates,
        )..where((t) => t.id.equals(row.id))).write(
          ExpenseTemplatesCompanion(
            amount: Value(
              rescaleMinorUnitValue(row.amount, oldDigits, newDigits),
            ),
            unitPrice: Value(scaleValue(row.unitPrice)),
          ),
        );
      }
      final setting =
          await (_db.select(_db.settingsItems)..where(
                (s) => s.key.equals(SettingsRepository.keyBudgetDefaultAmount),
              ))
              .getSingleOrNull();
      if (setting != null) {
        final value = int.tryParse(setting.value);
        if (value != null) {
          await (_db.update(_db.settingsItems)..where(
                (s) => s.key.equals(SettingsRepository.keyBudgetDefaultAmount),
              ))
              .write(
                SettingsItemsCompanion(
                  value: Value(
                    '${rescaleMinorUnitValue(value, oldDigits, newDigits)}',
                  ),
                ),
              );
        }
      }

      await (_db
          .into(_db.settingsItems)
          .insertOnConflictUpdate(
            SettingsItemsCompanion.insert(
              key: SettingsRepository.keyCurrency,
              value: newCode,
            ),
          ));
    });
  }
}

int _pow10(int exponent) {
  var value = 1;
  for (var i = 0; i < exponent; i++) {
    value *= 10;
  }
  return value;
}
