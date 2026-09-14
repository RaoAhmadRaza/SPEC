import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart';

import 'package:spec/data/models/spec_models.dart';
import 'package:spec/data/zone_repository.dart';

/// The `format` key. Kept from the loose-file export it replaces, so a
/// backup made before zips still reads as SPEC's own.
const kBackupFormat = 'spec-export';

/// Bumped whenever the JSON shape changes. Version 2 added `notes`.
const kBackupVersion = 2;

/// The data file's name inside the zip.
const kBackupJsonName = 'spec-backup.json';

/// The folder photos sit in inside the zip.
const kBackupPhotosFolder = 'photos';

// Caps well past any real archive. A backup is a file from outside the app,
// and these are what stop a hostile one from turning into a hang or an
// out-of-memory crash halfway through a restore.
const kMaxBackupZones = 1000;
const kMaxBackupObjects = 10000;
const kMaxBackupAttributes = 50;
const kMaxBackupPhotosPerObject = 20;

/// What SPEC itself writes. Anything else is not a photo it could show.
const kBackupPhotoExtensions = {'.jpg', '.jpeg', '.png', '.heic', '.webp'};

/// A backup SPEC cannot read: not a zip, not a SPEC backup, from a newer
/// version, or damaged. [reason] is written for the person reading it.
class BackupFormatException implements Exception {
  const BackupFormatException(this.reason);

  final String reason;

  @override
  String toString() => 'BackupFormatException: $reason';
}

/// One zone as a backup carries it. Zones travel by name: ids are local to a
/// database and mean nothing in another one.
@immutable
class BackupZone {
  const BackupZone({required this.name, required this.order});

  final String name;
  final int order;
}

/// One object as a backup carries it: every column except ids, with its
/// zone as a name and its photos as file names in display order.
@immutable
class BackupObject {
  const BackupObject({
    required this.name,
    required this.type,
    required this.zone,
    required this.subLocation,
    required this.specKind,
    required this.specValue,
    required this.subtitle,
    required this.libraryTerm,
    required this.attributes,
    required this.purchasedFrom,
    required this.replacedOn,
    required this.remindEveryMonths,
    required this.createdAt,
    required this.updatedAt,
    required this.notes,
    required this.photos,
  });

  final String name;
  final ObjectType type;
  final String? zone;
  final String? subLocation;
  final SpecKind specKind;
  final String specValue;
  final String? subtitle;
  final String? libraryTerm;
  final List<SpecAttribute> attributes;
  final String? purchasedFrom;
  final String? replacedOn;
  final int? remindEveryMonths;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;
  final List<String> photos;

  /// The same object holding only [photos]. A restore drops references to
  /// photos the zip does not actually contain.
  BackupObject withPhotos(List<String> photos) => BackupObject(
    name: name,
    type: type,
    zone: zone,
    subLocation: subLocation,
    specKind: specKind,
    specValue: specValue,
    subtitle: subtitle,
    libraryTerm: libraryTerm,
    attributes: attributes,
    purchasedFrom: purchasedFrom,
    replacedOn: replacedOn,
    remindEveryMonths: remindEveryMonths,
    createdAt: createdAt,
    updatedAt: updatedAt,
    notes: notes,
    photos: photos,
  );
}

/// A backup that passed validation.
@immutable
class DecodedBackup {
  const DecodedBackup({required this.zones, required this.objects});

  /// In list order, followed by any zone an object names that the zone list
  /// lacked, so every object's zone is guaranteed to be here.
  final List<BackupZone> zones;
  final List<BackupObject> objects;

  int get photoCount =>
      objects.fold(0, (sum, object) => sum + object.photos.length);
}

