import 'package:flutter_test/flutter_test.dart';
import 'package:spec/add/add_icons.dart';
import 'package:spec/add/add_kinds.dart';
import 'package:spec/data/models/spec_models.dart';
import 'package:spec/onboarding/first_object_draft.dart';

void main() {
  test('a chip becomes a named shape of the right type', () {
    // Arrange
    const suggestion = 'FILTER';

    // Act
    final shape = firstObjectShape(suggestion);

    // Assert
    expect(shape.name, 'Filter');
    expect(shape.type, AddType.device);
    expect(shape.kind, SpecKind.filter);
  });

  test('every chip lights one of its type\'s own kinds on step 05', () {
    for (final chip in ['BULB', 'TYRE', 'CARTRIDGE', 'FILTER']) {
      final shape = firstObjectShape(chip);
      expect(kindsFor(shape.type), contains(shape.kind), reason: chip);
    }
  });

  test('an unrecognised chip is still a shape rather than a crash', () {
    final shape = firstObjectShape('SPROCKET');

    expect(shape.name, 'SPROCKET');
    expect(shape.type, AddType.other);
    expect(shape.kind, SpecKind.other);
  });
}
