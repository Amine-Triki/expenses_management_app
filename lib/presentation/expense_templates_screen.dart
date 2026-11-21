import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/expense_controller.dart';
import '../application/settings_controller.dart';
import '../domain/models.dart';
import '../domain/money_math.dart';
import '../l10n/app_localizations.dart';
import 'money_format.dart';
import 'formatting.dart';
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
                        '${money.format(item.amount)} · '
                        '${_recurrenceLabel(l10n, item.recurrence)} · '
                        '${item.recurrence == ExpenseTemplateRecurrence.none ? l10n.expenseTemplateReusable : l10n.expenseTemplateNextRun(AppFormat.date(context, DateTime.fromMillisecondsSinceEpoch(item.nextRunAtMs)))}',
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
    var firstRun = DateTime.now();
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
                if (recurrence != ExpenseTemplateRecurrence.none) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.templateFirstRun),
                    subtitle: Text(AppFormat.date(ctx, firstRun)),
                    onTap: () async {
                      final today = DateTime.now();
                      final picked = await showDatePicker(
                        context: ctx,
                        firstDate: DateTime(today.year, today.month, today.day),
                        lastDate: DateTime(today.year + 10),
                        initialDate: firstRun,
                      );
                      if (picked != null) {
                        setState(
                          () => firstRun = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                          ),
                        );
                      }
                    },
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      l10n.templateFirstRunHint,
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                  ),
                ],
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
    final firstRunAt =
        firstRun.day == DateTime.now().day &&
            firstRun.month == DateTime.now().month &&
            firstRun.year == DateTime.now().year
        ? DateTime.now()
        : DateTime(firstRun.year, firstRun.month, firstRun.day, 9);
    await ref
        .read(expenseTemplateControllerProvider)
        .addTemplate(
          name: parsedName,
          amount: parsedAmount,
          categoryId: categoryId,
          recurrence: recurrence,
          nextRunAtMs: firstRunAt.millisecondsSinceEpoch,
          anchorDay: firstRun.day,
        );
    if (recurrence != ExpenseTemplateRecurrence.none &&
        firstRunAt.millisecondsSinceEpoch <=
            DateTime.now().millisecondsSinceEpoch) {
      final created = await ref
          .read(expenseTemplateControllerProvider)
          .materializeDue();
      if (created > 0 && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.templateCreatedImmediately)),
        );
      }
    }
  }
}

String _recurrenceLabel(
  AppLocalizations l10n,
  ExpenseTemplateRecurrence recurrence,
) => switch (recurrence) {
  ExpenseTemplateRecurrence.none => l10n.expenseTemplateOnce,
  ExpenseTemplateRecurrence.weekly => l10n.expenseTemplateWeekly,
  ExpenseTemplateRecurrence.monthly => l10n.expenseTemplateMonthly,
};