/// The JSON a backup zip carries.
Map<String, Object?> encodeBackup({
  required List<BackupZone> zones,
  required List<BackupObject> objects,
  required DateTime exportedAt,
}) => {
  'format': kBackupFormat,
  'version': kBackupVersion,
  'exportedAt': exportedAt.toIso8601String(),
  'zones': [
    for (final zone in zones) {'name': zone.name, 'order': zone.order},
  ],
  'objects': [
    for (final o in objects)
      {
        'name': o.name,
        'type': o.type.name,
        'zone': o.zone,
        'subLocation': o.subLocation,
        'specKind': o.specKind.name,
        'specValue': o.specValue,
        'subtitle': o.subtitle,
        'libraryTerm': o.libraryTerm,
        'attributes': [for (final a in o.attributes) a.toJson()],
        'purchasedFrom': o.purchasedFrom,
        'replacedOn': o.replacedOn,
        'remindEveryMonths': o.remindEveryMonths,
        'createdAt': o.createdAt.toIso8601String(),
        'updatedAt': o.updatedAt.toIso8601String(),
        'notes': o.notes,
        'photos': o.photos,
      },
  ],
};

/// Validates decoded JSON from a backup file and returns it typed.
///
/// The file came from outside the app, so every field is checked before any
/// of it is trusted. Throws [BackupFormatException] on the first problem;
/// nothing is partially accepted.
DecodedBackup decodeBackup(Object? json) {
  if (json is! Map<String, Object?> || json['format'] != kBackupFormat) {
    throw const BackupFormatException('This file is not a SPEC backup.');
  }
  final version = json['version'];
  if (version is! int || version < 1) {
    throw const BackupFormatException('This file is not a SPEC backup.');
  }
  if (version > kBackupVersion) {
    throw const BackupFormatException(
      'This backup is from a newer version of SPEC.',
    );
  }

  final zones = _decodeZones(_list(json['zones'], 'zones', kMaxBackupZones));
  final objects = [
    for (final raw in _list(json['objects'], 'objects', kMaxBackupObjects))
      _decodeObject(raw),
  ];
  return DecodedBackup(
    zones: _withObjectZones(zones, objects),
    objects: objects,
  );
}

