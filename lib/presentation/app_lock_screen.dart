import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/settings_controller.dart';
import '../l10n/app_localizations.dart';

class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  final _pinController = TextEditingController();
  bool _invalid = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _unlock() {
    final pin = _pinController.text;
    final hash = sha256.convert(utf8.encode(pin)).toString();
    final expected = ref.read(appSettingsProvider).value?.appLockPinHash;
    if (pin.length < 4 || hash != expected) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute<void>(builder: (_) => widget.child));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 64),
                const SizedBox(height: 16),
                Text(
                  l10n.appLockTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _pinController,
                  autofocus: true,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  onSubmitted: (_) => _unlock(),
                  decoration: InputDecoration(
                    labelText: l10n.appLockPin,
                    errorText: _invalid ? l10n.appLockInvalid : null,
                  ),
                ),
                FilledButton(
                  onPressed: _unlock,
                  child: Text(l10n.appLockUnlock),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
