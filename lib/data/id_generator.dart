import 'package:uuid/uuid.dart';

/// Central entity-ID generator.
///
/// UUID v7: time-ordered (append-friendly B-tree inserts in SQLite, creation
/// order visible for future sync inspection) while remaining globally unique
/// without coordination. The 74 random bits make offline collisions
/// astronomically unlikely across devices.
///
/// NOTE: v7 ordering reflects record *creation* time. Domain queries must
/// keep ordering by their own timestamps (e.g. `spent_at`, which is editable
/// and can be backdated) — never by the ID.
class IdGenerator {
  const IdGenerator._();

  static const _uuid = Uuid();

  static String nextId() => _uuid.v7();
}
