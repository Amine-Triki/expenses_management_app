import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../application/settings_controller.dart';
import '../l10n/app_localizations.dart';

/// Mandatory privacy-policy consent gate (AppGallery rule 7.5): shown at app
/// launch until the user accepts. Cannot be dismissed by back navigation;
/// declining exits the app.
class PrivacyConsentScreen extends ConsumerWidget {
  const PrivacyConsentScreen({super.key});

  static const _policyUrl = 'https://amine-triki.tn/privacy/expenses-management-app/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.privacy_tip_outlined, size: 64),
                const SizedBox(height: 16),
                Text(
                  l10n.privacyConsentTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.privacyConsentMessage,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  icon: const Icon(Icons.open_in_new),
                  label: Text(l10n.privacyReadPolicy),
                  onPressed: () => launchUrl(Uri.parse(_policyUrl),
                      mode: LaunchMode.externalApplication),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () =>
                      ref.read(appSettingsProvider.notifier).acceptPrivacyPolicy(),
                  child: Text(l10n.privacyAccept),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => SystemNavigator.pop(),
                  child: Text(l10n.privacyDecline),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
