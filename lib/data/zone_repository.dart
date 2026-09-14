import 'package:drift/drift.dart';

import 'package:spec/data/db/spec_database.dart';
import 'package:spec/data/models/spec_models.dart';

/// The five zones a new archive starts with, in the order screen 06 lists
/// them.
const kDefaultZoneNames = ['Home', 'Car', 'Devices', 'Clothing', 'Other'];

/// A zone name is a word or two on one line at 26pt; anything past this is a
/// paste accident, not a name.
const kZoneNameMaxLength = 40;

/// Where an object goes when its own default zone no longer exists.
const _fallbackZone = 'Other';

/// How many recent specs a row samples.
const _sampleSize = 3;

/// The default zone an object of [type] is filed under.
///
/// There is no Products zone in the design, so products land in Other.
String defaultZoneFor(ObjectType type) => switch (type) {
  ObjectType.home => 'Home',
  ObjectType.car => 'Car',
  ObjectType.device => 'Devices',
  ObjectType.clothing => 'Clothing',
  ObjectType.product || ObjectType.other => 'Other',
};

/// One zone as the collections list needs it.
class ZoneSummary {
  const ZoneSummary({
    required this.id,
    required this.name,
    required this.count,
    required this.specValues,
    required this.photoFileName,
  });

  final int id;
  final String name;
  final int count;

  /// The newest objects' spec strings, newest first, at most three.
  final List<String> specValues;

  /// The newest object's first photo. Null when that object has none, even
  /// if an older one does: the thumb shows what was added last.
  final String? photoFileName;
}

/// Reads and writes zones. Concrete for the same reason [ObjectRepository]
/// is: one store, and tests use a real in-memory database.
class ZoneRepository {
  ZoneRepository(this._db);

  final SpecDatabase _db;

  /// Seeds the default zones into an empty table, then files every unfiled
  /// object under the zone its type maps to.
  ///
  /// Seeding only an empty table is what lets a deleted default stay
  /// deleted.
  // ponytail: an archive whose zones were all deleted reseeds on next launch;
  // add a settings flag if anyone ever wants zero zones to stick.
  Future<void> ensureDefaults() => _db.transaction(() async {
    final existing = await _db.select(_db.zones).get();
    if (existing.isEmpty) {
      final now = DateTime.now();
      for (var i = 0; i < kDefaultZoneNames.length; i++) {
        await _db
            .into(_db.zones)
            .insert(
              ZonesCompanion.insert(
                name: kDefaultZoneNames[i],
                sortOrder: i,
                createdAt: now,
              ),
            );
      }
    }
    await _fileUnfiledObjects();
  });

  /// An object whose default zone was deleted goes to Other, which is
  /// recreated for it if that was deleted too: no object is ever outside
  /// every zone, where Collections cannot show it.
  Future<void> _fileUnfiledObjects() async {
    for (final type in ObjectType.values) {
      await _db.customUpdate(
        'UPDATE objects SET zone_id = (SELECT id FROM zones WHERE name = ?) '
        'WHERE zone_id IS NULL AND type = ?',
        variables: [
          Variable.withString(defaultZoneFor(type)),
          Variable.withString(type.name),
        ],
        updates: {_db.objects},
      );
    }
    final stranded = await (_db.select(
      _db.objects,
    )..where((o) => o.zoneId.isNull())).get();
    if (stranded.isEmpty) return;
    final other = await _idOf(_fallbackZone) ?? await _append(_fallbackZone);
    await (_db.update(_db.objects)..where((o) => o.zoneId.isNull())).write(
      ObjectsCompanion(zoneId: Value(other)),
    );
  }

