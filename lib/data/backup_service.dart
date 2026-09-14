import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'package:spec/data/backup_format.dart';
import 'package:spec/data/bounded_zip_read.dart';
import 'package:spec/data/db/spec_database.dart';
import 'package:spec/data/models/spec_models.dart';
import 'package:spec/data/photo_store.dart';

export 'package:spec/data/backup_format.dart' show BackupFormatException;

// Size caps on what a zip may make SPEC read. A real archive of thousands of
// objects with photos is a few hundred megabytes; past these it is damage or
// hostility, and either way reading on would only end in a crash.
const kMaxBackupZipBytes = 1024 * 1024 * 1024;
const kMaxBackupJsonBytes = 8 * 1024 * 1024;
const kMaxBackupPhotoBytes = 25 * 1024 * 1024;

/// What a backup holds, counted before anything is replaced.
@immutable
class BackupSummary {
  const BackupSummary({
    required this.zones,
    required this.objects,
    required this.photos,
  });

  final int zones;
  final int objects;
  final int photos;
}

/// Export, restore and wipe: the user's way out of the app, back in, and
/// clean away. Everything here is local — a backup is a file the user holds.
///
/// A backup is one zip: `spec-backup.json` plus `photos/<fileName>`. One
/// file, because a share target or the Files app handles one file cleanly
/// and a folder of loose photos not at all.
class BackupService {
  BackupService(
    this._db,
    this._photos, {
    this.maxJsonBytes = kMaxBackupJsonBytes,
  });

  final SpecDatabase _db;
  final PhotoStore _photos;

  /// Injectable so a test can prove the cap without an 8 MiB fixture.
  @visibleForTesting
  final int maxJsonBytes;

  /// Writes `spec-backup-YYYY-MM-DD.zip` into [into] and returns it.
  ///
  /// A photo whose file is gone is left out of the JSON as well as the zip,
  /// so a restore never meets a reference it cannot satisfy.
  Future<File> writeZip({required Directory into, DateTime? now}) async {
    final stamp = now ?? DateTime.now();
    final zones = await (_db.select(
      _db.zones,
    )..orderBy([(z) => OrderingTerm(expression: z.sortOrder)])).get();
    final zoneNames = {for (final zone in zones) zone.id: zone.name};
    final objects = await (_db.select(
      _db.objects,
    )..orderBy([(o) => OrderingTerm(expression: o.id)])).get();
    final photosByObject = await _existingPhotosByObject();

    final json = encodeBackup(
      exportedAt: stamp,
      zones: [
        for (final zone in zones)
          BackupZone(name: zone.name, order: zone.sortOrder),
      ],
      objects: [
        for (final o in objects)
          _toBackup(o, zoneNames[o.zoneId], photosByObject[o.id] ?? const []),
      ],
    );

    final zip = File(p.join(into.path, 'spec-backup-${_day(stamp)}.zip'));
    final encoder = ZipFileEncoder()..create(zip.path);
    try {
      encoder.addArchiveFile(
        ArchiveFile.string(
          kBackupJsonName,
          const JsonEncoder.withIndent('  ').convert(json),
        ),
      );
      for (final name in photosByObject.values.expand((names) => names)) {
        await _addStored(encoder, _photos.resolve(name), name);
      }
    } finally {
      await encoder.close();
    }
    return zip;
  }

  /// Validates [zip] and counts what it holds. Touches nothing.
  ///
  /// Throws [BackupFormatException] for anything SPEC cannot restore.
  Future<BackupSummary> inspect(File zip) =>
      _withBackup(zip, (backup, _) async => _summarise(backup));

  /// Replaces every zone, object and photo with the contents of [zip].
  ///
  /// Validates first; a backup that fails leaves existing data untouched.
  /// Photos are staged under fresh names before the database is touched,
  /// the swap is one transaction, and old files go only after it commits —
  /// so every failure point leaves either the old archive or the new one,
  /// never half of each.
  Future<BackupSummary> restore(File zip) =>
      _withBackup(zip, (backup, entries) async {
        final staged = <String>[];
        var isCommitted = false;
        try {
          final photoNames = <List<String>>[];
          for (final object in backup.objects) {
            final names = <String>[];
            for (final name in object.photos) {
              final bytes = _readEntry(entries[name]!, kMaxBackupPhotoBytes);
              final newName = await _photos.addBytes(
                bytes,
                extension: p.extension(name),
              );
              staged.add(newName);
              names.add(newName);
            }
            photoNames.add(names);
          }
          final oldNames = await _allPhotoNames();
          await _db.transaction(() => _replaceRows(backup, photoNames));
          isCommitted = true;
          await _removeOldPhotos(oldNames);
          return _summarise(backup);
        } finally {
          // Deliberately no catch: whatever failed is the caller's to report,
          // and the only work here is not leaving staged files behind.
          if (!isCommitted) await _photos.remove(staged);
        }
      });

