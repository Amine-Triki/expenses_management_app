import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/settings_controller.dart';
import '../domain/currency.dart';
import '../l10n/app_localizations.dart';

/// One-time welcome: the currency is chosen explicitly by the user — never
/// inferred from language or location (planning document C.1 / K.1).
class FirstRunScreen extends ConsumerStatefulWidget {
  const FirstRunScreen({super.key});

  @override
  ConsumerState<FirstRunScreen> createState() => _FirstRunScreenState();
}

class _FirstRunScreenState extends ConsumerState<FirstRunScreen> {
  String? _currency;
  late String _language;

  @override
  void initState() {
    super.initState();
    // Language is offered explicitly on the first screen; the system locale
    // is only the preselected value, never a silent decision.
    _language = AppSettings.systemLanguageDefault();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              Icon(Icons.savings_outlined,
                  size: 72, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                l10n.firstRunTitle,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.firstRunHint,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(l10n.settingsLanguage,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'ar', label: Text('العربية')),
                  ButtonSegment(value: 'en', label: Text('English')),
                  ButtonSegment(value: 'fr', label: Text('Français')),
                ],
                selected: {_language},
                onSelectionChanged: (s) =>
                    setState(() => _language = s.first),
              ),
              const SizedBox(height: 24),
              Text(l10n.firstRunChooseCurrency,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(l10n.firstRunCurrencyHint,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _currency,
                isExpanded: true,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.payments_outlined)),
                items: [
                  for (final code in CurrencyInfo.pickerCodes)
                    DropdownMenuItem(value: code, child: Text(code)),
                ],
                onChanged: (v) => setState(() => _currency = v),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _currency == null ? null : _start,
                child: Text(l10n.firstRunStart),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _start() async {
    final notifier = ref.read(appSettingsProvider.notifier);
    await notifier.setLanguage(_language);
    await notifier.setCurrency(_currency!);
    await notifier.completeFirstRun();
  }
}