  /// Every zone in list order, with its objects newest first folded in.
  Stream<List<ZoneSummary>> watchAll() => _db
      .customSelect(
        'SELECT z.id AS zone_id, z.name AS zone_name, o.id AS object_id, '
        'o.spec_value, '
        '(SELECT p.file_name FROM photos p WHERE p.object_id = o.id '
        'ORDER BY p.sort_order LIMIT 1) AS photo_file_name '
        'FROM zones z LEFT JOIN objects o ON o.zone_id = z.id '
        'ORDER BY z.sort_order, z.id, o.created_at DESC, o.id DESC',
        readsFrom: {_db.zones, _db.objects, _db.photos},
      )
      .watch()
      .map(_fold);

  static List<ZoneSummary> _fold(List<QueryRow> rows) {
    final zones = <ZoneSummary>[];
    for (final row in rows) {
      final id = row.read<int>('zone_id');
      final hasObject = row.readNullable<int>('object_id') != null;
      final isNewZone = zones.isEmpty || zones.last.id != id;
      if (isNewZone) {
        zones.add(
          ZoneSummary(
            id: id,
            name: row.read<String>('zone_name'),
            count: hasObject ? 1 : 0,
            specValues: [if (hasObject) row.read<String>('spec_value')],
            photoFileName: hasObject
                ? row.readNullable<String>('photo_file_name')
                : null,
          ),
        );
        continue;
      }
      final last = zones.last;
      zones[zones.length - 1] = ZoneSummary(
        id: last.id,
        name: last.name,
        count: last.count + 1,
        specValues: last.specValues.length < _sampleSize
            ? [...last.specValues, row.read<String>('spec_value')]
            : last.specValues,
        photoFileName: last.photoFileName,
      );
    }
    return zones;
  }

  /// Appends a zone. Null when the name is blank, too long, or taken.
  ///
  /// The name check and the insert share a transaction, so two commits of
  /// the same name cannot both pass the check and trip the UNIQUE constraint.
  Future<int?> create(String name) async {
    final trimmed = _validName(name);
    if (trimmed == null) return null;
    return _db.transaction(() async {
      if (await _isTaken(trimmed)) return null;
      return _append(trimmed);
    });
  }

  Future<int> _append(String name) async {
    final last = await _db
        .customSelect('SELECT COALESCE(MAX(sort_order), -1) AS n FROM zones')
        .getSingle();
    return _db
        .into(_db.zones)
        .insert(
          ZonesCompanion.insert(
            name: name,
            sortOrder: last.read<int>('n') + 1,
            createdAt: DateTime.now(),
          ),
        );
  }

  /// False when the name is blank, too long, or held by another zone.
  Future<bool> rename(int id, String name) async {
    final trimmed = _validName(name);
    if (trimmed == null) return false;
    return _db.transaction(() async {
      if (await _isTaken(trimmed, exceptId: id)) return false;
      await (_db.update(_db.zones)..where((z) => z.id.equals(id))).write(
        ZonesCompanion(name: Value(trimmed)),
      );
      return true;
    });
  }

  /// [ids] in their new order, top first.
  Future<void> reorder(List<int> ids) => _db.transaction(() async {
    for (var i = 0; i < ids.length; i++) {
      await (_db.update(_db.zones)..where((z) => z.id.equals(ids[i]))).write(
        ZonesCompanion(sortOrder: Value(i)),
      );
    }
  });

  /// Its objects are never deleted: the foreign key's SET NULL unfiles them,
  /// and the same transaction refiles them under their type's default zone.
  Future<void> delete(int id) => _db.transaction(() async {
    await (_db.delete(_db.zones)..where((z) => z.id.equals(id))).go();
    await _fileUnfiledObjects();
  });

  static String? _validName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > kZoneNameMaxLength) return null;
    return trimmed;
  }

  /// `name` is COLLATE NOCASE, so `=` already ignores case.
  Future<bool> _isTaken(String name, {int? exceptId}) async {
    final id = await _idOf(name);
    return id != null && id != exceptId;
  }

  Future<int?> _idOf(String name) async => (await (_db.select(
    _db.zones,
  )..where((z) => z.name.equals(name))).getSingleOrNull())?.id;
}
