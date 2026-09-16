import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show AsyncProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/data/db/spec_database.dart';
import 'package:spec/data/models/spec_models.dart';
import 'package:spec/data/photo_store.dart';
import 'package:spec/providers/database.dart';
import 'package:spec/providers/photos.dart';
import 'package:spec/providers/search.dart';

/// A container over a real in-memory database, already open.
Future<ProviderContainer> _container() async {
  final database = SpecDatabase.memory();
  addTearDown(database.close);
  final photos = Directory.systemTemp.createTempSync('spec_search_provider');
  addTearDown(() => photos.deleteSync(recursive: true));
  final container = ProviderContainer(
    overrides: [
      specDatabaseProvider.overrideWith((ref) async => database),
      photoStoreProvider.overrideWith((ref) async => PhotoStore(photos)),
    ],
  );
  addTearDown(container.dispose);
  await container.read(specDatabaseProvider.future);
  return container;
}

/// Held open while it loads: a bare `read` of an auto-disposed provider
/// drops it before its first value arrives.
Future<T> _read<T>(
  ProviderContainer container,
  AsyncProviderListenable<T> provider,
) {
  final subscription = container.listen(provider.future, (_, _) {});
  addTearDown(subscription.close);
  return subscription.read();
}

Future<void> _create(
  ProviderContainer container,
  String name, {
  String? zone,
  ObjectType type = ObjectType.product,
  required DateTime updatedAt,
}) => container
    .read(objectRepositoryProvider)
    .create(
      ObjectsCompanion.insert(
        name: name,
        type: type.name,
        specKind: SpecKind.model.name,
        specValue: 'B22',
        createdAt: updatedAt,
        updatedAt: updatedAt,
      ),
      zoneName: zone,
    );

void main() {
  group('searchZones', () {
    test('keeps a zone name exactly as it was stored', () async {
      // Arrange
      final container = await _container();
      await _create(
        container,
        'Drill',
        zone: 'Garage Shelf',
        updatedAt: DateTime(2026, 9, 1),
      );

      // Act
      final zones = await _read(container, searchZonesProvider);

      // Assert
      expect(zones.map((zone) => zone.name), ['Garage Shelf']);
    });

    test(
      'an object with no zone is filed under its title-cased type',
      () async {
        // Arrange
        final container = await _container();
        await _create(
          container,
          'Scarf',
          type: ObjectType.clothing,
          updatedAt: DateTime(2026, 9, 1),
        );

        // Act
        final zones = await _read(container, searchZonesProvider);

        // Assert
        expect(zones.single.name, 'Clothing');
        expect(zones.single.count, 1);
      },
    );
  });

  group('searchQueryRunner', () {
    test('a blank query lists nothing on the plain search', () async {
      // Arrange
      final container = await _container();
      await _create(container, 'Drill', updatedAt: DateTime(2026, 9, 1));
      final runner = await _read(container, searchQueryRunnerProvider());

      // Act
      final results = await runner.run('');

      // Assert
      expect(results.matches, isEmpty);
    });

    test(
      'a blank query lists every object newest first under SEE ALL',
      () async {
        // Arrange
        final container = await _container();
        await _create(container, 'Older', updatedAt: DateTime(2026, 9, 1));
        await _create(container, 'Newer', updatedAt: DateTime(2026, 9, 2));
        final runner = await _read(
          container,
          searchQueryRunnerProvider(isListingAll: true),
        );

        // Act
        final all = await runner.run('');
        final filtered = await runner.run('older');

        // Assert
        expect(all.matches.map((result) => result.name), ['Newer', 'Older']);
        expect(filtered.matches.map((result) => result.name), ['Older']);
      },
    );
  });
}
