import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../application/settings_controller.dart';
import 'first_run_screen.dart';
import 'home_shell.dart';
import 'app_lock_screen.dart';
import 'privacy_consent_screen.dart';

/// Root widget: applies the user-selected language (independent from the
/// currency setting) and gates the first-run currency selection.
class ExpenseTrackerApp extends ConsumerWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final mode = settings.value?.themeMode ?? 'system';
    final themeMode = switch (mode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: themeMode,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => LockGate(child: child!),
      locale: settings.value == null
          ? null
          : Locale(settings.value!.languageCode),
      home: settings.when(
        loading: () => const _Loading(),
        error: (e, _) => const _Loading(),
        data: (s) => !s.privacyAccepted
            ? const PrivacyConsentScreen()
            : s.firstRunCompleted
            ? const HomeShell()
            : const FirstRunScreen(),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
