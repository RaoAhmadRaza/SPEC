import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:spec/app/router.dart';
import 'package:spec/data/db/spec_database.dart';
import 'package:spec/data/models/spec_models.dart';
import 'package:spec/data/photo_store.dart';
import 'package:spec/providers/database.dart';
import 'package:spec/providers/onboarding.dart';
import 'package:spec/providers/photos.dart';
import 'package:spec/search/search_result_row.dart';
import 'package:spec/search/search_screen.dart';

import '../support/fonts.dart';
import '../support/prefs.dart';

/// The canvas every number in the design is measured against.
const _canvas = Size(402, 874);

class _AlreadyOnboarded extends OnboardingCompleted {
  @override
  Future<bool> build() async => true;
}

/// The router on Home, over an in-memory archive holding two objects.
Future<GoRouter> _pumpHome(WidgetTester tester) async {
  tester.view
    ..physicalSize = _canvas * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final database = SpecDatabase.memory();
  addTearDown(database.close);
  final photos = Directory.systemTemp.createTempSync('spec_home_route');
  addTearDown(() => photos.deleteSync(recursive: true));

  final container = ProviderContainer(
    overrides: [
      specDatabaseProvider.overrideWith((ref) async => database),
      photoStoreProvider.overrideWith((ref) async => PhotoStore(photos)),
      onboardingCompletedProvider.overrideWith(_AlreadyOnboarded.new),
    ],
  );
  addTearDown(container.dispose);
  await tester.runAsync(() async {
    await container.read(specDatabaseProvider.future);
    final objects = container.read(objectRepositoryProvider);
    await objects.create(
      _draft('Drill', DateTime(2026, 9, 1)),
      zoneName: 'Garage Shelf',
    );
    await objects.create(
      _draft('Bedroom bulb', DateTime(2026, 9, 2)),
      zoneName: 'Home',
    );
  });

  final router = container.read(routerProvider);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await _pumpFrames(tester);
  return router;
}

ObjectsCompanion _draft(String name, DateTime updatedAt) =>
    ObjectsCompanion.insert(
      name: name,
      type: ObjectType.home.name,
      specKind: SpecKind.model.name,
      specValue: 'B22',
      createdAt: updatedAt,
      updatedAt: updatedAt,
    );

/// The orb breathes forever, so pumpAndSettle would never return. Real time
/// passes in between so the database streams can deliver.
Future<void> _pumpFrames(WidgetTester tester) async {
  for (var round = 0; round < 3; round++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }
}

void main() {
  setUpAll(loadSpecFonts);
  setUp(useInMemoryPrefs);

  testWidgets('a zone chip opens Search scoped to that zone', (tester) async {
    // Arrange
    final router = await _pumpHome(tester);

    // Act
    await tester.tap(find.text('Garage Shelf'));
    await _pumpFrames(tester);

    // Assert
    expect(router.state.uri.path, '/search');
    expect(router.state.uri.queryParameters, {'scope': 'Garage Shelf'});
    final screen = tester.widget<SearchScreen>(find.byType(SearchScreen));
    expect(screen.scope, 'Garage Shelf');
    expect(find.text('Drill'), findsWidgets);
    expect(
      find.descendant(
        of: find.byType(SearchResultRow),
        matching: find.text('Bedroom bulb'),
      ),
      findsNothing,
    );
  });

  testWidgets('SEE ALL opens Search listing every object newest first', (
    tester,
  ) async {
    // Arrange
    final router = await _pumpHome(tester);

    // Act
    await tester.tap(find.text('SEE ALL ›'));
    await _pumpFrames(tester);

    // Assert
    expect(router.state.uri.path, '/search');
    expect(router.state.uri.queryParameters, {'all': '1'});
    final screen = tester.widget<SearchScreen>(find.byType(SearchScreen));
    expect(screen.scope, isNull);
    expect(screen.isListingAll, isTrue);
    final names = [
      for (final row in tester.widgetList<SearchResultRow>(
        find.byType(SearchResultRow),
      ))
        row.result.name,
    ];
    expect(names, ['Bedroom bulb', 'Drill']);
    expect(find.text('2 OBJECTS · 0 PHOTOS'), findsOneWidget);
  });
}
