import 'package:flutter/widgets.dart';

import 'package:spec/data/models/spec_models.dart';
import 'package:spec/data/reminder_schedule.dart';

/// Where the screen was opened from. The two sources set the spec Hero's
/// starting size, which is the only thing that differs between them.
enum ObjectSource { homeTile, searchRow }

/// One object as screen 03 draws it.
///
/// A presentation model rather than the database row, so the screen stays
/// buildable in a test with no database and no photo files — the same reason
/// [HomeObject] exists.
@immutable
class ObjectView {
  const ObjectView({
    required this.id,
    required this.zone,
    required this.spec,
    this.name,
    this.subZone,
    this.subtitle,
    this.fields = const [],
    this.mainPhoto,
    this.detailPhoto,
    this.lastReplaced,
    this.purchasedFrom,
    this.notes,
    this.remindEveryMonths,
    this.createdAt,
  });

  final int id;

  /// `BEDROOM`, already uppercased by the caller. Fills the lime chip.
  final String zone;

  /// `CEILING`, the glass chip beside it. Absent for an unplaced object.
  final String? subZone;

  /// The hero string. A space in it means two lines, the way `205/55 R16`
  /// wraps in the design.
  final String spec;

  /// `Bulb`, what the user called it. Null only while a seed stands in for
  /// the row.
  final String? name;

  final String? subtitle;

  /// Rendered three to a row. More than three stacks a second row.
  final List<SpecAttribute> fields;

  final ImageProvider? mainPhoto;
  final ImageProvider? detailPhoto;

  /// A calendar date as written, `2026-08-14`. Not a timestamp.
  final String? lastReplaced;
  final String? purchasedFrom;

  /// Free text, already cleaned. Null when there is none.
  final String? notes;

  /// Carried rather than a precomputed due date, so NEXT DUE follows
  /// [lastReplaced] the moment REPLACED or SAVE changes it on screen.
  final int? remindEveryMonths;
  final DateTime? createdAt;

  DateTime? get nextDue => nextDueDate(
    remindEveryMonths: remindEveryMonths,
    replacedOn: lastReplaced,
    createdAt: createdAt,
  );

  /// Two-line specs set smaller. Breaks before the last word, which is where
  /// `205/55 R16` splits.
  bool get isSpecTall => spec.trim().contains(' ');

  String get specText => isSpecTall
      ? spec.trim().replaceFirst(RegExp(r'\s+(?=\S+$)'), '\n')
      : spec.trim();

  ObjectView copyWith({String? lastReplaced}) => ObjectView(
    id: id,
    zone: zone,
    spec: spec,
    name: name,
    subZone: subZone,
    subtitle: subtitle,
    fields: fields,
    mainPhoto: mainPhoto,
    detailPhoto: detailPhoto,
    lastReplaced: lastReplaced ?? this.lastReplaced,
    purchasedFrom: purchasedFrom,
    notes: notes,
    remindEveryMonths: remindEveryMonths,
    createdAt: createdAt,
  );
}

const _months = [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
];

/// The metadata rows' placeholder. A blank right-hand side reads as broken.
const kMissingValue = '—';

/// `14 AUG 2026`. Uppercase month, no comma.
///
/// Deliberately not `intl`: the format is fixed by the design and never
/// localised, so a package and a locale lookup would buy nothing.
String formatSpecDate(String? isoDate) {
  if (isoDate == null) return kMissingValue;
  final date = DateTime.tryParse(isoDate);
  if (date == null) return kMissingValue;
  return '${date.day.toString().padLeft(2, '0')} '
      '${_months[date.month - 1]} ${date.year}';
}

/// `2026-08-14`, the shape the `replaced_on` column stores.
String toIsoDate(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

/// Reads `14 AUG 2026` back into `2026-08-14`, or null if it is not a date.
///
/// Edited text is user input, so a typo keeps the stored date rather than
/// writing something the reminder maths cannot read.
String? parseSpecDate(String text) {
  final match = RegExp(r'^(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})$')
      .firstMatch(text.trim());
  if (match == null) return null;

  final month = _months.indexOf(match.group(2)!.toUpperCase()) + 1;
  if (month == 0) return null;

  final day = int.parse(match.group(1)!);
  final year = int.parse(match.group(3)!);
  final date = DateTime(year, month, day);
  // DateTime rolls 31 FEB over into March rather than refusing it.
  if (date.month != month || date.day != day) return null;
  return toIsoDate(date);
}

/// What SAVE writes. Only the fields screen 03 lets you edit in place.
@immutable
class ObjectEdits {
  const ObjectEdits({
    required this.spec,
    required this.fields,
    required this.purchasedFrom,
    required this.lastReplaced,
    required this.notes,
  });

  final String spec;
  final List<SpecAttribute> fields;

  /// Null when cleared.
  final String? purchasedFrom;

  /// ISO, and null when cleared.
  final String? lastReplaced;

  /// Cleaned by [cleanNotes], so null when cleared.
  final String? notes;
}
