import 'dart:io';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as raw;

import '../data/database/database_provider.dart';
import 'settings_controller.dart';
import 'providers.dart';

/// Outcome of a restore attempt.
enum RestoreStatus { restored, invalidFile, tooNew, failed, cancelled }

/// Local backup/restore: the WHOLE app state (expenses, lists, budget
/// cycles, settings) lives in one SQLite file, so a backup is a consistent
/// snapshot of that file. Offline-only, no extra permissions (SAF dialogs).
class BackupController {
  BackupController(this._ref, {Future<String> Function()? filePath})
    : _filePath = filePath ?? dbFilePath;

  final Ref _ref;

  /// Overridable for tests (tests use temp paths, not the device one).
  final Future<String> Function() _filePath;

  /// Writes a consistent snapshot of the live database to [targetPath]
  /// (must not exist — SQLite's VACUUM INTO requirement). The snapshot folds
  /// the journal/WAL into one portable file, safe to copy while running.
  Future<void> exportTo(String targetPath) async {
    final database = _ref.read(appDatabaseProvider);
    await database.customStatement('VACUUM INTO ?', [targetPath]);
  }

  /// Production export: snapshot → system save dialog. Returns true when the
  /// user picked a destination and the file was written.
  Future<bool> exportBackup() async {
    final tmpDir = await getTemporaryDirectory();
    final tmpFile = File(p.join(tmpDir.path, 'expenses_backup_tmp.sqlite'));
    if (tmpFile.existsSync()) tmpFile.deleteSync();
    try {
      await exportTo(tmpFile.path);
      final bytes = await tmpFile.readAsBytes();
      final name =
          'expenses_backup_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.sqlite';
      final saved = await FilePicker.platform.saveFile(
        fileName: name,
        bytes: bytes,
      );
      if (saved == null) return false; // user cancelled
      // Desktop pickers return a destination path without writing the bytes.
      if (!File(saved).existsSync()) await File(saved).writeAsBytes(bytes);
      return true;
    } finally {
      if (tmpFile.existsSync()) tmpFile.deleteSync();
    }
  }

  Future<bool> exportCsv() async {
    final database = _ref.read(appDatabaseProvider);
    final rows = await database.select(database.expenses).get();
    final buffer = StringBuffer(
      'id,name,amount,currency,category,note,spent_at\n',
    );
    final currency = _ref.read(appSettingsProvider).value?.currencyCode ?? '';
    for (final row in rows.where((r) => r.deletedAt == null)) {
      buffer.writeln(
        [
          row.id,
          row.name,
          row.amount,
          currency,
          row.categoryId ?? '',
          row.note ?? '',
          DateTime.fromMillisecondsSinceEpoch(row.spentAt).toIso8601String(),
        ].map(_csvCell).join(','),
      );
    }
    final saved = await FilePicker.platform.saveFile(
      fileName:
          'expenses_${DateTime.now().toIso8601String().substring(0, 10)}.csv',
      bytes: utf8.encode(buffer.toString()),
    );
    return saved != null;
  }

  String _csvCell(Object value) {
    final text = '$value';
    final protected =
        text.isNotEmpty &&
            const {'=', '+', '-', '@', '\t', '\r'}.contains(text[0])
        ? "'$text"
        : text;
    return '"${protected.replaceAll('"', '""')}"';
  }

  /// Restore entry point: pick a file, then [restoreFrom].
  Future<RestoreStatus> restoreBackup() async {
    final picked = await FilePicker.platform.pickFiles(type: FileType.any);
    final pickedPath = picked?.files.single.path;
    if (pickedPath == null) return RestoreStatus.cancelled;
    return restoreFrom(pickedPath);
  }

  /// Validates a backup file, then swaps it in as THE database:
  /// close live connection → replace file → invalidate the provider graph
  /// (repositories, streams and settings rebuild on the restored data).
  Future<RestoreStatus> restoreFrom(String pickedPath) async {
    final source = File(pickedPath);
    if (!source.existsSync()) return RestoreStatus.invalidFile;

    // Quick rejection: a real SQLite database starts with this 16-byte magic.
    final magic = 'SQLite format 3\u0000'.codeUnits;
    final header = <int>[];
    final raf = await source.open();
    try {
      header.addAll(await raf.read(magic.length));
    } finally {
      await raf.close();
    }
    if (header.length < magic.length) return RestoreStatus.invalidFile;
    for (var i = 0; i < magic.length; i++) {
      if (header[i] != magic[i]) return RestoreStatus.invalidFile;
    }

    // Schema sanity via a throwaway read-only handle — never the live one.
    final live = _ref.read(appDatabaseProvider);
    try {
      final probe = raw.sqlite3.open(pickedPath, mode: raw.OpenMode.readOnly);
      int version = 0;
      var expenseTables = 0;
      try {
        version = probe.select('PRAGMA user_version').first.values.first as int;
        expenseTables =
            probe
                    .select(
                      "SELECT count(*) AS c FROM sqlite_master "
                      "WHERE type = 'table' AND name = 'expenses'",
                    )
                    .first
                    .values
                    .first
                as int;
      } finally {
        probe.close();
      }
      if (expenseTables == 0) return RestoreStatus.invalidFile;
      // Older backups are fine — drift migrates them on the next open.
      if (version > live.schemaVersion) return RestoreStatus.tooNew;
    } on raw.SqliteException {
      return RestoreStatus.invalidFile;
    }

    final target = await _filePath();
    await live.close();
    await source.copy(target);
    _ref.invalidate(appDatabaseProvider);
    return RestoreStatus.restored;
  }
}

final backupControllerProvider = Provider<BackupController>(
  (ref) => BackupController(ref),
);
