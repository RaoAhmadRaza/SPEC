import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/add/library_search_pill.dart';
import 'package:spec/add/manual_add_button.dart';
import 'package:spec/add/manual_field_row.dart';
import 'package:spec/add/manual_return_bar.dart';
import 'package:spec/add/manual_tokens.dart';
import 'package:spec/add/not_in_library_screen.dart';
import 'package:spec/add/photo_drop_card.dart';
import 'package:spec/theme/spec_layout.dart';

import '../support/fonts.dart';
import '../support/responsive.dart';

const _canvas = Size(402, 874);

/// Past the 152ms delay, the 620ms entrance and the 520ms focus.
const _settle = Duration(milliseconds: 1200);

const _caret = ValueKey('square-caret');
const _hint = 'NO PHOTO — THIS OBJECT WILL SHOW A BLANK TILE';

Future<void> _pumpScreen(
  WidgetTester tester, {
  String query = 'moka pot gasket',
  ValueChanged<ManualDraft>? onAdd,
  int Function(String)? countLibraryMatches,
  Future<File?> Function()? pickPhoto,
  VoidCallback? onCancel,
  ValueChanged<String>? onReturnToLibrary,
  bool disableAnimations = false,
  bool settle = true,
}) async {
  tester.view
    ..physicalSize = _canvas * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(disableAnimations: disableAnimations),
        child: child!,
      ),
      home: NotInLibraryScreen(
        query: query,
        onAdd: onAdd ?? (_) {},
        countLibraryMatches: countLibraryMatches ?? (_) => 0,
        pickPhoto: pickPhoto,
        onCancel: onCancel,
        onReturnToLibrary: onReturnToLibrary,
      ),
    ),
  );
  if (settle) await _run(tester, _settle);
}

/// One frame for whatever was just triggered to start, then [duration] for
/// it to run. A single long pump only ever builds the starting frame.
Future<void> _run(WidgetTester tester, Duration duration) async {
  await tester.pump();
  await tester.pump(duration);
  await tester.pump(duration);
}

Finder _row(String label) => find.widgetWithText(ManualFieldRow, label);

Finder _fieldIn(Finder of) =>
    find.descendant(of: of, matching: find.byType(TextField));

Finder get _searchField => _fieldIn(find.byType(LibrarySearchPill));

bool _isEnabled(WidgetTester tester) =>
    tester.widget<ManualAddButton>(find.byType(ManualAddButton)).isEnabled;

double _hintOpacity(WidgetTester tester) => tester
    .widget<AnimatedOpacity>(
      find.ancestor(
        of: find.text(_hint),
        matching: find.byType(AnimatedOpacity),
      ),
    )
    .opacity;

/// The product of every [Opacity] above [of] — what the eye actually gets.
double _visibility(WidgetTester tester, Finder of) {
  return tester
      .widgetList<Opacity>(
        find.ancestor(of: of, matching: find.byType(Opacity)),
      )
      .fold(1.0, (value, opacity) => value * opacity.opacity);
}

BorderRadius _rowRadius(WidgetTester tester, String label) =>
    tester.widget<ManualFieldRow>(_row(label)).borderRadius;

/// The pinned block's box: from the return bar's top to the privacy line's
/// bottom, which is the whole thing the fields must stay clear of.
Rect _bottomBlock(WidgetTester tester) {
  final bar = tester.getRect(find.byType(ManualReturnBar));
  final caption = tester.getRect(find.text('NOTHING LEAVES THIS PHONE'));
  return Rect.fromLTRB(bar.left, bar.top, bar.right, caption.bottom);
}

/// The same screen on an arbitrary canvas, with real insets.
///
/// The reveal schedules two post-frame callbacks, and the suite never uses
/// `pumpAndSettle` (the caret blinks forever), so this pumps fixed rounds.
Future<void> _pumpResponsiveScreen(
  WidgetTester tester, {
  required Size canvas,
  EdgeInsets padding = EdgeInsets.zero,
  EdgeInsets viewInsets = EdgeInsets.zero,
  double textScale = 1.0,
}) async {
  tester.view
    ..physicalSize = canvas * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: canvas,
          padding: padding,
          viewPadding: padding,
          viewInsets: viewInsets,
          textScaler: TextScaler.linear(textScale),
        ),
        child: NotInLibraryScreen(
          query: 'moka pot gasket',
          onAdd: (_) {},
          countLibraryMatches: (_) => 0,
        ),
      ),
    ),
  );
  await _run(tester, _settle);
}

