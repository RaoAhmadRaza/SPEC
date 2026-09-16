import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:spec/data/photo_store.dart';

void main() {
  late Directory directory;
  late PhotoStore store;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('spec_photo_store');
    store = PhotoStore(directory);
  });

  tearDown(() => directory.deleteSync(recursive: true));

  File sourceFile(String name) =>
      File(p.join(directory.path, name))..writeAsBytesSync([1, 2, 3]);

  test(
    'a photo is copied in under a name, and the name resolves back',
    () async {
      // Arrange
      final source = sourceFile('source.jpg');

      // Act
      final fileName = await store.add(source);

      // Assert
      expect(p.extension(fileName), '.jpg');
      expect(store.resolve(fileName).readAsBytesSync(), [1, 2, 3]);
    },
  );

  test('bytes written together still land under distinct names', () async {
    // Arrange: a restore writes many photos within one microsecond.
    final writes = [
      for (var i = 0; i < 20; i++) store.addBytes([i], extension: '.JPG'),
    ];

    // Act
    final names = await Future.wait(writes);

    // Assert
    expect(names.toSet(), hasLength(20));
    expect(names.every((name) => name.endsWith('.jpg')), isTrue);
  });

  test(
    'remove deletes the named files and ignores ones already gone',
    () async {
      final kept = await store.add(sourceFile('kept.jpg'));
      final removed = await store.add(sourceFile('removed.jpg'));

      await store.remove([removed, 'never-existed.jpg']);

      expect(store.resolve(kept).existsSync(), isTrue);
      expect(store.resolve(removed).existsSync(), isFalse);
    },
  );

  test('the sweep deletes files no row refers to', () async {
    final kept = await store.add(sourceFile('kept.jpg'));
    final orphan = await store.add(sourceFile('orphan.jpg'));

    await store.sweep({kept});

    expect(store.resolve(kept).existsSync(), isTrue);
    expect(store.resolve(orphan).existsSync(), isFalse);
  });
}
