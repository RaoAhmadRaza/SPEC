import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:spec/data/backup_service.dart';
import 'package:spec/data/db/spec_database.dart';
import 'package:spec/data/models/spec_models.dart';
import 'package:spec/data/photo_store.dart';

void main() {
  late SpecDatabase db;
  late Directory root;
  late Directory photoDir;
  late PhotoStore photos;
  late BackupService service;

  setUp(() {
    db = SpecDatabase.memory();
    root = Directory.systemTemp.createTempSync('spec_backup_test');
    photoDir = Directory(p.join(root.path, 'photos'))..createSync();
    photos = PhotoStore(photoDir);
    service = BackupService(db, photos);
  });

  tearDown(() async {
    await db.close();
    await root.delete(recursive: true);
  });

  Future<int> addZone(String name, int order) => db
      .into(db.zones)
      .insert(
        ZonesCompanion.insert(
          name: name,
          sortOrder: order,
          createdAt: DateTime(2026, 9, 1),
        ),
      );

  Future<int> addObject(
    String name, {
    int? zoneId,
    String? notes,
    List<List<int>> photoBytes = const [],
  }) async {
    final id = await db
        .into(db.objects)
        .insert(
          ObjectsCompanion.insert(
            name: name,
            type: ObjectType.home.name,
            specKind: SpecKind.model.name,
            specValue: 'B22',
            zoneId: Value(zoneId),
            subLocation: const Value('Ceiling'),
            attributes: Value(
              encodeAttributes(const [
                SpecAttribute(label: 'POWER', value: '9W'),
              ]),
            ),
            purchasedFrom: const Value('IKEA'),
            replacedOn: const Value('2026-08-14'),
            remindEveryMonths: const Value(6),
            notes: Value(notes),
            createdAt: DateTime(2026, 9, 1),
            updatedAt: DateTime(2026, 9, 2),
          ),
        );
    for (final (order, bytes) in photoBytes.indexed) {
      final fileName = await photos.addBytes(bytes, extension: '.jpg');
      await db
          .into(db.photos)
          .insert(
            PhotosCompanion.insert(
              objectId: id,
              fileName: fileName,
              sortOrder: order,
              createdAt: DateTime(2026, 9, 1),
            ),
          );
    }
    return id;
  }

  Directory outDir() =>
      Directory(p.join(root.path, 'out'))..createSync(recursive: true);

  File writeRawZip(Archive archive, [String name = 'fixture.zip']) =>
      File(p.join(outDir().path, name))
        ..writeAsBytesSync(ZipEncoder().encodeBytes(archive));

  Map<String, Object?> backupJson({
    Object? version = 2,
    Object? format = 'spec-export',
    List<Map<String, Object?>>? zones,
    List<String> photoNames = const [],
    Object? createdAt = '2026-09-01T00:00:00.000',
  }) => {
    'format': format,
    'version': version,
    'zones':
        zones ??
        [
          {'name': 'Garage', 'order': 0},
        ],
    'objects': [
      {
        'name': 'Drill battery',
        'type': 'device',
        'zone': 'Garage',
        'specKind': 'battery',
        'specValue': '18V',
        'attributes': <Object?>[],
        'createdAt': createdAt,
        'updatedAt': '2026-09-01T00:00:00.000',
        'photos': photoNames,
      },
    ],
  };

  List<String> photoListing() =>
      [for (final f in photoDir.listSync()) p.basename(f.path)]..sort();

  Future<List<String>> objectNames() async => [
    for (final o in await db.select(db.objects).get()) o.name,
  ];

  test('a backup restores the same archive under new photo names', () async {
    // Arrange
    final homeId = await addZone('Home', 0);
    await addZone('Car', 1);
    await addObject(
      'Bedroom bulb',
      zoneId: homeId,
      notes: 'the one with the blue cap',
      photoBytes: [
        [1, 2, 3],
        [4, 5, 6, 7],
      ],
    );
    final oldNames = [
      for (final ph in await db.select(db.photos).get()) ph.fileName,
    ];
    final zip = await service.writeZip(
      into: outDir(),
      now: DateTime(2026, 9, 14),
    );

    // Act
    await service.deleteEverything();
    final summary = await service.restore(zip);

    // Assert
    expect(p.basename(zip.path), 'spec-backup-2026-09-14.zip');
    expect((summary.zones, summary.objects, summary.photos), (2, 1, 2));
    final zones = await (db.select(
      db.zones,
    )..orderBy([(z) => OrderingTerm(expression: z.sortOrder)])).get();
    expect(zones.map((z) => z.name), ['Home', 'Car']);
    final object = (await db.select(db.objects).get()).single;
    expect(object.name, 'Bedroom bulb');
    expect(object.zoneId, zones.first.id);
    expect(object.subLocation, 'Ceiling');
    expect(object.notes, 'the one with the blue cap');
    expect(object.purchasedFrom, 'IKEA');
    expect(object.replacedOn, '2026-08-14');
    expect(object.remindEveryMonths, 6);
    expect(object.createdAt, DateTime(2026, 9, 1));
    expect(object.updatedAt, DateTime(2026, 9, 2));
    expect(decodeAttributes(object.attributes).single.value, '9W');
    final restored = await (db.select(
      db.photos,
    )..orderBy([(ph) => OrderingTerm(expression: ph.sortOrder)])).get();
    expect(restored.map((ph) => ph.fileName), isNot(contains(oldNames.first)));
    expect(restored.map((ph) => ph.fileName), isNot(contains(oldNames.last)));
    expect(photos.resolve(restored[0].fileName).readAsBytesSync(), [1, 2, 3]);
    expect(photos.resolve(restored[1].fileName).readAsBytesSync(), [
      4,
      5,
      6,
      7,
    ]);
  });

  test('restore replaces data that is not in the backup', () async {
    // Arrange
    final zip = writeRawZip(
      Archive()
        ..add(ArchiveFile.string('spec-backup.json', jsonEncode(backupJson()))),
    );
    await addObject(
      'Old kettle',
      photoBytes: [
        [9],
      ],
    );
    final oldPhoto = photoListing().single;

    // Act
    await service.restore(zip);

    // Assert
    expect(await objectNames(), ['Drill battery']);
    expect(photoListing(), isNot(contains(oldPhoto)));
    expect(photoListing(), isEmpty);
  });

  test('a photo missing from the zip is dropped, not fatal', () async {
    // Arrange
    final zip = writeRawZip(
      Archive()..add(
        ArchiveFile.string(
          'spec-backup.json',
          jsonEncode(backupJson(photoNames: ['gone.jpg'])),
        ),
      ),
    );

    // Act
    final summary = await service.restore(zip);

    // Assert
    expect(summary.photos, 0);
    expect(await db.select(db.photos).get(), isEmpty);
  });

  test('a version 1 export zipped by hand restores with notes null', () async {
    // Arrange: the old loose layout, JSON and photos side by side in a folder.
    final zip = writeRawZip(
      Archive()
        ..add(
          ArchiveFile.string(
            'export/spec-export-2026-09-14.json',
            jsonEncode(backupJson(version: 1, photoNames: ['1.jpg'])),
          ),
        )
        ..add(ArchiveFile.bytes('export/1.jpg', [7, 7]))
        ..add(ArchiveFile.string('__MACOSX/export/._1.jpg', 'junk'))
        ..add(ArchiveFile.string('export/.DS_Store', 'junk')),
    );

    // Act
    final summary = await service.restore(zip);

    // Assert
    expect(summary.photos, 1);
    final object = (await db.select(db.objects).get()).single;
    expect(object.notes, isNull);
    final photo = (await db.select(db.photos).get()).single;
    expect(photos.resolve(photo.fileName).readAsBytesSync(), [7, 7]);
  });

  test('inspect counts a backup without touching data', () async {
    // Arrange
    final zip = writeRawZip(
      Archive()
        ..add(
          ArchiveFile.string(
            'spec-backup.json',
            jsonEncode(backupJson(photoNames: ['1.jpg'])),
          ),
        )
        ..add(ArchiveFile.bytes('photos/1.jpg', [1])),
    );
    await addObject('Kept');

    // Act
    final summary = await service.inspect(zip);

    // Assert
    expect((summary.zones, summary.objects, summary.photos), (1, 1, 1));
    expect(await objectNames(), ['Kept']);
  });

  group('a malformed backup throws and leaves data untouched', () {
    final cases = <String, File Function(File Function(Archive, [String]))>{
      'not a zip': (_) =>
          File(p.join(root.path, 'junk.zip'))
            ..writeAsBytesSync(utf8.encode('definitely not a zip')),
      'a truncated zip': (zip) {
        final whole = zip(
          Archive()..add(
            ArchiveFile.string('spec-backup.json', jsonEncode(backupJson())),
          ),
        );
        final bytes = whole.readAsBytesSync();
        return whole..writeAsBytesSync(bytes.sublist(0, bytes.length ~/ 2));
      },
      'a zip without JSON': (zip) =>
          zip(Archive()..add(ArchiveFile.bytes('photos/1.jpg', [1]))),
      'two JSON files': (zip) => zip(
        Archive()
          ..add(ArchiveFile.string('a.json', jsonEncode(backupJson())))
          ..add(ArchiveFile.string('b.json', jsonEncode(backupJson()))),
      ),
      'broken JSON': (zip) =>
          zip(Archive()..add(ArchiveFile.string('spec-backup.json', '{"x'))),
      'the wrong format key': (zip) => zip(
        Archive()..add(
          ArchiveFile.string(
            'spec-backup.json',
            jsonEncode(backupJson(format: 'other-app')),
          ),
        ),
      ),
      'version 3': (zip) => zip(
        Archive()..add(
          ArchiveFile.string(
            'spec-backup.json',
            jsonEncode(backupJson(version: 3)),
          ),
        ),
      ),
      'an entry climbing out with ..': (zip) => zip(
        Archive()
          ..add(
            ArchiveFile.string('spec-backup.json', jsonEncode(backupJson())),
          )
          ..add(ArchiveFile.bytes('../evil.jpg', [1])),
      ),
      'an absolute entry': (zip) => zip(
        Archive()
          ..add(
            ArchiveFile.string('spec-backup.json', jsonEncode(backupJson())),
          )
          ..add(ArchiveFile.bytes('/etc/evil.jpg', [1])),
      ),
      'a bad date': (zip) => zip(
        Archive()..add(
          ArchiveFile.string(
            'spec-backup.json',
            jsonEncode(backupJson(createdAt: 'not a date')),
          ),
        ),
      ),
      'duplicate zone names': (zip) => zip(
        Archive()..add(
          ArchiveFile.string(
            'spec-backup.json',
            jsonEncode(
              backupJson(
                zones: [
                  {'name': 'Garage', 'order': 0},
                  {'name': 'garage', 'order': 1},
                ],
              ),
            ),
          ),
        ),
      ),
    };

    for (final MapEntry(key: name, value: build) in cases.entries) {
      test(name, () async {
        // Arrange
        await addObject(
          'Kept',
          photoBytes: [
            [1, 2],
          ],
        );
        final before = photoListing();
        final zip = build(writeRawZip);

        // Act + Assert
        await expectLater(
          service.restore(zip),
          throwsA(isA<BackupFormatException>()),
        );
        expect(await objectNames(), ['Kept']);
        expect((await db.select(db.photos).get()), hasLength(1));
        expect(photoListing(), before);
      });
    }

    test('a header that under-declares its size is still capped', () async {
      // Arrange: valid JSON padded far past the cap. It deflates to almost
      // nothing, and the zip's headers are rewritten to claim 10 bytes — the
      // shape of a decompression bomb.
      final padded = '${jsonEncode(backupJson())}${' ' * 64000}';
      final zip = writeRawZip(
        Archive()..add(ArchiveFile.string('spec-backup.json', padded)),
      );
      zip.writeAsBytesSync(_declareUncompressedSize(zip.readAsBytesSync(), 10));
      // The lie took: without this, the header check alone would pass the
      // test and the bounded inflate would go unexercised.
      final declared = ZipDecoder().decodeBytes(zip.readAsBytesSync());
      expect(declared.single.size, 10);
      final small = BackupService(db, photos, maxJsonBytes: 1024);
      await addObject('Kept');

      // Act + Assert
      await expectLater(
        small.restore(zip),
        throwsA(
          isA<BackupFormatException>().having(
            (error) => error.reason,
            'reason',
            'This backup holds a file too large.',
          ),
        ),
      );
      expect(await objectNames(), ['Kept']);
    });

    test('JSON over the size cap', () async {
      // Arrange
      final small = BackupService(db, photos, maxJsonBytes: 16);
      final zip = writeRawZip(
        Archive()..add(
          ArchiveFile.string('spec-backup.json', jsonEncode(backupJson())),
        ),
      );
      await addObject('Kept');

      // Act + Assert
      await expectLater(
        small.restore(zip),
        throwsA(isA<BackupFormatException>()),
      );
      expect(await objectNames(), ['Kept']);
    });
  });

  test('deleteEverything empties every table and the photo folder', () async {
    // Arrange
    final zoneId = await addZone('Home', 0);
    await addObject(
      'Bulb',
      zoneId: zoneId,
      photoBytes: [
        [1],
      ],
    );
    File(p.join(photoDir.path, 'orphan.jpg')).writeAsBytesSync([0]);

    // Act
    await service.deleteEverything();

    // Assert
    expect(await db.select(db.zones).get(), isEmpty);
    expect(await db.select(db.objects).get(), isEmpty);
    expect(await db.select(db.photos).get(), isEmpty);
    expect(photoListing(), isEmpty);
  });
}

/// Rewrites every declared uncompressed size in a zip to [size], in both the
/// local file headers and the central directory, the way a hostile archive
/// would under-declare an entry.
List<int> _declareUncompressedSize(List<int> zip, int size) {
  const localHeader = 0x04034b50;
  const centralHeader = 0x02014b50;
  const localSizeOffset = 22;
  const centralSizeOffset = 24;
  final bytes = Uint8List.fromList(zip);
  final data = ByteData.sublistView(bytes);
  for (var i = 0; i + 4 <= bytes.length; i++) {
    final signature = data.getUint32(i, Endian.little);
    final offset = switch (signature) {
      localHeader => localSizeOffset,
      centralHeader => centralSizeOffset,
      _ => null,
    };
    if (offset == null || i + offset + 4 > bytes.length) continue;
    data.setUint32(i + offset, size, Endian.little);
  }
  return bytes;
}
