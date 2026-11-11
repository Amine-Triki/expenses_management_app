import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'application/expense_controller.dart';
import 'application/providers.dart';
import 'application/settings_controller.dart';
import 'application/list_reminder_service.dart';
import 'l10n/app_localizations.dart';
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

class _BootstrapState extends ConsumerState<_Bootstrap>
    with WidgetsBindingObserver {
  bool? _ready;
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _ready == true) {
      _refreshReminderTimezone();
    }
  }

  Future<void> _refreshReminderTimezone() async {
    try {
      final changed = await ListReminderService.instance.refreshTimezone();
      if (!changed) return;
      final lists = await ref
          .read(shoppingRepositoryProvider)
          .getListsWithReminders();
      final language = ref.read(appSettingsProvider).value?.languageCode;
      await ListReminderService.instance.rescheduleAll(
        lists,
        languageCode: language ?? 'en',
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to refresh reminder timezone: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _initialize() async {
    if (mounted) setState(() => _error = null);
    try {
      await ref.read(categoryRepositoryProvider).seedBuiltins();
      await ref.read(appSettingsProvider.future);
      try {
        final language = ref.read(appSettingsProvider).value?.languageCode;
        await ListReminderService.instance.initialize(
          languageCode: language ?? 'en',
        );
        final lists = await ref
            .read(shoppingRepositoryProvider)
            .getListsWithReminders();
        await ListReminderService.instance.rescheduleAll(
          lists,
          languageCode: language ?? 'en',
        );
      } catch (error, stackTrace) {
        debugPrint('Notification initialization failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
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
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: _BootstrapError(onRetry: _initialize),
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

class _BootstrapError extends StatelessWidget {
  const _BootstrapError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.startupFailed, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: Text(l10n.retry)),
            ],
          ),
        ),
      ),
    );
  }
}
