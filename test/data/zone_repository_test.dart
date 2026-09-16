import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/data/db/spec_database.dart';
import 'package:spec/data/models/spec_models.dart';
import 'package:spec/data/zone_repository.dart';

void main() {
  late SpecDatabase db;
  late ZoneRepository zones;

  setUp(() {
    db = SpecDatabase.memory();
    zones = ZoneRepository(db);
  });

  tearDown(() => db.close());

  Future<int> createObject({
    required ObjectType type,
    required String spec,
    int? zoneId,
    required DateTime createdAt,
    List<String> photos = const [],
  }) async {
    final id = await db
        .into(db.objects)
        .insert(
          ObjectsCompanion.insert(
            name: spec,
            type: type.name,
            specKind: SpecKind.model.name,
            specValue: spec,
            zoneId: Value(zoneId),
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        );
    for (var i = 0; i < photos.length; i++) {
      await db
          .into(db.photos)
          .insert(
            PhotosCompanion.insert(
              objectId: id,
              fileName: photos[i],
              sortOrder: i,
              createdAt: createdAt,
            ),
          );
    }
    return id;
  }

  group('ensureDefaults', () {
    test('seeds the five design zones in order when there are none', () async {
      // Act
      await zones.ensureDefaults();
      final rows = await zones.watchAll().first;

      // Assert
      expect(rows.map((z) => z.name), kDefaultZoneNames);
      expect(rows.every((z) => z.count == 0), isTrue);
    });

    test('does not reseed once zones exist', () async {
      // Arrange
      await zones.ensureDefaults();
      final home = (await zones.watchAll().first).first;
      await zones.delete(home.id);

      // Act
      await zones.ensureDefaults();
      final rows = await zones.watchAll().first;

      // Assert
      expect(rows.map((z) => z.name), isNot(contains('Home')));
    });

    test('files unfiled objects under the zone their type maps to', () async {
      // Arrange
      await createObject(
        type: ObjectType.device,
        spec: '67XL',
        createdAt: DateTime(2026, 9, 1),
      );
      await createObject(
        type: ObjectType.product,
        spec: 'M10',
        createdAt: DateTime(2026, 9, 1),
      );

      // Act
      await zones.ensureDefaults();
      final rows = await zones.watchAll().first;

      // Assert
      int countOf(String name) => rows.firstWhere((z) => z.name == name).count;
      expect(countOf('Devices'), 1);
      expect(countOf('Other'), 1, reason: 'product lands in Other');
    });
  });

  group('watchAll', () {
    test('samples the three most recently added specs, newest first', () async {
      // Arrange
      await zones.ensureDefaults();
      final homeId = (await zones.watchAll().first).first.id;
      for (final (day, spec) in [(1, 'OLD'), (2, 'LT1000P'), (3, 'E27')]) {
        await createObject(
          type: ObjectType.home,
          spec: spec,
          zoneId: homeId,
          createdAt: DateTime(2026, 9, day),
        );
      }
      await createObject(
        type: ObjectType.home,
        spec: 'B22',
        zoneId: homeId,
        createdAt: DateTime(2026, 9, 4),
        photos: ['bulb.jpg'],
      );

      // Act
      final home = (await zones.watchAll().first).first;

      // Assert
      expect(home.count, 4);
      expect(home.specValues, ['B22', 'E27', 'LT1000P']);
      expect(home.photoFileName, 'bulb.jpg');
    });

    test(
      'takes the photo of the newest object only, even if it has none',
      () async {
        // Arrange
        await zones.ensureDefaults();
        final homeId = (await zones.watchAll().first).first.id;
        await createObject(
          type: ObjectType.home,
          spec: 'B22',
          zoneId: homeId,
          createdAt: DateTime(2026, 9, 1),
          photos: ['old.jpg'],
        );
        await createObject(
          type: ObjectType.home,
          spec: 'E27',
          zoneId: homeId,
          createdAt: DateTime(2026, 9, 2),
        );

        // Act
        final home = (await zones.watchAll().first).first;

        // Assert
        expect(home.photoFileName, isNull);
      },
    );
  });

  group('writes', () {
    test('create appends a zone at the end of the order', () async {
      // Arrange
      await zones.ensureDefaults();

      // Act
      final id = await zones.create('  Garage ');
      final rows = await zones.watchAll().first;

      // Assert
      expect(id, isNotNull);
      expect(rows.last.name, 'Garage');
    });

    test('create refuses a blank or already-taken name', () async {
      // Arrange
      await zones.ensureDefaults();

      // Act & Assert
      expect(await zones.create('   '), isNull);
      expect(await zones.create('home'), isNull, reason: 'names are NOCASE');
    });

    test('rename trims, and refuses a name another zone holds', () async {
      // Arrange
      await zones.ensureDefaults();
      final rows = await zones.watchAll().first;
      final car = rows[1];

      // Act
      final isTaken = await zones.rename(car.id, 'HOME');
      final isRenamed = await zones.rename(car.id, ' Garage ');
      final after = await zones.watchAll().first;

      // Assert
      expect(isTaken, isFalse);
      expect(isRenamed, isTrue);
      expect(after[1].name, 'Garage');
    });

    test('rename to its own name in another case is allowed', () async {
      // Arrange
      await zones.ensureDefaults();
      final car = (await zones.watchAll().first)[1];

      // Act
      final isRenamed = await zones.rename(car.id, 'CAR');

      // Assert
      expect(isRenamed, isTrue);
    });

    test('reorder writes the given order', () async {
      // Arrange
      await zones.ensureDefaults();
      final ids = [for (final z in await zones.watchAll().first) z.id];

      // Act
      await zones.reorder(ids.reversed.toList());
      final rows = await zones.watchAll().first;

      // Assert
      expect(rows.map((z) => z.name), kDefaultZoneNames.reversed);
    });

    Future<String?> zoneNameOf(int objectId) async {
      final row = await db
          .customSelect(
            'SELECT z.name FROM objects o LEFT JOIN zones z ON z.id = o.zone_id '
            'WHERE o.id = ?',
            variables: [Variable.withInt(objectId)],
          )
          .getSingle();
      return row.readNullable<String>('name');
    }

    test('delete refiles its objects under their type default zone', () async {
      // Arrange
      await zones.ensureDefaults();
      final kitchen = (await zones.create('Kitchen'))!;
      final lamp = await createObject(
        type: ObjectType.home,
        spec: 'B22',
        zoneId: kitchen,
        createdAt: DateTime(2026, 9, 1),
      );
      final ink = await createObject(
        type: ObjectType.device,
        spec: '67XL',
        zoneId: kitchen,
        createdAt: DateTime(2026, 9, 1),
      );

      // Act
      await zones.delete(kitchen);
      final rows = await zones.watchAll().first;

      // Assert
      expect(await zoneNameOf(lamp), 'Home');
      expect(await zoneNameOf(ink), 'Devices');
      expect(rows.fold<int>(0, (sum, z) => sum + z.count), 2);
    });

    test('delete falls back to Other when the type default is gone', () async {
      // Arrange
      await zones.ensureDefaults();
      final homeId = (await zones.watchAll().first).first.id;
      final lamp = await createObject(
        type: ObjectType.home,
        spec: 'B22',
        zoneId: homeId,
        createdAt: DateTime(2026, 9, 1),
      );

      // Act
      await zones.delete(homeId);

      // Assert
      expect(await zoneNameOf(lamp), 'Other');
    });

    test('delete recreates Other when nothing else can take them', () async {
      // Arrange
      await zones.ensureDefaults();
      final otherId = (await zones.watchAll().first).last.id;
      final bolt = await createObject(
        type: ObjectType.product,
        spec: 'M10',
        zoneId: otherId,
        createdAt: DateTime(2026, 9, 1),
      );

      // Act
      await zones.delete(otherId);
      final rows = await zones.watchAll().first;

      // Assert
      expect(await zoneNameOf(bolt), 'Other');
      expect(rows.last.name, 'Other');
      expect(rows.last.count, 1);
    });
  });
}
