import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/add/add_icons.dart';
import 'package:spec/add/add_what_sheet.dart';
import 'package:spec/add/photo_drop_card.dart';
import 'package:spec/add/type_tile.dart';
import 'package:spec/theme/spec_tokens.dart';

import '../support/fonts.dart';
import '../support/responsive.dart';

/// The canvas every number in the brief is measured against.
const _canvas = Size(402, 874);

/// Long enough for the staggered entrance and every tile treatment to settle.
const _settle = Duration(milliseconds: 1200);

const _labels = ['Product', 'Device', 'Car', 'Home', 'Clothing', 'Other'];

Future<void> _pumpSheet(
  WidgetTester tester, {
  AddType initialType = defaultAddType,
  void Function(AddType, File?)? onContinue,
  Future<File?> Function()? pickPhoto,
  bool disableAnimations = false,
}) async {
  tester.view
    ..physicalSize = _canvas * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: _canvas, disableAnimations: disableAnimations),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: AddWhatSheet(
            initialType: initialType,
            pickPhoto: pickPhoto,
            onContinue: onContinue ?? (_, _) {},
          ),
        ),
      ),
    ),
  );
}

Finder _tile(String label) => find.widgetWithText(TypeTile, label);

bool _isSelected(WidgetTester tester, String label) =>
    tester.widget<TypeTile>(_tile(label)).isSelected;

BoxDecoration _tileDecoration(WidgetTester tester, String label) {
  final box = find
      .descendant(of: _tile(label), matching: find.byType(Container))
      .first;
  return tester.widget<Container>(box).decoration! as BoxDecoration;
}

double _opacityAbove(WidgetTester tester, Finder of) {
  final finder = find.ancestor(of: of, matching: find.byType(Opacity)).first;
  return tester.widget<Opacity>(finder).opacity;
}

/// How many tiles share the top edge of the first, which is the column count.
int _gridColumns(WidgetTester tester) {
  final tiles = find.byType(TypeTile);
  final tops = [
    for (var i = 0; i < tiles.evaluate().length; i++)
      tester.getRect(tiles.at(i)).top,
  ];
  return tops.where((top) => (top - tops.first).abs() < 1).length;
}

Future<void> _pumpResponsiveWhat(
  WidgetTester tester, {
  required Size canvas,
}) async {
  tester.view
    ..physicalSize = canvas * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: canvas),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: AddWhatSheet(
            initialType: defaultAddType,
            onContinue: (_, _) {},
          ),
        ),
      ),
    ),
  );
  await tester.pump(_settle);
}

