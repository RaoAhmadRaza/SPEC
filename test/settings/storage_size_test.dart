import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:spec/settings/storage_size.dart';

void main() {
  group('storageLabel', () {
    test('uses decimal units with one place past a kilobyte', () {
      expect(storageLabel(0), '0 B');
      expect(storageLabel(999), '999 B');
      expect(storageLabel(1000), '1.0 KB');
      expect(storageLabel(2100000), '2.1 MB');
      expect(storageLabel(3400000000), '3.4 GB');
    });
  });

  group('bytesOf', () {
    late Directory root;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('storage_size_test');
    });

    tearDown(() => root.delete(recursive: true));

    test('sums files, nested folders included', () async {
      // Arrange
      final nested = await Directory(p.join(root.path, 'photos')).create();
      await File(p.join(root.path, 'spec.sqlite')).writeAsBytes([1, 2, 3]);
      await File(p.join(nested.path, 'a.jpg')).writeAsBytes([1, 2]);

      // Act / Assert
      expect(await bytesOf(root), 5);
      expect(await bytesOf(File(p.join(root.path, 'spec.sqlite'))), 3);
    });

    test('counts something missing as zero', () async {
      expect(await bytesOf(File(p.join(root.path, 'gone'))), 0);
      expect(await bytesOf(Directory(p.join(root.path, 'gone'))), 0);
    });
  });
}
