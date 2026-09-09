import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/budget_controller.dart';
import '../application/expense_controller.dart';
import '../application/settings_controller.dart';
import '../l10n/app_localizations.dart';
import 'add_expense_screen.dart';
import 'budget_screen.dart';
import 'formatting.dart';
import 'money_format.dart';
import 'settings_screen.dart';
import 'widgets/expense_tile.dart';

/// Home: budget card (when enabled) or month total, plus recent expenses.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(appSettingsProvider).value;
    final recent = ref.watch(recentExpensesProvider);
    final money = MoneyFormatter(settings?.currencyCode ?? 'USD');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.navSettings,
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          if (settings?.budgetEnabled == true)
            const _BudgetCard()
          else
            _NoBudgetCard(monthly: money),
          const SizedBox(height: 16),
          Text(l10n.homeRecentExpenses,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          recent.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text(l10n.errorGeneric),
            data: (expenses) {
              if (expenses.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Text(l10n.homeEmptyTitle,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(l10n.homeEmptyHint),
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  for (final e in expenses)
                    ExpenseTile(
                      expense: e,
                      money: money,
                      onTap: () => openAddExpenseScreen(context, existing: e),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends ConsumerWidget {
  const _BudgetCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(appSettingsProvider).value;
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
            if (s == null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.homeCycleEnded(
                      MoneyFormatter(settings?.currencyCode ?? 'USD')
                          .format(0))),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                            builder: (_) => const BudgetScreen())),
                    child: Text(l10n.navBudget),
                  ),
                ],
              );
            }
            final money = MoneyFormatter(settings?.currencyCode ?? 'USD');
            final negative = s.remaining < 0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        money.format(s.remaining),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: negative
                                  ? Theme.of(context).colorScheme.error
                                  : null,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.tune),
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) => const BudgetScreen())),
                    ),
                  ],
                ),
                Text(negative ? l10n.homeNegativeRemaining : l10n.homeRemaining),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${l10n.homeSpent}: ${money.format(s.spent)}'),
                    Text(l10n.homeDaysLeft(s.remainingDays)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        '${l10n.homeDailyAvailable}: ${money.formatDaily(s.dailyAvailable)}'),
                    Text('${formatDateIso(context, s.cycle.window.start)} – '
                        '${formatDateIso(context, s.cycle.window.end)}'),
                  ],
                ),
                if (s.cycle.carryOverAmount != 0) ...[
                  const SizedBox(height: 4),
                  Text(l10n.homeCarryOverLine(
                          money.format(s.cycle.carryOverAmount)),
                      style: Theme.of(context).textTheme.bodySmall),
                ],
                const SizedBox(height: 8),
                Text(l10n.budgetDailyInfo,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NoBudgetCard extends ConsumerWidget {
  const _NoBudgetCard({required this.monthly});

  final MoneyFormatter monthly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final total = ref.watch(monthTotalProvider);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.homeNoBudgetTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            total.when(
              loading: () => const SizedBox.shrink(),
              error: (e, _) => Text(l10n.errorGeneric),
              data: (t) => Text(l10n.homeNoBudgetHint(monthly.format(t))),
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const BudgetScreen())),
                child: Text(l10n.homeEnableBudget),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
