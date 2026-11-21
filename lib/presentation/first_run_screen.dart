import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/settings_controller.dart';
import '../l10n/app_localizations.dart';
import 'widgets/currency_picker.dart';

/// One-time welcome: the currency is chosen explicitly by the user — never
/// inferred from language or location (planning document C.1 / K.1).
class FirstRunScreen extends ConsumerStatefulWidget {
  const FirstRunScreen({super.key});

  @override
  ConsumerState<FirstRunScreen> createState() => _FirstRunScreenState();
}

class _FirstRunScreenState extends ConsumerState<FirstRunScreen> {
  String? _currency;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'favicon_io/android-chrome-192x192.png',
                  width: 96,
                  height: 96,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.firstRunTitle,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(l10n.firstRunHint, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Text(
                l10n.firstRunChooseCurrency,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.firstRunCurrencyHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () async {
                  final picked = await showCurrencyPicker(
                    context,
                    current: _currency,
                  );
                  if (picked != null && mounted) {
                    setState(() => _currency = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  child: Text(_currency ?? l10n.firstRunChooseCurrency),
                ),
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
    await notifier.setCurrency(_currency!);
    await notifier.completeFirstRun();
  }
}
