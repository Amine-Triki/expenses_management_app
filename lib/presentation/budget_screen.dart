import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/budget_controller.dart';
import '../application/expense_controller.dart' show budgetControllerProvider;
import '../application/settings_controller.dart';
import '../l10n/app_localizations.dart';
import 'formatting.dart' show formatDateIso;
import 'money_format.dart';
import 'decimal_input.dart';

/// Budget setup and management: enable form when off, live cycle card +
/// history when on. Current vs Default amounts are separate (K.9).
class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(appSettingsProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.budgetTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (settings == null)
            const SizedBox.shrink()
          else if (!settings.budgetEnabled) ...[
            Text(l10n.budgetDisabledTitle,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(l10n.budgetDisabledHint),
            const SizedBox(height: 16),
            _EnableForm(defaultAmount: settings.budgetDefaultAmount),
          ] else ...[
            const _CurrentCycleCard(),
            const SizedBox(height: 16),
            const _ManagementActions(),
            const SizedBox(height: 24),
            Text(l10n.budgetHistory,
                style: Theme.of(context).textTheme.titleMedium),
            const _HistoryList(),
          ],
        ],
      ),
    );
  }
}

class _EnableForm extends ConsumerStatefulWidget {
  const _EnableForm({required this.defaultAmount});

  final int defaultAmount;

  @override
  ConsumerState<_EnableForm> createState() => _EnableFormState();
}

class _EnableFormState extends ConsumerState<_EnableForm> {
  late final TextEditingController _amountC;
  int _startDay = 1;
  bool _carryOver = false;
  bool _startFromToday = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(appSettingsProvider).value;
    _startDay = settings?.budgetStartDay ?? 1;
    _carryOver = settings?.budgetCarryOver ?? false;
    final money = MoneyFormatter(settings?.currencyCode ?? 'USD');
    _amountC = TextEditingController(
      text: widget.defaultAmount > 0
          ? money.format(widget.defaultAmount, withCode: false)
          : '',
    );
  }

  @override
  void dispose() {
    _amountC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(appSettingsProvider).value;
    final money = MoneyFormatter(settings?.currencyCode ?? 'USD');

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _amountC,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^[0-9]*[.,]?[0-9]*$')),
              ],
              decoration:
                  InputDecoration(labelText: l10n.budgetInitialAmount),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _startDay,
              decoration: InputDecoration(labelText: l10n.budgetStartDay),
              items: [
                for (var d = 1; d <= 31; d++)
                  DropdownMenuItem(value: d, child: Text('$d')),
              ],
              onChanged: (v) => setState(() => _startDay = v ?? 1),
            ),
            SwitchListTile(
              value: _carryOver,
              onChanged: (v) => setState(() => _carryOver = v),
              title: Text(l10n.budgetCarryOver),
              subtitle: Text(l10n.budgetCarryOverHint),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              value: _startFromToday,
              onChanged: (v) => setState(() => _startFromToday = v),
              title: Text(l10n.budgetStartFromToday),
              subtitle: Text(l10n.budgetStartFromTodayHint),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              icon: const Icon(Icons.savings_outlined),
              label: Text(l10n.budgetEnable),
              onPressed: () async {
                final amount = money.parse(_amountC.text);
                // Never fail silently: an invalid amount must be visible.
                if (amount == null || amount <= 0) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(l10n.expenseInvalidAmount)));
                  return;
                }
                await ref.read(budgetControllerProvider).activateBudget(
                      defaultAmountMinor: amount,
                      startDay: _startDay,
                      carryOver: _carryOver,
                      startFromToday: _startFromToday,
                    );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentCycleCard extends ConsumerWidget {
  const _CurrentCycleCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(appSettingsProvider).value;
    final money = MoneyFormatter(settings?.currencyCode ?? 'USD');
    final summary = ref.watch(openCycleSummaryProvider);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: summary.when(
          loading: () => const Center(
              child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          )),
          error: (e, _) => Text(l10n.errorGeneric),
          data: (s) {
            if (s == null) return Text(l10n.budgetDisabledTitle);
            final negative = s.remaining < 0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.budgetCurrentCycle,
                    style: Theme.of(context).textTheme.titleMedium),
                Text('${formatDateIso(context, s.cycle.window.start)} – '
                    '${formatDateIso(context, s.cycle.window.end)}'),
                const SizedBox(height: 8),
                Text(money.format(s.remaining),
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: negative
                                ? Theme.of(context).colorScheme.error
                                : null)),
                Text(negative
                    ? l10n.budgetOverBudget
                    : l10n.homeRemaining),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${l10n.homeSpent}: ${money.format(s.spent)}'),
                    Text(l10n.homeDaysLeft(s.remainingDays)),
                  ],
                ),
                Text(
                    '${l10n.homeDailyAvailable}: ${money.formatDaily(s.dailyAvailable)}'),
                if (s.cycle.carryOverAmount != 0)
                  Text(l10n.budgetCarryOverApplied(
                      money.format(s.cycle.carryOverAmount))),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => _editAmount(context, ref, s, money),
                  child: Text(l10n.budgetEditAmount),
                ),
                Text(l10n.budgetEditAmountNote,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _editAmount(BuildContext context, WidgetRef ref,
      OpenCycleSummary s, MoneyFormatter money) async {
    final l10n = AppLocalizations.of(context)!;
    final c = TextEditingController(
        text: money.format(s.cycle.available, withCode: false));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.budgetEditAmount),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            ...DotDecimalFormatter.standard,
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.commonCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.commonSave)),
        ],
      ),
    );
    if (ok != true) return;
    final amount = money.parse(c.text);
    if (amount == null || amount <= 0) return;
    await ref.read(budgetControllerProvider).editCurrentAmount(amount);
  }
}

class _ManagementActions extends ConsumerWidget {
  const _ManagementActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.restart_alt),
          label: Text(l10n.budgetStartNewCycleNow),
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                content: Text(l10n.budgetNewCycleConfirm),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l10n.commonCancel)),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(l10n.commonConfirm)),
                ],
              ),
            );
            if (ok == true) {
              await ref
                  .read(budgetControllerProvider)
                  .closeAndStartNewNow();
            }
          },
        ),
        TextButton.icon(
          icon: const Icon(Icons.close),
          label: Text(l10n.budgetDisable),
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                content: Text(l10n.budgetDisableConfirm),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l10n.commonCancel)),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(l10n.commonConfirm)),
                ],
              ),
            );
            if (ok == true) {
              await ref.read(budgetControllerProvider).deactivateBudget();
            }
          },
        ),
      ],
    );
  }
}

class _HistoryList extends ConsumerWidget {
  const _HistoryList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(appSettingsProvider).value;
    final money = MoneyFormatter(settings?.currencyCode ?? 'USD');
    final history = ref.watch(budgetHistoryProvider);

    return history.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => Text(l10n.errorGeneric),
      data: (cycles) => Column(
        children: [
          for (final c in cycles)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                c.isOpen
                    ? Icons.play_circle_outline
                    : Icons.check_circle_outline,
                color: c.isOpen
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: Text('${formatDateIso(context, c.startDate)} – '
                  '${formatDateIso(context, c.endDate)}'),
              subtitle: Text(c.isOpen
                  ? l10n.budgetCycleActive
                  : l10n.budgetCycleClosed),
              trailing: c.isClosed
                  ? Text(money.format(c.finalRemaining ?? 0))
                  : null,
            ),
        ],
      ),
    );
  }
}
