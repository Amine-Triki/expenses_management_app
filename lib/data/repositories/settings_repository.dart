import '../database/app_database.dart';

/// Local-only key/value settings (not sync-ready in the MVP).
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  static const keyLanguage = 'language';
  static const keyCurrency = 'currency_code';
  static const keyBudgetEnabled = 'budget_enabled';
  static const keyBudgetDefaultAmount = 'budget_default_amount';
  static const keyBudgetStartDay = 'budget_start_day';
  static const keyBudgetCarryOver = 'budget_carry_over';
  static const keyFirstRunCompleted = 'first_run_completed';

  Stream<Map<String, String>> watchAll() {
    final query = _db.select(_db.settingsItems);
    return query.watch().map((rows) =>
        {for (final r in rows) r.key: r.value});
  }

  Future<String?> get(String key) async {
    final row = await (_db.select(_db.settingsItems)
          ..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> set(String key, String value) async {
    await _db.into(_db.settingsItems).insertOnConflictUpdate(
          SettingsItemsCompanion.insert(key: key, value: value),
        );
  }

  /// Deliberate physical cleanup for the user-facing "delete all data" action.
  /// The only place where records are physically removed.
  Future<void> wipeAllData() async {
    await _db.transaction(() async {
      await _db.delete(_db.expenses).go();
      await _db.delete(_db.shoppingListItems).go();
      await _db.delete(_db.shoppingLists).go();
      await _db.delete(_db.budgetCycles).go();
      await _db.delete(_db.settingsItems).go();
      // Categories are reseeded by the app bootstrap.
    });
  }
}
