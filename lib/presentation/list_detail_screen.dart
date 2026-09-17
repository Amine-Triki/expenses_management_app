import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/budget_controller.dart' show openCycleSummaryProvider;
import '../application/expense_controller.dart' show shoppingListNamesProvider;
import '../application/settings_controller.dart';
import '../application/shopping_controller.dart';
import '../domain/money_math.dart';
import '../domain/models.dart';
import '../l10n/app_localizations.dart';
import 'money_format.dart';
import 'decimal_input.dart';
import 'widgets/category_dropdown.dart';

/// One shopping list: items, estimated total, purchase → convert flow.
class ListDetailScreen extends ConsumerWidget {
  const ListDetailScreen({super.key, required this.listId});

  final String listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(appSettingsProvider).value;
    final money = MoneyFormatter(settings?.currencyCode ?? 'USD');
    final items = ref.watch(shoppingListItemsProvider(listId));
    final listInfo = ref.watch(shoppingListNamesProvider(listId)).value;
    final archived = listInfo?.isArchived ?? false;
    final budgetOn = settings?.budgetEnabled == true;
    final summary = budgetOn ? ref.watch(openCycleSummaryProvider).value : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(listInfo?.name ?? l10n.listsTitle),
        actions: [
          IconButton(
            tooltip: archived ? l10n.listUnarchive : l10n.listArchive,
            icon: Icon(
              archived ? Icons.unarchive_outlined : Icons.archive_outlined,
            ),
            onPressed: () async {
              await ref
                  .read(shoppingControllerProvider)
                  .archiveList(listId, archived: !archived);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorGeneric)),
        data: (list) {
          final totals = computeTotals(list);
          return Column(
            children: [
              Card(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.listEstimatedTotal,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        money.format(totals.total),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (totals.unestimated > 0)
                        Text(
                          l10n.listItemsWithoutEstimate(totals.unestimated),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      if (summary != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          l10n.listVsRemaining(
                            money.format(totals.total),
                            money.format(summary.remaining),
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? Center(child: Text(l10n.listEmptyList))
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 96),
                        children: [
                          for (final item in list)
                            _ItemTile(item: item, money: money),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-add-item',
        onPressed: () => _addItem(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Add-item dialog following the add-expense calculation method (G.2):
  /// the amount field holds the TOTAL, quantity and unit price sit below it,
  /// and each side auto-fills from the other (quantity × unit price ⇄ total
  /// ÷ quantity) unless the user typed that field manually. Only the unit
  /// price and quantity are stored — the total is always derived (E.5).
  Future<void> _addItem(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.read(appSettingsProvider).value;
    final money = MoneyFormatter(settings?.currencyCode ?? 'USD');
    final digits = money.info.digits;
    final nameC = TextEditingController();
    final totalC = TextEditingController();
    final qtyC = TextEditingController(text: '1');
    final unitC = TextEditingController();
    final noteC = TextEditingController();
    String? categoryId;
    var totalManual = false;
    var unitManual = false;

    int? computedTotal() {
      final qtyText = qtyC.text.trim();
      final unitText = unitC.text.trim();
      if (qtyText.isEmpty || unitText.isEmpty) return null;
      final qty = quantityToScaled(qtyText);
      final unit = parseMinorUnits(unitText, digits);
      if (qty <= 0 || unit == null) return null;
      return scaledQuantityTimesPrice(qty, unit);
    }

    int? computedUnit() {
      final totalText = totalC.text.trim();
      final qtyText = qtyC.text.trim();
      if (totalText.isEmpty || qtyText.isEmpty) return null;
      final total = parseMinorUnits(totalText, digits);
      final qty = quantityToScaled(qtyText);
      if (qty <= 0) return null;
      return priceFromTotalAndScaledQuantity(total ?? 0, qty);
    }

    String fmt(int minor) => money.format(minor, withCode: false);

    final result =
        await showDialog<
          ({
            String name,
            int? unitPrice,
            int qty,
            String? categoryId,
            String? note,
          })
        >(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setState) {
              void recalc() {
                if (!unitManual) {
                  final u = computedUnit();
                  if (u != null) unitC.text = fmt(u);
                }
                if (!totalManual) {
                  final t = computedTotal();
                  if (t != null) totalC.text = fmt(t);
                }
              }

              return AlertDialog(
                title: Text(l10n.listsAddItem),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameC,
                        autofocus: true,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: l10n.listItemName,
                        ),
                      ),
                      TextField(
                        controller: totalC,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [const DotDecimalFormatter()],
                        onChanged: (_) => setState(() => totalManual = true),
                        decoration: InputDecoration(
                          labelText: l10n.listEstimatedTotal,
                          suffixIcon: totalManual && computedUnit() != null
                              ? IconButton(
                                  tooltip: l10n.expenseAmountComputed,
                                  icon: const Icon(Icons.autorenew),
                                  onPressed: () {
                                    setState(() => totalManual = false);
                                    recalc();
                                  },
                                )
                              : null,
                        ),
                      ),
                      TextField(
                        controller: qtyC,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [const DotDecimalFormatter()],
                        onChanged: (_) {
                          setState(() {});
                          recalc();
                        },
                        decoration: InputDecoration(
                          labelText: l10n.expenseQuantity,
                        ),
                      ),
                      TextField(
                        controller: unitC,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [const DotDecimalFormatter()],
                        onChanged: (_) => setState(() => unitManual = true),
                        decoration: InputDecoration(
                          labelText: l10n.expenseUnitPrice,
                          suffixIcon: unitManual && computedTotal() != null
                              ? IconButton(
                                  tooltip: l10n.expenseAmountComputed,
                                  icon: const Icon(Icons.autorenew),
                                  onPressed: () {
                                    setState(() => unitManual = false);
                                    recalc();
                                  },
                                )
                              : null,
                        ),
                      ),
                      CategoryDropdown(
                        value: categoryId,
                        onChanged: (v) => setState(() => categoryId = v),
                      ),
                      TextField(
                        controller: noteC,
                        decoration: InputDecoration(
                          labelText: l10n.expenseNote,
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(l10n.commonCancel),
                  ),
                  FilledButton(
                    onPressed: () {
                      final name = nameC.text.trim();
                      if (name.isEmpty) return;
                      final qty = quantityToScaled(
                        qtyC.text.trim().isEmpty ? '1' : qtyC.text,
                      );
                      final total = totalC.text.trim().isEmpty
                          ? null
                          : money.parse(totalC.text);
                      final unitParsed = unitC.text.trim().isEmpty
                          ? null
                          : money.parse(unitC.text);
                      // The manually typed unit price wins; otherwise the unit
                      // price is derived from the manually entered total.
                      int? unit;
                      if (unitManual) {
                        unit = (unitParsed != null && unitParsed > 0)
                            ? unitParsed
                            : null;
                      } else if (total != null && total > 0 && qty > 0) {
                        unit = priceFromTotalAndScaledQuantity(total, qty);
                      } else if (unitParsed != null && unitParsed > 0) {
                        unit = unitParsed;
                      }
                      Navigator.pop(ctx, (
                        name: name,
                        unitPrice: unit,
                        qty: qty > 0 ? qty : 1000,
                        categoryId: categoryId,
                        note: noteC.text.trim().isEmpty
                            ? null
                            : noteC.text.trim(),
                      ));
                    },
                    child: Text(l10n.commonSave),
                  ),
                ],
              );
            },
          ),
        );
    if (result != null) {
      await ref
          .read(shoppingControllerProvider)
          .addItem(
            listId: listId,
            name: result.name,
            quantityScaled: result.qty,
            estimatedUnitPriceMinor: result.unitPrice,
            categoryId: result.categoryId,
            note: result.note,
          );
    }
  }
}

class _ItemTile extends ConsumerWidget {
  const _ItemTile({required this.item, required this.money});

  final ShoppingItem item;
  final MoneyFormatter money;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final est = item.estimatedAmount;
    // Source of truth for the actual amount (E.5): a linked ACTIVE expense
    // wins; actualAmount applies only when no linked active expense exists.
    final actualMinor = item.expenseId != null ? null : item.actualAmount;

    return ListTile(
      leading: Checkbox(
        value: item.purchased,
        onChanged: item.purchased ? null : (_) => _purchaseDialog(context, ref),
      ),
      title: Text(
        item.name,
        style: item.purchased
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: Text(
        [
          if (est != null) '${l10n.listItemEstPrice}: ${money.format(est)}',
          if (actualMinor != null)
            '${l10n.listActualPrice}: ${money.format(actualMinor)}',
          if (item.note != null && item.note!.isNotEmpty) item.note!,
        ].join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: item.purchased
          ? Icon(
              Icons.check_circle_outline,
              color: Theme.of(context).colorScheme.primary,
            )
          : IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () =>
                  ref.read(shoppingControllerProvider).deleteItem(item.id),
            ),
    );
  }

  Future<void> _purchaseDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    // The actual price is a TOTAL (stored as actualAmount → expense amount),
    // so prefill it with the estimated TOTAL, not the unit price.
    final priceC = TextEditingController(
      text: item.estimatedAmount == null
          ? ''
          : money.format(item.estimatedAmount!, withCode: false),
    );
    var record = true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l10n.listConvertTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.estimatedAmount != null)
                Text(
                  l10n.listActualPriceHint(money.format(item.estimatedAmount!)),
                ),
              TextField(
                controller: priceC,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^[0-9]*[.,]?[0-9]*$'),
                  ),
                ],
                decoration: InputDecoration(labelText: l10n.listActualPrice),
              ),
              CheckboxListTile(
                value: record,
                onChanged: (v) => setState(() => record = v ?? true),
                title: Text(l10n.listConvertQuestion),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.commonOk),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;

    final amount = money.parse(priceC.text);
    if (amount == null || amount <= 0) return;
    await ref
        .read(shoppingControllerProvider)
        .purchaseItem(item, actualAmountMinor: amount, recordAsExpense: record);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.listConverted)));
    }
  }
}
