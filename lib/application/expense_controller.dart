import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/expense_repository.dart';
import '../domain/models.dart';
import 'budget_controller.dart';
import 'providers.dart';

/// Application-level expense operations (add / edit / soft delete).
class ExpenseController {
  ExpenseController(this._ref);

  final Ref _ref;

  ExpenseRepository get _repo => _ref.read(expenseRepositoryProvider);

  Future<Expense> addExpense({
    required String name,
    required int amountMinor,
    int? quantityScaled,
    int? unitPriceMinor,
    String? categoryId,
    String? groupId,
    String? note,
    required int spentAtMs,
  }) =>
      _repo.add(
        name: name,
        amount: amountMinor,
        quantity: quantityScaled,
        unitPrice: unitPriceMinor,
        categoryId: categoryId,
        groupId: groupId,
        note: note,
        spentAtMs: spentAtMs,
        source: ExpenseSource.manual,
      );

  /// Starts a new purchase group and returns its id.
  Future<String> startGroup(String name) =>
      _repo.createGroup(name).then((g) => g.id);

  Future<void> updateExpense(
    Expense existing, {
    String? name,
    int? amountMinor,
    int? quantityScaled,
    Object? unitPriceMinor = _unset,
    Object? categoryId = _unset,
    Object? note = _unset,
    int? spentAtMs,
  }) =>
      _repo.update(
        existing,
        name: name,
        amount: amountMinor,
        quantity: quantityScaled,
        unitPrice: unitPriceMinor,
        categoryId: categoryId,
        note: note,
        spentAtMs: spentAtMs,
      );

  Future<void> deleteExpense(String id) => _repo.softDelete(id);
}

const _unset = Object();

final budgetControllerProvider =
    Provider<BudgetController>((ref) => BudgetController(ref));

final expenseControllerProvider =
    Provider<ExpenseController>((ref) => ExpenseController(ref));

/// Live sum of expenses for a [fromMs, toMs] window (inclusive).
final sumBetweenProvider =
    StreamProvider.family<int, (int, int)>((ref, range) {
  return ref
      .watch(expenseRepositoryProvider)
      .watchSumBetween(range.$1, range.$2);
});

/// Live sum for the current local calendar month (home screen, budget off).
final monthTotalProvider = StreamProvider<int>((ref) {
  final now = DateTime.now();
  final from =
      DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
  final to = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999)
      .millisecondsSinceEpoch;
  return ref.watch(expenseRepositoryProvider).watchSumBetween(from, to);
});

/// Filtered expense history.
class ExpenseFilter {
  const ExpenseFilter({this.search, this.categoryId, this.fromMs, this.toMs});

  final String? search;
  final String? categoryId;
  final int? fromMs;
  final int? toMs;

  ExpenseFilter copyWith({
    Object? search = _fUnset,
    Object? categoryId = _fUnset,
    Object? fromMs = _fUnset,
    Object? toMs = _fUnset,
  }) =>
      ExpenseFilter(
        search: search == _fUnset ? this.search : search as String?,
        categoryId:
            categoryId == _fUnset ? this.categoryId : categoryId as String?,
        fromMs: fromMs == _fUnset ? this.fromMs : fromMs as int?,
        toMs: toMs == _fUnset ? this.toMs : toMs as int?,
      );
}

const _fUnset = Object();

class ExpenseFilterNotifier extends Notifier<ExpenseFilter> {
  @override
  ExpenseFilter build() => const ExpenseFilter();

  void set(ExpenseFilter filter) => state = filter;
}

final expenseFilterProvider =
    NotifierProvider<ExpenseFilterNotifier, ExpenseFilter>(
        ExpenseFilterNotifier.new);

final expenseListProvider =
    StreamProvider.autoDispose<ExpenseListData>((ref) {
  final f = ref.watch(expenseFilterProvider);
  return ref.watch(expenseRepositoryProvider).watchAll(
    search: f.search,
    categoryId: f.categoryId,
    fromMs: f.fromMs,
    toMs: f.toMs,
  ).asyncMap((list) async {
    // Group names resolved inside the stream — never via a FutureBuilder
    // future recreated on every rebuild (infinite query loop).
    final ids = {
      for (final e in list)
        if (e.groupId != null) e.groupId!,
    };
    final names =
        await ref.watch(expenseRepositoryProvider).groupNamesFor(ids);
    return ExpenseListData(expenses: list, groupNames: names);
  });
});

/// Expense history + display names of the groups its members belong to.
class ExpenseListData {
  const ExpenseListData({required this.expenses, required this.groupNames});

  final List<Expense> expenses;
  final Map<String, String> groupNames;
}

final shoppingListNamesProvider = FutureProvider.autoDispose
    .family<ShoppingList?, String>((ref, listId) {
  return ref.watch(shoppingRepositoryProvider).getList(listId);
});

final recentExpensesProvider = StreamProvider<List<Expense>>((ref) {
  return ref.watch(expenseRepositoryProvider).watchAll(limit: 5);
});

final categoriesProvider = StreamProvider<List<Category>>(
    (ref) => ref.watch(categoryRepositoryProvider).watchAll());

/// Statistics: per-category totals for a window.
final categoryTotalsProvider =
    StreamProvider.autoDispose.family<List<CategoryTotal>, (int, int)>(
        (ref, range) {
  return ref
      .watch(expenseRepositoryProvider)
      .watchSumByCategory(range.$1, range.$2);
});

/// Statistics: highest-spending local days for a window.
final topDaysProvider =
    StreamProvider.autoDispose.family<List<DayTotal>, (int, int)>(
        (ref, range) {
  return ref.watch(expenseRepositoryProvider).watchTopDays(range.$1, range.$2);
});
