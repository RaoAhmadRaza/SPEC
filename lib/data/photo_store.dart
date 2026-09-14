import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Where photo files live, and the only thing that knows their paths.
///
/// Rows store a file name and never a path: iOS regenerates the app container
/// UUID on every reinstall and restore, so a stored absolute path dangles
/// tomorrow. Documents rather than cache, because these are not a cache.
class PhotoStore {
  PhotoStore(this._directory);

  final Directory _directory;

  static Future<PhotoStore> open() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(documents.path, 'photos'));
    await directory.create(recursive: true);
    return PhotoStore(directory);
  }

  File resolve(String fileName) => File(p.join(_directory.path, fileName));

  /// Copies [source] in and returns the file name to store on the row.
  ///
  /// The bytes are flushed before the caller inserts anything, so a crash
  /// leaves an invisible orphan file rather than a visible broken tile.
  Future<String> add(File source) async =>
      addBytes(await source.readAsBytes(), extension: p.extension(source.path));

  /// Writes [bytes] under a fresh name and returns it.
  ///
  /// The name is a timestamp, bumped while it is taken: a restore writes many
  /// photos inside one microsecond, and two of them must never share a file.
  Future<String> addBytes(List<int> bytes, {required String extension}) async {
    final suffix = extension.toLowerCase();
    var stamp = DateTime.now().microsecondsSinceEpoch;
    // The name is claimed synchronously and exclusively before any await, so
    // two writes in flight at once can never both pick it.
    while (true) {
      try {
        resolve('$stamp$suffix').createSync(exclusive: true);
        break;
      } on PathExistsException {
        stamp++;
      }
    }
    final fileName = '$stamp$suffix';
    await resolve(fileName).writeAsBytes(bytes, flush: true);
    return fileName;
  }

  /// Deletes the named files. A file that is already gone is the outcome the
  /// caller wanted, so it is not an error.
  Future<void> remove(Iterable<String> fileNames) async {
    for (final fileName in fileNames) {
      try {
        await resolve(p.basename(fileName)).delete();
      } on PathNotFoundException {
        continue;
      }
    }
  }

  /// Deletes files no row refers to. Cold-start reconciliation for the orphans
  /// that a crash between write and insert leaves behind.
  Future<void> sweep(Set<String> knownFileNames) async {
    if (!_directory.existsSync()) return;
    await for (final entity in _directory.list()) {
      if (entity is! File) continue;
      if (knownFileNames.contains(p.basename(entity.path))) continue;
      await entity.delete();
    }
  }
}
