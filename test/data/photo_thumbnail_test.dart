import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/add/add_draft.dart';
import 'package:spec/add/add_icons.dart';
import 'package:spec/data/models/spec_models.dart';
import 'package:spec/data/photo_thumbnail.dart';

void main() {
  group('photoThumbnail', () {
    test('decodes a list photo at 4/3 of three times its box', () {
      final large = photoThumbnail(File('a.jpg'), edge: kPhotoEdgeLarge);
      final small = photoThumbnail(File('a.jpg'), edge: kPhotoEdgeSmall);

      expect(large, isA<ResizeImage>());
      expect((large as ResizeImage).width, 960);
      expect(large.height, 960);
      expect(large.policy, ResizeImagePolicy.fit);
      expect((small as ResizeImage).width, 240);
    });

    test('the viewer gets the original back', () {
      final thumb = photoThumbnail(File('a.jpg'), edge: kPhotoEdgeSmall);

      expect(fullResolution(thumb), isA<FileImage>());
      final plain = FileImage(File('b.jpg'));
      expect(fullResolution(plain), same(plain));
    });
  });

  group('cleanNotes', () {
    test('blank notes are stored as nothing', () {
      expect(cleanNotes(null), isNull);
      expect(cleanNotes('   '), isNull);
    });

    test('notes are trimmed and capped', () {
      expect(cleanNotes('  blue cap  '), 'blue cap');
      expect(cleanNotes('x' * 400), hasLength(kNotesMaxLength));
    });

    test('the cap never splits an emoji', () {
      final notes = cleanNotes('${'x' * (kNotesMaxLength - 1)}🪛🪛');

      expect(notes!.endsWith('🪛'), isTrue);
      expect(notes.characters.length, kNotesMaxLength);
    });
  });

  group('SpecDraft name and notes', () {
    const base = (type: AddType.home, kind: SpecKind.bulb, zone: 'Home');

    test('a carried name wins over the type and kind', () {
      final row = objectDraftFrom(
        SpecDraft(
          type: base.type,
          kind: base.kind,
          value: 'B22',
          zone: base.zone,
          name: '  Bedroom bulb ',
          notes: ' warm white ',
        ),
      );

      expect(row.name.value, 'Bedroom bulb');
      expect(row.notes.value, 'warm white');
    });

    test('no name falls back to type and kind, and no notes stay null', () {
      final row = objectDraftFrom(
        SpecDraft(
          type: base.type,
          kind: base.kind,
          value: 'B22',
          zone: base.zone,
        ),
      );

      expect(row.name.value, isNot(isEmpty));
      expect(row.notes.value, isNull);
    });
  });
}
