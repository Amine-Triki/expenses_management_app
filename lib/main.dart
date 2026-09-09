import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'application/expense_controller.dart';
import 'application/providers.dart';
import 'application/settings_controller.dart';
import 'presentation/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: _Bootstrap()));
}

/// Local bootstrap: opens the database, seeds builtin categories (idempotent)
/// and runs the lazy budget-cycle lifecycle (close expired, materialize the
/// current cycle) before showing any UI.
class _Bootstrap extends ConsumerStatefulWidget {
  const _Bootstrap();

  @override
  ConsumerState<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends ConsumerState<_Bootstrap> {
  bool? _ready;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await ref.read(categoryRepositoryProvider).seedBuiltins();
      await ref.read(appSettingsProvider.future);
      await ref.read(budgetControllerProvider).ensureCurrentCycle();
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        home: Scaffold(body: Center(child: Text('Failed to start: $_error'))),
      );
    }
    if (_ready != true) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return const ExpenseTrackerApp();
  }
}
