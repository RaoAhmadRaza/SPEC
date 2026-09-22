import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/library/library_models.dart';

/// The bundled library, parsed the way the app parses it.
final List<LibraryItem> _bundled = parseLibrary(
  File('assets/library.json').readAsStringSync(),
);

Iterable<LibraryItem> get _withAsset =>
    _bundled.where((item) => item.asset != null);

void main() {
  // A thumbnail that fails to load draws the same flat tile as an item with
  // no image at all, so a typo'd path or an undeclared directory is invisible
  // on screen. These assert it loudly instead.
  test('every declared library asset exists on disk', () {
    expect(_withAsset, isNotEmpty, reason: 'no library item declares an asset');
    for (final item in _withAsset) {
      expect(
        File(item.asset!).existsSync(),
        isTrue,
        reason: '${item.id} points at ${item.asset}',
      );
    }
  });

  testWidgets('every declared library asset is in the bundle', (tester) async {
    // Declaring a file on disk is not enough: `assets/images/` does not carry
    // its subdirectories, so a path can exist and still be unbundled.
    for (final item in _withAsset) {
      await expectLater(
        rootBundle.load(item.asset!),
        completes,
        reason: '${item.id} is not bundled: ${item.asset}',
      );
    }
  });
}
