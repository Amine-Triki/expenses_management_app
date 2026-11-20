import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/expense_controller.dart';
import '../application/settings_controller.dart';
import '../domain/models.dart';
import '../domain/money_math.dart';
import '../l10n/app_localizations.dart';
import 'money_format.dart';
import 'widgets/category_dropdown.dart';

class ExpenseTemplatesScreen extends ConsumerWidget {
  const ExpenseTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final templates = ref.watch(expenseTemplatesProvider);
    final settings = ref.watch(appSettingsProvider).value;
    final money = MoneyFormatter(settings?.currencyCode ?? 'USD');

    return Scaffold(
      appBar: AppBar(title: Text(l10n.expenseTemplates)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTemplate(context, ref, money),
        child: const Icon(Icons.add),
      ),
      body: templates.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.errorGeneric)),
        data: (items) => items.isEmpty
            ? Center(child: Text(l10n.expenseTemplatesEmpty))
            : ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, index) {
                  final item = items[index];
                  return Dismissible(
                    key: ValueKey(item.id),
                    direction: DismissDirection.endToStart,
                    background: const ColoredBox(color: Colors.red),
                    onDismissed: (_) => ref
                        .read(expenseTemplateControllerProvider)
                        .deleteTemplate(item.id),
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Text(
                        '${money.format(item.amount)} · ${item.recurrence.name}',
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _showAddTemplate(
    BuildContext context,
    WidgetRef ref,
    MoneyFormatter money,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final name = TextEditingController();
    final amount = TextEditingController();
    String? categoryId;
    var recurrence = ExpenseTemplateRecurrence.none;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l10n.expenseTemplateAdd),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: InputDecoration(labelText: l10n.expenseName),
                ),
                TextField(
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(labelText: l10n.expenseAmount),
                ),
                CategoryDropdown(
                  value: categoryId,
                  onChanged: (value) => setState(() => categoryId = value),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<ExpenseTemplateRecurrence>(
                  initialValue: recurrence,
                  items: [
                    DropdownMenuItem(
                      value: ExpenseTemplateRecurrence.none,
                      child: Text(l10n.expenseTemplateOnce),
                    ),
                    DropdownMenuItem(
                      value: ExpenseTemplateRecurrence.weekly,
                      child: Text(l10n.expenseTemplateWeekly),
                    ),
                    DropdownMenuItem(
                      value: ExpenseTemplateRecurrence.monthly,
                      child: Text(l10n.expenseTemplateMonthly),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => recurrence = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.commonSave),
            ),
          ],
        ),
      ),
    );
    final parsedName = name.text.trim();
    final parsedAmount = parseMinorUnits(amount.text, money.info.digits);
    name.dispose();
    amount.dispose();
    if (saved != true ||
        parsedName.isEmpty ||
        parsedAmount == null ||
        parsedAmount <= 0) {
      return;
    }
    await ref
        .read(expenseTemplateControllerProvider)
        .addTemplate(
          name: parsedName,
          amount: parsedAmount,
          categoryId: categoryId,
          recurrence: recurrence,
          nextRunAtMs: recurrence == ExpenseTemplateRecurrence.none
              ? DateTime.now().millisecondsSinceEpoch
              : DateTime.now().millisecondsSinceEpoch,
        );
  }
}
