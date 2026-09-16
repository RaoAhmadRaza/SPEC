import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/collections/collections_models.dart';
import 'package:spec/home/home_header.dart';
import 'package:spec/home/home_models.dart';
import 'package:spec/providers/collections.dart';
import 'package:spec/providers/home.dart';
import 'package:spec/providers/search.dart';
import 'package:spec/search/search_models.dart';
import 'package:spec/shell/home_shell_route.dart';

import '../support/fonts.dart';

const _canvas = Size(402, 874);

Future<void> _pumpFrames(WidgetTester tester, int count) async {
  // The orb breathes forever, so pumpAndSettle would never return.
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  setUpAll(loadSpecFonts);

  testWidgets('the rail + opens Collections with the zone name field focused', (
    tester,
  ) async {
    // Arrange
    tester.view
      ..physicalSize = _canvas * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeObjectsProvider.overrideWith(
            (ref) => Stream.value(const <HomeObject>[]),
          ),
          collectionZonesProvider.overrideWith(
            (ref) => Stream.value(const [
              CollectionZone(id: 1, name: 'Home', count: 2),
              CollectionZone(id: 2, name: 'Car', count: 1),
            ]),
          ),
          archiveCountsProvider.overrideWith(
            (ref) => Stream.value(const ArchiveCounts(objects: 3, photos: 0)),
          ),
        ],
        child: const MaterialApp(home: HomeShellRoute()),
      ),
    );
    await _pumpFrames(tester, 10);
    final isCollectionsHidden = find.text('MY\nSTUFF').evaluate().isEmpty;

    // Act
    await tester.tap(
      find.descendant(
        of: find.byType(HomeCategoryRail),
        matching: find.text('+'),
      ),
    );
    await _pumpFrames(tester, 60);

    // Assert
    expect(isCollectionsHidden, isTrue);
    expect(find.text('MY\nSTUFF'), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
  });
}
