import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_database.dart';

AppDatabase openAppDatabase() => AppDatabase(_openConnection());

/// All SQL runs on a background isolate — the UI thread never blocks on
/// SQLite (drift-recommended setup for Flutter apps).
LazyDatabase _openConnection() => LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'expenses_app.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
