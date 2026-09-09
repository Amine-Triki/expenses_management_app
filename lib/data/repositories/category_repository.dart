import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models.dart';
import '../database/app_database.dart' as db;

/// Seed IDs are stable so builtin categories are never duplicated across
/// runs; their display names come from localization keys ('cat.*').
class CategoryRepository {
  CategoryRepository(this._db);

  static const _uuid = Uuid();
  final db.AppDatabase _db;

  static const builtin = [
    ('8a3c1e6a-1111-4a11-9a01-000000000001', 'cat.food', 1),
    ('8a3c1e6a-1111-4a11-9a01-000000000002', 'cat.home', 2),
    ('8a3c1e6a-1111-4a11-9a01-000000000003', 'cat.transport', 3),
    ('8a3c1e6a-1111-4a11-9a01-000000000004', 'cat.bills', 4),
    ('8a3c1e6a-1111-4a11-9a01-000000000005', 'cat.health', 5),
    ('8a3c1e6a-1111-4a11-9a01-000000000006', 'cat.entertainment', 6),
    ('8a3c1e6a-1111-4a11-9a01-000000000007', 'cat.other', 7),
  ];

  /// Translation key for a builtin category id, or null for user categories.
  static String? builtinKeyFor(String id) {
    for (final b in builtin) {
      if (b.$1 == id) return b.$2;
    }
    return null;
  }

  /// Seeds the seven builtin categories once (idempotent).
  Future<void> seedBuiltins() async {
    final existing = await (_db.select(_db.categories)
          ..where((c) => c.id.isIn(builtin.map((b) => b.$1).toList())))
        .get();
    if (existing.length >= builtin.length) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final b in builtin) {
      if (existing.any((e) => e.id == b.$1)) continue;
      await _db.into(_db.categories).insert(db.CategoriesCompanion.insert(
            id: b.$1,
            name: b.$2,
            sortOrder: b.$3,
            createdAt: now,
            updatedAt: now,
          ));
    }
  }

  Category _toModel(db.Category r) => Category(
        id: r.id,
        name: r.name,
        sortOrder: r.sortOrder,
      );

  Stream<List<Category>> watchAll() {
    final query = _db.select(_db.categories)
      ..where((c) => c.deletedAt.isNull())
      ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]);
    return query.watch().map((rows) => rows.map(_toModel).toList());
  }

  Future<Category> add(String name) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = _uuid.v4();
    final maxOrder = await (_db.selectOnly(_db.categories)
          ..addColumns([_db.categories.sortOrder.max()]))
        .getSingle();
    final nextOrder =
        (maxOrder.read(_db.categories.sortOrder.max()) ?? 0) + 1;
    await _db.into(_db.categories).insert(db.CategoriesCompanion.insert(
          id: id,
          name: name,
          sortOrder: nextOrder,
          createdAt: now,
          updatedAt: now,
        ));
    return Category(id: id, name: name, sortOrder: nextOrder);
  }
}
