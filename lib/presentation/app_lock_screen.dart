import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/settings_controller.dart';
import '../l10n/app_localizations.dart';

class LockGate extends ConsumerStatefulWidget {
  const LockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate>
    with WidgetsBindingObserver {
  static const _lockAfter = Duration(seconds: 30);

  bool _locked = false;
  bool _inactiveCover = false;
  DateTime? _pausedAt;

  bool get _enabled {
    final settings = ref.read(appSettingsProvider).value;
    return settings?.appLockEnabled == true && settings?.appLockPinHash != null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locked = _enabled;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_enabled) return;
    switch (state) {
      case AppLifecycleState.inactive:
        setState(() => _inactiveCover = true);
      case AppLifecycleState.paused:
        _pausedAt = DateTime.now();
      case AppLifecycleState.resumed:
        final pausedAt = _pausedAt;
        _pausedAt = null;
        setState(() {
          _inactiveCover = false;
          if (pausedAt != null &&
              DateTime.now().difference(pausedAt) >= _lockAfter) {
            _locked = true;
          }
        });
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _unlock() => setState(() => _locked = false);

  @override
  Widget build(BuildContext context) {
    final enabled =
        ref.watch(appSettingsProvider).value?.appLockEnabled == true;
    if (!enabled) return widget.child;

    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(offstage: _locked, child: widget.child),
        if (_inactiveCover && !_locked) const ColoredBox(color: Colors.black),
        if (_locked) _LockScreen(onUnlocked: _unlock),
      ],
    );
  }
}

class _LockScreen extends ConsumerStatefulWidget {
  const _LockScreen({required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  ConsumerState<_LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<_LockScreen> {
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
    widget.onUnlocked();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
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
