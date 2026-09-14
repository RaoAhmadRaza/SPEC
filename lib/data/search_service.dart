import 'package:spec/data/models/spec_models.dart';
import 'package:spec/data/object_repository.dart';
import 'package:spec/data/search_scorer.dart';

/// Search results plus how long they actually took.
///
/// The `0.004S` badge on screen 02 renders this, so it has to be a real
/// reading. That is also why there is no debounce: a debounce would make the
/// badge a lie.
class SearchOutcome {
  const SearchOutcome({required this.matches, required this.elapsed});

  final List<ObjectSummary> matches;
  final Duration elapsed;
}

class SearchService {
  SearchService(this._objects);

  final ObjectRepository _objects;

  /// Loads every object and scores it in Dart.
  ///
  /// The whole call is timed, including the read, because that is what the
  /// user waits for.
  Future<SearchOutcome> searchObjects(String query) async {
    final stopwatch = Stopwatch()..start();
    final tokens = tokenizeQuery(query);
    if (tokens.isEmpty) {
      return SearchOutcome(matches: const [], elapsed: stopwatch.elapsed);
    }

    final scored = <({ObjectSummary object, double score})>[];
    for (final object in await _objects.all()) {
      final score = scoreRecord(tokens, searchFieldsOf(object));
      if (score > 0) scored.add((object: object, score: score));
    }
    // Equal scores fall back to recency, so the order never wobbles between
    // two identical reads.
    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      return byScore != 0
          ? byScore
          : b.object.updatedAt.compareTo(a.object.updatedAt);
    });

    stopwatch.stop();
    return SearchOutcome(
      matches: [for (final entry in scored) entry.object],
      elapsed: stopwatch.elapsed,
    );
  }
}

/// The weighted text of one object. Public so the scorer's tests can build a
/// candidate without a database.
List<WeightedText> searchFieldsOf(ObjectSummary object) => [
  (text: object.specValue, weight: kWeightSpecValue),
  (text: object.name, weight: kWeightName),
  (text: object.libraryTerm ?? '', weight: kWeightLibraryTerm),
  (text: object.zoneName ?? '', weight: kWeightLocation),
  (text: object.subLocation ?? '', weight: kWeightLocation),
  for (final attribute in object.attributes)
    (text: '${attribute.label} ${attribute.value}', weight: kWeightAttributes),
  (text: object.notes ?? '', weight: kWeightNotes),
];
