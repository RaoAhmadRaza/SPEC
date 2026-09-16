import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/data/db/spec_database.dart';
import 'package:spec/data/models/spec_models.dart';
import 'package:spec/data/object_repository.dart';
import 'package:spec/data/photo_store.dart';
import 'package:spec/object/object_actions.dart';
import 'package:spec/object/object_icons.dart';
import 'package:spec/providers/database.dart';
import 'package:spec/providers/photos.dart';

import '../support/fonts.dart';

const _canvas = Size(402, 874);

ObjectsCompanion _bulb() => ObjectsCompanion.insert(
  name: 'Bulb',
  type: ObjectType.home.name,
  specKind: SpecKind.bulb.name,
  specValue: 'B22',
  createdAt: DateTime(2026, 9, 1),
  updatedAt: DateTime(2026, 9, 1),
);

/// A page with one button that opens the actions sheet for [id], over a
/// real in-memory database.
Future<ObjectRepository> _pump(
  WidgetTester tester,
  Future<int> Function(ObjectRepository) seed, {
  ValueChanged<int>? onDuplicated,
  VoidCallback? onDeleting,
}) async {
  tester.view
    ..physicalSize = _canvas * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final database = SpecDatabase.memory();
  addTearDown(database.close);
  final photos = Directory.systemTemp.createTempSync('spec_actions_test');
  addTearDown(() => photos.deleteSync(recursive: true));
  final container = ProviderContainer(
    overrides: [
      specDatabaseProvider.overrideWith((ref) async => database),
      photoStoreProvider.overrideWith((ref) async => PhotoStore(photos)),
    ],
  );
  addTearDown(container.dispose);
  await container.read(specDatabaseProvider.future);
  final repository = container.read(objectRepositoryProvider);
  final id = await seed(repository);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Consumer(
          builder: (context, ref, _) => Center(
            child: GestureDetector(
              onTap: () => showObjectActions(
                context,
                ref,
                id,
                onDuplicated: onDuplicated,
                onDeleting: onDeleting,
              ),
              child: const Text('OPEN'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('OPEN'));
  await tester.pumpAndSettle();
  return repository;
}

Finder _checkedRow(String label) => find.ancestor(
  of: find.byType(CheckMark),
  matching: find.widgetWithText(Row, label),
);

void main() {
  setUpAll(loadSpecFonts);

  testWidgets('offers the four actions, Delete last', (tester) async {
    await _pump(tester, (repository) => repository.create(_bulb()));

    final tops = [
      'Move to zone',
      'Duplicate',
      'Set reminder',
      'Delete',
    ].map((label) => tester.getTopLeft(find.text(label)).dy).toList();
    expect(tops, [...tops]..sort());
  });

  testWidgets('Move to zone checks the current zone and moves on a pick', (
    tester,
  ) async {
    late int id;
    final repository = await _pump(tester, (repository) async {
      await repository.create(_bulb(), zoneName: 'Garage');
      return id = await repository.create(_bulb(), zoneName: 'Kitchen');
    });

    await tester.tap(find.text('Move to zone'));
    await tester.pumpAndSettle();

    expect(_checkedRow('Kitchen'), findsOneWidget);
    expect(_checkedRow('Garage'), findsNothing);

    await tester.tap(find.text('Garage'));
    await tester.pumpAndSettle();

    final detail = await repository.detail(id);
    expect(detail!.summary.zoneName, 'Garage');
    expect(find.text('Garage'), findsNothing, reason: 'the sheet closed');
  });

  testWidgets('Set reminder offers the REMIND ME choices and writes one', (
    tester,
  ) async {
    late int id;
    final repository = await _pump(
      tester,
      (repository) async => id = await repository.create(_bulb()),
    );

    await tester.tap(find.text('Set reminder'));
    await tester.pumpAndSettle();

    for (final label in [
      'NEVER',
      'EVERY 3 MONTHS',
      'EVERY 6 MONTHS',
      'EVERY YEAR',
      'EVERY 2 YEARS',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(_checkedRow('NEVER'), findsOneWidget);

    await tester.tap(find.text('EVERY YEAR'));
    await tester.pumpAndSettle();

    expect((await repository.detail(id))!.remindEveryMonths, 12);
  });

  testWidgets('Duplicate hands back the copy', (tester) async {
    int? copy;
    late int id;
    final repository = await _pump(
      tester,
      (repository) async => id = await repository.create(_bulb()),
      onDuplicated: (value) => copy = value,
    );

    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();

    expect(copy, isNotNull);
    expect(copy, isNot(id));
    expect((await repository.detail(copy!))!.summary.name, 'Bulb');
  });

  testWidgets('Delete asks once, then leaves and deletes', (tester) async {
    var left = 0;
    late int id;
    final repository = await _pump(
      tester,
      (repository) async => id = await repository.create(_bulb()),
      onDeleting: () => left++,
    );

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(left, 0);
    expect(await repository.detail(id), isNotNull);

    await tester.tap(find.text('Yes, delete'));
    await tester.pumpAndSettle();
    expect(left, 1);
    expect(await repository.detail(id), isNull);
  });

  group('share', () {
    late Directory directory;

    setUp(() => directory = Directory.systemTemp.createTempSync('spec_share'));
    tearDown(() => directory.deleteSync(recursive: true));

    ObjectDetail detail({String? zone, String? notes, List<String>? photos}) =>
        ObjectDetail(
          summary: ObjectSummary(
            id: 1,
            name: 'Water filter',
            type: ObjectType.home,
            specKind: SpecKind.filter,
            specValue: 'LT1000P',
            zoneName: zone,
            subLocation: null,
            libraryTerm: null,
            attributes: const [],
            photoFileName: null,
            updatedAt: DateTime(2026, 9, 1),
            notes: notes,
          ),
          subtitle: null,
          purchasedFrom: null,
          replacedOn: null,
          remindEveryMonths: null,
          photoFileNames: photos ?? const [],
          createdAt: DateTime(2026, 9, 1),
        );

    test('summarises name, spec, zone and notes with the photos', () {
      final store = PhotoStore(directory);

      final params = objectShareParams(
        detail(zone: 'Kitchen', notes: 'under sink left', photos: ['a.jpg']),
        store,
      );

      expect(
        params.text,
        'Water filter\nFILTER: LT1000P\nZone: Kitchen\nNotes: under sink left',
      );
      expect(params.files!.single.path, store.resolve('a.jpg').path);
    });

    test('leaves out what the object does not have', () {
      final params = objectShareParams(detail(), PhotoStore(directory));

      expect(params.text, 'Water filter\nFILTER: LT1000P');
      expect(params.files, isNull);
    });
  });
}
