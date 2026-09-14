import 'dart:convert';

// Notes are cut by user-perceived character, so a cap never splits an emoji.
import 'package:characters/characters.dart';

/// The six tiles on the add sheet. A closed set: never user-editable.
enum ObjectType { product, device, car, home, clothing, other }

/// What the hero string on the detail screen actually is.
///
/// Stored by name in a TEXT column, so adding a value needs no migration.
enum SpecKind {
  model,
  serial,
  filter,
  battery,
  other,
  tyre,
  oil,
  bulb,
  wiper,
  paint,
  bolt,
  size,
  waist,
  shoe,
  sku,
}

/// Enum columns are plain TEXT, so a row written by a future release can
/// carry a name this build has never heard of. Fall back rather than throw:
/// one unknown value must not make an object unreadable.
ObjectType parseObjectType(String raw) =>
    ObjectType.values.asNameMap()[raw] ?? ObjectType.other;

SpecKind parseSpecKind(String raw) =>
    SpecKind.values.asNameMap()[raw] ?? SpecKind.other;

/// One row of the three-column attribute block on the detail screen.
class SpecAttribute {
  const SpecAttribute({required this.label, required this.value});

  final String label;
  final String value;

  Map<String, String> toJson() => {'label': label, 'value': value};
}

/// Decodes the `attributes` column.
///
/// Malformed JSON means an empty block, never a crashed screen: the column is
/// free-form text that a future release or a restored export could have
/// written in a shape this build does not know.
List<SpecAttribute> decodeAttributes(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return [
      for (final entry in decoded)
        if (entry is Map &&
            entry['label'] is String &&
            entry['value'] is String)
          SpecAttribute(
            label: entry['label'] as String,
            value: entry['value'] as String,
          ),
    ];
  } on FormatException {
    return const [];
  }
}

String encodeAttributes(List<SpecAttribute> attributes) =>
    jsonEncode([for (final a in attributes) a.toJson()]);

/// Notes are a line, not a document: long enough for "the one with the blue
/// cap", short enough never to turn the detail screen into a form.
const kNotesMaxLength = 280;

/// The form notes are stored in: trimmed, capped, and null when there is
/// nothing left, so "no notes" has exactly one representation.
String? cleanNotes(String? raw) {
  final trimmed = raw?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  final characters = trimmed.characters;
  return characters.length <= kNotesMaxLength
      ? trimmed
      : characters.take(kNotesMaxLength).toString().trimRight();
}

/// What a card on Home and a row on Search need, and nothing more.
class ObjectSummary {
  const ObjectSummary({
    required this.id,
    required this.name,
    required this.type,
    required this.specKind,
    required this.specValue,
    required this.zoneName,
    required this.subLocation,
    required this.libraryTerm,
    required this.attributes,
    required this.photoFileName,
    required this.updatedAt,
    this.notes,
  });

  final int id;
  final String name;
  final ObjectType type;
  final SpecKind specKind;
  final String specValue;
  final String? zoneName;
  final String? subLocation;
  final String? libraryTerm;

  /// Read as one ordered set and rendered into three columns, which is why
  /// they live in a JSON column rather than a table.
  final List<SpecAttribute> attributes;

  /// First photo, by sort order. A file name, resolved against the photos
  /// directory at render time.
  final String? photoFileName;
  final DateTime updatedAt;

  /// On the summary rather than only the detail, because search scores
  /// summaries and the spec asks for search across notes.
  final String? notes;

  /// `HOME · CEILING`, the taxonomy line under the name.
  String get taxonomy => [
    if (zoneName != null) zoneName!.toUpperCase(),
    if (subLocation != null) subLocation!.toUpperCase(),
  ].join(' · ');
}

/// Everything screen 03 renders.
class ObjectDetail {
  const ObjectDetail({
    required this.summary,
    required this.subtitle,
    required this.purchasedFrom,
    required this.replacedOn,
    required this.remindEveryMonths,
    required this.photoFileNames,
    required this.createdAt,
  });

  final ObjectSummary summary;
  final String? subtitle;
  final String? purchasedFrom;

  /// A calendar date as written, `2026-08-14`. Not a timestamp: nobody
  /// replaces a filter at 14:32:07 UTC.
  final String? replacedOn;
  final int? remindEveryMonths;
  final List<String> photoFileNames;
  final DateTime createdAt;

  String? get notes => summary.notes;

  /// Due date is derived, which is why there is no reminders table.
  DateTime? get remindOn {
    final every = remindEveryMonths;
    final from = replacedOn;
    if (every == null || from == null) return null;
    final start = DateTime.tryParse(from);
    if (start == null) return null;
    return DateTime(start.year, start.month + every, start.day);
  }
}
