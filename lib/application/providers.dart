import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import '../data/database/database_provider.dart';
import '../data/repositories/budget_cycle_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/expense_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/shopping_repository.dart';

/// Overrides in tests replace the whole database with an in-memory one.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = openAppDatabase();
  ref.onDispose(() async {
    // The restore flow closes the database explicitly before swapping the
    // file; the invalidation then closes it a second time — ignore that.
    try {
      await db.close();
    } catch (_) {}
  });
  return db;
});

final expenseRepositoryProvider = Provider(
  (ref) => ExpenseRepository(ref.watch(appDatabaseProvider)),
);

final categoryRepositoryProvider = Provider(
  (ref) => CategoryRepository(ref.watch(appDatabaseProvider)),
);

final budgetCycleRepositoryProvider = Provider(
  (ref) => BudgetCycleRepository(ref.watch(appDatabaseProvider)),
);

final shoppingRepositoryProvider = Provider(
  (ref) => ShoppingRepository(ref.watch(appDatabaseProvider)),
);

final settingsRepositoryProvider = Provider(
  (ref) => SettingsRepository(ref.watch(appDatabaseProvider)),
);
