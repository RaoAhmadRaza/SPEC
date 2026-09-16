import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/data/db/spec_database.dart';
import 'package:spec/data/models/spec_models.dart';
import 'package:spec/data/photo_store.dart';
import 'package:spec/providers/database.dart';
import 'package:spec/providers/photos.dart';
import 'package:spec/search/search_result_row.dart';
import 'package:spec/search/search_route.dart';

/// The canvas every number in the design is measured against.
const _canvas = Size(402, 874);

Future<ProviderContainer> _pumpRoute(WidgetTester tester) async {
  tester.view
    ..physicalSize = _canvas * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final database = SpecDatabase.memory();
  addTearDown(database.close);
  final photos = Directory.systemTemp.createTempSync('spec_search_route');
  addTearDown(() => photos.deleteSync(recursive: true));

  final container = ProviderContainer(
    overrides: [
      specDatabaseProvider.overrideWith((ref) async => database),
      photoStoreProvider.overrideWith((ref) async => PhotoStore(photos)),
    ],
  );
  addTearDown(container.dispose);
  await container.read(specDatabaseProvider.future);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: SearchRoute()),
    ),
  );
  return container;
}

/// The waveform ripples forever, so pumpAndSettle would never return.
Future<void> _pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// Database work is real I/O, which the fake clock of a widget test never
/// lets finish on its own.
Future<void> _write(WidgetTester tester, Future<void> Function() body) async {
  await tester.runAsync(() async {
    await body();
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
  await _pumpFrames(tester);
}

Future<int> _seedBulb(WidgetTester tester, ProviderContainer container) async {
  late int id;
  await _write(tester, () async {
    id = await container
        .read(objectRepositoryProvider)
        .create(
          ObjectsCompanion.insert(
            name: 'Bedroom bulb',
            type: ObjectType.home.name,
            specKind: SpecKind.model.name,
            specValue: 'B22',
            createdAt: DateTime(2026, 9, 1),
            updatedAt: DateTime(2026, 9, 1),
          ),
          zoneName: 'Home',
        );
  });
  return id;
}

Future<void> _search(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await _pumpFrames(tester);
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await _pumpFrames(tester);
}

void main() {
  testWidgets('an edited object updates its row in place', (tester) async {
    // Arrange
    final container = await _pumpRoute(tester);
    final id = await _seedBulb(tester, container);
    await _search(tester, 'bulb');
    expect(find.text('B22'), findsOneWidget);

    // Act
    await _write(
      tester,
      () => container
          .read(objectRepositoryProvider)
          .updateDetail(
            id,
            specValue: 'B22 E27',
            attributes: const [],
            purchasedFrom: null,
            replacedOn: null,
            notes: null,
          ),
    );
    await _write(tester, () async {});

    // Assert
    expect(find.text('B22 E27'), findsOneWidget);
    expect(find.text('B22'), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'bulb',
    );
  });

  testWidgets('a deleted object leaves the results', (tester) async {
    // Arrange
    final container = await _pumpRoute(tester);
    final id = await _seedBulb(tester, container);
    await _search(tester, 'bulb');
    expect(find.byType(SearchResultRow), findsOneWidget);

    // Act
    await _write(
      tester,
      () => container.read(objectRepositoryProvider).delete(id),
    );
    await _write(tester, () async {});

    // Assert
    expect(find.byType(SearchResultRow), findsNothing);
    expect(find.text('Bedroom bulb'), findsNothing);
  });
}
