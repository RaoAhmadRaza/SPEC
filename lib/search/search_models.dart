import 'package:flutter/widgets.dart';

/// One row of the result list.
///
/// A presentation model rather than the database row, so the screen stays
/// buildable in a test with no database and no photo files — the same reason
/// [HomeObject] exists.
@immutable
class SearchResult {
  const SearchResult({
    required this.id,
    required this.name,
    required this.zoneLine,
    required this.spec,
    this.photo,
  });

  final int id;
  final String name;

  /// `HOME · CEILING`, already uppercased by the caller.
  final String zoneLine;

  final String spec;
  final ImageProvider? photo;
}

/// One line of `BROWSE BY ZONE` on the resting empty state.
@immutable
class SearchZone {
  const SearchZone({required this.name, required this.count});

  final String name;
  final int count;
}

/// What `41 OBJECTS · 96 PHOTOS` renders.
@immutable
class ArchiveCounts {
  const ArchiveCounts({required this.objects, required this.photos});

  static const empty = ArchiveCounts(objects: 0, photos: 0);

  final int objects;
  final int photos;

  String get label =>
      '$objects ${_plural('OBJECT', objects)} · '
      '$photos ${_plural('PHOTO', photos)}';
}

String _plural(String word, int count) => count == 1 ? word : '${word}S';

/// One run of the search: what matched, and how long it actually took.
///
/// The timing is a real reading, which is why it travels with the matches
/// rather than being estimated at the point it is drawn.
@immutable
class SearchResults {
  const SearchResults({required this.matches, required this.elapsed});

  static const none = SearchResults(matches: [], elapsed: Duration.zero);

  final List<SearchResult> matches;
  final Duration elapsed;

  /// `0.004S` — three decimals, always, uppercase S.
  String get timing => '${(elapsed.inMicroseconds / 1e6).toStringAsFixed(3)}S';
}

/// Runs one query and reports how long it took.
typedef SearchRunner = Future<SearchResults> Function(String query);
