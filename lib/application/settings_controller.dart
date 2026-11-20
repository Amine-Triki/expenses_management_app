import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/settings_repository.dart';
import 'providers.dart';
import 'list_reminder_service.dart';

/// Reactive view over the local key/value settings.
class AppSettings {
  AppSettings({
    this.languageCode = 'en',
    this.currencyCode = 'USD',
    this.themeMode = 'system',
    this.budgetEnabled = false,
    this.budgetDefaultAmount = 0,
    this.budgetStartDay = 1,
    this.firstRunCompleted = false,
    this.privacyAccepted = false,
    this.appLockEnabled = false,
    this.appLockPinHash,
    this.appLockFailedAttempts = 0,
    this.appLockLockedUntilMs = 0,
  }) : assert(budgetStartDay >= 1 && budgetStartDay <= 31);

  final String languageCode;
  final String currencyCode;
  final String themeMode;
  final bool budgetEnabled;
  final int budgetDefaultAmount; // minor units — Default budget amount
  final int budgetStartDay; // 1–31 user intent
  final bool firstRunCompleted;
  final bool privacyAccepted;
  final bool appLockEnabled;
  final String? appLockPinHash;
  final int appLockFailedAttempts;
  final int appLockLockedUntilMs;

  AppSettings copyWith({
    String? languageCode,
    String? currencyCode,
    String? themeMode,
    bool? budgetEnabled,
    int? budgetDefaultAmount,
    int? budgetStartDay,
    bool? firstRunCompleted,
    bool? privacyAccepted,
    bool? appLockEnabled,
    String? appLockPinHash,
    int? appLockFailedAttempts,
    int? appLockLockedUntilMs,
  }) => AppSettings(
    languageCode: languageCode ?? this.languageCode,
    currencyCode: currencyCode ?? this.currencyCode,
    themeMode: themeMode ?? this.themeMode,
    budgetEnabled: budgetEnabled ?? this.budgetEnabled,
    budgetDefaultAmount: budgetDefaultAmount ?? this.budgetDefaultAmount,
    budgetStartDay: budgetStartDay ?? this.budgetStartDay,
    firstRunCompleted: firstRunCompleted ?? this.firstRunCompleted,
    privacyAccepted: privacyAccepted ?? this.privacyAccepted,
    appLockEnabled: appLockEnabled ?? this.appLockEnabled,
    appLockPinHash: appLockPinHash ?? this.appLockPinHash,
    appLockFailedAttempts: appLockFailedAttempts ?? this.appLockFailedAttempts,
    appLockLockedUntilMs: appLockLockedUntilMs ?? this.appLockLockedUntilMs,
  );

  /// First-launch language detection: system locale when supported,
  /// otherwise English (planning document C.1).
  static String systemLanguageDefault() {
    final code = PlatformDispatcher.instance.locale.languageCode;
    return const {'ar', 'en', 'fr', 'zh'}.contains(code) ? code : 'en';
  }
}

