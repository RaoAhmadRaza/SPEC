import 'package:spec/object/object_models.dart';
import 'package:spec/object/object_route.dart';
import 'package:spec/search/search_models.dart';
import 'package:spec/search/search_result_row.dart';
import 'package:spec/search/search_tokens.dart';

/// Joins zone and sub-zone in a result's zone line.
const _zoneSeparator = ' · ';

/// Seeds screen 03 from the search row that was tapped, the way
/// [objectRouteArgsFor] does from a Home tile: the row's spec style and thumb
/// corner for the flight, and its zone, spec and photo so the Heroes have a
/// destination on the first frame.
///
/// `HOME · CEILING` splits into the zone and its sub-zone; a line with no
/// separator is a zone alone.
ObjectRouteArgs objectRouteArgsForSearch(SearchResult result) {
  final [zone, ...rest] = result.zoneLine.split(_zoneSeparator);
  return ObjectRouteArgs(
    seed: ObjectView(
      id: result.id,
      name: result.name,
      zone: zone,
      subZone: rest.isEmpty ? null : rest.join(_zoneSeparator),
      spec: result.spec,
      mainPhoto: result.photo,
    ),
    sourceSpecStyle: SearchText.spec,
    sourcePhotoRadius: kSearchThumbRadius,
    source: ObjectSource.searchRow,
  );
}
