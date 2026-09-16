import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/add/add_draft.dart';
import 'package:spec/add/add_icons.dart';
import 'package:spec/add/add_kinds.dart';
import 'package:spec/data/models/spec_models.dart';
import 'package:spec/library/library_models.dart';

List<String> _labels(AddType type) => [
  for (final kind in kindsFor(type)) kindLabel(kind),
];

void main() {
  group('kinds', () {
    test('each type offers its own chip set, OTHER always last', () {
      expect(_labels(AddType.device), [
        'MODEL',
        'SERIAL',
        'FILTER',
        'BATTERY',
        'OTHER',
      ]);
      expect(_labels(AddType.car), ['TYRE', 'OIL', 'BULB', 'WIPER', 'OTHER']);
      expect(_labels(AddType.home), [
        'BULB',
        'PAINT',
        'FILTER',
        'BOLT',
        'OTHER',
      ]);
      expect(_labels(AddType.clothing), ['SIZE', 'WAIST', 'SHOE', 'OTHER']);
      expect(_labels(AddType.product), ['MODEL', 'SKU', 'OTHER']);
      for (final type in AddType.values) {
        expect(kindsFor(type).last, SpecKind.other, reason: type.name);
      }
    });

    test('the default is the type’s most-used kind, not the first', () {
      expect(defaultKindFor(AddType.device), SpecKind.filter);
      expect(defaultKindFor(AddType.car), SpecKind.tyre);
      for (final type in AddType.values) {
        expect(kindsFor(type), contains(defaultKindFor(type)));
      }
    });

    test('codes get an alphanumeric keyboard, sizes a number pad', () {
      expect(keyboardFor(SpecKind.serial), TextInputType.visiblePassword);
      expect(keyboardFor(SpecKind.sku), TextInputType.visiblePassword);
      expect(keyboardFor(SpecKind.battery), TextInputType.text);
      expect(
        keyboardFor(SpecKind.waist),
        const TextInputType.numberWithOptions(),
      );
    });

    test('only model, serial and filter are forced to capitals', () {
      expect(capitalizationFor(SpecKind.filter), TextCapitalization.characters);
      expect(capitalizationFor(SpecKind.bulb), TextCapitalization.none);
    });

    test('reminders default from the kind', () {
      expect(defaultReminderFor(SpecKind.filter), 6);
      expect(defaultReminderFor(SpecKind.battery), 12);
      expect(defaultReminderFor(SpecKind.tyre), 24);
      expect(defaultReminderFor(SpecKind.model), isNull);
    });

    test('the reminder cycle wraps from the last interval to NEVER', () {
      expect(reminderLabel(null), 'NEVER');
      expect(reminderLabel(6), 'EVERY 6 MONTHS');
      expect(nextReminder(6), 12);
      expect(nextReminder(24), isNull);
      expect(nextReminder(null), 3);
    });

    test('zones merge stored names first, starters after, no duplicates', () {
      expect(zoneChoices(const []), starterZones);
      final merged = zoneChoices(const ['Loft', 'kitchen']);
      expect(merged.take(2), ['Loft', 'kitchen']);
      expect(merged.where((z) => z.toLowerCase() == 'kitchen'), hasLength(1));
    });
  });

  group('library picks', () {
    LibraryItem item(String name, String category, String specLabel) =>
        LibraryItem(
          id: name,
          name: name,
          category: category,
          specLabel: specLabel,
          exampleSpec: '—',
        );

    test('each library category files under its add type', () {
      expect(addTypeForCategory('HOME'), AddType.home);
      expect(addTypeForCategory('CAR'), AddType.car);
      expect(addTypeForCategory('DEVICES'), AddType.device);
      expect(addTypeForCategory('CLOTHING'), AddType.clothing);
      expect(addTypeForCategory('OTHER'), AddType.other);
      expect(addTypeForCategory('GARDEN'), AddType.other);
    });

    test('the label lights its chip, then a word of the name, then OTHER', () {
      SpecKind kindOf(String name, String category, String label) =>
          kindForLibraryItem(
            item(name, category, label),
            addTypeForCategory(category),
          );

      expect(kindOf('Headlight', 'CAR', 'BULB'), SpecKind.bulb);
      expect(kindOf('Trainers', 'CLOTHING', 'SHOE'), SpecKind.shoe);
      expect(kindOf('Water filter', 'HOME', 'SIZE'), SpecKind.filter);
      expect(kindOf('Tyre', 'CAR', 'SIZE'), SpecKind.tyre);
      expect(kindOf('Duvet', 'HOME', 'TOG'), SpecKind.other);
      // A kind that exists, but not among this type's chips, is not lit.
      expect(kindOf('Tyre', 'HOME', 'SIZE'), SpecKind.other);
    });

    test('every bundled item lands on a chip its type offers', () {
      final library = parseLibrary(
        File('assets/library.json').readAsStringSync(),
      );

      for (final entry in library) {
        final type = addTypeForCategory(entry.category);
        expect(
          kindsFor(type),
          contains(kindForLibraryItem(entry, type)),
          reason: entry.name,
        );
      }
    });
  });

  group('draft', () {
    SpecDraft draft({
      SpecKind kind = SpecKind.filter,
      String value = 'LT1000P',
      String? fieldName,
      int? remind = 6,
    }) => SpecDraft(
      type: AddType.device,
      kind: kind,
      value: value,
      fieldName: fieldName,
      zone: 'Kitchen',
      photo: File('p.jpg'),
      remindEveryMonths: remind,
    );

    test('names the object by type and kind', () {
      final row = objectDraftFrom(draft(), at: DateTime(2026, 9, 14));

      expect(row.name.value, 'Device filter');
      expect(row.type.value, 'device');
      expect(row.specKind.value, 'filter');
      expect(row.specValue.value, 'LT1000P');
      expect(row.remindEveryMonths.value, 6);
      expect(row.createdAt.value, DateTime(2026, 9, 14));
    });

    test('OTHER takes the name the user gave the field', () {
      final named = objectDraftFrom(
        draft(kind: SpecKind.other, fieldName: '  Hinge  '),
      );
      final unnamed = objectDraftFrom(draft(kind: SpecKind.other));

      expect(named.name.value, 'Hinge');
      expect(unnamed.name.value, 'Device');
    });

    test('trims the value and marks a hex paint code', () {
      expect(objectDraftFrom(draft(value: '  B22 ')).specValue.value, 'B22');
      expect(
        objectDraftFrom(draft(kind: SpecKind.paint, value: 'a1b2c3'))
            .specValue
            .value,
        '#A1B2C3',
      );
      expect(
        objectDraftFrom(draft(kind: SpecKind.paint, value: 'Dulux 123'))
            .specValue
            .value,
        'Dulux 123',
      );
    });

    test('NEVER stores no interval', () {
      expect(
        objectDraftFrom(draft(remind: null)).remindEveryMonths.value,
        null,
      );
    });
  });

  group('default zone', () {
    test('a library item lands in the zone named for its category', () {
      const stored = ['Home', 'car', 'Devices'];

      expect(defaultZoneFor(category: 'CAR', stored: stored), 'car');
      expect(defaultZoneFor(category: 'DEVICES', stored: stored), 'Devices');
      expect(defaultZoneFor(category: 'HOME', stored: stored), 'Home');
    });

    test('no such zone keeps the usual first-zone default', () {
      expect(defaultZoneFor(category: 'CLOTHING', stored: ['Home']), isNull);
    });

    test('the zone the caller was scoped to still wins', () {
      expect(
        defaultZoneFor(scope: 'Garage', category: 'CAR', stored: ['Car']),
        'Garage',
      );
    });
  });
}
