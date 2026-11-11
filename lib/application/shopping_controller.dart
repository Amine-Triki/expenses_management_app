import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/expense_repository.dart';
import '../data/repositories/shopping_repository.dart';
import '../domain/models.dart';
import 'list_reminder_service.dart';
import 'providers.dart';
import 'settings_controller.dart';

/// Shopping list + purchase/conversion flow (item by item only — K.4).
class ShoppingController {
  ShoppingController(this._ref);

  final Ref _ref;

  ShoppingRepository get _shopping => _ref.read(shoppingRepositoryProvider);
  ExpenseRepository get _expenses => _ref.read(expenseRepositoryProvider);

  Future<String> createList(String name) => _shopping.createList(name);

  Future<void> archiveList(String id, {required bool archived}) =>
      _archiveList(id, archived: archived);

  Future<void> _archiveList(String id, {required bool archived}) async {
    await _shopping.archiveList(id, archived: archived);
    if (archived) {
      await ListReminderService.instance.cancel(id);
    } else {
      final list = await _shopping.getList(id);
      if (list != null) {
        final language = _ref.read(appSettingsProvider).value?.languageCode;
        await ListReminderService.instance.schedule(
          list,
          languageCode: language ?? 'en',
        );
      }
    }
  }

  Future<void> setReminder(
    String id, {
    required int? reminderLocalMs,
    required ListReminderRecurrence? recurrence,
  }) async {
    if (reminderLocalMs != null &&
        recurrence == ListReminderRecurrence.monthly) {
      final local = fromFloating(reminderLocalMs);
      if (local.day > 28) {
        throw ArgumentError(
          'Monthly reminder dates must be on or before day 28.',
        );
      }
    }
    await _shopping.setReminder(
      id,
      reminderAtMs: reminderLocalMs,
      recurrence: recurrence,
    );
    final list = await _shopping.getList(id);
    if (list != null) {
      final language = _ref.read(appSettingsProvider).value?.languageCode;
      await ListReminderService.instance.schedule(
        list,
        languageCode: language ?? 'en',
      );
    }
  }

  Future<void> deleteList(String id) async {
    await _shopping.softDeleteList(id);
    await ListReminderService.instance.cancel(id);
  }

  Future<ShoppingItem> addItem({
    required String listId,
    required String name,
    required int quantityScaled,
    int? estimatedUnitPriceMinor,
    String? categoryId,
    String? note,
  }) => _shopping.addItem(
    listId: listId,
    name: name,
    quantity: quantityScaled,
    estimatedUnitPrice: estimatedUnitPriceMinor,
    categoryId: categoryId,
    note: note,
  );

  Future<void> updateItem(
    ShoppingItem item, {
    String? name,
    int? quantityScaled,
    Object? estimatedUnitPriceMinor = _unset,
    Object? categoryId = _unset,
    Object? note = _unset,
  }) => _shopping.updateItem(
    item,
    name: name,
    quantity: quantityScaled,
    estimatedUnitPrice: estimatedUnitPriceMinor,
    categoryId: categoryId,
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
      categoryId: item.categoryId,
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

final activeListsProvider = StreamProvider<List<ShoppingList>>(
  (ref) => ref.watch(shoppingRepositoryProvider).watchLists(archived: false),
);

final archivedListsProvider = StreamProvider<List<ShoppingList>>(
  (ref) => ref.watch(shoppingRepositoryProvider).watchLists(archived: true),
);

final shoppingListItemsProvider = StreamProvider.autoDispose
    .family<List<ShoppingItem>, String>((ref, listId) {
      return ref.watch(shoppingRepositoryProvider).watchItems(listId);
    });

final shoppingControllerProvider = Provider<ShoppingController>(
  (ref) => ShoppingController(ref),
);
