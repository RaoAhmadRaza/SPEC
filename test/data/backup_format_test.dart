import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:spec/data/backup_format.dart';
import 'package:spec/data/models/spec_models.dart';

/// A valid version 2 object; tests override one field at a time.
Map<String, Object?> _object([Map<String, Object?> overrides = const {}]) => {
  'name': 'Bedroom bulb',
  'type': 'home',
  'zone': 'Home',
  'subLocation': 'Ceiling',
  'specKind': 'model',
  'specValue': 'B22',
  'subtitle': null,
  'libraryTerm': 'bulb',
  'attributes': [
    {'label': 'POWER', 'value': '9W'},
  ],
  'purchasedFrom': 'IKEA',
  'replacedOn': '2026-08-14',
  'remindEveryMonths': 6,
  'createdAt': '2026-09-01T00:00:00.000',
  'updatedAt': '2026-09-02T00:00:00.000',
  'notes': 'the one with the blue cap',
  'photos': ['1.jpg'],
  ...overrides,
};

Map<String, Object?> _backup({
  Object? version = 2,
  Object? zones,
  List<Object?>? objects,
}) => {
  'format': 'spec-export',
  'version': version,
  'exportedAt': '2026-09-14T00:00:00.000',
  'zones':
      zones ??
      [
        {'name': 'Home', 'order': 0},
      ],
  'objects': objects ?? [_object()],
};

Matcher _rejects() => throwsA(isA<BackupFormatException>());

