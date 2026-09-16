import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/data/db/spec_database.dart';
import 'package:spec/data/models/spec_models.dart';
import 'package:spec/data/object_repository.dart';
import 'package:spec/data/photo_store.dart';

void main() {
  late SpecDatabase db;
  late ObjectRepository objects;

  setUp(() {
    db = SpecDatabase.memory();
    objects = ObjectRepository(db);
  });

  tearDown(() => db.close());

  Future<int> createBulb({int? zoneId, List<String> photos = const []}) =>
      objects.create(
        ObjectsCompanion.insert(
          name: 'Bedroom bulb',
          type: ObjectType.product.name,
          specKind: SpecKind.model.name,
          specValue: 'B22',
          zoneId: Value(zoneId),
          subLocation: const Value('Ceiling'),
          attributes: Value(
            encodeAttributes(const [
              SpecAttribute(label: 'WATTAGE', value: '9W'),
            ]),
          ),
          createdAt: DateTime(2026, 9, 1),
          updatedAt: DateTime(2026, 9, 1),
        ),
        photoFileNames: photos,
      );

  test('saving edits writes the spec, attributes and metadata', () async {
    // Arrange
    final id = await createBulb();

    // Act
    await objects.updateDetail(
      id,
      specValue: 'E27',
      attributes: const [SpecAttribute(label: 'WATTAGE', value: '11W')],
      purchasedFrom: 'IKEA',
      replacedOn: '2026-08-14',
      notes: null,
    );
    final detail = await objects.watchDetail(id).first;

    // Assert
    expect(detail!.summary.specValue, 'E27');
    expect(detail.summary.attributes.single.value, '11W');
    expect(detail.purchasedFrom, 'IKEA');
    expect(detail.replacedOn, '2026-08-14');
  });

  test(
    'saving a cleared field stores null rather than an empty string',
    () async {
      final id = await createBulb();
      await objects.updateDetail(
        id,
        specValue: 'B22',
        attributes: const [],
        purchasedFrom: 'IKEA',
        replacedOn: '2026-08-14',
        notes: 'Warm white only',
      );

      await objects.updateDetail(
        id,
        specValue: 'B22',
        attributes: const [],
        purchasedFrom: null,
        replacedOn: null,
        notes: '   ',
      );
      final detail = await objects.watchDetail(id).first;

      expect(detail!.purchasedFrom, isNull);
      expect(detail.replacedOn, isNull);
      expect(detail.notes, isNull);
    },
  );

  test('photos come back in the order they were added', () async {
    // Arrange
    final id = await createBulb(photos: ['a.jpg', 'b.jpg']);

    // Act
    final detail = await objects.watchDetail(id).first;

    // Assert
    expect(detail!.photoFileNames, ['a.jpg', 'b.jpg']);
    expect(detail.summary.photoFileName, 'a.jpg');
  });

  test('attributes survive the JSON column', () async {
    final id = await createBulb();

    final detail = await objects.watchDetail(id).first;

    expect(detail!.summary.attributes.single.label, 'WATTAGE');
    expect(detail.summary.attributes.single.value, '9W');
  });

  test('deleting an object takes its photo rows with it', () async {
    // The cascade only fires because beforeOpen turns foreign keys on; it is
    // off by default and per connection.
    final id = await createBulb(photos: ['a.jpg']);

    await objects.delete(id);

    expect(await db.select(db.photos).get(), isEmpty);
  });

  test('deleting an object hands back its photo file names', () async {
    // Arrange
    final id = await createBulb(photos: ['a.jpg', 'b.jpg']);
    await createBulb(photos: ['c.jpg']);

    // Act
    final names = await objects.delete(id);

    // Assert
    expect(names, ['a.jpg', 'b.jpg']);
    expect(await objects.photoFileNames(), {'c.jpg'});
  });

  test('photo file names cover every object', () async {
    await createBulb(photos: ['a.jpg', 'b.jpg']);
    await createBulb(photos: ['c.jpg']);

    expect(await objects.photoFileNames(), {'a.jpg', 'b.jpg', 'c.jpg'});
  });

  test('deleting an object the way screen 03 does removes its files', () async {
    // Arrange: a real file in a real store, filed under a real row.
    final directory = Directory.systemTemp.createTempSync('spec_delete');
    addTearDown(() => directory.deleteSync(recursive: true));
    final store = PhotoStore(directory);
    final fileName = await store.addBytes([1, 2, 3], extension: '.jpg');
    final id = await createBulb(photos: [fileName]);

    // Act: the sequence ObjectRoute's onDelete runs.
    await store.remove(await objects.delete(id));

    // Assert
    expect(store.resolve(fileName).existsSync(), isFalse);
  });

  group('notes', () {
    ObjectsCompanion withNotes(String? notes) => ObjectsCompanion.insert(
      name: 'Bedroom bulb',
      type: ObjectType.product.name,
      specKind: SpecKind.model.name,
      specValue: 'B22',
      notes: Value(notes),
      createdAt: DateTime(2026, 9, 1),
      updatedAt: DateTime(2026, 9, 1),
    );

    Future<void> save(int id, String? notes) => objects.updateDetail(
      id,
      specValue: 'B22',
      attributes: const [],
      purchasedFrom: null,
      replacedOn: null,
      notes: notes,
    );

    test('come back from create', () async {
      final id = await objects.create(withNotes('Warm white only'));

      final detail = await objects.watchDetail(id).first;

      expect(detail!.notes, 'Warm white only');
    });

    test('saving writes them trimmed and capped', () async {
      final id = await objects.create(withNotes(null));

      await save(id, '  ${'x' * (kNotesMaxLength + 20)}  ');
      final detail = await objects.watchDetail(id).first;

      expect(detail!.notes, 'x' * kNotesMaxLength);
    });

    test('saving them cleared stores null', () async {
      final id = await objects.create(withNotes('Warm white only'));

      await save(id, '');
      final detail = await objects.watchDetail(id).first;

      expect(detail!.notes, isNull);
    });
  });

  test('deleting a zone keeps the object and clears its zone', () async {
    final zoneId = await db
        .into(db.zones)
        .insert(
          ZonesCompanion.insert(
            name: 'Home',
            sortOrder: 0,
            createdAt: DateTime(2026, 1, 1),
          ),
        );
    final id = await createBulb(zoneId: zoneId);

    await (db.delete(db.zones)..where((z) => z.id.equals(zoneId))).go();

    final detail = await objects.watchDetail(id).first;
    expect(detail, isNotNull);
    expect(detail!.summary.zoneName, isNull);
  });

  test('zone names are unique regardless of case', () async {
    await db
        .into(db.zones)
        .insert(
          ZonesCompanion.insert(
            name: 'Home',
            sortOrder: 0,
            createdAt: DateTime(2026, 1, 1),
          ),
        );

    expect(
      () => db
          .into(db.zones)
          .insert(
            ZonesCompanion.insert(
              name: 'home',
              sortOrder: 1,
              createdAt: DateTime(2026, 1, 1),
            ),
          ),
      throwsA(isA<Exception>()),
    );
  });

  group('zones on create', () {
    ObjectsCompanion filter() => ObjectsCompanion.insert(
      name: 'Device filter',
      type: ObjectType.device.name,
      specKind: SpecKind.filter.name,
      specValue: 'LT1000P',
      createdAt: DateTime(2026, 9, 1),
      updatedAt: DateTime(2026, 9, 1),
    );

    test('files the object under a zone it creates on first use', () async {
      final id = await objects.create(filter(), zoneName: 'Kitchen');

      final detail = await objects.watchDetail(id).first;
      expect(detail!.summary.zoneName, 'Kitchen');
      expect(await objects.zoneNames(), ['Kitchen']);
    });

    test('reuses an existing zone whatever the case', () async {
      await objects.create(filter(), zoneName: 'Kitchen');
      final id = await objects.create(filter(), zoneName: 'KITCHEN');

      final detail = await objects.watchDetail(id).first;
      expect(detail!.summary.zoneName, 'Kitchen');
      expect(await objects.zoneNames(), ['Kitchen']);
    });

    test('zone names come back in the order they were made', () async {
      await objects.create(filter(), zoneName: 'Kitchen');
      await objects.create(filter(), zoneName: 'Garage');

      expect(await objects.zoneNames(), ['Kitchen', 'Garage']);
    });
  });

  test(
    'REPLACED stamps a calendar day and the reminder derives from it',
    () async {
      final id = await objects.create(
        ObjectsCompanion.insert(
          name: 'Fridge filter',
          type: ObjectType.device.name,
          specKind: SpecKind.filter.name,
          specValue: 'LT1000P',
          remindEveryMonths: const Value(6),
          createdAt: DateTime(2026, 9, 1),
          updatedAt: DateTime(2026, 9, 1),
        ),
      );

      await objects.markReplaced(id, on: DateTime(2026, 8, 14));

      final detail = await objects.watchDetail(id).first;
      expect(detail!.replacedOn, '2026-08-14');
      expect(detail.remindOn, DateTime(2027, 2, 14));
    },
  );

  group('object actions', () {
    late Directory directory;
    late PhotoStore store;

    setUp(() {
      directory = Directory.systemTemp.createTempSync('spec_actions');
      store = PhotoStore(directory);
    });

    tearDown(() => directory.deleteSync(recursive: true));

    test('moving to a zone files it there and bumps updated_at', () async {
      // Arrange
      await objects.create(
        ObjectsCompanion.insert(
          name: 'Other',
          type: ObjectType.home.name,
          specKind: SpecKind.other.name,
          specValue: 'X',
          createdAt: DateTime(2026, 9, 1),
          updatedAt: DateTime(2026, 9, 1),
        ),
        zoneName: 'Garage',
      );
      final id = await createBulb();

      // Act
      await objects.moveToZone(id, 'garage');
      final detail = await objects.watchDetail(id).first;

      // Assert: matched case-insensitively, no second zone made.
      expect(detail!.summary.zoneName, 'Garage');
      expect(detail.summary.updatedAt.isAfter(DateTime(2026, 9, 1)), isTrue);
      expect(await objects.zoneNames(), ['Garage']);
    });

    test(
      'setting a reminder writes the interval, and NEVER clears it',
      () async {
        final id = await createBulb();

        await objects.setReminder(id, 12);
        expect((await objects.watchDetail(id).first)!.remindEveryMonths, 12);

        await objects.setReminder(id, null);
        expect(
          (await objects.watchDetail(id).first)!.remindEveryMonths,
          isNull,
        );
      },
    );

    test('duplicating copies the fields and the photo files', () async {
      // Arrange
      final photo = await store.addBytes([1, 2, 3], extension: '.jpg');
      final id = await createBulb(photos: [photo]);
      await objects.updateDetail(
        id,
        specValue: 'B22',
        attributes: const [SpecAttribute(label: 'WATTAGE', value: '9W')],
        purchasedFrom: 'IKEA',
        replacedOn: '2026-08-14',
        notes: 'Warm white only',
      );
      await objects.setReminder(id, 6);

      // Act
      final copyId = await objects.duplicate(id, store);
      final original = (await objects.watchDetail(id).first)!;
      final copy = (await objects.watchDetail(copyId).first)!;

      // Assert
      expect(copyId, isNot(id));
      expect(copy.summary.name, original.summary.name);
      expect(copy.summary.specValue, 'B22');
      expect(copy.summary.subLocation, 'Ceiling');
      expect(copy.summary.attributes.single.value, '9W');
      expect(copy.purchasedFrom, 'IKEA');
      expect(copy.notes, 'Warm white only');
      expect(copy.remindEveryMonths, 6);
      expect(copy.replacedOn, isNull);
      expect(copy.createdAt.isAfter(original.createdAt), isTrue);

      final copied = copy.photoFileNames.single;
      expect(copied, isNot(photo));
      expect(store.resolve(copied).readAsBytesSync(), [1, 2, 3]);
      expect(original.photoFileNames, [photo]);
    });

    test('replacing a photo swaps the file on its row', () async {
      final id = await createBulb(photos: ['a.jpg', 'b.jpg']);

      final old = await objects.replacePhoto(id, 1, 'c.jpg');

      expect(old, 'b.jpg');
      expect((await objects.watchDetail(id).first)!.photoFileNames, [
        'a.jpg',
        'c.jpg',
      ]);
    });

    test('removing a photo drops its row and hands back the file', () async {
      final id = await createBulb(photos: ['a.jpg', 'b.jpg']);

      final removed = await objects.removePhoto(id, 0);

      expect(removed, 'a.jpg');
      expect((await objects.watchDetail(id).first)!.photoFileNames, ['b.jpg']);
    });

    test('a slot with no photo is refused rather than guessed', () async {
      final id = await createBulb(photos: ['a.jpg']);

      expect(objects.replacePhoto(id, 1, 'c.jpg'), throwsStateError);
      expect(objects.removePhoto(id, 1), throwsStateError);
    });
  });
}
