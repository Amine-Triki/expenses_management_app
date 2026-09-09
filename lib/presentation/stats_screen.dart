import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/budget_controller.dart';
import '../application/expense_controller.dart';
import '../application/settings_controller.dart';
import '../domain/models.dart';
import '../l10n/app_localizations.dart';
import 'money_format.dart';
import 'widgets/category_name.dart';

/// Simple statistics: period selector, total, average daily, by category,
/// top spending days. Period windows use LOCAL calendar days.
class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

enum _Period { today, week, month, cycle, custom }

class _StatsScreenState extends ConsumerState<StatsScreen> {
  _Period _period = _Period.month;
  DateTimeRange? _customRange;

  (int, int)? _windowMs(BudgetCycle? openCycle) {
    final now = DateTime.now();
    switch (_period) {
      case _Period.today:
        return (
          DateTime(now.year, now.month, now.day).millisecondsSinceEpoch,
          DateTime(now.year, now.month, now.day, 23, 59, 59, 999)
              .millisecondsSinceEpoch,
        );
      case _Period.week:
        final start = _weekStart(now);
        return (
          start.millisecondsSinceEpoch,
          DateTime(start.year, start.month, start.day + 6, 23, 59, 59, 999)
              .millisecondsSinceEpoch,
        );
      case _Period.month:
        return (
          DateTime(now.year, now.month, 1).millisecondsSinceEpoch,
          DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999)
              .millisecondsSinceEpoch,
        );
      case _Period.cycle:
        if (openCycle == null) return null;
        return (
          openCycle.window.start.toLocalDateTime().millisecondsSinceEpoch,
          openCycle.window.end.toLocalEndOfDay().millisecondsSinceEpoch,
        );
      case _Period.custom:
        final r = _customRange;
        if (r == null) return null;
        return (
          DateTime(r.start.year, r.start.month, r.start.day)
              .millisecondsSinceEpoch,
          DateTime(r.end.year, r.end.month, r.end.day, 23, 59, 59, 999)
              .millisecondsSinceEpoch,
        );
    }
  }

  DateTime _weekStart(DateTime now) {
    final daysFromMonday = (now.weekday - 1) % 7;
    return DateTime(now.year, now.month, now.day - daysFromMonday);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(appSettingsProvider).value;
    final money = MoneyFormatter(settings?.currencyCode ?? 'USD');
    final openCycle = ref.watch(openCycleProvider).value;
    final window = _windowMs(openCycle);

    final labels = {
      _Period.today: l10n.statsToday,
      _Period.week: l10n.statsThisWeek,
      _Period.month: l10n.statsThisMonth,
      _Period.cycle: l10n.statsThisCycle,
      _Period.custom: l10n.statsCustom,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.statsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final p in _Period.values)
                if (p != _Period.cycle || settings?.budgetEnabled == true)
                  ChoiceChip(
                    label: Text(labels[p]!),
                    selected: _period == p,
                    onSelected: (_) async {
                      if (p == _Period.custom) {
                        final now = DateTime.now();
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(now.year - 5),
                          lastDate: DateTime(now.year + 5),
                          initialDateRange: _customRange ??
                              DateTimeRange(
                                  start: DateTime(now.year, now.month, 1),
                                  end: now),
                        );
                        if (picked == null) return;
                        setState(() => _customRange = picked);
                      }
                      setState(() => _period = p);
                    },
                  ),
            ],
          ),
          const SizedBox(height: 16),
          if (window == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(child: Text(l10n.statsNoData)),
            )
          else ...[
            _TotalCard(window: window, money: money),
            const SizedBox(height: 16),
            Text(l10n.statsByCategory,
                style: Theme.of(context).textTheme.titleMedium),
            _ByCategory(window: window, money: money),
            const SizedBox(height: 16),
            Text(l10n.statsTopDays,
                style: Theme.of(context).textTheme.titleMedium),
            _TopDays(window: window, money: money),
          ],
        ],
      ),
    );
  }
}

class _TotalCard extends ConsumerWidget {
  const _TotalCard({required this.window, required this.money});

  final (int, int) window;
  final MoneyFormatter money;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final total = ref.watch(sumBetweenProvider(window));

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: total.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text(l10n.errorGeneric),
          data: (t) {
            final start = DateTime.fromMillisecondsSinceEpoch(window.$1);
            final end = DateTime.fromMillisecondsSinceEpoch(window.$2);
            final elapsedDays =
                end.difference(DateTime(start.year, start.month, start.day)).inDays + 1;
            final cappedDays = elapsedDays.clamp(1, 1 << 20);
            final daily = t / cappedDays;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.statsTotalSpent),
                Text(money.format(t),
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${l10n.statsAvgDaily}: ${money.formatDaily(daily)}'),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ByCategory extends ConsumerWidget {
  const _ByCategory({required this.window, required this.money});

  final (int, int) window;
  final MoneyFormatter money;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final totals = ref.watch(categoryTotalsProvider(window));

    return totals.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => Text(l10n.errorGeneric),
      data: (list) {
        if (list.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(l10n.statsNoData),
          );
        }
        final maxTotal = list.fold<int>(1, (m, c) => c.total > m ? c.total : m);
        return Column(
          children: [
            for (final c in list)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        c.categoryId == null
                            ? l10n.statsUncategorized
                            : categoryDisplayName(context, c.categoryId!),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: c.total / maxTotal,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(money.format(c.total),
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TopDays extends ConsumerWidget {
  const _TopDays({required this.window, required this.money});

  final (int, int) window;
  final MoneyFormatter money;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final days = ref.watch(topDaysProvider(window));

    return days.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => Text(l10n.errorGeneric),
      data: (list) {
        if (list.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(l10n.statsNoData),
          );
        }
        return Column(
          children: [
            for (final d in list)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Text(_formatDay(d.dayIso)),
                title: LinearProgressIndicator(
                  value: d.total / list.first.total,
                  minHeight: 8,
                ),
                trailing: Text(money.format(d.total)),
              ),
          ],
        );
      },
    );
  }

  String _formatDay(String iso) {
    final parts = iso.split('-');
    if (parts.length != 3) return iso;
    return '${int.parse(parts[2])}/${int.parse(parts[1])}';
  }
}