  /// Deletes every zone, object and photo file.
  Future<void> deleteEverything() async {
    await _db.transaction(_deleteRows);
    await _photos.sweep(const {});
  }

  Future<void> _deleteRows() async {
    await _db.delete(_db.photos).go();
    await _db.delete(_db.objects).go();
    await _db.delete(_db.zones).go();
  }

  Future<void> _replaceRows(
    DecodedBackup backup,
    List<List<String>> photoNames,
  ) async {
    await _deleteRows();
    final now = DateTime.now();
    final zoneIds = <String, int>{};
    for (final (index, zone) in backup.zones.indexed) {
      zoneIds[zone.name.toLowerCase()] = await _db
          .into(_db.zones)
          .insert(
            ZonesCompanion.insert(
              name: zone.name,
              sortOrder: index,
              createdAt: now,
            ),
          );
    }
    for (final (index, o) in backup.objects.indexed) {
      final id = await _db
          .into(_db.objects)
          .insert(
            ObjectsCompanion.insert(
              name: o.name,
              type: o.type.name,
              zoneId: Value(zoneIds[o.zone?.toLowerCase()]),
              subLocation: Value(o.subLocation),
              specKind: o.specKind.name,
              specValue: o.specValue,
              subtitle: Value(o.subtitle),
              libraryTerm: Value(o.libraryTerm),
              attributes: Value(encodeAttributes(o.attributes)),
              purchasedFrom: Value(o.purchasedFrom),
              replacedOn: Value(o.replacedOn),
              remindEveryMonths: Value(o.remindEveryMonths),
              createdAt: o.createdAt,
              updatedAt: o.updatedAt,
              notes: Value(o.notes),
            ),
          );
      for (final (order, fileName) in photoNames[index].indexed) {
        await _db
            .into(_db.photos)
            .insert(
              PhotosCompanion.insert(
                objectId: id,
                fileName: fileName,
                sortOrder: order,
                createdAt: now,
              ),
            );
      }
    }
  }