void main() {
  setUpAll(loadSpecFonts);

  group('responsive', () {
    testWidgets('photo card is 210pt tall at the reference canvas with no '
        'keyboard', (tester) async {
      // Arrange / Act
      await _pumpResponsiveScreen(tester, canvas: specReferenceCanvas);

      // Assert: the ceiling is a no-op at the canvas it was drawn against.
      expect(tester.getSize(find.byType(PhotoDropCard)).height, 210.0);
    });

    for (final name in ['tiny', 'ref', 'tabletLandscape']) {
      testWidgets('focused SPEC field is never covered by the pinned block '
          'on $name', (tester) async {
        // Arrange
        final canvas = specCanvases[name]!;
        await _pumpResponsiveScreen(
          tester,
          canvas: canvas,
          viewInsets: const EdgeInsets.only(bottom: 300),
        );

        // Act: the reveal runs across two post-frame callbacks, then animates.
        await tester.tap(_fieldIn(_row('SPEC')));
        await _run(tester, _settle);

        // Assert
        expect(
          tester.getRect(_row('SPEC')).overlaps(_bottomBlock(tester)),
          isFalse,
          reason: name,
        );
      });
    }

    testWidgets('bottom block clears a 34pt home indicator when the keyboard '
        'is closed', (tester) async {
      // Arrange / Act
      await _pumpResponsiveScreen(
        tester,
        canvas: specReferenceCanvas,
        padding: const EdgeInsets.only(bottom: 34),
      );

      // Assert
      expect(
        specReferenceCanvas.height - _bottomBlock(tester).bottom,
        greaterThanOrEqualTo(34.0),
      );
    });

    testWidgets('bottom block is not pushed too high when the keyboard is '
        'open', (tester) async {
      // Arrange / Act: both insets set at once.
      await _pumpResponsiveScreen(
        tester,
        canvas: specReferenceCanvas,
        padding: const EdgeInsets.only(bottom: 34),
        viewInsets: const EdgeInsets.only(bottom: 300),
      );

      // Assert: the keyboard already covers the indicator, so the block sits
      // at exactly 300 — not 334.
      expect(
        specReferenceCanvas.height - _bottomBlock(tester).bottom,
        closeTo(300.0, 0.01),
      );
    });

    testWidgets('field label does not clip at text scale 1.5', (tester) async {
      // Arrange / Act
      await _pumpResponsiveScreen(
        tester,
        canvas: specCanvases['tiny']!,
        textScale: 1.5,
      );

      // Assert
      expect(find.text('SPEC'), findsWidgets);
      expectNoOverflow(tester);
    });

    testWidgets('content and bottom block are capped on a landscape tablet', (
      tester,
    ) async {
      // Arrange
      final canvas = specCanvases['tabletLandscape']!;

      // Act
      await _pumpResponsiveScreen(tester, canvas: canvas);

      // Assert
      final block = _bottomBlock(tester);
      expect(block.width, lessThanOrEqualTo(SpecLayout.maxContentWidth));
      expect(block.center.dx, closeTo(canvas.width / 2, 0.5));
      expect(
        tester.getSize(find.byType(PhotoDropCard)).width,
        lessThanOrEqualTo(SpecLayout.maxContentWidth),
      );
    });
  });

  group('filled', () {
    testWidgets('lays out on the 402pt canvas without overflow', (
      tester,
    ) async {
      await _pumpScreen(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('STEP 1 / 3'), findsOneWidget);
      expect(tester.getSize(find.byType(PhotoDropCard)).height, 210);
      expect(tester.getSize(find.byType(ManualAddButton)).height, 58);

      final caption = tester.getRect(find.text('NOTHING LEAVES THIS PHONE'));
      expect(caption.bottom, closeTo(874 - 24, 0.5));
      expect(tester.getRect(find.byType(ManualAddButton)).left, 16);
    });

    testWidgets('carries the query, title-cased into NAME', (tester) async {
      await _pumpScreen(tester);

      expect(find.text('0 MATCHES IN LIBRARY'), findsOneWidget);
      expect(find.text('NOT IN\nTHE LIST.'), findsOneWidget);
      expect(
        tester.widget<TextField>(_searchField).controller!.text,
        'moka pot gasket',
      );
      expect(
        tester.widget<TextField>(_fieldIn(_row('NAME'))).controller!.text,
        'Moka pot gasket',
      );
    });

    testWidgets('only the card cuts bottom-left; the rows mirror', (
      tester,
    ) async {
      await _pumpScreen(tester);

      final card = tester.widget<PhotoDropCard>(find.byType(PhotoDropCard));
      expect(card.borderRadius.bottomLeft, const Radius.circular(6));
      expect(card.borderRadius.topLeft, const Radius.circular(22));
      expect(card.borderRadius.bottomRight, const Radius.circular(22));

      expect(_rowRadius(tester, 'NAME').bottomLeft, const Radius.circular(5));
      expect(_rowRadius(tester, 'NAME').bottomRight, const Radius.circular(18));
      expect(_rowRadius(tester, 'SPEC').bottomRight, const Radius.circular(5));
      expect(_rowRadius(tester, 'SPEC').bottomLeft, const Radius.circular(18));
    });

    testWidgets('both values start on the same x', (tester) async {
      await _pumpScreen(tester);

      final name = tester.getTopLeft(_fieldIn(_row('NAME'))).dx;
      final spec = tester.getTopLeft(_fieldIn(_row('SPEC'))).dx;
      expect(name, spec);
      // 18 gutter + 1 border + 16 padding + 56 label + 12 gap.
      expect(name, 18 + 1 + 16 + 56 + 12);
    });

    testWidgets('the empty photo card carries only the chip', (tester) async {
      await _pumpScreen(tester);

      final texts = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(PhotoDropCard),
              matching: find.byType(Text),
            ),
          )
          .map((text) => text.data);
      expect(texts, unorderedEquals(['+ PHOTO', '×']));
    });
  });

  group('arrived with no query', () {
    testWidgets('says ADD YOUR OWN, drops the count, keeps the rule', (
      tester,
    ) async {
      await _pumpScreen(tester, query: '');

      expect(find.text('0 MATCHES IN LIBRARY'), findsNothing);
      expect(find.text('ADD YOUR\nOWN.'), findsOneWidget);
      expect(
        find.text(
          'Photograph it and give it a name. SPEC keeps both on this phone.',
        ),
        findsOneWidget,
      );
      expect(find.text('What is it called?'), findsWidgets);
    });

    testWidgets('everything empty: disabled, silent, promise intact', (
      tester,
    ) async {
      var added = 0;
      await _pumpScreen(tester, query: '', onAdd: (_) => added++);

      expect(_isEnabled(tester), isFalse);
      await tester.tap(find.byType(ManualAddButton));
      await tester.pump();
      expect(added, 0);

      expect(_hintOpacity(tester), 0);
      expect(_visibility(tester, find.text('NOTHING LEAVES THIS PHONE')), 1);
    });
  });

  group('no photo', () {
    testWidgets('a pre-filled, untouched name does not nag', (tester) async {
      await _pumpScreen(tester);

      expect(_hintOpacity(tester), 0);
    });

    testWidgets('typing a name raises the advisory, and a photo clears it', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        query: '',
        pickPhoto: () async => File('photo.jpg'),
      );

      await tester.enterText(_fieldIn(_row('NAME')), 'Gasket');
      await _run(tester, const Duration(milliseconds: 250));
      expect(_hintOpacity(tester), 1);
      expect(_isEnabled(tester), isTrue, reason: 'a photo never blocks');

      await tester.tap(find.byType(PhotoDropCard));
      await tester.pump();
      await _run(tester, const Duration(milliseconds: 300));
      expect(_hintOpacity(tester), 0);
      // The whole label shows: a cover crop cuts a portrait shot's text.
      expect(
        tester
            .widget<Image>(
              find.descendant(
                of: find.byType(PhotoDropCard),
                matching: find.byType(Image),
              ),
            )
            .fit,
        BoxFit.contain,
      );

      await tester.tap(find.text('×'));
      await tester.pump();
      await _run(tester, const Duration(milliseconds: 300));
      expect(_hintOpacity(tester), 1);
    });
  });

  group('adding', () {
    testWidgets('blocks on NAME only; a missing spec is legal', (tester) async {
      ManualDraft? draft;
      await _pumpScreen(tester, onAdd: (d) => draft = d);

      expect(_isEnabled(tester), isTrue);
      await tester.tap(find.byType(ManualAddButton));
      await tester.pump();

      expect(draft?.name, 'Moka pot gasket');
      expect(draft?.spec, '');
      expect(draft?.photo, isNull);
    });

    testWidgets('clearing NAME disables, and never scolds', (tester) async {
      await _pumpScreen(tester);

      await tester.enterText(_fieldIn(_row('NAME')), '   ');
      await _run(tester, const Duration(milliseconds: 250));

      expect(_isEnabled(tester), isFalse);
      expect(_hintOpacity(tester), 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('return on NAME moves to SPEC; return on SPEC submits', (
      tester,
    ) async {
      ManualDraft? draft;
      await _pumpScreen(tester, onAdd: (d) => draft = d);

      await tester.tap(_row('NAME'));
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      expect(
        tester.widget<TextField>(_fieldIn(_row('SPEC'))).focusNode!.hasFocus,
        isTrue,
      );

      await tester.enterText(_fieldIn(_row('SPEC')), '3 cup · 60 mm');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(draft?.spec, '3 cup · 60 mm');
    });
  });

  group('focus and caret', () {
    testWidgets('focus lands on SPEC when NAME arrived filled', (tester) async {
      await _pumpScreen(tester, settle: false);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(_caret), findsNothing);

      await tester.pump(const Duration(milliseconds: 40));
      expect(
        tester.widget<TextField>(_fieldIn(_row('SPEC'))).focusNode!.hasFocus,
        isTrue,
      );
    });

    testWidgets('focus lands on NAME when it arrived empty', (tester) async {
      await _pumpScreen(tester, query: '');

      expect(
        tester.widget<TextField>(_fieldIn(_row('NAME'))).focusNode!.hasFocus,
        isTrue,
      );
    });

    testWidgets('an early tap keeps its focus when the keyboard is due', (
      tester,
    ) async {
      await _pumpScreen(tester, settle: false);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byType(LibrarySearchPill), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        tester.widget<TextField>(_searchField).focusNode!.hasFocus,
        isTrue,
      );
    });

    testWidgets('exactly one caret, wherever focus goes', (tester) async {
      await _pumpScreen(tester);

      for (final target in [
        _row('NAME'),
        find.byType(LibrarySearchPill),
        _row('SPEC'),
      ]) {
        await tester.tap(target);
        await tester.pump();
        expect(find.byKey(_caret), findsOneWidget);
        expect(
          find.descendant(of: target, matching: find.byKey(_caret)),
          findsOneWidget,
        );
      }
    });

    testWidgets('a focused row changes colour, never geometry', (tester) async {
      await _pumpScreen(tester, query: '');
      await tester.tap(find.byType(LibrarySearchPill));
      await _run(tester, _settle);
      final before = tester.getRect(_row('NAME'));

      await tester.tap(_row('NAME'));
      await _run(tester, const Duration(milliseconds: 250));

      expect(tester.getRect(_row('NAME')), before);
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(of: _row('NAME'), matching: find.byType(DecoratedBox))
            .first,
      );
      final border = (box.decoration as BoxDecoration).border! as Border;
      expect(border.top.color, ManualColors.fieldBorderFocused);
    });

    testWidgets('with the keyboard up, the focused field clears the button', (
      tester,
    ) async {
      tester.view.viewInsets = const FakeViewPadding(bottom: 336 * 3);
      addTearDown(tester.view.resetViewInsets);
      await _pumpScreen(tester);

      Future<void> expectClear(String label) async {
        final row = tester.getRect(_row(label));
        final button = tester.getRect(find.byType(ManualAddButton));
        expect(row.top, greaterThanOrEqualTo(0), reason: label);
        expect(row.bottom, lessThanOrEqualTo(button.top), reason: label);
      }

      // Arrives with SPEC focused; the reveal runs once it has settled.
      await _run(tester, const Duration(milliseconds: 400));
      await expectClear('SPEC');

      await tester.showKeyboard(_fieldIn(_row('NAME')));
      await _run(tester, const Duration(milliseconds: 400));
      await expectClear('NAME');

      await tester.showKeyboard(_fieldIn(_row('SPEC')));
      await _run(tester, const Duration(milliseconds: 400));
      await expectClear('SPEC');
    });
  });

  group('return path', () {
    testWidgets('a match again offers the way back, with a live count', (
      tester,
    ) async {
      String? returned;
      await _pumpScreen(
        tester,
        countLibraryMatches: (q) => q.contains('bulb') ? 3 : 0,
        onReturnToLibrary: (q) => returned = q,
      );
      expect(
        tester.widget<ManualReturnBar>(find.byType(ManualReturnBar)).matches,
        0,
      );

      await tester.enterText(_searchField, 'bulb');
      await _run(tester, const Duration(milliseconds: 300));
      expect(find.text('SHOW 3'), findsOneWidget);
      expect(_visibility(tester, find.text('SHOW 3')), 1);

      await tester.tap(find.text('Found it in the library'));
      expect(returned, 'bulb');

      await tester.enterText(_searchField, 'moka');
      await _run(tester, const Duration(milliseconds: 300));
      final gate = tester.widget<IgnorePointer>(
        find
            .descendant(
              of: find.byType(ManualReturnBar),
              matching: find.byType(IgnorePointer),
            )
            .first,
      );
      expect(gate.ignoring, isTrue);
      expect(
        tester.widget<ManualReturnBar>(find.byType(ManualReturnBar)).matches,
        0,
      );
    });

    testWidgets('CANCEL leaves the flow', (tester) async {
      var cancelled = 0;
      await _pumpScreen(tester, onCancel: () => cancelled++);

      await tester.tap(find.text('CANCEL'));
      expect(cancelled, 1);
    });
  });

  group('motion', () {
    testWidgets('the verdict enters; the header was never away', (
      tester,
    ) async {
      await _pumpScreen(tester, settle: false);

      expect(_visibility(tester, find.text('NOT IN\nTHE LIST.')), 0);
      expect(_visibility(tester, find.text('STEP 1 / 3')), 1);
      expect(_visibility(tester, find.byType(LibrarySearchPill)), 1);

      await _run(tester, _settle);
      expect(_visibility(tester, find.text('NOT IN\nTHE LIST.')), 1);
      expect(_visibility(tester, find.text('ADD MANUALLY')), 1);
    });

    testWidgets('reduce motion: a 200ms fade with no travel', (tester) async {
      await _pumpScreen(tester, disableAnimations: true, settle: false);
      await tester.pump(const Duration(milliseconds: 80));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(_visibility(tester, find.text('NOT IN\nTHE LIST.')), 1);
      final lift = tester
          .widget<Transform>(
            find
                .ancestor(
                  of: find.text('NOT IN\nTHE LIST.'),
                  matching: find.byType(Transform),
                )
                .first,
          )
          .transform
          .getTranslation()
          .y;
      expect(lift, 0);
    });
  });

  test('sentence case only lifts the first letter', () {
    expect(sentenceCase('moka pot gasket'), 'Moka pot gasket');
    expect(sentenceCase('  '), '');
    expect(sentenceCase('B22 bulb'), 'B22 bulb');
  });
}
