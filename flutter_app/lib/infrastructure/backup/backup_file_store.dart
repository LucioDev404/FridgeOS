import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// App-private backup directory helpers. Avoids `file_picker`, which pinned
/// compileSdk 34 and broke release builds via flutter_plugin_android_lifecycle.
final class BackupFileStore {
  const BackupFileStore();

  static const String relativeDir = 'FridgeOS/backups';

  Future<Directory> backupsDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(root.path, relativeDir));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Writes [bytes] as a new backup file and returns its path.
  Future<File> writeBackup(Uint8List bytes, {required String fileName}) async {
    final dir = await backupsDirectory();
    final file = File(p.join(dir.path, fileName));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Lists encrypted backup JSON files, newest first.
  Future<List<File>> listBackups() async {
    final dir = await backupsDirectory();
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.json'))
        .toList();
    files.sort(
      (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
    );
    return files;
  }

  /// Opens the system share sheet so the user can copy the backup off-device.
  Future<void> shareBackup(File file) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: p.basename(file.path),
      ),
    );
  }
}