  /// The replaced archive's files. The new rows already committed, so a
  /// file that will not delete is an invisible orphan the next sweep takes —
  /// reported, but not a failed restore.
  Future<void> _removeOldPhotos(List<String> names) async {
    try {
      await _photos.remove(names);
    } on FileSystemException catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'backup',
          context: ErrorDescription('while removing replaced photo files'),
        ),
      );
    }
  }

  /// Opens [zip], validates it, and runs [action] with the decoded backup
  /// and the zip entry behind each photo it references. The zip stays open
  /// for [action] so a restore can stream photos out of it.
  Future<T> _withBackup<T>(
    File zip,
    Future<T> Function(DecodedBackup, Map<String, ArchiveFile>) action,
  ) async {
    if (await zip.length() > kMaxBackupZipBytes) {
      throw const BackupFormatException('This backup is too large to open.');
    }
    // ponytail: decoding runs on the UI isolate; move it to Isolate.run if a
    // large restore visibly stalls the progress UI.
    final input = InputFileStream(zip.path);
    try {
      final archive = _decodeZip(input);
      final json = _findJson(archive);
      final decoded = decodeBackup(_parseJson(json));
      final (backup, entries) = _resolvePhotos(decoded, archive, json);
      return await action(backup, entries);
    } finally {
      await input.close();
    }
  }

  static Archive _decodeZip(InputFileStream input) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeStream(input);
    } on FormatException {
      throw const BackupFormatException('This file is not a SPEC backup.');
    } on RangeError {
      // A truncated zip runs the decoder off the end of its buffer, which it
      // reports as RangeError rather than a format error. Untrusted bytes, so
      // this is bad input, not a bug here.
      throw const BackupFormatException('This file is not a SPEC backup.');
    }
    for (final entry in archive) {
      if (!_isSafeEntry(entry)) {
        throw const BackupFormatException(
          'This backup contains a file SPEC will not open.',
        );
      }
    }
    return archive;
  }

  /// Nothing is ever written to a zip-provided path, but an entry that tries
  /// to climb out or link elsewhere says the file was built to attack an
  /// extractor, so none of it is trusted.
  static bool _isSafeEntry(ArchiveFile entry) {
    final name = entry.name;
    if (entry.isSymbolicLink) return false;
    if (name.startsWith('/') || name.contains(r'\')) return false;
    if (RegExp('^[A-Za-z]:').hasMatch(name)) return false;
    return !name.split('/').contains('..');
  }

  /// Finder's `__MACOSX/` shadow folder and dotfiles ride along when a user
  /// zips a folder by hand; they are noise, not content.
  static bool _isIgnored(ArchiveFile entry) =>
      !entry.isFile ||
      entry.name.startsWith('__MACOSX/') ||
      entry.name.split('/').any((segment) => segment.startsWith('.'));

  /// The single data file, at the root or one folder down (a zipped folder).
  static ArchiveFile _findJson(Archive archive) {
    final candidates = [
      for (final entry in archive)
        if (!_isIgnored(entry) &&
            entry.name.toLowerCase().endsWith('.json') &&
            entry.name.split('/').length <= 2)
          entry,
    ];
    if (candidates.isEmpty) {
      throw const BackupFormatException('This file is not a SPEC backup.');
    }
    if (candidates.length > 1) {
      throw const BackupFormatException(
        'This file holds more than one backup.',
      );
    }
    return candidates.single;
  }

  Object? _parseJson(ArchiveFile entry) {
    try {
      return jsonDecode(utf8.decode(_readEntry(entry, maxJsonBytes)));
    } on FormatException {
      throw const BackupFormatException('This backup is damaged.');
    }
  }

  /// Pairs each referenced photo with its zip entry: `photos/<name>` beside
  /// the JSON, or `<name>` beside it for the old loose-file export zipped by
  /// hand. A reference with no file is dropped rather than failing the whole
  /// restore over one missing picture.
  static (DecodedBackup, Map<String, ArchiveFile>) _resolvePhotos(
    DecodedBackup backup,
    Archive archive,
    ArchiveFile json,
  ) {
    final slash = json.name.lastIndexOf('/');
    final folder = json.name.substring(0, slash + 1);
    final entries = <String, ArchiveFile>{};
    bool isPresent(String name) {
      if (entries.containsKey(name)) return true;
      for (final path in [
        '$folder$kBackupPhotosFolder/$name',
        '$folder$name',
      ]) {
        final entry = archive.find(path);
        if (entry == null || !entry.isFile) continue;
        entries[name] = entry;
        return true;
      }
      return false;
    }

    final objects = [
      for (final object in backup.objects)
        object.withPhotos([
          for (final name in object.photos)
            if (isPresent(name)) name,
        ]),
    ];
    return (DecodedBackup(zones: backup.zones, objects: objects), entries);
  }

  /// The entry's bytes, refusing anything over [max] or failing its checksum.
  ///
  /// The header's size claim is checked first as a cheap early out, but the
  /// real bound is enforced while inflating: the header is as untrusted as the
  /// rest, and inflating first would let a small entry expand without limit.
  static Uint8List _readEntry(ArchiveFile entry, int max) {
    if (entry.size > max) {
      throw const BackupFormatException('This backup holds a file too large.');
    }
    final Uint8List bytes;
    try {
      bytes = readZipEntryBounded(entry, max);
    } on BoundedReadException catch (error) {
      throw BackupFormatException(switch (error.failure) {
        BoundedReadFailure.tooLarge => 'This backup holds a file too large.',
        BoundedReadFailure.unsupported ||
        BoundedReadFailure.damaged => 'This backup is damaged.',
      });
    } on RangeError {
      // As in _decodeZip: truncated compressed data, not a bug here.
      throw const BackupFormatException('This backup is damaged.');
    }
    final crc = entry.crc32;
    if (crc != null && getCrc32(bytes) != crc) {
      throw const BackupFormatException('This backup is damaged.');
    }
    return bytes;
  }

  /// Photos travel as they are: JPEG and HEIC are already compressed, so
  /// deflating them again costs time and saves nothing.
  static Future<void> _addStored(
    ZipFileEncoder encoder,
    File file,
    String name,
  ) async {
    final stream = InputFileStream(file.path);
    try {
      encoder.addArchiveFile(
        ArchiveFile.stream('$kBackupPhotosFolder/$name', stream)
          ..compression = CompressionType.none,
      );
    } finally {
      await stream.close();
    }
  }

  /// Photo file names per object in display order, skipping missing files.
  Future<Map<int, List<String>>> _existingPhotosByObject() async {
    final rows = await (_db.select(
      _db.photos,
    )..orderBy([(ph) => OrderingTerm(expression: ph.sortOrder)])).get();
    final byObject = <int, List<String>>{};
    for (final row in rows) {
      if (!_photos.resolve(row.fileName).existsSync()) continue;
      (byObject[row.objectId] ??= []).add(row.fileName);
    }
    return byObject;
  }

  Future<List<String>> _allPhotoNames() async => [
    for (final row in await _db.select(_db.photos).get()) row.fileName,
  ];

  static BackupObject _toBackup(
    SpecObject o,
    String? zone,
    List<String> photos,
  ) => BackupObject(
    name: o.name,
    type: parseObjectType(o.type),
    zone: zone,
    subLocation: o.subLocation,
    specKind: parseSpecKind(o.specKind),
    specValue: o.specValue,
    subtitle: o.subtitle,
    libraryTerm: o.libraryTerm,
    attributes: decodeAttributes(o.attributes),
    purchasedFrom: o.purchasedFrom,
    replacedOn: o.replacedOn,
    remindEveryMonths: o.remindEveryMonths,
    createdAt: o.createdAt,
    updatedAt: o.updatedAt,
    notes: o.notes,
    photos: photos,
  );

  static BackupSummary _summarise(DecodedBackup backup) => BackupSummary(
    zones: backup.zones.length,
    objects: backup.objects.length,
    photos: backup.photoCount,
  );

  static String _day(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
}
