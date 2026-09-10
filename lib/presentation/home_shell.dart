import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'add_expense_screen.dart';
import 'expenses_screen.dart';
import 'home_screen.dart';
import 'lists_screen.dart';
import 'stats_screen.dart';

/// Four-tab shell (Home / Expenses / Lists / Stats) with a global add-expense
/// FAB — Budget and Settings are secondary destinations from Home.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          ExpensesScreen(),
          ListsScreen(),
          StatsScreen(),
        ],
      ),
      floatingActionButton: _index == 2
          ? null // Lists tab has its own "new list" FAB.
          : FloatingActionButton(
              // IndexedStack keeps every tab alive: FAB hero tags MUST be
              // unique or every route push triggers a hero-exception storm.
              heroTag: 'fab-add-expense',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const AddExpenseScreen()),
              ),
              tooltip: l10n.expenseAdd,
              child: const Icon(Icons.add),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: l10n.navHome),
          NavigationDestination(
              icon: const Icon(Icons.receipt_long_outlined),
              selectedIcon: const Icon(Icons.receipt_long),
              label: l10n.navExpenses),
          NavigationDestination(
              icon: const Icon(Icons.shopping_cart_outlined),
              selectedIcon: const Icon(Icons.shopping_cart),
              label: l10n.navLists),
          NavigationDestination(
              icon: const Icon(Icons.insights_outlined),
              selectedIcon: const Icon(Icons.insights),
              label: l10n.navStats),
        ],
      ),
    );
  }
}
