import 'package:drift/drift.dart';

import 'package:spec/data/db/spec_database.dart';
import 'package:spec/data/models/spec_models.dart';
import 'package:spec/data/photo_store.dart';

/// Reads and writes objects. No abstract interface: there is one storage
/// implementation and there will never be a second, because "no server" is the
/// product. Tests inject a real in-memory database instead of a fake.
class ObjectRepository {
  ObjectRepository(this._db);

  final SpecDatabase _db;

  /// Newest first. Home takes the first few; search scores all of them.
  Stream<List<ObjectSummary>> watchAll() => _db.objectSummaries().watch().map(
    (rows) => [
      for (final row in rows)
        _toSummary(row.o, row.zoneName, row.photoFileName),
    ],
  );

  Future<List<ObjectSummary>> all() async => (await _db.objectSummaries().get())
      .map((row) => _toSummary(row.o, row.zoneName, row.photoFileName))
      .toList();

  /// Live, so stamping a replacement date updates the detail screen with no
  /// manual invalidation.
  Stream<ObjectDetail?> watchDetail(int id) =>
      _db.objectSummary(id).watchSingleOrNull().asyncMap(_withPhotos);

  /// One read, for an action that needs the row as it is now.
  Future<ObjectDetail?> detail(int id) async =>
      _withPhotos(await _db.objectSummary(id).getSingleOrNull());

  Future<ObjectDetail?> _withPhotos(ObjectSummaryResult? row) async {
    if (row == null) return null;
    final photoFileNames = await _db.objectPhotoNames(row.o.id).get();
    final summary = _toSummary(row.o, row.zoneName, row.photoFileName);
    return _toDetail(row.o, summary, photoFileNames);
  }

  /// Photos arrive as file names, never paths, and only after their bytes are
  /// on disk: a crash then leaves an invisible orphan file rather than a
  /// visible broken tile.
  ///
  /// [zoneName] is looked up case-insensitively and created on first use, in
  /// the same transaction, so a failed insert never leaves an empty zone.
  Future<int> create(
    ObjectsCompanion draft, {
    List<String> photoFileNames = const [],
    String? zoneName,
  }) {
    return _db.transaction(() async {
      final row = zoneName == null
          ? draft
          : draft.copyWith(zoneId: Value(await _zoneIdFor(zoneName)));
      final id = await _db.into(_db.objects).insert(row);
      final now = DateTime.now();
      for (var i = 0; i < photoFileNames.length; i++) {
        await _db
            .into(_db.photos)
            .insert(
              PhotosCompanion.insert(
                objectId: id,
                fileName: photoFileNames[i],
                sortOrder: i,
                createdAt: now,
              ),
            );
      }
      return id;
    });
  }

