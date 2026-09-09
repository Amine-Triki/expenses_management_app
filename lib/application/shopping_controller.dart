import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/expense_repository.dart';
import '../data/repositories/shopping_repository.dart';
import '../domain/models.dart';
import 'providers.dart';

/// Shopping list + purchase/conversion flow (item by item only — K.4).
class ShoppingController {
  ShoppingController(this._ref);

  final Ref _ref;

  ShoppingRepository get _shopping => _ref.read(shoppingRepositoryProvider);
  ExpenseRepository get _expenses => _ref.read(expenseRepositoryProvider);

  Future<String> createList(String name) => _shopping.createList(name);

  Future<void> archiveList(String id, {required bool archived}) =>
      _shopping.archiveList(id, archived: archived);

  Future<void> deleteList(String id) => _shopping.softDeleteList(id);

  Future<ShoppingItem> addItem({
    required String listId,
    required String name,
    required int quantityScaled,
    int? estimatedUnitPriceMinor,
    String? note,
  }) =>
      _shopping.addItem(
        listId: listId,
        name: name,
        quantity: quantityScaled,
        estimatedUnitPrice: estimatedUnitPriceMinor,
        note: note,
      );

  Future<void> updateItem(
    ShoppingItem item, {
    String? name,
    int? quantityScaled,
    Object? estimatedUnitPriceMinor = _unset,
    Object? note = _unset,
  }) =>
      _shopping.updateItem(
        item,
        name: name,
        quantity: quantityScaled,
        estimatedUnitPrice: estimatedUnitPriceMinor,
        note: note,
      );

  Future<void> deleteItem(String itemId) => _shopping.softDeleteItem(itemId);

  /// Marks the item purchased with the actual price; optionally converts it
  /// into a real expense (default flow). The expense uses the ACTUAL amount,
  /// is stamped with the purchase time, and keeps a traceable link.
  Future<void> purchaseItem(
    ShoppingItem item, {
    required int actualAmountMinor,
    required bool recordAsExpense,
  }) async {
    await _shopping.markPurchased(item.id, actualAmountMinor);
    if (!recordAsExpense) return;
    final expense = await _expenses.add(
      name: item.name,
      amount: actualAmountMinor,
      quantity: item.quantity,
      note: item.note,
      spentAtMs: DateTime.now().millisecondsSinceEpoch,
      source: ExpenseSource.shoppingList,
    );
    await _shopping.linkExpense(item.id, expense.id);
  }
}

const _unset = Object();

/// Derived list totals — computed at display time, never stored.
ShoppingListTotals computeTotals(List<ShoppingItem> items) {
  var total = 0;
  var unestimated = 0;
  for (final item in items) {
    if (!item.isActive || item.purchased) continue;
    final est = item.estimatedAmount;
    if (est == null) {
      unestimated += 1;
    } else {
      total += est;
    }
  }
  return ShoppingListTotals(total: total, unestimated: unestimated);
}

final activeListsProvider = StreamProvider<List<ShoppingList>>((ref) =>
    ref.watch(shoppingRepositoryProvider).watchLists(archived: false));

final archivedListsProvider = StreamProvider<List<ShoppingList>>((ref) =>
    ref.watch(shoppingRepositoryProvider).watchLists(archived: true));

final shoppingListItemsProvider =
    StreamProvider.autoDispose.family<List<ShoppingItem>, String>(
        (ref, listId) {
  return ref.watch(shoppingRepositoryProvider).watchItems(listId);
});

final shoppingControllerProvider =
    Provider<ShoppingController>((ref) => ShoppingController(ref));
