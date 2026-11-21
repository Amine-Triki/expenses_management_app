import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/pin_security.dart';
import '../application/settings_controller.dart';
import '../application/providers.dart';
import '../application/list_reminder_service.dart';
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
    return settings?.appLockEnabled == true;
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
  DateTime? _lockedUntil;
  Timer? _lockTimer;

  @override
  void initState() {
    super.initState();
    _loadLockState();
  }

  Future<void> _loadLockState() async {
    final untilMs = await PinSecurity.lockedUntilMs();
    if (untilMs > DateTime.now().millisecondsSinceEpoch) {
      _lockedUntil = DateTime.fromMillisecondsSinceEpoch(untilMs);
      if (!mounted) return;
      _lockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        final until = _lockedUntil;
        if (until == null || !DateTime.now().isBefore(until)) {
          _lockTimer?.cancel();
          setState(() {
            _lockedUntil = null;
            _invalid = false;
          });
          PinSecurity.resetFailures();
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
      });
    }

    final pin = _pinController.text;
    if (pin.length < 4) {
      setState(() => _invalid = true);
      return;
    }

    var valid = await PinSecurity.verify(pin);
    if (!valid && !await PinSecurity.hasSecureHash()) {
      final legacy = ref.read(appSettingsProvider).value?.appLockPinHash;
      valid = await PinSecurity.verifyLegacy(pin, legacy);
    }
    if (valid) {
      await ref.read(appSettingsProvider.notifier).clearLegacyPinHash();
    }
    if (!valid) {
      await PinSecurity.recordFailure();
      final untilMs = await PinSecurity.lockedUntilMs();
      if (!mounted) return;
      setState(() {
        _invalid = true;
        if (untilMs > DateTime.now().millisecondsSinceEpoch) {
          _lockedUntil = DateTime.fromMillisecondsSinceEpoch(untilMs);
          _lockTimer?.cancel();
          _lockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
            if (!mounted) return;
            final until = _lockedUntil;
            if (until == null || !DateTime.now().isBefore(until)) {
              _lockTimer?.cancel();
              setState(() {
                _lockedUntil = null;
                _invalid = false;
              });
              PinSecurity.resetFailures();
            } else {
              setState(() {});
            }
          });
        }
      });
      return;
    }
    _lockedUntil = null;
    _lockTimer?.cancel();
    await PinSecurity.resetFailures();
    widget.onUnlocked();
  }

  Future<void> _forgotPin() async {
    final l10n = AppLocalizations.of(context)!;
    final restoreOrErase = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.appLockForgotTitle),
        content: Text(l10n.appLockForgotMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.appLockEraseData),
          ),
        ],
      ),
    );
    if (restoreOrErase != true || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l10n.appLockEraseConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.appLockEraseData),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await PinSecurity.clear();
    await ref.read(settingsRepositoryProvider).wipeAllData();
    await ListReminderService.instance.cancelAll();
    await ref.read(categoryRepositoryProvider).seedBuiltins();
    await ref.read(appSettingsProvider.notifier).resetToDefaults();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lockedUntil = _lockedUntil;
    final remaining = lockedUntil == null
        ? 0
        : (lockedUntil.difference(DateTime.now()).inSeconds + 1).clamp(1, 3840);
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
                TextButton(
                  onPressed: isLocked ? null : _forgotPin,
                  child: Text(l10n.appLockForgot),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
