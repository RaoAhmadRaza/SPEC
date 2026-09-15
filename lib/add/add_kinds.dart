import 'package:flutter/services.dart';

import 'package:spec/add/add_icons.dart';
import 'package:spec/data/models/spec_models.dart';
import 'package:spec/library/library_models.dart';

/// The type tiles' labels, shared by step 04's grid and step 05's context row.
const addTypeLabels = <AddType, String>{
  AddType.product: 'Product',
  AddType.device: 'Device',
  AddType.car: 'Car',
  AddType.home: 'Home',
  AddType.clothing: 'Clothing',
  AddType.other: 'Other',
};

/// Step 05's chip row, contextual to the type. OTHER is always last.
///
/// The first entry of each record is the default: the type's most-used kind,
/// which is not always the first chip.
const _kinds = <AddType, (SpecKind, List<SpecKind>)>{
  AddType.device: (
    SpecKind.filter,
    [
      SpecKind.model,
      SpecKind.serial,
      SpecKind.filter,
      SpecKind.battery,
      SpecKind.other,
    ],
  ),
  AddType.car: (
    SpecKind.tyre,
    [
      SpecKind.tyre,
      SpecKind.oil,
      SpecKind.bulb,
      SpecKind.wiper,
      SpecKind.other,
    ],
  ),
  AddType.home: (
    SpecKind.bulb,
    [
      SpecKind.bulb,
      SpecKind.paint,
      SpecKind.filter,
      SpecKind.bolt,
      SpecKind.other,
    ],
  ),
  AddType.clothing: (
    SpecKind.size,
    [SpecKind.size, SpecKind.waist, SpecKind.shoe, SpecKind.other],
  ),
  AddType.product: (
    SpecKind.model,
    [SpecKind.model, SpecKind.sku, SpecKind.other],
  ),
  // ponytail: the brief gives no set for Other; the generic codes cover it.
  AddType.other: (
    SpecKind.model,
    [SpecKind.model, SpecKind.serial, SpecKind.other],
  ),
};

List<SpecKind> kindsFor(AddType type) => _kinds[type]!.$2;

SpecKind defaultKindFor(AddType type) => _kinds[type]!.$1;

String kindLabel(SpecKind kind) => kind.name.toUpperCase();

/// The add type a library category files under. The library says `DEVICES`
/// where the type tiles say Device; anything unrecognised is Other.
AddType addTypeForCategory(String category) => switch (category) {
  'HOME' => AddType.home,
  'CAR' => AddType.car,
  'DEVICES' => AddType.device,
  'CLOTHING' => AddType.clothing,
  _ => AddType.other,
};

final _wordBreak = RegExp('[^a-z]+');

/// Which of [type]'s chips a library pick lights.
///
/// Chosen only from [kindsFor], so step 05 never opens with no chip lit: the
/// label itself (`BULB`, `SHOE`), then a word of the name (`Water filter`),
/// then OTHER, which every type offers.
SpecKind kindForLibraryItem(LibraryItem item, AddType type) {
  final words = [
    item.specLabel.toLowerCase(),
    ...item.name.toLowerCase().split(_wordBreak),
  ];
  for (final word in words) {
    final kind = kindsFor(type).where((k) => k.name == word).firstOrNull;
    if (kind != null) return kind;
  }
  return SpecKind.other;
}

/// Spec strings are codes, not words. A tyre size carries a slash and a
/// letter, a clothing size can be `XL` and a shoe `9.5`, so those depart from
/// a bare number pad.
TextInputType keyboardFor(SpecKind kind) => switch (kind) {
  SpecKind.model ||
  SpecKind.serial ||
  SpecKind.filter ||
  SpecKind.sku ||
  SpecKind.tyre => TextInputType.visiblePassword,
  SpecKind.waist => const TextInputType.numberWithOptions(),
  SpecKind.shoe => const TextInputType.numberWithOptions(decimal: true),
  _ => TextInputType.text,
};

TextCapitalization capitalizationFor(SpecKind kind) => switch (kind) {
  SpecKind.model ||
  SpecKind.serial ||
  SpecKind.filter => TextCapitalization.characters,
  _ => TextCapitalization.none,
};

/// The REMIND ME cycle, in tap order. Null is NEVER.
const reminderCycle = <int?>[null, 3, 6, 12, 24];

int? defaultReminderFor(SpecKind kind) => switch (kind) {
  SpecKind.filter => 6,
  SpecKind.battery => 12,
  SpecKind.tyre => 24,
  _ => null,
};

int? nextReminder(int? months) {
  final index = reminderCycle.indexOf(months);
  return reminderCycle[(index + 1) % reminderCycle.length];
}

String reminderLabel(int? months) => switch (months) {
  null => 'NEVER',
  12 => 'EVERY YEAR',
  24 => 'EVERY 2 YEARS',
  _ => 'EVERY $months MONTHS',
};

/// Offered in the location picker when the user has not made enough zones of
/// their own to choose from.
const starterZones = [
  'Kitchen',
  'Bedroom',
  'Bathroom',
  'Living room',
  'Garage',
];

/// The zone step 05 opens on for a library pick: the caller's [scope] when
/// it has one, else the stored zone named for the item's [category] — a Tyre
/// belongs in `Car`, not in whichever zone happens to be first. Null leaves
/// the first zone.
String? defaultZoneFor({
  String? scope,
  required String category,
  required List<String> stored,
}) {
  if (scope != null) return scope;
  final wanted = category.toLowerCase();
  return stored.where((zone) => zone.toLowerCase() == wanted).firstOrNull;
}

/// The user's zones first, then any starter they have not already made.
List<String> zoneChoices(List<String> stored) {
  final taken = {for (final zone in stored) zone.toLowerCase()};
  return [
    ...stored,
    for (final zone in starterZones)
      if (!taken.contains(zone.toLowerCase())) zone,
  ];
}
