import 'package:flutter_test/flutter_test.dart';
import 'package:spec/object/object_models.dart';
import 'package:spec/object/search_route_args.dart';
import 'package:spec/search/search_models.dart';
import 'package:spec/search/search_result_row.dart';
import 'package:spec/search/search_tokens.dart';

SearchResult _result(String zoneLine) =>
    SearchResult(id: 7, name: 'Bulb', zoneLine: zoneLine, spec: 'E27');

void main() {
  test('splits the zone line into zone and sub-zone', () {
    final args = objectRouteArgsForSearch(_result('HOME · CEILING'));

    expect(args.seed.id, 7);
    expect(args.seed.zone, 'HOME');
    expect(args.seed.subZone, 'CEILING');
    expect(args.seed.spec, 'E27');
  });

  test('a zone line with no separator is a zone alone', () {
    final args = objectRouteArgsForSearch(_result('GARAGE'));

    expect(args.seed.zone, 'GARAGE');
    expect(args.seed.subZone, isNull);
  });

  test('flies from the search row, not a Home tile', () {
    final args = objectRouteArgsForSearch(_result('HOME · CEILING'));

    expect(args.source, ObjectSource.searchRow);
    expect(args.sourceSpecStyle, SearchText.spec);
    expect(args.sourcePhotoRadius, kSearchThumbRadius);
  });
}
