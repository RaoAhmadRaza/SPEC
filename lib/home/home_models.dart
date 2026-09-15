import 'package:flutter/widgets.dart';

/// Which stroked glyph a category chip carries.
enum HomeCategoryIcon { house, car, monitor }

/// A zone chip on the rail: a name, a live count and an icon.
@immutable
class HomeCategory {
  const HomeCategory({
    required this.label,
    required this.count,
    required this.icon,
  });

  final String label;
  final int count;
  final HomeCategoryIcon icon;
}

/// One object as Home draws it.
///
/// A presentation model rather than the database row, so the screen stays
/// buildable in a test with no database and no photo files.
@immutable
class HomeObject {
  const HomeObject({
    required this.id,
    required this.zone,
    required this.spec,
    required this.name,
    this.subLines = const [],
    this.photo,
    this.isDue = false,
  });

  final int id;

  /// `HOME · CEILING`, already uppercased by the caller.
  final String zone;

  /// The hero string. A space in it means two lines, the way `205/55 R16`
  /// wraps in the design.
  final String spec;

  final String name;
  final List<String> subLines;
  final ImageProvider? photo;

  /// The reminder has fallen due: the card carries a DUE chip.
  final bool isDue;

  /// Two-line specs drop from 32pt to 27pt so they still fit the tile.
  bool get isSpecTall => spec.trim().contains(' ');

  /// Breaks before the last word, which is where `205/55 R16` splits.
  String get specText => isSpecTall
      ? spec.trim().replaceFirst(RegExp(r'\s+(?=\S+$)'), '\n')
      : spec.trim();
}