class SettingsController extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final repo = ref.watch(settingsRepositoryProvider);
    final map = await repo.watchAll().first;
    return _fromMap(map);
  }

  AppSettings _fromMap(Map<String, String> map) => AppSettings(
    languageCode:
        map[SettingsRepository.keyLanguage] ??
        AppSettings.systemLanguageDefault(),
    currencyCode: map[SettingsRepository.keyCurrency] ?? 'USD',
    themeMode: map[SettingsRepository.keyThemeMode] ?? 'system',
    budgetEnabled: map[SettingsRepository.keyBudgetEnabled] == 'true',
    budgetDefaultAmount:
        int.tryParse(map[SettingsRepository.keyBudgetDefaultAmount] ?? '') ?? 0,
    budgetStartDay:
        int.tryParse(map[SettingsRepository.keyBudgetStartDay] ?? '') ?? 1,
    firstRunCompleted: map[SettingsRepository.keyFirstRunCompleted] == 'true',
    privacyAccepted: map[SettingsRepository.keyPrivacyAccepted] == 'true',
    appLockEnabled: map[SettingsRepository.keyAppLockEnabled] == 'true',
    appLockPinHash: map[SettingsRepository.keyAppLockPinHash],
    appLockFailedAttempts:
        int.tryParse(map[SettingsRepository.keyAppLockFailedAttempts] ?? '') ??
        0,
    appLockLockedUntilMs:
        int.tryParse(map[SettingsRepository.keyAppLockLockedUntilMs] ?? '') ??
        0,
  );

  Future<void> _set(String key, String value) async {
    await ref.read(settingsRepositoryProvider).set(key, value);
  }

  Future<void> _mutate(AppSettings next) async {
    state = AsyncValue.data(next);
  }

  Future<void> setLanguage(String code) async {
    await _set(SettingsRepository.keyLanguage, code);
    await _mutate(_current().copyWith(languageCode: code));
    if (!ListReminderService.instance.isInitialized) return;
    await ListReminderService.instance.updateLanguage(code);
    final lists = await ref
        .read(shoppingRepositoryProvider)
        .getListsWithReminders();
    await ListReminderService.instance.rescheduleAll(lists, languageCode: code);
  }

  Future<void> setCurrency(String code) async {
    // Cosmetic-only currency setting: keep every stored minor-unit value
    // unchanged. The selected currency controls presentation and decimal
    // formatting only; there is no exchange-rate conversion.
    await _set(SettingsRepository.keyCurrency, code);
    await _mutate(_current().copyWith(currencyCode: code));
  }

  Future<void> setThemeMode(String mode) async {
    if (!const {'system', 'light', 'dark'}.contains(mode)) return;
    await _set(SettingsRepository.keyThemeMode, mode);
    await _mutate(_current().copyWith(themeMode: mode));
  }

  Future<void> completeFirstRun() async {
    await _set(SettingsRepository.keyFirstRunCompleted, 'true');
    await _mutate(_current().copyWith(firstRunCompleted: true));
  }

  Future<void> acceptPrivacyPolicy() async {
    await _set(SettingsRepository.keyPrivacyAccepted, 'true');
    await _mutate(_current().copyWith(privacyAccepted: true));
  }

  Future<void> setBudgetEnabled(bool enabled) async {
    await _set(SettingsRepository.keyBudgetEnabled, '$enabled');
    await _mutate(_current().copyWith(budgetEnabled: enabled));
  }

  Future<void> setBudgetDefaultAmount(int minorUnits) async {
    await _set(SettingsRepository.keyBudgetDefaultAmount, '$minorUnits');
    await _mutate(_current().copyWith(budgetDefaultAmount: minorUnits));
  }

  Future<void> setBudgetStartDay(int day) async {
    await _set(SettingsRepository.keyBudgetStartDay, '$day');
    await _mutate(_current().copyWith(budgetStartDay: day));
  }

  Future<void> setAppLock({required bool enabled, String? pinHash}) async {
    await _set(SettingsRepository.keyAppLockEnabled, '$enabled');
    if (pinHash != null) {
      await _set(SettingsRepository.keyAppLockPinHash, pinHash);
    }
    await _set(SettingsRepository.keyAppLockFailedAttempts, '0');
    await _set(SettingsRepository.keyAppLockLockedUntilMs, '0');
    await _mutate(
      _current().copyWith(
        appLockEnabled: enabled,
        appLockPinHash: pinHash ?? _current().appLockPinHash,
        appLockFailedAttempts: 0,
        appLockLockedUntilMs: 0,
      ),
    );
  }

  Future<void> setAppLockSecurity({
    required int failedAttempts,
    required int lockedUntilMs,
  }) async {
    await _set(SettingsRepository.keyAppLockFailedAttempts, '$failedAttempts');
    await _set(SettingsRepository.keyAppLockLockedUntilMs, '$lockedUntilMs');
    await _mutate(
      _current().copyWith(
        appLockFailedAttempts: failedAttempts,
        appLockLockedUntilMs: lockedUntilMs,
      ),
    );
  }

  /// After "delete all data": back to system defaults (first-run flow again).
  Future<void> resetToDefaults() async {
    await _mutate(
      AppSettings(languageCode: AppSettings.systemLanguageDefault()),
    );
  }

  AppSettings _current() =>
      state.value ??
      AppSettings(languageCode: AppSettings.systemLanguageDefault());
}

final appSettingsProvider =
    AsyncNotifierProvider<SettingsController, AppSettings>(
      SettingsController.new,
    );
