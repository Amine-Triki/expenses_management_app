import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as raw;

import 'package:expenses_management_app/application/backup_controller.dart';
import 'package:expenses_management_app/application/providers.dart';
import 'package:expenses_management_app/data/database/app_database.dart';
import 'package:expenses_management_app/data/repositories/settings_repository.dart';
import 'package:expenses_management_app/domain/models.dart';

void main() {
  late Directory tmpDir;

  setUp(() {
    tmpDir = Directory.systemTemp.createTempSync('backup_test');
    addTearDown(() => tmpDir.deleteSync(recursive: true));
  });

  AppDatabase fileDb(String path) => AppDatabase(NativeDatabase(File(path)));

  ProviderContainer containerFor(AppDatabase db, String dbPath) {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        backupControllerProvider.overrideWith(
          (ref) => BackupController(ref, filePath: () async => dbPath),
        ),
      ],
    );
    return container;
  }

  group('backup/restore', () {
    test('export → restore round-trip keeps all data', () async {
      final dbPath = p.join(tmpDir.path, 'expenses_app.sqlite');
      final backupPath = p.join(tmpDir.path, 'exported.sqlite');

      // 1. Seed a file-backed database and export it.
      final db1 = fileDb(dbPath);
      final c1 = containerFor(db1, dbPath);
      await c1.read(categoryRepositoryProvider).seedBuiltins();
      await c1
          .read(expenseRepositoryProvider)
          .add(
            name: 'Coffee',
            amount: 3500,
            spentAtMs: 1700000000000,
            source: ExpenseSource.manual,
          );
      await c1
          .read(settingsRepositoryProvider)
          .set(SettingsRepository.keyCurrency, 'TND');
      await c1.read(backupControllerProvider).exportTo(backupPath);
      await db1.close();
      c1.dispose();

      // 2. Fresh-install state: same path, empty database.
      await File(dbPath).delete();
      final db2 = fileDb(dbPath);
      final c2 = containerFor(db2, dbPath);

      // 3. Restore.
      final status = await c2
          .read(backupControllerProvider)
          .restoreFrom(backupPath);
      expect(status, RestoreStatus.restored);

      // 4. The swapped file opens with all the data back.
      await db2.close();
      final db3 = fileDb(dbPath);
      addTearDown(db3.close);
      final c3 = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db3)],
      );
      addTearDown(c3.dispose);

      final expenses = await c3
          .read(expenseRepositoryProvider)
          .watchAll()
          .first;
      expect(expenses.single.name, 'Coffee');
      expect(expenses.single.amount, 3500);

      final categories = await c3
          .read(categoryRepositoryProvider)
          .watchAll()
          .first;
      expect(categories, isNotEmpty);

      final settings = await c3
          .read(settingsRepositoryProvider)
          .watchAll()
          .first;
      expect(settings[SettingsRepository.keyCurrency], 'TND');
    });

    test('rejects a non-SQLite file', () async {
      final bad = File(p.join(tmpDir.path, 'bad.sqlite'));
      await bad.writeAsString('definitely not a database');

      final db = fileDb(p.join(tmpDir.path, 'live.sqlite'));
      final c = containerFor(db, p.join(tmpDir.path, 'live.sqlite'));
      addTearDown(() async {
        await db.close();
        c.dispose();
      });

      final status = await c
          .read(backupControllerProvider)
          .restoreFrom(bad.path);
      expect(status, RestoreStatus.invalidFile);
    });

    test('rejects a backup from a newer schema version', () async {
      final tooNew = p.join(tmpDir.path, 'toonew.sqlite');
      final probe = raw.sqlite3.open(tooNew);
      probe.execute('CREATE TABLE expenses (id TEXT PRIMARY KEY)');
      probe.execute('PRAGMA user_version = 99');
      probe.close();

      final db = fileDb(p.join(tmpDir.path, 'live2.sqlite'));
      final c = containerFor(db, p.join(tmpDir.path, 'live2.sqlite'));
      addTearDown(() async {
        await db.close();
        c.dispose();
      });

      final status = await c.read(backupControllerProvider).restoreFrom(tooNew);
      expect(status, RestoreStatus.tooNew);
    });

    test('rejects an SQLite file without app tables', () async {
      final foreign = p.join(tmpDir.path, 'foreign.sqlite');
      final probe = raw.sqlite3.open(foreign);
      probe.execute('CREATE TABLE something_else (x INTEGER)');
      probe.close();

      final db = fileDb(p.join(tmpDir.path, 'live3.sqlite'));
      final c = containerFor(db, p.join(tmpDir.path, 'live3.sqlite'));
      addTearDown(() async {
        await db.close();
        c.dispose();
      });

      final status = await c
          .read(backupControllerProvider)
          .restoreFrom(foreign);
      expect(status, RestoreStatus.invalidFile);
    });
  });
}
