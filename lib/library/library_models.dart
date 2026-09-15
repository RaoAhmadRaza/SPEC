import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:spec/data/search_scorer.dart';

/// The filter row, in order. `ALL` is first and always present.
const kLibraryAll = 'ALL';
const kLibraryCategories = [
  kLibraryAll,
  'HOME',
  'CAR',
  'DEVICES',
  'CLOTHING',
  'OTHER',
];

/// One bundled library object: a *shape* the user picks, never a value.
@immutable
class LibraryItem {
  const LibraryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.specLabel,
    required this.exampleSpec,
    this.asset,
  });

  final String id;
  final String name;

  /// One of [kLibraryCategories], never [kLibraryAll].
  final String category;

  /// What step 05 pre-selects as the field kind, e.g. `BASE`.
  final String specLabel;

  /// Illustrative only. Drawn under the name and never written into the
  /// user's object — picking creates a blank object of this shape.
  final String exampleSpec;

  /// The bundled image, or null. A missing or undecodable image draws a flat
  /// tile rather than a broken-image glyph.
  final String? asset;
}

/// Parses `assets/library.json`.
///
/// The file ships inside the binary, so a malformed entry is a build mistake
/// rather than bad user data: it throws, and the library test catches it
/// before a release does.
List<LibraryItem> parseLibrary(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! List) {
    throw const FormatException('library.json must be a list');
  }
  return List.unmodifiable([
    for (final (index, entry) in decoded.indexed) _parseItem(index, entry),
  ]);
}

LibraryItem _parseItem(int index, Object? entry) {
  if (entry is! Map) {
    throw FormatException('library entry $index is not an object');
  }
  String field(String key) => switch (entry[key]) {
    final String value when value.trim().isNotEmpty => value,
    _ => throw FormatException('library entry $index has no "$key"'),
  };

  final category = field('category');
  if (category == kLibraryAll || !kLibraryCategories.contains(category)) {
    throw FormatException('library entry $index has category "$category"');
  }
  return LibraryItem(
    id: field('id'),
    name: field('name'),
    category: category,
    specLabel: field('specLabel'),
    exampleSpec: field('exampleSpec'),
    asset: switch (entry['asset']) {
      final String path when path.isNotEmpty => path,
      _ => null,
    },
  );
}

/// The items [category] and [query] leave on screen, best match first.
///
/// Reuses the app search's scorer, so `bulb` and `bubl` behave here as they
/// do on screen 02. Ties keep library order, which keeps the grid from
/// shuffling between two equal reads.
List<LibraryItem> filterLibrary(
  List<LibraryItem> items, {
  required String category,
  required String query,
}) {
  final inCategory = category == kLibraryAll
      ? items
      : items.where((item) => item.category == category);
  final tokens = tokenizeQuery(query);
  if (tokens.isEmpty) return List.unmodifiable(inCategory);

  final scored =
      [
        for (final (order, item) in inCategory.indexed)
          (item: item, order: order, score: _score(tokens, item)),
      ].where((entry) => entry.score > 0).toList()..sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        return byScore != 0 ? byScore : a.order.compareTo(b.order);
      });
  return List.unmodifiable([for (final entry in scored) entry.item]);
}

/// Every token must land, as in [scoreRecord], but only the name forgives a
/// typo. The other fields are a handful of short codes and labels shared
/// across the library — `tyre` is one edit from the `TYPE` half of it
/// carries — so there a token has to actually appear.
double _score(List<String> tokens, LibraryItem item) {
  var total = 0.0;
  for (final token in tokens) {
    final score = scoreRecord(
      [token],
      [
        (text: item.name, weight: kWeightName),
        for (final field in _exactFieldsOf(item))
          if (field.text.toLowerCase().contains(token)) field,
      ],
    );
    if (score == 0) return 0;
    total += score;
  }
  return total;
}

List<WeightedText> _exactFieldsOf(LibraryItem item) => [
  (text: item.exampleSpec, weight: kWeightSpecValue),
  (text: item.specLabel, weight: kWeightAttributes),
  (text: item.category, weight: kWeightLocation),
];
