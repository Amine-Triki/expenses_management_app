import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../add_expense_screen.dart';
import '../money_format.dart';
import 'category_name.dart';

/// One expense row: name, time + category/note line, amount, edit on tap.
class ExpenseTile extends StatelessWidget {
  const ExpenseTile({
    super.key,
    required this.expense,
    required this.money,
    this.showTime = true,
    this.onTap,
    this.onDelete,
  });

  final Expense expense;
  final MoneyFormatter money;
  final bool showTime;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final time = DateFormat('HH:mm')
        .format(DateTime.fromMillisecondsSinceEpoch(expense.spentAtMs));
    final subtitle = <String>[
      if (showTime) time,
      if (expense.categoryId != null)
        categoryDisplayName(context, expense.categoryId!),
      if (expense.source == ExpenseSource.shoppingList)
        l10n.expenseSourceShoppingList,
      if (expense.note != null && expense.note!.isNotEmpty) expense.note!,
    ].join(' · ');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        child: Text(
          expense.name.isEmpty ? '?' : expense.name[0].toUpperCase(),
        ),
      ),
      title: Text(expense.name),
      subtitle: subtitle.isEmpty
          ? null
          : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(
        money.format(expense.amount),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      onTap: onTap ?? () => openAddExpenseScreen(context, existing: expense),
    );
  }
}
