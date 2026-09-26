import 'dart:io';

const _unit = 1000;
const _units = ['KB', 'MB', 'GB', 'TB'];

/// `2.1 MB`. Decimal units, the way iOS and Android both report storage, so
/// the figure agrees with the system's own Settings.
String storageLabel(int bytes) {
  if (bytes < _unit) return '$bytes B';
  var value = bytes / _unit;
  var index = 0;
  while (value >= _unit && index < _units.length - 1) {
    value /= _unit;
    index++;
  }
  return '${value.toStringAsFixed(1)} ${_units[index]}';
}

/// The bytes a file or a whole folder takes. Something missing is zero: the
/// photo folder does not exist until the first photo is saved.
///
/// A file removed between listing and measuring also counts as zero, since a
/// delete can land while this walks the folder.
Future<int> bytesOf(FileSystemEntity entity) async {
  if (entity is File) return _fileBytes(entity);
  if (entity is! Directory || !entity.existsSync()) return 0;
  return entity
      .list(recursive: true, followLinks: false)
      .where((child) => child is File)
      .asyncMap((child) => _fileBytes(child as File))
      .fold<int>(0, (total, bytes) => total + bytes);
}

Future<int> _fileBytes(File file) async {
  try {
    return await file.length();
  } on FileSystemException {
    return 0;
  }
}
