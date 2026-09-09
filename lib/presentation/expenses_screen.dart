import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/expense_controller.dart';
import '../application/settings_controller.dart';
import '../domain/models.dart';
import '../l10n/app_localizations.dart';
import 'add_expense_screen.dart';
import 'formatting.dart' show dayKeyOf;
import 'money_format.dart';
import 'widgets/category_name.dart';
import 'widgets/expense_tile.dart';

/// Expense history: search, category filter, day-grouped list with totals.
class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(appSettingsProvider).value;
    final money = MoneyFormatter(settings?.currencyCode ?? 'USD');
    final filter = ref.watch(expenseFilterProvider);
    final categories = ref.watch(categoriesProvider);
    final expenses = ref.watch(expenseListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navExpenses),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => ref
                        .read(expenseFilterProvider.notifier)
                        .set(filter.copyWith(search: v)),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: l10n.expensesSearch,
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                categories.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => const SizedBox.shrink(),
                  data: (list) => DropdownButton<String?>(
                    value: filter.categoryId,
                    hint: Text(l10n.expensesFilterCategory),
                    items: [
                      DropdownMenuItem<String?>(
                          value: null,
                          child: Text(l10n.expensesAllCategories)),
                      for (final c in list)
                        DropdownMenuItem<String?>(
                          value: c.id,
                          child: Text(c.isBuiltin
                              ? builtinCategoryName(context, c.name)
                              : c.name),
                        ),
                    ],
                    onChanged: (v) => ref
                        .read(expenseFilterProvider.notifier)
                        .set(filter.copyWith(categoryId: v)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: expenses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorGeneric)),
        data: (list) {
          if (list.isEmpty) {
            return Center(child: Text(l10n.expensesEmpty));
          }
          final groups = <String, List<Expense>>{};
          for (final e in list) {
            groups.putIfAbsent(dayKeyOf(e.spentAtMs), () => []).add(e);
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: groups.length,
            itemBuilder: (context, i) {
              final day = groups.keys.elementAt(i);
              final items = groups[day]!;
              final dayTotal = items.fold<int>(0, (s, e) => s + e.amount);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_dayLabel(context, day),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        Text(
                            '${l10n.expensesDayTotal}: ${money.format(dayTotal)}',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  for (final e in items)
                    Dismissible(
                      key: ValueKey(e.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: AlignmentDirectional.centerEnd,
                        padding: const EdgeInsetsDirectional.only(end: 24),
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: Icon(Icons.delete_outline,
                            color: Theme.of(context)
                                .colorScheme
                                .onErrorContainer),
                      ),
                      confirmDismiss: (_) =>
                          _confirmDelete(context, ref, e),
                      onDismissed: (_) {},
                      child: ExpenseTile(
                        expense: e,
                        money: money,
                        onTap: () =>
                            openAddExpenseScreen(context, existing: e),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String _dayLabel(BuildContext context, String dayIso) {
    final l10n = AppLocalizations.of(context)!;
    final todayKey = dayKeyOf(DateTime.now().millisecondsSinceEpoch);
    final yesterdayKey = dayKeyOf(DateTime.now()
        .subtract(const Duration(days: 1))
        .millisecondsSinceEpoch);
    if (dayIso == todayKey) return l10n.commonToday;
    if (dayIso == yesterdayKey) return l10n.commonYesterday;
    final parts = dayIso.split('-');
    if (parts.length != 3) return dayIso;
    return '${int.parse(parts[2])}/${int.parse(parts[1])}/${parts[0]}';
  }
}

Future<bool> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  Expense expense,
) async {
  final l10n = AppLocalizations.of(context)!;
  final money = MoneyFormatter(
      ref.read(appSettingsProvider).value?.currencyCode ?? 'USD');
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content:
          Text(l10n.expenseDeleteConfirm(money.format(expense.amount))),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel)),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.commonDelete)),
      ],
    ),
  );
  if (ok == true) {
    await ref.read(expenseControllerProvider).deleteExpense(expense.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.expenseDeleted)));
    }
  }
  return ok ?? false;
}