void main() {
  setUpAll(loadSpecFonts);

  group('responsive', () {
    testWidgets('type grid uses three columns at the reference canvas', (
      tester,
    ) async {
      // Arrange / Act
      await _pumpResponsiveWhat(tester, canvas: specReferenceCanvas);

      // Assert
      expect(_gridColumns(tester), 3);
      expectNoOverflow(tester);
    });

    testWidgets('type grid gains a column on a portrait tablet', (
      tester,
    ) async {
      // Arrange / Act
      await _pumpResponsiveWhat(
        tester,
        canvas: specCanvases['tabletPortrait']!,
      );

      // Assert
      expect(_gridColumns(tester), greaterThan(3));
      expectNoOverflow(tester);
    });
  });

  group('layout', () {
    testWidgets('blocks hold their design heights at 402pt', (tester) async {
      await _pumpSheet(tester);
      await tester.pump(_settle);

      expect(tester.getSize(find.byType(AddWhatSheet)).width, 402);
      expect(tester.getSize(find.byType(PhotoDropCard)).height, 132);
      for (final label in _labels) {
        expect(tester.getSize(_tile(label)).height, 96);
      }
      final button = find
          .ancestor(of: find.text('CONTINUE'), matching: find.byType(Container))
          .first;
      expect(tester.getSize(button).height, 56);
      expect(tester.takeException(), isNull);
    });

    testWidgets('content sits 22pt in from either side', (tester) async {
      await _pumpSheet(tester);
      await tester.pump(_settle);

      final card = tester.getRect(find.byType(PhotoDropCard));
      expect(card.left, 22);
      expect(card.right, 402 - 22);
    });

    testWidgets('the grid is three equal columns with 9pt gaps', (
      tester,
    ) async {
      await _pumpSheet(tester);
      await tester.pump(_settle);

      final product = tester.getRect(_tile('Product'));
      final device = tester.getRect(_tile('Device'));
      final car = tester.getRect(_tile('Car'));
      final home = tester.getRect(_tile('Home'));

      expect(device.left - product.right, closeTo(9, 0.01));
      expect(car.left - device.right, closeTo(9, 0.01));
      expect(product.width, closeTo(device.width, 0.01));
      expect(device.width, closeTo(car.width, 0.01));
      expect(home.top - product.bottom, closeTo(9, 0.01));
    });

    testWidgets('the empty photo card shows only the chip', (tester) async {
      await _pumpSheet(tester);
      await tester.pump(_settle);

      final texts = find.descendant(
        of: find.byType(PhotoDropCard),
        matching: find.byType(Text),
      );
      // `+ PHOTO` plus the zero-scaled clear disc's glyph, and nothing else.
      expect(
        tester.widgetList<Text>(texts).map((t) => t.data),
        unorderedEquals(['+ PHOTO', '×']),
      );
      expect(
        find.descendant(
          of: find.byType(PhotoDropCard),
          matching: find.byType(Image),
        ),
        findsNothing,
      );
    });

    testWidgets('only the photo card takes the cut corner', (tester) async {
      await _pumpSheet(tester);
      await tester.pump(_settle);

      final tileRadius = _tileDecoration(
        tester,
        'Car',
      ).borderRadius!.resolve(TextDirection.ltr);
      expect(tileRadius.bottomLeft, const Radius.circular(18));
      expect(tileRadius.topRight, const Radius.circular(18));

      final card = find
          .descendant(
            of: find.byType(PhotoDropCard),
            matching: find.byType(Container),
          )
          .first;
      final cardRadius =
          (tester.widget<Container>(card).decoration! as BoxDecoration)
              .borderRadius!
              .resolve(TextDirection.ltr);
      expect(cardRadius.bottomLeft, const Radius.circular(6));
      expect(cardRadius.topLeft, const Radius.circular(20));
    });
  });

  group('selection', () {
    testWidgets('opens on Device when nothing upstream knows better', (
      tester,
    ) async {
      await _pumpSheet(tester);
      await tester.pump(_settle);

      expect(_isSelected(tester, 'Device'), isTrue);
      expect(_labels.where((l) => _isSelected(tester, l)), ['Device']);
    });

    testWidgets('pre-selects whatever the caller knows', (tester) async {
      await _pumpSheet(tester, initialType: AddType.car);
      await tester.pump(_settle);

      expect(_labels.where((l) => _isSelected(tester, l)), ['Car']);
    });

    testWidgets('exactly one tile is ever selected', (tester) async {
      await _pumpSheet(tester);
      await tester.pump(_settle);

      for (final label in ['Car', 'Other', 'Other', 'Product']) {
        await tester.tap(_tile(label));
        await tester.pump(_settle);
        expect(_labels.where((l) => _isSelected(tester, l)), [label]);
      }
    });

    testWidgets('selecting a tile does not reflow the grid', (tester) async {
      await _pumpSheet(tester);
      await tester.pump(_settle);
      final before = [for (final l in _labels) tester.getRect(_tile(l))];

      await tester.tap(_tile('Clothing'));
      await tester.pump(_settle);
      final after = [for (final l in _labels) tester.getRect(_tile(l))];

      expect(after, before);
    });

    testWidgets('the selected tile is a lime outline with a white label', (
      tester,
    ) async {
      await _pumpSheet(tester);
      await tester.pump(_settle);

      final selected = _tileDecoration(tester, 'Device');
      final border = selected.border! as Border;
      expect(border.top.color, SpecColors.accent);
      expect(border.top.width, 1.5);
      expect(selected.color, isNot(SpecColors.accent));

      final label = tester.widget<Text>(
        find.descendant(of: _tile('Device'), matching: find.text('Device')),
      );
      expect(label.style!.color, SpecColors.ink);
      expect(label.style!.fontWeight, FontWeight.w600);

      final idle = _tileDecoration(tester, 'Car').border! as Border;
      expect(idle.top.width, 1);
    });

    testWidgets('a long label ellipsizes rather than widening its column', (
      tester,
    ) async {
      tester.view
        ..physicalSize = _canvas * 3
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 112,
              child: TypeTile(
                type: AddType.other,
                label: 'Vêtements et accessoires',
                isSelected: false,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(TypeTile)).width, 112);
      expect(tester.takeException(), isNull);
    });
  });

  group('photo', () {
    testWidgets('the clear disc never scales through zero on its way out', (
      tester,
    ) async {
      await _pumpSheet(tester, pickPhoto: () async => File('picked.jpg'));
      await tester.pump(_settle);
      await tester.tap(find.byType(PhotoDropCard));
      await tester.pump();
      await tester.pump(_settle);

      await tester.tap(find.text('×'));
      for (var ms = 0; ms <= 200; ms += 10) {
        await tester.pump(const Duration(milliseconds: 10));
        final disc = find
            .ancestor(of: find.text('×'), matching: find.byType(Transform))
            .first;
        final scale = tester.widget<Transform>(disc).transform.storage.first;
        expect(scale, greaterThanOrEqualTo(0), reason: 'at ${ms}ms');
      }
    });
  });

  group('semantics', () {
    testWidgets('only the selected tile is announced as selected', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pumpSheet(tester);
      await tester.pump(_settle);

      expect(
        tester.getSemantics(_tile('Device')),
        matchesSemantics(
          label: 'Device',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(_tile('Car')),
        matchesSemantics(
          label: 'Car',
          isButton: true,
          hasSelectedState: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });
  });

  group('continue', () {
    testWidgets('carries the selected type forward with no photo', (
      tester,
    ) async {
      AddType? type;
      File? photo = File('sentinel');
      await _pumpSheet(
        tester,
        onContinue: (t, p) {
          type = t;
          photo = p;
        },
      );
      await tester.pump(_settle);

      await tester.tap(_tile('Home'));
      await tester.pump(_settle);
      await tester.tap(find.text('CONTINUE'));

      expect(type, AddType.home);
      expect(photo, isNull);
    });

    testWidgets('carries a picked photo forward, and clearing drops it', (
      tester,
    ) async {
      final picked = File('picked.jpg');
      File? photo;
      await _pumpSheet(
        tester,
        pickPhoto: () async => picked,
        onContinue: (_, p) => photo = p,
      );
      await tester.pump(_settle);

      await tester.tap(find.byType(PhotoDropCard));
      // The pick resolves in a microtask: one frame to start the × scaling
      // in, then time for it to land.
      await tester.pump();
      await tester.pump(_settle);
      expect(find.text('RETAKE'), findsOneWidget);

      await tester.tap(find.text('CONTINUE'));
      expect(photo, picked);

      await tester.tap(find.text('×'));
      await tester.pump();
      await tester.pump(_settle);
      expect(find.text('+ PHOTO'), findsOneWidget);

      await tester.tap(find.text('CONTINUE'));
      expect(photo, isNull);
    });
  });

  group('motion', () {
    testWidgets('content waits for the sheet, then CONTINUE lands last', (
      tester,
    ) async {
      await _pumpSheet(tester);

      expect(_opacityAbove(tester, find.text('CONTINUE')), 0);

      await tester.pump(const Duration(milliseconds: 300));
      final question = _opacityAbove(
        tester,
        find.text('What are you\nremembering?'),
      );
      final button = _opacityAbove(tester, find.text('CONTINUE'));
      expect(question, greaterThan(button));

      await tester.pump(_settle);
      expect(_opacityAbove(tester, find.text('CONTINUE')), 1);
    });

    testWidgets('reduced motion: a 200ms fade with no travel', (tester) async {
      await _pumpSheet(tester, disableAnimations: true);
      await tester.pump(const Duration(milliseconds: 200));

      expect(_opacityAbove(tester, find.text('CONTINUE')), 1);
      final lift = tester
          .widget<Transform>(
            find
                .ancestor(
                  of: find.text('CONTINUE'),
                  matching: find.byType(Transform),
                )
                .first,
          )
          .transform
          .getTranslation()
          .y;
      expect(lift, 0);
    });

    testWidgets('reduced motion: selection snaps in a single frame', (
      tester,
    ) async {
      await _pumpSheet(tester, disableAnimations: true);
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(_tile('Car'));
      await tester.pump();

      final border = _tileDecoration(tester, 'Car').border! as Border;
      expect(border.top.color, SpecColors.accent);
    });
  });
}
