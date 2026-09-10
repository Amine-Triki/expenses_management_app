import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../application/providers.dart';
import '../application/settings_controller.dart';
import '../domain/currency.dart';
import '../l10n/app_localizations.dart';
import 'budget_screen.dart';

/// Settings: language, currency, budget settings, privacy, data management.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(appSettingsProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.settingsLanguage),
            subtitle: Text(_languageLabel(context, settings?.languageCode ?? 'en')),
            onTap: () => _pickLanguage(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.payments_outlined),
            title: Text(l10n.settingsCurrency),
            subtitle: Text(settings?.currencyCode ?? 'USD'),
            onTap: () => _pickCurrency(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.savings_outlined),
            title: Text(l10n.settingsBudget),
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const BudgetScreen())),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.settingsPrivacy),
            subtitle: Text(l10n.settingsPrivacyText),
            isThreeLine: true,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined),
            title: Text(l10n.settingsClearData),
            onTap: () => _wipeData(context, ref),
          ),
          ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'favicon_io/android-chrome-192x192.png',
                width: 28,
                height: 28,
              ),
            ),
            title: Text(l10n.settingsAbout),
            subtitle: Text(l10n.aboutDevelopedBy),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('amine-triki.tn'),
            onTap: () => launchUrl(Uri.https('amine-triki.tn'),
                mode: LaunchMode.externalApplication),
          ),
        ],
      ),
    );
  }

  String _languageLabel(BuildContext context, String code) {
    final l10n = AppLocalizations.of(context)!;
    return switch (code) {
      'ar' => 'العربية',
      'fr' => 'Français',
      _ => l10n.navSettings == '' ? 'English' : 'English',
    };
  }

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(appSettingsProvider.notifier);
    final current = ref.read(appSettingsProvider).value?.languageCode;
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        children: [
          RadioGroup<String>(
            groupValue: current,
            onChanged: (v) => Navigator.pop(ctx, v),
            child: const Column(
              children: [
                RadioListTile<String>(
                    value: 'ar', title: Text('العربية')),
                RadioListTile<String>(value: 'en', title: Text('English')),
                RadioListTile<String>(value: 'fr', title: Text('Français')),
              ],
            ),
          ),
        ],
      ),
    );
    if (picked != null) await notifier.setLanguage(picked);
  }

  Future<void> _pickCurrency(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(appSettingsProvider.notifier);
    final current = ref.read(appSettingsProvider).value?.currencyCode;
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Currency'),
        children: [
          RadioGroup<String>(
            groupValue: current,
            onChanged: (v) => Navigator.pop(ctx, v),
            child: Column(
              children: [
                for (final code in CurrencyInfo.pickerCodes)
                  RadioListTile<String>(value: code, title: Text(code)),
              ],
            ),
          ),
        ],
      ),
    );
    if (picked != null) await notifier.setCurrency(picked);
  }

  Future<void> _wipeData(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    var confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l10n.settingsClearDataConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.commonCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.commonDelete)),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    // Double confirmation for an irreversible destructive action.
    confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l10n.settingsClearDataFinal),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.commonCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.commonDelete)),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(settingsRepositoryProvider).wipeAllData();
    await ref.read(categoryRepositoryProvider).seedBuiltins();
    await ref.read(appSettingsProvider.notifier).resetToDefaults();
  }
}
