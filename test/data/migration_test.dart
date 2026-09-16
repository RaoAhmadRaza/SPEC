import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/data/db/spec_database.dart';
import 'package:spec/data/object_repository.dart';

/// Schema v1 as it shipped, frozen here from `tables.drift` at d63a657.
///
/// Copied rather than generated, because the point is to test against what is
/// already on people's phones — which does not change when tables.drift does.
const _v1Schema = [
  '''
CREATE TABLE zones (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL COLLATE NOCASE UNIQUE,
  sort_order INTEGER NOT NULL,
  created_at DATETIME NOT NULL
)''',
  '''
CREATE TABLE objects (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  zone_id INTEGER REFERENCES zones(id) ON DELETE SET NULL,
  sub_location TEXT,
  spec_kind TEXT NOT NULL,
  spec_value TEXT NOT NULL,
  subtitle TEXT,
  library_term TEXT,
  attributes TEXT NOT NULL DEFAULT '[]',
  purchased_from TEXT,
  replaced_on TEXT,
  remind_every_months INTEGER,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
)''',
  'CREATE INDEX objects_zone ON objects (zone_id)',
  'CREATE INDEX objects_updated ON objects (updated_at DESC)',
  '''
CREATE TABLE photos (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  object_id INTEGER NOT NULL REFERENCES objects(id) ON DELETE CASCADE,
  file_name TEXT NOT NULL UNIQUE,
  sort_order INTEGER NOT NULL,
  created_at DATETIME NOT NULL
)''',
  'CREATE INDEX photos_object ON photos (object_id, sort_order)',
];

/// A v1 database holding one object, as a phone on the previous build has it.
SpecDatabase _openV1() => SpecDatabase(
  NativeDatabase.memory(
    setup: (raw) {
      _v1Schema.forEach(raw.execute);
      raw.execute(
        'INSERT INTO objects (name, type, spec_kind, spec_value, created_at, '
        "updated_at) VALUES ('Bedroom bulb', 'product', 'model', 'B22', "
        '1788220800, 1788220800)',
      );
      raw.execute('PRAGMA user_version = 1');
    },
  ),
);

Future<List<String>> _objectColumns(SpecDatabase db) async => [
  for (final row
      in await db
          .customSelect("SELECT name FROM pragma_table_info('objects')")
          .get())
    row.read<String>('name'),
];

void main() {
  test('a v1 object survives the upgrade with no notes', () async {
    // Arrange
    final db = _openV1();
    addTearDown(db.close);

    // Act
    final objects = await ObjectRepository(db).all();

    // Assert
    expect(objects.single.name, 'Bedroom bulb');
    expect(objects.single.specValue, 'B22');
    expect(objects.single.notes, isNull);
  });

  test('an upgraded object takes notes', () async {
    // Arrange
    final db = _openV1();
    addTearDown(db.close);
    final repository = ObjectRepository(db);
    final id = (await repository.all()).single.id;

    // Act
    await repository.updateDetail(
      id,
      specValue: 'B22',
      attributes: const [],
      purchasedFrom: null,
      replacedOn: null,
      notes: 'Warm white only',
    );

    // Assert
    expect((await repository.watchDetail(id).first)!.notes, 'Warm white only');
  });

  test('an upgraded objects table matches a fresh one', () async {
    // Arrange
    final upgraded = _openV1();
    final fresh = SpecDatabase.memory();
    addTearDown(upgraded.close);
    addTearDown(fresh.close);

    // Act
    final upgradedColumns = await _objectColumns(upgraded);
    final freshColumns = await _objectColumns(fresh);

    // Assert
    expect(upgradedColumns, freshColumns);
    expect(upgradedColumns.last, 'notes');
  });
}
