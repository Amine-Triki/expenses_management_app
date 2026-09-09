import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/settings_repository.dart';
import 'providers.dart';

/// Reactive view over the local key/value settings.
class AppSettings {
  AppSettings({
    this.languageCode = 'en',
    this.currencyCode = 'USD',
    this.budgetEnabled = false,
    this.budgetDefaultAmount = 0,
    this.budgetStartDay = 1,
    this.budgetCarryOver = false,
    this.firstRunCompleted = false,
  }) : assert(budgetStartDay >= 1 && budgetStartDay <= 31);

  final String languageCode;
  final String currencyCode;
  final bool budgetEnabled;
  final int budgetDefaultAmount; // minor units — Default budget amount
  final int budgetStartDay; // 1–31 user intent
  final bool budgetCarryOver;
  final bool firstRunCompleted;

  AppSettings copyWith({
    String? languageCode,
    String? currencyCode,
    bool? budgetEnabled,
    int? budgetDefaultAmount,
    int? budgetStartDay,
    bool? budgetCarryOver,
    bool? firstRunCompleted,
  }) =>
      AppSettings(
        languageCode: languageCode ?? this.languageCode,
        currencyCode: currencyCode ?? this.currencyCode,
        budgetEnabled: budgetEnabled ?? this.budgetEnabled,
        budgetDefaultAmount: budgetDefaultAmount ?? this.budgetDefaultAmount,
        budgetStartDay: budgetStartDay ?? this.budgetStartDay,
        budgetCarryOver: budgetCarryOver ?? this.budgetCarryOver,
        firstRunCompleted: firstRunCompleted ?? this.firstRunCompleted,
      );

  /// First-launch language detection: system locale when supported,
  /// otherwise English (planning document C.1).
  static String systemLanguageDefault() {
    final code = PlatformDispatcher.instance.locale.languageCode;
    return const {'ar', 'en', 'fr'}.contains(code) ? code : 'en';
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
        budgetEnabled: map[SettingsRepository.keyBudgetEnabled] == 'true',
        budgetDefaultAmount: int.tryParse(
                map[SettingsRepository.keyBudgetDefaultAmount] ?? '') ??
            0,
        budgetStartDay:
            int.tryParse(map[SettingsRepository.keyBudgetStartDay] ?? '') ?? 1,
        budgetCarryOver: map[SettingsRepository.keyBudgetCarryOver] == 'true',
        firstRunCompleted:
            map[SettingsRepository.keyFirstRunCompleted] == 'true',
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
  }

  Future<void> setCurrency(String code) async {
    await _set(SettingsRepository.keyCurrency, code);
    await _mutate(_current().copyWith(currencyCode: code));
  }

  Future<void> completeFirstRun() async {
    await _set(SettingsRepository.keyFirstRunCompleted, 'true');
    await _mutate(_current().copyWith(firstRunCompleted: true));
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

  Future<void> setBudgetCarryOver(bool value) async {
    await _set(SettingsRepository.keyBudgetCarryOver, '$value');
    await _mutate(_current().copyWith(budgetCarryOver: value));
  }

  /// After "delete all data": back to system defaults (first-run flow again).
  Future<void> resetToDefaults() async {
    await _mutate(AppSettings(
      languageCode: AppSettings.systemLanguageDefault(),
    ));
  }

  AppSettings _current() =>
      state.value ??
      AppSettings(languageCode: AppSettings.systemLanguageDefault());
}

final appSettingsProvider =
    AsyncNotifierProvider<SettingsController, AppSettings>(
        SettingsController.new);
