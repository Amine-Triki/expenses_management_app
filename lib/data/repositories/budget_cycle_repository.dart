import 'package:drift/drift.dart';

import '../../domain/cycle_resolver.dart';
import '../../domain/models.dart';
import '../database/app_database.dart' as db;
import '../id_generator.dart';

/// Budget cycles with lazy materialization: rows exist only for activated
/// (open) and closed cycles — never for future or skipped periods.
class BudgetCycleRepository {
  BudgetCycleRepository(this._db);

  final db.AppDatabase _db;

  BudgetCycle _toModel(db.BudgetCycle r) => BudgetCycle(
        id: r.id,
        startDay: r.startDay,
        startDate: CalendarDate.tryParse(r.startDate)!,
        endDate: CalendarDate.tryParse(r.endDate)!,
        initialAmount: r.initialAmount,
        carryOverAmount: r.carryOverAmount,
        carryOverEnabled: r.carryOverEnabled,
        previousCycleId: r.previousCycleId,
        closedAtMs: r.closedAt,
        finalExpenseTotal: r.finalExpenseTotal,
        finalRemaining: r.finalRemaining,
        createdAtMs: r.createdAt,
        updatedAtMs: r.updatedAt,
        deletedAtMs: r.deletedAt,
      );

  /// The single open (active) cycle, if any.
  Stream<BudgetCycle?> watchOpen() {
    final query = _db.select(_db.budgetCycles)
      ..where((c) => c.deletedAt.isNull() & c.closedAt.isNull())
      ..limit(1);
    return query
        .watchSingleOrNull()
        .map((r) => r == null ? null : _toModel(r));
  }

  Future<BudgetCycle?> getOpen() async {
    final rows = await (_db.select(_db.budgetCycles)
          ..where((c) => c.deletedAt.isNull() & c.closedAt.isNull())
          ..limit(1))
        .get();
    return rows.isEmpty ? null : _toModel(rows.first);
  }

  /// The most recently closed cycle, for carry-over transfer.
  Future<BudgetCycle?> getLastClosed() async {
    final rows = await (_db.select(_db.budgetCycles)
          ..where((c) => c.deletedAt.isNull() & c.closedAt.isNotNull())
          ..orderBy([(c) => OrderingTerm.desc(c.endDate)])
          ..limit(1))
        .get();
    return rows.isEmpty ? null : _toModel(rows.first);
  }

  Stream<List<BudgetCycle>> watchHistory({int limit = 12}) {
    final query = _db.select(_db.budgetCycles)
      ..where((c) => c.deletedAt.isNull())
      ..orderBy([(c) => OrderingTerm.desc(c.startDate)])
      ..limit(limit);
    return query.watch().map((rows) => rows.map(_toModel).toList());
  }

  /// Creates a new open cycle. The caller derives amounts via
  /// BudgetCalculator (initial = default amount; carry-over from the last
  /// closed snapshot).
  Future<BudgetCycle> create({
    required int startDay,
    required CycleWindow window,
    required int initialAmount,
    required int carryOverAmount,
    required bool carryOverEnabled,
    String? previousCycleId,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = IdGenerator.nextId();
    await _db.into(_db.budgetCycles).insert(
          db.BudgetCyclesCompanion.insert(
            id: id,
            startDay: startDay,
            startDate: window.start.iso,
            endDate: window.end.iso,
            initialAmount: initialAmount,
            carryOverAmount: carryOverAmount,
            carryOverEnabled: carryOverEnabled,
            previousCycleId: Value(previousCycleId),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return BudgetCycle(
      id: id,
      startDay: startDay,
      startDate: window.start,
      endDate: window.end,
      initialAmount: initialAmount,
      carryOverAmount: carryOverAmount,
      carryOverEnabled: carryOverEnabled,
      previousCycleId: previousCycleId,
      createdAtMs: now,
      updatedAtMs: now,
    );
  }

  /// Closes a cycle with its frozen snapshot — written once, never recomputed.
  /// [endDateOverride] rewrites the cycle's last day: a manual early restart
  /// cuts the period at today inclusive, so the books match the covered days
  /// (no day may belong to two cycles).
  Future<void> close(
    String cycleId, {
    required int finalExpenseTotal,
    required int finalRemaining,
    String? endDateOverride,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.budgetCycles)..where((c) => c.id.equals(cycleId)))
        .write(db.BudgetCyclesCompanion(
      endDate:
          endDateOverride == null ? const Value.absent() : Value(endDateOverride),
      closedAt: Value(now),
      finalExpenseTotal: Value(finalExpenseTotal),
      finalRemaining: Value(finalRemaining),
      updatedAt: Value(now),
    ));
  }

  /// Edits the current cycle's amount (current-cycle-only decision K.9).
  Future<void> updateInitialAmount(String cycleId, int newAmount) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.budgetCycles)..where((c) => c.id.equals(cycleId)))
        .write(db.BudgetCyclesCompanion(
      initialAmount: Value(newAmount),
      updatedAt: Value(now),
    ));
  }
}