  /// The REPLACED button. The date is a calendar day as written, because
  /// nobody replaces a filter at 14:32:07 UTC.
  Future<void> markReplaced(int id, {DateTime? on}) {
    final day = on ?? DateTime.now();
    final iso =
        '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    return (_db.update(_db.objects)..where((o) => o.id.equals(id))).write(
      ObjectsCompanion(
        replacedOn: Value(iso),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// SAVE on screen 03. Every field it can edit is written, so a cleared
  /// field becomes null rather than keeping its old value.
  Future<void> updateDetail(
    int id, {
    required String specValue,
    required List<SpecAttribute> attributes,
    required String? purchasedFrom,
    required String? replacedOn,
    required String? notes,
  }) {
    return (_db.update(_db.objects)..where((o) => o.id.equals(id))).write(
      ObjectsCompanion(
        specValue: Value(specValue),
        attributes: Value(encodeAttributes(attributes)),
        purchasedFrom: Value(purchasedFrom),
        replacedOn: Value(replacedOn),
        notes: Value(cleanNotes(notes)),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Move to zone on screen 03. [zoneName] matches case-insensitively, so a
  /// name read from the zones table never makes a second zone.
  Future<void> moveToZone(int id, String zoneName) => _db.transaction(() async {
    final zoneId = await _zoneIdFor(zoneName);
    await (_db.update(_db.objects)..where((o) => o.id.equals(id))).write(
      ObjectsCompanion(zoneId: Value(zoneId), updatedAt: Value(DateTime.now())),
    );
  });

  /// Set reminder on screen 03. Null is NEVER.
  Future<void> setReminder(int id, int? months) =>
      (_db.update(_db.objects)..where((o) => o.id.equals(id))).write(
        ObjectsCompanion(
          remindEveryMonths: Value(months),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Duplicate on screen 03: every field the user wrote, and a copy of every
  /// photo file under a fresh name, so deleting either object never takes
  /// the other's photos with it. The replacement date is not copied: the
  /// copy has not been replaced yet.
  ///
  /// Files are copied before their rows are inserted, so a failure leaves
  /// orphans for the startup sweep rather than rows pointing at nothing.
  Future<int> duplicate(int id, PhotoStore photos) => _db.transaction(() async {
    final source = await (_db.select(
      _db.objects,
    )..where((o) => o.id.equals(id))).getSingle();
    final copies = [
      for (final name in await _db.objectPhotoNames(id).get())
        await photos.add(photos.resolve(name)),
    ];
    final now = DateTime.now();
    return create(
      source
          .toCompanion(true)
          .copyWith(
            id: const Value.absent(),
            replacedOn: const Value(null),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
      photoFileNames: copies,
    );
  });

  /// Replace on a photo tile: points the photo at [index] (in sort order) at
  /// [fileName] and hands back the old file name, for the caller to delete
  /// once this has committed.
  Future<String> replacePhoto(int objectId, int index, String fileName) =>
      _db.transaction(() async {
        final photo = await _photoAt(objectId, index);
        await (_db.update(_db.photos)..where((p) => p.id.equals(photo.id)))
            .write(PhotosCompanion(fileName: Value(fileName)));
        return photo.fileName;
      });

  /// Remove on a photo tile: deletes the row and hands back its file name,
  /// for the caller to delete once this has committed.
  Future<String> removePhoto(int objectId, int index) => _db.transaction(
    () async {
      final photo = await _photoAt(objectId, index);
      await (_db.delete(_db.photos)..where((p) => p.id.equals(photo.id))).go();
      return photo.fileName;
    },
  );

  /// Throws [StateError] when there is no photo there: the tile the user
  /// pressed is gone, and guessing another would change the wrong photo.
  Future<Photo> _photoAt(int objectId, int index) async {
    final rows =
        await (_db.select(_db.photos)
              ..where((p) => p.objectId.equals(objectId))
              ..orderBy([(p) => OrderingTerm.asc(p.sortOrder)]))
            .get();
    if (index < 0 || index >= rows.length) {
      throw StateError('Object $objectId has no photo at $index');
    }
    return rows[index];
  }

  /// Every zone the user has filed something under, oldest first.
  Future<List<String>> zoneNames() async {
    final query = _db.select(_db.zones)
      ..orderBy([(z) => OrderingTerm.asc(z.sortOrder)]);
    return [for (final zone in await query.get()) zone.name];
  }

  /// The column is `COLLATE NOCASE`, so `equals` already ignores case.
  Future<int> _zoneIdFor(String name) async {
    final existing = await (_db.select(
      _db.zones,
    )..where((z) => z.name.equals(name))).getSingleOrNull();
    if (existing != null) return existing.id;
    final count = await _db.zones.count().getSingle();
    return _db
        .into(_db.zones)
        .insert(
          ZonesCompanion.insert(
            name: name,
            sortOrder: count,
            createdAt: DateTime.now(),
          ),
        );
  }

  /// Photo rows go with it, by cascade, and their file names come back so the
  /// caller can delete the files. Read and delete share one transaction: a
  /// photo added in between would otherwise lose its row but keep its file.
  Future<List<String>> delete(int id) => _db.transaction(() async {
    final photoFileNames = await _db.objectPhotoNames(id).get();
    await (_db.delete(_db.objects)..where((o) => o.id.equals(id))).go();
    return photoFileNames;
  });

  /// Every file name any row refers to. What the startup sweep keeps.
  Future<Set<String>> photoFileNames() async => {
    for (final photo in await _db.select(_db.photos).get()) photo.fileName,
  };

  ObjectSummary _toSummary(
    SpecObject o,
    String? zoneName,
    String? photoFileName,
  ) {
    return ObjectSummary(
      id: o.id,
      name: o.name,
      type: parseObjectType(o.type),
      specKind: parseSpecKind(o.specKind),
      specValue: o.specValue,
      zoneName: zoneName,
      subLocation: o.subLocation,
      libraryTerm: o.libraryTerm,
      attributes: decodeAttributes(o.attributes),
      photoFileName: photoFileName,
      updatedAt: o.updatedAt,
      notes: o.notes,
    );
  }

  ObjectDetail _toDetail(
    SpecObject o,
    ObjectSummary summary,
    List<String> photoFileNames,
  ) => ObjectDetail(
    summary: summary,
    subtitle: o.subtitle,
    purchasedFrom: o.purchasedFrom,
    replacedOn: o.replacedOn,
    remindEveryMonths: o.remindEveryMonths,
    photoFileNames: photoFileNames,
    createdAt: o.createdAt,
  );
}