void main() {
  group('decodeBackup', () {
    test('accepts a valid version 2 backup', () {
      // Act
      final backup = decodeBackup(_backup());

      // Assert
      final object = backup.objects.single;
      expect(backup.zones.single.name, 'Home');
      expect(object.type, ObjectType.home);
      expect(object.notes, 'the one with the blue cap');
      expect(object.attributes.single.value, '9W');
      expect(object.createdAt, DateTime(2026, 9, 1));
      expect(backup.photoCount, 1);
    });

    test('reads a version 1 backup, which has no notes, as notes null', () {
      // Arrange
      final json = _backup(version: 1, objects: [_object()..remove('notes')]);

      // Act
      final backup = decodeBackup(json);

      // Assert
      expect(backup.objects.single.notes, isNull);
    });

    test('rejects anything that is not a SPEC backup', () {
      expect(() => decodeBackup([]), _rejects());
      expect(() => decodeBackup({..._backup(), 'format': 'other'}), _rejects());
      expect(() => decodeBackup(_backup(version: '2')), _rejects());
    });

    test('explains that a newer version cannot be read', () {
      expect(
        () => decodeBackup(_backup(version: 3)),
        throwsA(
          isA<BackupFormatException>().having(
            (e) => e.reason,
            'reason',
            'This backup is from a newer version of SPEC.',
          ),
        ),
      );
    });

    test('rejects duplicate zone names regardless of case', () {
      final zones = [
        {'name': 'Home', 'order': 0},
        {'name': 'HOME', 'order': 1},
      ];

      expect(() => decodeBackup(_backup(zones: zones)), _rejects());
    });

    test('rejects blank and overlong zone names', () {
      for (final name in ['  ', 'x' * 41]) {
        final zones = [
          {'name': name, 'order': 0},
        ];
        expect(() => decodeBackup(_backup(zones: zones)), _rejects());
      }
    });

    test('rejects dates that do not parse', () {
      for (final bad in [
        {'createdAt': 'yesterday'},
        {'updatedAt': null},
        {'replacedOn': 'soon'},
      ]) {
        expect(
          () => decodeBackup(_backup(objects: [_object(bad)])),
          _rejects(),
        );
      }
    });

    test('rejects notes longer than the app allows', () {
      final json = _backup(
        objects: [
          _object({'notes': 'x' * (kNotesMaxLength + 1)}),
        ],
      );

      expect(() => decodeBackup(json), _rejects());
    });

    test('rejects photo names that are paths or not images', () {
      for (final name in [
        '../evil.jpg',
        'a/b.jpg',
        r'a\b.jpg',
        'x.exe',
        '..',
      ]) {
        final json = _backup(
          objects: [
            _object({
              'photos': [name],
            }),
          ],
        );
        expect(() => decodeBackup(json), _rejects(), reason: name);
      }
    });

    test('rejects fields of the wrong type', () {
      for (final bad in [
        {'name': 3},
        {'specValue': null},
        {'remindEveryMonths': '6'},
        {'attributes': 'POWER'},
        {
          'attributes': [
            {'label': 'POWER'},
          ],
        },
        {'subtitle': 7},
      ]) {
        expect(
          () => decodeBackup(_backup(objects: [_object(bad)])),
          _rejects(),
          reason: '$bad',
        );
      }
    });

    test('rejects more photos per object than the cap', () {
      final json = _backup(
        objects: [
          _object({
            'photos': [
              for (var i = 0; i <= kMaxBackupPhotosPerObject; i++) '$i.jpg',
            ],
          }),
        ],
      );

      expect(() => decodeBackup(json), _rejects());
    });

    test('falls back for a type or kind this build does not know', () {
      // Arrange
      final json = _backup(
        objects: [
          _object({'type': 'boat', 'specKind': 'hull'}),
        ],
      );

      // Act
      final object = decodeBackup(json).objects.single;

      // Assert
      expect(object.type, ObjectType.other);
      expect(object.specKind, SpecKind.other);
    });

    test('appends a zone an object names but the zone list lacks', () {
      // Arrange
      final json = _backup(
        objects: [
          _object({'zone': 'Garage'}),
          _object({'zone': 'home'}),
        ],
      );

      // Act
      final backup = decodeBackup(json);

      // Assert
      expect(backup.zones.map((z) => z.name), ['Home', 'Garage']);
    });

    test('orders zones by their order field', () {
      final zones = [
        {'name': 'Car', 'order': 1},
        {'name': 'Home', 'order': 0},
      ];

      final backup = decodeBackup(_backup(zones: zones, objects: []));

      expect(backup.zones.map((z) => z.name), ['Home', 'Car']);
    });
  });

  test('encode then decode round-trips every field', () {
    // Arrange
    final original = BackupObject(
      name: 'Headlight',
      type: ObjectType.car,
      zone: 'Car',
      subLocation: 'Front left',
      specKind: SpecKind.bulb,
      specValue: 'H7',
      subtitle: 'Low beam',
      libraryTerm: 'bulb',
      attributes: const [SpecAttribute(label: 'WATTS', value: '55')],
      purchasedFrom: 'Halfords',
      replacedOn: '2026-01-02',
      remindEveryMonths: 12,
      createdAt: DateTime(2026, 1, 2, 3, 4, 5),
      updatedAt: DateTime(2026, 2, 3, 4, 5, 6),
      notes: 'passenger side is harder',
      photos: const ['a.jpg', 'b.heic'],
    );

    // Act — through a string, as it travels in the zip.
    final json = jsonDecode(
      jsonEncode(
        encodeBackup(
          zones: const [BackupZone(name: 'Car', order: 0)],
          objects: [original],
          exportedAt: DateTime(2026, 9, 14),
        ),
      ),
    );
    final decoded = decodeBackup(json).objects.single;

    // Assert
    expect(decoded.name, original.name);
    expect(decoded.type, original.type);
    expect(decoded.zone, original.zone);
    expect(decoded.subLocation, original.subLocation);
    expect(decoded.specKind, original.specKind);
    expect(decoded.specValue, original.specValue);
    expect(decoded.subtitle, original.subtitle);
    expect(decoded.libraryTerm, original.libraryTerm);
    expect(decoded.attributes.single.toJson(), {
      'label': 'WATTS',
      'value': '55',
    });
    expect(decoded.purchasedFrom, original.purchasedFrom);
    expect(decoded.replacedOn, original.replacedOn);
    expect(decoded.remindEveryMonths, original.remindEveryMonths);
    expect(decoded.createdAt, original.createdAt);
    expect(decoded.updatedAt, original.updatedAt);
    expect(decoded.notes, original.notes);
    expect(decoded.photos, original.photos);
  });
}
