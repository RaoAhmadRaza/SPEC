import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:spec/add/add_fields_sheet.dart';
import 'package:spec/add/add_value_field.dart';
import 'package:spec/data/db/spec_database.dart';
import 'package:spec/data/models/spec_models.dart';
import 'package:spec/data/photo_store.dart';
import 'package:spec/onboarding/capture_frame.dart';
import 'package:spec/onboarding/onboarding_routes.dart';
import 'package:spec/providers/database.dart';
import 'package:spec/providers/onboarding.dart';
import 'package:spec/providers/photos.dart';
import 'package:spec/services/photo_capture.dart';

import '../support/prefs.dart';

/// The canvas every number in the design is measured against.
const _canvas = Size(402, 874);

/// A one-pixel PNG, so Image.file has something real to decode.
final _pixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAE'
  'hQGAhKmMIQAAAABJRU5ErkJggg==',
);

/// Stands in for the platform picker, which cannot open in a widget test.
class _StubCapture implements PhotoCapture {
  _StubCapture(this.result);

  final File? result;

  @override
  Future<File?> takePhoto() async => result;

  @override
  Future<File?> pickFromLibrary() async => result;
}

void main() {
  setUp(useInMemoryPrefs);

  Future<ProviderContainer> pumpRoute(
    WidgetTester tester, {
    required File? photo,
    required Directory photosDirectory,
  }) async {
    tester.view
      ..physicalSize = _canvas * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final database = SpecDatabase.memory();
    addTearDown(database.close);

    final container = ProviderContainer(
      overrides: [
        specDatabaseProvider.overrideWith((ref) async => database),
        photoStoreProvider.overrideWith(
          (ref) async => PhotoStore(photosDirectory),
        ),
        photoCaptureProvider.overrideWith((ref) => _StubCapture(photo)),
      ],
    );
    addTearDown(container.dispose);
    await container.read(specDatabaseProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: FirstObjectRoute()),
      ),
    );
    return container;
  }

  /// The screen's ambient loops never end, so pumpAndSettle would hang.
  Future<void> pumpFrames(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  testWidgets('a captured photo appears in the frame', (tester) async {
    // Arrange
    final directory = Directory.systemTemp.createTempSync('spec_photos');
    addTearDown(() => directory.deleteSync(recursive: true));
    final shot = File(p.join(directory.path, 'shot.png'))
      ..writeAsBytesSync(_pixel);
    await pumpRoute(tester, photo: shot, photosDirectory: directory);

    // Act
    await tester.tap(find.byType(CaptureFrame));
    await pumpFrames(tester);

    // Assert
    final preview = tester
        .widget<CaptureFrame>(find.byType(CaptureFrame))
        .preview;
    // The whole label shows: a cover crop cuts a portrait shot's text.
    expect(preview, isA<Image>().having((i) => i.fit, 'fit', BoxFit.contain));
  });

  /// ADD MY FIRST OBJECT reads the zones before step 05 can rise.
  Future<void> openFields(WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.tap(find.text('ADD MY FIRST OBJECT'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  Future<void> typeSpecAndSave(WidgetTester tester, String spec) async {
    await tester.enterText(
      find.descendant(
        of: find.byType(AddValueField),
        matching: find.byType(EditableText),
      ),
      spec,
    );
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.text('SAVE'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await pumpFrames(tester);
  }

  Future<List<ObjectSummary>> objectsIn(
    WidgetTester tester,
    ProviderContainer container,
  ) async => (await tester.runAsync(
    () => container.read(objectRepositoryProvider).all(),
  ))!;

  testWidgets('the chip and photo open step 05, and SAVE keeps the spec', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync('spec_photos');
    addTearDown(() => directory.deleteSync(recursive: true));
    final shot = File(p.join(directory.path, 'shot.png'))
      ..writeAsBytesSync(_pixel);
    final container = await pumpRoute(
      tester,
      photo: shot,
      photosDirectory: directory,
    );
    await tester.tap(find.byType(CaptureFrame));
    await pumpFrames(tester);

    await openFields(tester);
    expect(find.byType(AddFieldsSheet), findsOneWidget);
    // No zones exist yet during onboarding, so the object's type decides —
    // not whichever starter zone happens to be first.
    expect(find.text('BULB · OTHER'), findsOneWidget);
    expect(
      tester.widget<AddFieldsSheet>(find.byType(AddFieldsSheet)).photo,
      shot,
    );
    expect(container.read(onboardingCompletedProvider).value, isNot(isTrue));

    await typeSpecAndSave(tester, 'E27');

    final objects = await objectsIn(tester, container);
    expect(objects.single.name, 'Bulb');
    expect(objects.single.specValue, 'E27');
    expect(objects.single.specKind, SpecKind.model);
    expect(objects.single.libraryTerm, 'Bulb');
    expect(objects.single.zoneName, 'Other');
    expect(objects.single.photoFileName, isNotNull);
    expect(container.read(onboardingCompletedProvider).value, isTrue);
  });

  testWidgets('dismissing step 05 writes nothing and stays on 11', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync('spec_photos');
    addTearDown(() => directory.deleteSync(recursive: true));
    final container = await pumpRoute(
      tester,
      photo: null,
      photosDirectory: directory,
    );

    await openFields(tester);
    // Above the sheet's top edge: the backdrop.
    await tester.tapAt(const Offset(200, 40));
    await pumpFrames(tester);
    await pumpFrames(tester);

    expect(find.byType(AddFieldsSheet), findsNothing);
    expect(find.text('ADD MY FIRST OBJECT'), findsOneWidget);
    expect(await objectsIn(tester, container), isEmpty);
    expect(container.read(onboardingCompletedProvider).value, isNot(isTrue));
  });

  testWidgets('refusing the camera still lets onboarding finish', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync('spec_photos');
    addTearDown(() => directory.deleteSync(recursive: true));
    final container = await pumpRoute(
      tester,
      photo: null,
      photosDirectory: directory,
    );

    await tester.tap(find.byType(CaptureFrame));
    await pumpFrames(tester);
    await openFields(tester);
    await typeSpecAndSave(tester, '205/55 R16');

    final objects = await objectsIn(tester, container);
    expect(objects.single.photoFileName, isNull);
    expect(container.read(onboardingCompletedProvider).value, isTrue);
  });
}
