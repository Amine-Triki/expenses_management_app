import 'package:drift/drift.dart';

import '../../domain/models.dart';
import '../database/app_database.dart' as db;
import '../id_generator.dart';

class ExpenseTemplateRepository {
  ExpenseTemplateRepository(this._db);

  final db.AppDatabase _db;

  ExpenseTemplate _toModel(db.ExpenseTemplate r) => ExpenseTemplate(
    id: r.id,
    name: r.name,
    amount: r.amount,
    quantity: r.quantity,
    unitPrice: r.unitPrice,
    categoryId: r.categoryId,
    note: r.note,
    recurrence: r.recurrence,
    nextRunAtMs: r.nextRunAt,
    createdAtMs: r.createdAt,
    updatedAtMs: r.updatedAt,
    deletedAtMs: r.deletedAt,
  );

  Stream<List<ExpenseTemplate>> watchAll() {
    final query = _db.select(_db.expenseTemplates)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.nextRunAt)]);
    return query.watch().map((rows) => rows.map(_toModel).toList());
  }

  Future<ExpenseTemplate> add({
    required String name,
    required int amount,
    int? quantity,
    int? unitPrice,
    String? categoryId,
    String? note,
    required ExpenseTemplateRecurrence recurrence,
    required int nextRunAtMs,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = IdGenerator.nextId();
    await _db
        .into(_db.expenseTemplates)
        .insert(
          db.ExpenseTemplatesCompanion.insert(
            id: id,
            name: name,
            amount: amount,
            quantity: Value(quantity),
            unitPrice: Value(unitPrice),
            categoryId: Value(categoryId),
            note: Value(note),
            recurrence: recurrence,
            nextRunAt: nextRunAtMs,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return ExpenseTemplate(
      id: id,
      name: name,
      amount: amount,
      quantity: quantity,
      unitPrice: unitPrice,
      categoryId: categoryId,
      note: note,
      recurrence: recurrence,
      nextRunAtMs: nextRunAtMs,
      createdAtMs: now,
      updatedAtMs: now,
    );
  }

  Future<void> softDelete(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(
      _db.expenseTemplates,
    )..where((t) => t.id.equals(id))).write(
      db.ExpenseTemplatesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> markRun(ExpenseTemplate template, int nextRunAtMs) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(
      _db.expenseTemplates,
    )..where((t) => t.id.equals(template.id))).write(
      db.ExpenseTemplatesCompanion(
        nextRunAt: Value(nextRunAtMs),
        updatedAt: Value(now),
      ),
    );
  }

  Stream<List<ExpenseTemplate>> watchDue(int nowMs) {
    final query = _db.select(_db.expenseTemplates)
      ..where(
        (t) => t.deletedAt.isNull() & t.nextRunAt.isSmallerOrEqualValue(nowMs),
      );
    return query.watch().map(
      (rows) => rows
          .map(_toModel)
          .where(
            (template) => template.recurrence != ExpenseTemplateRecurrence.none,
          )
          .toList(),
    );
  }
}
