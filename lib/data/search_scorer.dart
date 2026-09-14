/// The whole of SPEC's search, as pure functions over text.
///
/// Not FTS5. The corpus is tens of rows, and FTS5 cannot produce two of the
/// three behaviours the design shows: it has no edit distance, so `bubl` never
/// reaches `Bedroom bulb`, and `bulb` reaching `Headlight` is synonym matching
/// that comes from a copied `library_term`, not from any tokenizer.
library;

import 'dart:math' as math;

/// Field weights. A hit on the hero spec beats a hit on a zone name.
const double kWeightSpecValue = 1;
const double kWeightName = 0.95;
const double kWeightLibraryTerm = 0.70;
const double kWeightLocation = 0.50;
const double kWeightAttributes = 0.40;

/// Free text, so a hit there is the weakest evidence the object is the one
/// being looked for.
const double kWeightNotes = 0.35;

/// Match tiers, best first.
const double _tierExact = 1;
const double _tierPrefix = 0.92;
const double _tierWord = 0.85;
const double _tierSubstring = 0.60;
const double _tierFuzzy = 0.50;

/// A hit on the first word beats the same hit on the fourth, which is what
/// puts `Bedroom bulb` above `Desk lamp bulb`.
const double _positionPenalty = 0.03;
const int _positionPenaltyCap = 5;

/// Below three characters, edit distance matches almost everything.
const int _minFuzzyLength = 3;
const int _shortTokenLength = 4;

/// A field of a searchable record, with the weight its content earns.
typedef WeightedText = ({String text, double weight});

final RegExp _whitespace = RegExp(r'\s+');

/// Splits on whitespace only, so `205/55`, `M10` and `5W-30` survive intact.
List<String> tokenizeQuery(String query) => [
  for (final token in query.trim().toLowerCase().split(_whitespace))
    if (token.isNotEmpty) token,
];

/// Scores one record. Returns 0 when the record is not a match.
///
/// Every token must land somewhere, so a multi-word query is an AND. The
/// record's score is the sum of each token's best field.
double scoreRecord(List<String> tokens, List<WeightedText> fields) {
  if (tokens.isEmpty) return 0;
  var total = 0.0;
  for (final token in tokens) {
    var best = 0.0;
    for (final field in fields) {
      if (field.text.isEmpty) continue;
      final score = _scoreField(token, field.text) * field.weight;
      if (score > best) best = score;
    }
    if (best == 0) return 0;
    total += best;
  }
  return total;
}

double _scoreField(String token, String text) {
  final field = text.toLowerCase();
  if (field == token) return _tierExact;
  if (field.startsWith(token)) return _tierPrefix;

  final words = field.split(_whitespace);
  for (var i = 1; i < words.length; i++) {
    if (words[i].startsWith(token)) return _tierWord * _positionDecay(i);
  }
  if (field.contains(token)) return _tierSubstring;

  return _fuzzyScore(token, words);
}

double _positionDecay(int wordIndex) =>
    1 - _positionPenalty * math.min(wordIndex, _positionPenaltyCap);

double _fuzzyScore(String token, List<String> words) {
  if (token.length < _minFuzzyLength) return 0;
  final limit = token.length <= _shortTokenLength ? 1 : 2;
  var bestDistance = limit + 1;
  for (final word in words) {
    final distance = _editDistance(token, word, limit);
    if (distance < bestDistance) bestDistance = distance;
    if (bestDistance == 0) break;
  }
  if (bestDistance > limit) return 0;
  return _tierFuzzy * (1 - bestDistance / token.length);
}

/// Damerau-Levenshtein, bounded. Returns [limit] + 1 once it is certain the
/// distance exceeds the limit, so a long word costs almost nothing.
int _editDistance(String a, String b, int limit) {
  if ((a.length - b.length).abs() > limit) return limit + 1;
  if (a == b) return 0;

  var twoBack = List<int>.filled(b.length + 1, 0);
  var previous = List<int>.generate(b.length + 1, (i) => i);
  var current = List<int>.filled(b.length + 1, 0);

  for (var i = 1; i <= a.length; i++) {
    current[0] = i;
    var rowBest = current[0];
    for (var j = 1; j <= b.length; j++) {
      final substitution = a[i - 1] == b[j - 1] ? 0 : 1;
      var best = math.min(
        current[j - 1] + 1,
        math.min(previous[j] + 1, previous[j - 1] + substitution),
      );
      final isTransposition =
          i > 1 && j > 1 && a[i - 1] == b[j - 2] && a[i - 2] == b[j - 1];
      if (isTransposition) best = math.min(best, twoBack[j - 2] + 1);
      current[j] = best;
      if (best < rowBest) rowBest = best;
    }
    if (rowBest > limit) return limit + 1;

    final spent = twoBack;
    twoBack = previous;
    previous = current;
    current = spent;
  }
  return previous[b.length];
}
