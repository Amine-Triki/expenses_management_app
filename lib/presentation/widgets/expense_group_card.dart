import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../money_format.dart';
import 'expense_tile.dart';

/// One purchase group rendered as a single card: group name, item count,
/// derived total (never stored), expandable member items.
class ExpenseGroupCard extends StatelessWidget {
  const ExpenseGroupCard({
    super.key,
    required this.groupName,
    required this.members,
    required this.money,
    this.onDeleteGroup,
  });

  final String groupName;
  final List<Expense> members;
  final MoneyFormatter money;
  final VoidCallback? onDeleteGroup;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = members.fold<int>(0, (s, e) => s + e.amount);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          leading: const Icon(Icons.receipt_long_outlined),
          title: Text(groupName),
          subtitle: Text(l10n.expenseGroupItems(members.length)),
          trailing: Text(
            money.format(total),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          children: [
            for (final e in members)
              ExpenseTile(
                expense: e,
                money: money,
                onTap: null,
              ),
            if (onDeleteGroup != null)
              TextButton.icon(
                onPressed: onDeleteGroup,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text(l10n.commonDelete),
              ),
          ],
        ),
      ),
    );
  }
}