/// True for a bare file name SPEC could have written: no folders, no way
/// out of the photos directory, and an image extension.
bool isBackupPhotoName(String name) {
  if (name.isEmpty || name.startsWith('.')) return false;
  if (name.contains('/') || name.contains(r'\') || name.contains('\x00')) {
    return false;
  }
  final dot = name.lastIndexOf('.');
  if (dot <= 0) return false;
  return kBackupPhotoExtensions.contains(name.substring(dot).toLowerCase());
}

List<BackupZone> _decodeZones(List<Object?> raw) {
  final seen = <String>{};
  final zones = <BackupZone>[];
  for (final entry in raw) {
    if (entry is! Map<String, Object?>) _damaged('a zone is not readable');
    final name = _zoneName(entry['name']);
    if (name == null) _damaged('a zone has no valid name');
    final order = entry['order'];
    if (order is! int) _damaged('zone "$name" has no order');
    // The column is COLLATE NOCASE, so these would collide on insert.
    if (!seen.add(name.toLowerCase())) {
      _damaged('the zone "$name" appears twice');
    }
    zones.add(BackupZone(name: name, order: order));
  }
  // Order is authoritative, list position breaks ties: List.sort is not
  // stable, so the index rides along.
  final indexed = zones.indexed.toList()
    ..sort(
      (a, b) => a.$2.order != b.$2.order
          ? a.$2.order.compareTo(b.$2.order)
          : a.$1.compareTo(b.$1),
    );
  return [for (final (_, zone) in indexed) zone];
}

/// An object may name a zone the list lacks (a hand-edited file, or a zone
/// deleted mid-export). It is appended rather than refused.
List<BackupZone> _withObjectZones(
  List<BackupZone> zones,
  List<BackupObject> objects,
) {
  final known = {for (final zone in zones) zone.name.toLowerCase()};
  final extra = <BackupZone>[];
  for (final object in objects) {
    final zone = object.zone;
    if (zone == null || !known.add(zone.toLowerCase())) continue;
    extra.add(BackupZone(name: zone, order: zones.length + extra.length));
  }
  return [...zones, ...extra];
}

BackupObject _decodeObject(Object? raw) {
  if (raw is! Map<String, Object?>) _damaged('an object is not readable');
  final name = raw['name'];
  if (name is! String) _damaged('an object has no name');
  final zone = raw['zone'];
  final zoneName = zone == null ? null : _zoneName(zone);
  if (zone != null && zoneName == null) {
    _damaged('"$name" names an invalid zone');
  }
  final replacedOn = _optionalString(raw, 'replacedOn', name);
  if (replacedOn != null && DateTime.tryParse(replacedOn) == null) {
    _damaged('"$name" has an invalid replacement date');
  }
  final remind = raw['remindEveryMonths'];
  if (remind != null && remind is! int) {
    _damaged('"$name" has an invalid reminder');
  }
  final notes = _optionalString(raw, 'notes', name);
  if (notes != null && notes.characters.length > kNotesMaxLength) {
    _damaged('the notes on "$name" are too long');
  }
  final specValue = raw['specValue'];
  if (specValue is! String) _damaged('"$name" has no spec');

  return BackupObject(
    name: name,
    type: parseObjectType(_requiredString(raw, 'type', name)),
    zone: zoneName,
    subLocation: _optionalString(raw, 'subLocation', name),
    specKind: parseSpecKind(_requiredString(raw, 'specKind', name)),
    specValue: specValue,
    subtitle: _optionalString(raw, 'subtitle', name),
    libraryTerm: _optionalString(raw, 'libraryTerm', name),
    attributes: _decodeAttributes(raw['attributes'], name),
    purchasedFrom: _optionalString(raw, 'purchasedFrom', name),
    replacedOn: replacedOn,
    remindEveryMonths: remind as int?,
    createdAt: _date(raw, 'createdAt', name),
    updatedAt: _date(raw, 'updatedAt', name),
    notes: cleanNotes(notes),
    photos: _decodePhotos(raw['photos'], name),
  );
}

List<SpecAttribute> _decodeAttributes(Object? raw, String objectName) => [
  for (final entry in _list(raw, 'attributes', kMaxBackupAttributes))
    if (entry case {'label': final String label, 'value': final String value})
      SpecAttribute(label: label, value: value)
    else
      _damaged('an attribute on "$objectName" is not readable'),
];

List<String> _decodePhotos(Object? raw, String objectName) => [
  for (final entry in _list(raw, 'photos', kMaxBackupPhotosPerObject))
    if (entry is String && isBackupPhotoName(entry))
      entry
    else
      _damaged('a photo on "$objectName" has an invalid name'),
];

/// A trimmed zone name within the same limits the app enforces, or null.
String? _zoneName(Object? raw) {
  if (raw is! String) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty || trimmed.length > kZoneNameMaxLength) return null;
  return trimmed;
}

List<Object?> _list(Object? raw, String what, int max) {
  if (raw is! List<Object?>) _damaged('$what is not a list');
  if (raw.length > max) _damaged('it holds more $what than SPEC allows');
  return raw;
}

String _requiredString(Map<String, Object?> raw, String key, String name) {
  final value = raw[key];
  if (value is! String) _damaged('"$name" has no $key');
  return value;
}

String? _optionalString(Map<String, Object?> raw, String key, String name) {
  final value = raw[key];
  if (value == null || value is String) return value as String?;
  _damaged('"$name" has an invalid $key');
}

DateTime _date(Map<String, Object?> raw, String key, String name) {
  final value = raw[key];
  final parsed = value is String ? DateTime.tryParse(value) : null;
  if (parsed == null) _damaged('"$name" has an invalid $key');
  return parsed;
}

Never _damaged(String what) =>
    throw BackupFormatException('This backup is damaged: $what.');
