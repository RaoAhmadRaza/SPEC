import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spec/data/models/spec_models.dart';
import 'package:spec/data/photo_store.dart';
import 'package:spec/library/library_models.dart';
import 'package:spec/providers/object.dart';

const _items = [
  LibraryItem(
    id: 'fridge-filter',
    name: 'Fridge filter',
    category: 'HOME',
    specLabel: 'MODEL',
    exampleSpec: 'DA29-00020B',
    asset: 'assets/images/components/filter refg.png',
  ),
  LibraryItem(
    id: 'tap-washer',
    name: 'Tap washer',
    category: 'HOME',
    specLabel: 'SIZE',
    exampleSpec: '1/2"',
  ),
];

void main() {
  test('an object named after a library item gets its bundled picture', () {
    expect(
      libraryAssetFor('Fridge filter', _items),
      'assets/images/components/filter refg.png',
    );
    // Case and stray spaces from an edit do not break the match.
    expect(
      libraryAssetFor('  fridge FILTER ', _items),
      'assets/images/components/filter refg.png',
    );
  });

  test('no picture for an item without one, or a name not in the library', () {
    expect(libraryAssetFor('Tap washer', _items), isNull);
    expect(libraryAssetFor('Garage remote', _items), isNull);
  });

  group('toObjectView', () {
    ObjectDetail detail({List<String> photos = const []}) => ObjectDetail(
      summary: ObjectSummary(
        id: 1,
        name: 'Fridge filter',
        type: ObjectType.values.first,
        specKind: SpecKind.values.first,
        specValue: 'DA29-00020B',
        zoneName: 'HOME',
        subLocation: null,
        libraryTerm: null,
        attributes: const [],
        photoFileName: photos.isEmpty ? null : photos.first,
        updatedAt: DateTime(2026),
      ),
      subtitle: null,
      purchasedFrom: null,
      replacedOn: null,
      remindEveryMonths: null,
      photoFileNames: photos,
      createdAt: DateTime(2026),
    );
    final store = PhotoStore(Directory('photos'));

    test('a library pick with no photo shows the bundled picture', () {
      final view = toObjectView(detail(), store, library: _items);

      expect(view.mainPhoto, isNotNull);
      expect(view.isMainPhotoBundled, isTrue);
    });

    test("the user's own photo wins over the bundled one", () {
      final view = toObjectView(
        detail(photos: ['a.jpg']),
        store,
        library: _items,
      );

      expect(view.mainPhoto, isNotNull);
      expect(view.isMainPhotoBundled, isFalse);
    });
  });
}
