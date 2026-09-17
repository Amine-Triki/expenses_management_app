import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_database.dart';

AppDatabase openAppDatabase() => AppDatabase(_openConnection());

/// Path of the single SQLite file that holds ALL app data (including
/// settings). The backup/restore flow swaps this whole file.
Future<String> dbFilePath() async {
  final dir = await getApplicationDocumentsDirectory();
  return p.join(dir.path, 'expenses_app.sqlite');
}

/// All SQL runs on a background isolate — the UI thread never blocks on
/// SQLite (drift-recommended setup for Flutter apps).
LazyDatabase _openConnection() => LazyDatabase(() async {
  final file = File(await dbFilePath());
  return NativeDatabase.createInBackground(file);
});
