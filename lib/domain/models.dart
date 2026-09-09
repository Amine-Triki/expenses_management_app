import 'cycle_resolver.dart';
import 'money_math.dart' show scaledQuantityTimesPrice;

/// Where an expense originated from.
enum ExpenseSource { manual, shoppingList }

/// Immutable expense model (domain). All money values are integer minor
/// units; all timestamps are UTC epoch milliseconds.
class Expense {
  const Expense({
    required this.id,
    required this.name,
    required this.amount,
    this.quantity,
    this.unitPrice,
    this.categoryId,
    this.note,
    required this.spentAtMs,
    required this.source,
    required this.createdAtMs,
    required this.updatedAtMs,
    this.deletedAtMs,
  });

  final String id;
  final String name;
  final int amount;
  final int? quantity;
  final int? unitPrice;
  final String? categoryId;
  final String? note;
  final int spentAtMs;
  final ExpenseSource source;
  final int createdAtMs;
  final int updatedAtMs;
  final int? deletedAtMs;

  bool get isActive => deletedAtMs == null;

  Expense copyWith({
    String? name,
    int? amount,
    int? quantity,
    Object? unitPrice = _unset,
    Object? categoryId = _unset,
    Object? note = _unset,
    int? spentAtMs,
    int? updatedAtMs,
  }) =>
      Expense(
        id: id,
        name: name ?? this.name,
        amount: amount ?? this.amount,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice == _unset ? this.unitPrice : unitPrice as int?,
        categoryId:
            categoryId == _unset ? this.categoryId : categoryId as String?,
        note: note == _unset ? this.note : note as String?,
        spentAtMs: spentAtMs ?? this.spentAtMs,
        source: source,
        createdAtMs: createdAtMs,
        updatedAtMs: updatedAtMs ?? this.updatedAtMs,
        deletedAtMs: deletedAtMs,
      );
}

const _unset = Object();

/// Category. Builtin categories carry a translation key in [name]
/// (e.g. 'cat.food'); user categories carry raw text.
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final int sortOrder;

  bool get isBuiltin => name.startsWith('cat.');
}

/// A budget cycle row. Open cycles have [closedAtMs] == null.
class BudgetCycle {
  const BudgetCycle({
    required this.id,
    required this.startDay,
    required this.startDate,
    required this.endDate,
    required this.initialAmount,
    required this.carryOverAmount,
    required this.carryOverEnabled,
    this.previousCycleId,
    this.closedAtMs,
    this.finalExpenseTotal,
    this.finalRemaining,
    required this.createdAtMs,
    required this.updatedAtMs,
    this.deletedAtMs,
  });

  final String id;
  final int startDay;
  final CalendarDate startDate;
  final CalendarDate endDate;
  final int initialAmount;
  final int carryOverAmount;
  final bool carryOverEnabled;
  final String? previousCycleId;
  final int? closedAtMs;
  final int? finalExpenseTotal;
  final int? finalRemaining;
  final int createdAtMs;
  final int updatedAtMs;
  final int? deletedAtMs;

  bool get isOpen => closedAtMs == null && deletedAtMs == null;
  bool get isClosed => closedAtMs != null;

  CycleWindow get window =>
      CycleWindow(start: startDate, end: endDate);

  int get available => initialAmount + carryOverAmount;
}

class ShoppingList {
  const ShoppingList({
    required this.id,
    required this.name,
    this.archivedAtMs,
    required this.createdAtMs,
    required this.updatedAtMs,
    this.deletedAtMs,
  });

  final String id;
  final String name;
  final int? archivedAtMs;
  final int createdAtMs;
  final int updatedAtMs;
  final int? deletedAtMs;

  bool get isActive => deletedAtMs == null;
  bool get isArchived => archivedAtMs != null;
}

class ShoppingItem {
  const ShoppingItem({
    required this.id,
    required this.shoppingListId,
    required this.name,
    required this.quantity,
    this.estimatedUnitPrice,
    this.note,
    required this.purchased,
    this.purchasedAtMs,
    this.expenseId,
    this.actualAmount,
    required this.createdAtMs,
    required this.updatedAtMs,
    this.deletedAtMs,
  });

  final String id;
  final String shoppingListId;
  final String name;
  final int quantity; // scaled ×1000
  final int? estimatedUnitPrice;
  final String? note;
  final bool purchased;
  final int? purchasedAtMs;
  final String? expenseId;
  final int? actualAmount;
  final int createdAtMs;
  final int updatedAtMs;
  final int? deletedAtMs;

  bool get isActive => deletedAtMs == null;

  /// Derived at display time — never stored (planning document E.5).
  /// Half-up rounding of quantity × estimated unit price, in minor units.
  int? get estimatedAmount {
    final price = estimatedUnitPrice;
    if (price == null) return null;
    return scaledQuantityTimesPrice(quantity, price);
  }
}

/// Computed totals for a shopping list, derived at display time.
class ShoppingListTotals {
  const ShoppingListTotals({required this.total, required this.unestimated});

  final int total; // minor units, open (non-purchased) items only
  final int unestimated; // count of open items without an estimate
}
