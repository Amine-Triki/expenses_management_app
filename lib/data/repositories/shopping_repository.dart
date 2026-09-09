import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models.dart';
import '../database/app_database.dart' as db;

/// Shopping lists and items. Lists archive manually only; deletion is soft.
class ShoppingRepository {
  ShoppingRepository(this._db);

  static const _uuid = Uuid();
  final db.AppDatabase _db;

  ShoppingList _listToModel(db.ShoppingList r) => ShoppingList(
        id: r.id,
        name: r.name,
        archivedAtMs: r.archivedAt,
        createdAtMs: r.createdAt,
        updatedAtMs: r.updatedAt,
        deletedAtMs: r.deletedAt,
      );

  ShoppingItem _itemToModel(db.ShoppingListItem r) => ShoppingItem(
        id: r.id,
        shoppingListId: r.shoppingListId,
        name: r.name,
        quantity: r.quantity,
        estimatedUnitPrice: r.estimatedUnitPrice,
        note: r.note,
        purchased: r.purchased,
        purchasedAtMs: r.purchasedAt,
        expenseId: r.expenseId,
        actualAmount: r.actualAmount,
        createdAtMs: r.createdAt,
        updatedAtMs: r.updatedAt,
        deletedAtMs: r.deletedAt,
      );

  Stream<List<ShoppingList>> watchLists({required bool archived}) {
    final query = _db.select(_db.shoppingLists)
      ..where((l) => l.deletedAt.isNull())
      ..orderBy([(l) => OrderingTerm.desc(l.createdAt)]);
    if (archived) {
      query.where((l) => l.archivedAt.isNotNull());
    } else {
      query.where((l) => l.archivedAt.isNull());
    }
    return query.watch().map((rows) => rows.map(_listToModel).toList());
  }

  Stream<List<ShoppingItem>> watchItems(String listId) {
    final query = _db.select(_db.shoppingListItems)
      ..where((i) =>
          i.shoppingListId.equals(listId) & i.deletedAt.isNull())
      ..orderBy([(i) => OrderingTerm.asc(i.createdAt)]);
    return query.watch().map((rows) => rows.map(_itemToModel).toList());
  }

  Future<String> createList(String name) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = _uuid.v4();
    await _db.into(_db.shoppingLists).insert(db.ShoppingListsCompanion.insert(
          id: id,
          name: name,
          createdAt: now,
          updatedAt: now,
        ));
    return id;
  }

  Future<void> archiveList(String listId, {required bool archived}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.shoppingLists)
          ..where((l) => l.id.equals(listId)))
        .write(db.ShoppingListsCompanion(
          archivedAt: Value(archived ? now : null),
          updatedAt: Value(now),
        ));
  }

  /// Soft-deletes a list and all its items (tombstones, sync-ready).
  Future<void> softDeleteList(String listId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.transaction(() async {
      await (_db.update(_db.shoppingLists)
              ..where((l) => l.id.equals(listId)))
          .write(db.ShoppingListsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ));
      await (_db.update(_db.shoppingListItems)
              ..where((i) => i.shoppingListId.equals(listId)))
          .write(db.ShoppingListItemsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ));
    });
  }

  Future<ShoppingItem> addItem({
    required String listId,
    required String name,
    required int quantity,
    int? estimatedUnitPrice,
    String? note,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = _uuid.v4();
    await _db.into(_db.shoppingListItems).insert(
          db.ShoppingListItemsCompanion.insert(
            id: id,
            shoppingListId: listId,
            name: name,
            quantity: quantity,
            estimatedUnitPrice: Value(estimatedUnitPrice),
            note: Value(note),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return ShoppingItem(
      id: id,
      shoppingListId: listId,
      name: name,
      quantity: quantity,
      estimatedUnitPrice: estimatedUnitPrice,
      note: note,
      purchased: false,
      createdAtMs: now,
      updatedAtMs: now,
    );
  }

  Future<void> updateItem(
    ShoppingItem item, {
    String? name,
    int? quantity,
    Object? estimatedUnitPrice = _unset,
    Object? note = _unset,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.shoppingListItems)
            ..where((i) => i.id.equals(item.id)))
        .write(db.ShoppingListItemsCompanion(
      name: name == null ? const Value.absent() : Value(name),
      quantity: quantity == null ? const Value.absent() : Value(quantity),
      estimatedUnitPrice: estimatedUnitPrice == _unset
          ? const Value.absent()
          : Value(estimatedUnitPrice as int?),
      note: note == _unset ? const Value.absent() : Value(note as String?),
      updatedAt: Value(now),
    ));
  }

  Future<void> softDeleteItem(String itemId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.shoppingListItems)
            ..where((i) => i.id.equals(itemId)))
        .write(db.ShoppingListItemsCompanion(
      deletedAt: Value(now),
      updatedAt: Value(now),
    ));
  }

  /// Marks an item purchased with the actual price the user entered.
  /// Whether an expense is created is decided by the caller (conversion flow).
  Future<void> markPurchased(String itemId, int actualAmount) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.shoppingListItems)
            ..where((i) => i.id.equals(itemId)))
        .write(db.ShoppingListItemsCompanion(
      purchased: const Value(true),
      purchasedAt: Value(now),
      actualAmount: Value(actualAmount),
      updatedAt: Value(now),
    ));
  }

  Future<void> linkExpense(String itemId, String expenseId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.shoppingListItems)
            ..where((i) => i.id.equals(itemId)))
        .write(db.ShoppingListItemsCompanion(
      expenseId: Value(expenseId),
      updatedAt: Value(now),
    ));
  }

  Future<ShoppingList?> getList(String listId) async {
    final row = await (_db.select(_db.shoppingLists)
          ..where((l) => l.id.equals(listId)))
        .getSingleOrNull();
    return row == null ? null : _listToModel(row);
  }
}

const _unset = Object();
