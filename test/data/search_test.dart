import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/data/db/spec_database.dart';
import 'package:spec/data/models/spec_models.dart';
import 'package:spec/data/object_repository.dart';
import 'package:spec/data/search_service.dart';

/// The three rows screen 02 shows for the query `bulb`, verbatim from the
/// design file: name, `ZONE · SUB-LOCATION`, and the hero spec.
Future<void> _seedDesignRows(SpecDatabase db, ObjectRepository objects) async {
  final home = await db
      .into(db.zones)
      .insert(
        ZonesCompanion.insert(
          name: 'Home',
          sortOrder: 0,
          createdAt: DateTime(2026, 1, 1),
        ),
      );
  final car = await db
      .into(db.zones)
      .insert(
        ZonesCompanion.insert(
          name: 'Car',
          sortOrder: 1,
          createdAt: DateTime(2026, 1, 1),
        ),
      );

  await objects.create(
    _draft(
      name: 'Bedroom bulb',
      zoneId: home,
      subLocation: 'Ceiling',
      specValue: 'B22',
      libraryTerm: 'Bulb',
    ),
  );
  await objects.create(
    _draft(
      name: 'Desk lamp bulb',
      zoneId: home,
      subLocation: 'Study',
      specValue: 'E27',
      libraryTerm: 'Bulb',
    ),
  );
  await objects.create(
    _draft(
      name: 'Headlight',
      zoneId: car,
      subLocation: 'Low beam',
      specValue: 'H7',
      libraryTerm: 'Bulb',
    ),
  );
}

ObjectsCompanion _draft({
  required String name,
  required String specValue,
  int? zoneId,
  String? subLocation,
  String? libraryTerm,
  String? notes,
  List<SpecAttribute> attributes = const [],
}) => ObjectsCompanion.insert(
  name: name,
  type: ObjectType.product.name,
  specKind: SpecKind.model.name,
  specValue: specValue,
  zoneId: Value(zoneId),
  subLocation: Value(subLocation),
  libraryTerm: Value(libraryTerm),
  notes: Value(notes),
  attributes: Value(encodeAttributes(attributes)),
  createdAt: DateTime(2026, 9, 1),
  updatedAt: DateTime(2026, 9, 1),
);

void main() {
  late SpecDatabase db;
  late ObjectRepository objects;
  late SearchService search;

  setUp(() {
    db = SpecDatabase.memory();
    objects = ObjectRepository(db);
    search = SearchService(objects);
  });

  tearDown(() => db.close());

  test('bulb returns the design file\'s three matches, in its order', () async {
    // Arrange
    await _seedDesignRows(db, objects);

    // Act
    final outcome = await search.searchObjects('bulb');

    // Assert
    expect(outcome.matches.map((m) => m.name), [
      'Bedroom bulb',
      'Desk lamp bulb',
      'Headlight',
    ]);
  });

  test('a misspelling still reaches the object', () async {
    await _seedDesignRows(db, objects);

    final outcome = await search.searchObjects('bubl');

    expect(outcome.matches.first.name, 'Bedroom bulb');
  });

  test('the hero spec outranks everything else', () async {
    await _seedDesignRows(db, objects);

    final outcome = await search.searchObjects('E27');

    expect(outcome.matches.first.name, 'Desk lamp bulb');
  });

  test('a multi-word query is an AND across fields', () async {
    await _seedDesignRows(db, objects);

    final outcome = await search.searchObjects('bulb car');

    expect(outcome.matches.map((m) => m.name), ['Headlight']);
  });

  test('an object whose only match is in its notes is found', () async {
    // Arrange
    await _seedDesignRows(db, objects);
    await objects.create(
      _draft(
        name: 'Hallway light',
        specValue: 'GU10',
        notes: 'Spare in the garage drawer',
      ),
    );

    // Act
    final outcome = await search.searchObjects('drawer');

    // Assert
    expect(outcome.matches.map((m) => m.name), ['Hallway light']);
  });

  test('a spec match outranks a notes-only match', () async {
    // Arrange: created first, so recency alone would put it on top.
    await objects.create(
      _draft(name: 'Hallway light', specValue: 'GU10', notes: 'Not an E14'),
    );
    await objects.create(_draft(name: 'Fridge light', specValue: 'E14'));

    // Act
    final outcome = await search.searchObjects('E14');

    // Assert
    expect(outcome.matches.map((m) => m.name), [
      'Fridge light',
      'Hallway light',
    ]);
  });

  test('a query that matches nothing returns nothing', () async {
    await _seedDesignRows(db, objects);

    final outcome = await search.searchObjects('gearbox');

    expect(outcome.matches, isEmpty);
  });

  test('an empty query returns nothing rather than everything', () async {
    await _seedDesignRows(db, objects);

    final outcome = await search.searchObjects('   ');

    expect(outcome.matches, isEmpty);
  });

  test('the elapsed reading is real', () async {
    await _seedDesignRows(db, objects);

    final outcome = await search.searchObjects('bulb');

    expect(outcome.elapsed, greaterThan(Duration.zero));
  });
}
