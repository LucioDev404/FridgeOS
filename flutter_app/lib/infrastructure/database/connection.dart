import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:fridgeos/infrastructure/database/app_database.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Filename of the on-device SQLite database.
const String kDatabaseFileName = 'fridgeos.sqlite';

/// Opens the application database in the app's private documents directory.
///
/// Encryption-at-rest extension point (docs/06-database-design.md §6): to enable
/// SQLCipher, provision the key via `DatabaseKeyManager`, swap in the SQLCipher
/// native library and apply `PRAGMA key` in [NativeDatabase.setup]. This is
/// finalized in Phase 9; the standard build ships unencrypted app-private
/// storage until then.
AppDatabase openAppDatabase() => AppDatabase(_openConnection());

QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, kDatabaseFileName));
    return NativeDatabase.createInBackground(file);
  });
}
