import 'dart:async';
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
  int _failedAttempts = 0;
  DateTime? _lockedUntil;
  Timer? _lockTimer;

  static const _maxAttempts = 5;
  static const _lockDuration = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    final settings = ref.read(appSettingsProvider).value;
    _failedAttempts = settings?.appLockFailedAttempts ?? 0;
    final untilMs = settings?.appLockLockedUntilMs ?? 0;
    if (untilMs > DateTime.now().millisecondsSinceEpoch) {
      _lockedUntil = DateTime.fromMillisecondsSinceEpoch(untilMs);
      _lockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        final until = _lockedUntil;
        if (until == null || !DateTime.now().isBefore(until)) {
          _lockTimer?.cancel();
          setState(() {
            _lockedUntil = null;
            _failedAttempts = 0;
            _invalid = false;
          });
          ref
              .read(appSettingsProvider.notifier)
              .setAppLockSecurity(failedAttempts: 0, lockedUntilMs: 0);
        } else {
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    final lockedUntil = _lockedUntil;
    if (lockedUntil != null && DateTime.now().isBefore(lockedUntil)) {
      setState(() => _invalid = true);
      return;
    }
    if (lockedUntil != null && !DateTime.now().isBefore(lockedUntil)) {
      setState(() {
        _lockedUntil = null;
        _failedAttempts = 0;
      });
    }

    final pin = _pinController.text;
    final hash = sha256.convert(utf8.encode(pin)).toString();
    final expected = ref.read(appSettingsProvider).value?.appLockPinHash;
    if (pin.length < 4 || hash != expected) {
      final attempts = _failedAttempts + 1;
      var lockedUntilMs = 0;
      setState(() {
        _failedAttempts = attempts;
        _invalid = true;
        if (attempts >= _maxAttempts) {
          _lockedUntil = DateTime.now().add(_lockDuration);
          lockedUntilMs = _lockedUntil!.millisecondsSinceEpoch;
          _lockTimer?.cancel();
          _lockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
            if (!mounted) return;
            final until = _lockedUntil;
            if (until == null || !DateTime.now().isBefore(until)) {
              _lockTimer?.cancel();
              setState(() {
                _lockedUntil = null;
                _failedAttempts = 0;
                _invalid = false;
              });
              ref
                  .read(appSettingsProvider.notifier)
                  .setAppLockSecurity(failedAttempts: 0, lockedUntilMs: 0);
            } else {
              setState(() {});
            }
          });
        }
      });
      await ref
          .read(appSettingsProvider.notifier)
          .setAppLockSecurity(
            failedAttempts: attempts,
            lockedUntilMs: lockedUntilMs,
          );
      return;
    }
    _failedAttempts = 0;
    _lockedUntil = null;
    _lockTimer?.cancel();
    await ref
        .read(appSettingsProvider.notifier)
        .setAppLockSecurity(failedAttempts: 0, lockedUntilMs: 0);
    widget.onUnlocked();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lockedUntil = _lockedUntil;
    final remaining = lockedUntil == null
        ? 0
        : (lockedUntil.difference(DateTime.now()).inSeconds + 1).clamp(1, 30);
    final isLocked = remaining > 0;
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
                  enabled: !isLocked,
                  onSubmitted: (_) => isLocked ? null : _unlock(),
                  decoration: InputDecoration(
                    labelText: l10n.appLockPin,
                    errorText: _invalid ? l10n.appLockInvalid : null,
                  ),
                ),
                FilledButton(
                  onPressed: isLocked ? null : _unlock,
                  child: Text(
                    isLocked
                        ? '${l10n.appLockUnlock} (${remaining}s)'
                        : l10n.appLockUnlock,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
