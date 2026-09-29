import 'package:flutter_test/flutter_test.dart';
import 'package:spec/providers/backup.dart';

void main() {
  test('the restore picker accepts zips Android labels as non-zip types', () {
    // A backup saved through Drive or WhatsApp is not always application/zip;
    // without these the file shows greyed out and cannot be picked.
    expect(
      backupTypeGroup.mimeTypes,
      containsAll(<String>[
        'application/zip',
        'application/x-zip-compressed',
        'application/octet-stream',
      ]),
    );
    // iOS still needs its UTI, or its picker throws.
    expect(backupTypeGroup.uniformTypeIdentifiers, ['public.zip-archive']);
  });
}
