import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models.dart';
import '../database/app_database.dart' as db;

/// Statistics aggregates (computed live, never stored).
class CategoryTotal {
  const CategoryTotal({this.categoryId, required this.total});

  final String? categoryId;
  final int total;
}

class DayTotal {
  const DayTotal({required this.dayIso, required this.total});

  final String dayIso; // 'yyyy-MM-dd' local
  final int total;
}

/// Repository boundary between application/domain logic and SQLite. Hides
/// whether data comes from the local source or (in the future) a sync layer.
class ExpenseRepository {
  ExpenseRepository(this._db);

  static const _uuid = Uuid();
  final db.AppDatabase _db;

  Expense _toModel(db.Expense r) => Expense(
        id: r.id,
        name: r.name,
        amount: r.amount,
        quantity: r.quantity,
        unitPrice: r.unitPrice,
        categoryId: r.categoryId,
        note: r.note,
        spentAtMs: r.spentAt,
        source: r.expenseSource,
        createdAtMs: r.createdAt,
        updatedAtMs: r.updatedAt,
        deletedAtMs: r.deletedAt,
      );

  Stream<List<Expense>> watchAll({
    String? search,
    String? categoryId,
    int? fromMs,
    int? toMs,
    int? limit,
  }) {
    final query = _db.select(_db.expenses)
      ..where((e) => e.deletedAt.isNull())
      ..orderBy([(e) => OrderingTerm.desc(e.spentAt)]);
    if (search != null && search.trim().isNotEmpty) {
      final pattern = '%${search.trim()}%';
      query.where((e) => e.name.like(pattern) | e.note.like(pattern));
    }
    if (categoryId != null) {
      query.where((e) => e.categoryId.equals(categoryId));
    }
    if (fromMs != null) {
      query.where((e) => e.spentAt.isBiggerOrEqualValue(fromMs));
    }
    if (toMs != null) {
      query.where((e) => e.spentAt.isSmallerOrEqualValue(toMs));
    }
    if (limit != null) {
      query.limit(limit);
    }
    return query.watch().map((rows) => rows.map(_toModel).toList());
  }

  /// Live sum of active expenses whose spent instant falls within
  /// [fromMs, toMs] (inclusive; UTC epoch milliseconds).
  Stream<int> watchSumBetween(int fromMs, int toMs) {
    final sum = _db.expenses.amount.sum();
    final query = _db.selectOnly(_db.expenses)
      ..addColumns([sum])
      ..where(_db.expenses.deletedAt.isNull() &
          _db.expenses.spentAt.isBiggerOrEqualValue(fromMs) &
          _db.expenses.spentAt.isSmallerOrEqualValue(toMs));
    return query.watchSingle().map((row) => row.read(sum) ?? 0);
  }

  Future<int> sumBetween(int fromMs, int toMs) async {
    final sum = _db.expenses.amount.sum();
    final query = _db.selectOnly(_db.expenses)
      ..addColumns([sum])
      ..where(_db.expenses.deletedAt.isNull() &
          _db.expenses.spentAt.isBiggerOrEqualValue(fromMs) &
          _db.expenses.spentAt.isSmallerOrEqualValue(toMs));
    final row = await query.getSingle();
    return row.read(sum) ?? 0;
  }

  /// Adds an expense. [amount] is the user-adopted final value in minor units
  /// (rounded half-up once, at save time); [quantity] is scaled ×1000.
  Future<Expense> add({
    required String name,
    required int amount,
    int? quantity,
    int? unitPrice,
    String? categoryId,
    String? note,
    required int spentAtMs,
    required ExpenseSource source,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = _uuid.v4();
    await _db.into(_db.expenses).insert(db.ExpensesCompanion.insert(
          id: id,
          name: name,
          amount: amount,
          quantity: Value(quantity),
          unitPrice: Value(unitPrice),
          categoryId: Value(categoryId),
          note: Value(note),
          spentAt: spentAtMs,
          expenseSource: source,
          createdAt: now,
          updatedAt: now,
        ));
    return Expense(
      id: id,
      name: name,
      amount: amount,
      quantity: quantity,
      unitPrice: unitPrice,
      categoryId: categoryId,
      note: note,
      spentAtMs: spentAtMs,
      source: source,
      createdAtMs: now,
      updatedAtMs: now,
    );
  }

  /// Updates an expense. created_at never changes; updated_at always does.
  Future<void> update(
    Expense existing, {
    String? name,
    int? amount,
    int? quantity,
    Object? unitPrice = _unset,
    Object? categoryId = _unset,
    Object? note = _unset,
    int? spentAtMs,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.expenses)..where((e) => e.id.equals(existing.id)))
        .write(db.ExpensesCompanion(
      name: name == null ? const Value.absent() : Value(name),
      amount: amount == null ? const Value.absent() : Value(amount),
      quantity: quantity == null ? const Value.absent() : Value(quantity),
      unitPrice: unitPrice == _unset
          ? const Value.absent()
          : Value(unitPrice as int?),
      categoryId: categoryId == _unset
          ? const Value.absent()
          : Value(categoryId as String?),
      note: note == _unset ? const Value.absent() : Value(note as String?),
      spentAt: spentAtMs == null ? const Value.absent() : Value(spentAtMs),
      updatedAt: Value(now),
    ));
  }

  /// Soft delete: deleted_at is set; the record is never physically removed
  /// by normal flows.
  Future<void> softDelete(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.expenses)..where((e) => e.id.equals(id))).write(
      db.ExpensesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  Future<Expense?> getById(String id) async {
    final row = await (_db.select(_db.expenses)
          ..where((e) => e.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  /// Live per-category totals for a window (statistics).
  Stream<List<CategoryTotal>> watchSumByCategory(int fromMs, int toMs) {
    return _db
        .customSelect(
          'SELECT category_id, SUM(amount) AS total FROM expenses '
          'WHERE deleted_at IS NULL AND spent_at >= ? AND spent_at <= ? '
          'GROUP BY category_id ORDER BY total DESC',
          variables: [Variable.withInt(fromMs), Variable.withInt(toMs)],
          readsFrom: {_db.expenses},
        )
        .watch()
        .map((rows) => rows
            .map((r) => CategoryTotal(
                  categoryId: r.data['category_id'] as String?,
                  total: (r.data['total'] as num?)?.toInt() ?? 0,
                ))
            .toList());
  }

  /// Live highest-spending local calendar days in a window (statistics).
  /// The day bucket uses the user's local timezone ('localtime').
  Stream<List<DayTotal>> watchTopDays(int fromMs, int toMs, {int limit = 5}) {
    return _db
        .customSelect(
          "SELECT date(spent_at / 1000, 'unixepoch', 'localtime') AS day, "
          'SUM(amount) AS total FROM expenses '
          'WHERE deleted_at IS NULL AND spent_at >= ? AND spent_at <= ? '
          'GROUP BY day ORDER BY total DESC LIMIT ?',
          variables: [
            Variable.withInt(fromMs),
            Variable.withInt(toMs),
            Variable.withInt(limit),
          ],
          readsFrom: {_db.expenses},
        )
        .watch()
        .map((rows) => rows
            .map((r) => DayTotal(
                  dayIso: r.data['day'] as String? ?? '',
                  total: (r.data['total'] as num?)?.toInt() ?? 0,
                ))
            .toList());
  }
}

const _unset = Object();
