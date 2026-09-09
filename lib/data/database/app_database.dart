import 'package:drift/drift.dart';
import '../../domain/models.dart' show ExpenseSource;

part 'app_database.g.dart';

/// Expenses — the authoritative record of spending.
/// Money fields are integer minor units; timestamps are UTC epoch milliseconds.
@TableIndex(name: 'idx_expenses_spent_at', columns: {#spentAt, #deletedAt})
@TableIndex(name: 'idx_expenses_category', columns: {#categoryId})
class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  // Final amount adopted by the user at save time (minor units). Source of truth.
  IntColumn get amount => integer()();
  // Scaled ×1000. NULL means the user did not enter a quantity.
  IntColumn get quantity => integer().nullable()();
  // Minor units. NULL when the final amount was entered directly.
  IntColumn get unitPrice => integer().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get note => text().nullable()();
  // Actual transaction time (may be in the past), distinct from createdAt.
  IntColumn get spentAt => integer()();
  TextColumn get expenseSource => textEnum<ExpenseSource>()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Categories. Builtin categories store a translation key (e.g. 'cat.food');
/// user-created categories store raw text.
@TableIndex(name: 'idx_categories_name', columns: {#name})
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Budget cycles. One row per actual cycle, materialized at activation and at
/// close only (lazy materialization). Snapshot fields (final_*, closed_at) are
/// frozen at close and never recomputed. start/end dates are local calendar
/// dates stored as 'yyyy-MM-dd' strings — not UTC instants.
@TableIndex(name: 'idx_budget_cycles_end_date', columns: {#endDate})
class BudgetCycles extends Table {
  TextColumn get id => text()();
  IntColumn get startDay => integer()();
  TextColumn get startDate => text()();
  TextColumn get endDate => text()();
  IntColumn get initialAmount => integer()();
  IntColumn get carryOverAmount => integer()();
  BoolColumn get carryOverEnabled => boolean()();
  TextColumn get previousCycleId => text().nullable()();
  IntColumn get closedAt => integer().nullable()();
  IntColumn get finalExpenseTotal => integer().nullable()();
  IntColumn get finalRemaining => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Shopping lists. Manual archiving only (archived_at is separate from
/// soft deletion).
class ShoppingLists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get archivedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Shopping list items. The estimated amount is NOT stored — it is derived at
/// display time as quantity × estimatedUnitPrice with a single half-up round.
@TableIndex(name: 'idx_items_list', columns: {#shoppingListId})
@TableIndex(name: 'idx_items_expense', columns: {#expenseId})
class ShoppingListItems extends Table {
  TextColumn get id => text()();
  TextColumn get shoppingListId => text().references(ShoppingLists, #id)();
  TextColumn get name => text()();
  // Scaled ×1000. Defaults to 1000 (= 1) as an actual initial value.
  IntColumn get quantity => integer()();
  IntColumn get estimatedUnitPrice => integer().nullable()();
  TextColumn get note => text().nullable()();
  BoolColumn get purchased => boolean().withDefault(const Constant(false))();
  IntColumn get purchasedAt => integer().nullable()();
  TextColumn get expenseId => text().nullable()();
  // Only authoritative when no active linked expense exists.
  IntColumn get actualAmount => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Application settings, key-value. Local only — not sync-ready in the MVP.
class SettingsItems extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [
  Expenses,
  Categories,
  BudgetCycles,
  ShoppingLists,
  ShoppingListItems,
  SettingsItems,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // Versioned migrations only; never assume an empty user database.
        },
      );
}
