import 'package:spec/data/models/spec_models.dart';
import 'package:spec/data/object_repository.dart';
import 'package:spec/data/photo_store.dart';
import 'package:spec/data/photo_thumbnail.dart';
import 'package:spec/data/search_service.dart';
import 'package:spec/data/zone_naming.dart';
import 'package:spec/search/search_models.dart';

/// Turns a typed query into rows the screen can draw.
///
/// The scope is applied here rather than in [SearchService] because it is a
/// presentation filter: the scorer has no opinion about which zone the user
/// is currently looking at.
class SearchQueryRunner {
  const SearchQueryRunner(
    this._search,
    this._objects,
    this._photos, {
    this.scope,
    this.isListingAll = false,
  });

  final SearchService _search;
  final ObjectRepository _objects;
  final PhotoStore _photos;

  /// A zone name, uppercased, or null for the whole archive.
  final String? scope;

  /// A blank query lists the whole archive rather than nothing: SEE ALL.
  final bool isListingAll;

  Future<SearchResults> run(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      // An unscoped blank query has nothing to say, unless it is SEE ALL; a
      // scoped one is the zone.
      return scope == null && !isListingAll ? SearchResults.none : _listScope();
    }

    final outcome = await _search.searchObjects(trimmed);
    return SearchResults(
      matches: _map(outcome.matches.where(_isInScope)),
      elapsed: outcome.elapsed,
    );
  }

  /// Landing on a zone, or on SEE ALL, lists it newest first, and is timed
  /// like any other read.
  Future<SearchResults> _listScope() async {
    final stopwatch = Stopwatch()..start();
    final rows = (await _objects.all()).where(_isInScope);
    stopwatch.stop();
    return SearchResults(matches: _map(rows), elapsed: stopwatch.elapsed);
  }

  bool _isInScope(ObjectSummary object) =>
      scope == null || zoneOf(object) == scope!.toUpperCase();

  List<SearchResult> _map(Iterable<ObjectSummary> rows) => [
    for (final row in rows)
      SearchResult(
        id: row.id,
        name: row.name,
        zoneLine: zoneLineOf(row),
        spec: row.specValue,
        photo: switch (row.photoFileName) {
          final String fileName => photoThumbnail(
            _photos.resolve(fileName),
            edge: kPhotoEdgeSmall,
          ),
          null => null,
        },
      ),
  ];
}
