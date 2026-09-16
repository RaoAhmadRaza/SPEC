import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/data/db/spec_database.dart';
import 'package:spec/data/models/spec_models.dart';
import 'package:spec/data/photo_store.dart';
import 'package:spec/home/home_models.dart';
import 'package:spec/providers/database.dart';
import 'package:spec/providers/home.dart';
import 'package:spec/providers/photos.dart';

void main() {
  test('the zone rail keeps a zone name exactly as it was stored', () async {
    // Arrange
    final database = SpecDatabase.memory();
    addTearDown(database.close);
    final photos = Directory.systemTemp.createTempSync('spec_home_provider');
    addTearDown(() => photos.deleteSync(recursive: true));
    final container = ProviderContainer(
      overrides: [
        specDatabaseProvider.overrideWith((ref) async => database),
        photoStoreProvider.overrideWith((ref) async => PhotoStore(photos)),
      ],
    );
    addTearDown(container.dispose);
    await container.read(specDatabaseProvider.future);
    await container
        .read(objectRepositoryProvider)
        .create(
          ObjectsCompanion.insert(
            name: 'Drill',
            type: ObjectType.home.name,
            specKind: SpecKind.model.name,
            specValue: 'B22',
            createdAt: DateTime(2026, 9, 1),
            updatedAt: DateTime(2026, 9, 1),
          ),
          zoneName: 'Garage Shelf',
        );
    container.listen(homeCategoriesProvider, (_, _) {});

    // Act
    var categories = const <HomeCategory>[];
    for (var i = 0; i < 20 && categories.isEmpty; i++) {
      await Future<void>.delayed(Duration.zero);
      categories = container.read(homeCategoriesProvider);
    }

    // Assert
    expect(categories.map((category) => category.label), ['Garage Shelf']);
    expect(categories.single.count, 1);
  });
}
