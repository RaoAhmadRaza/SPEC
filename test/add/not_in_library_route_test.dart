import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/add/library_search_pill.dart';
import 'package:spec/add/manual_heroes.dart';
import 'package:spec/add/not_in_library_route.dart';
import 'package:spec/add/not_in_library_screen.dart';
import 'package:spec/add/plain_field_theme.dart';
import 'package:spec/search/search_header.dart';

import '../support/fonts.dart';

const _canvas = Size(402, 874);
const _settle = Duration(milliseconds: 1200);

/// A stand-in for 07: the same header and pill, on the same gutter.
class _LibraryStub extends StatefulWidget {
  const _LibraryStub();

  @override
  State<_LibraryStub> createState() => _LibraryStubState();
}

class _LibraryStubState extends State<_LibraryStub> {
  final _query = TextEditingController(text: 'moka pot gasket');
  final _focus = FocusNode();

  @override
  void dispose() {
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0A0B0C),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 56, 18, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DefaultTextStyle(
              style: TextStyle(),
              child: Hero(
                tag: kAddStepHeaderTag,
                flightShuttleBuilder: keepTextStyleShuttle,
                child: SearchHeaderRow(label: 'STEP 1 / 3'),
              ),
            ),
            const SizedBox(height: 16),
            LibrarySearchPill(controller: _query, focusNode: _focus),
            const SizedBox(height: 40),
            Builder(
              builder: (context) => GestureDetector(
                onTap: () => Navigator.of(context).push(
                  notInLibraryPageRoute(
                    context: context,
                    builder: (context) => NotInLibraryScreen(
                      query: 'moka pot gasket',
                      onAdd: (_) => Navigator.of(context).push(_fieldsStub()),
                    ),
                  ),
                ),
                child: const Text('GO'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A stand-in for 05: an 86pt photo slot and a context row to land in.
PageRoute<void> _fieldsStub() => PageRouteBuilder<void>(
  transitionDuration: const Duration(milliseconds: 420),
  pageBuilder: (context, _, _) => const Material(
    color: Color(0xFF0A0B0C),
    child: Padding(
      padding: EdgeInsets.fromLTRB(22, 120, 22, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(tag: kManualPhotoTag, child: SizedBox(width: 86, height: 86)),
          SizedBox(width: 14),
          Hero(tag: kManualNameTag, child: Text('MOKA POT GASKET')),
        ],
      ),
    ),
  ),
  transitionsBuilder: (context, animation, _, child) =>
      FadeTransition(opacity: animation, child: child),
);

Future<void> _pumpLibrary(
  WidgetTester tester, {
  bool disableAnimations = false,
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
      home: const _LibraryStub(),
    ),
  );
}

Future<void> _push(WidgetTester tester) async {
  await tester.tap(find.text('GO'));
  await tester.pump();
  await tester.pump();
}

double _visibility(WidgetTester tester, Finder of) => tester
    .widgetList<Opacity>(find.ancestor(of: of, matching: find.byType(Opacity)))
    .fold(1.0, (value, opacity) => value * opacity.opacity);

void main() {
  setUpAll(loadSpecFonts);

  testWidgets('the header and the pill hold perfectly still through the push', (
    tester,
  ) async {
    await _pumpLibrary(tester);
    final header = tester.getRect(find.text('STEP 1 / 3'));
    final pill = tester.getRect(find.byType(LibrarySearchPill));

    await _push(tester);
    for (var ms = 0; ms < 380; ms += 40) {
      await tester.pump(const Duration(milliseconds: 40));
      for (final element in find.text('STEP 1 / 3').evaluate()) {
        final box = element.renderObject! as RenderBox;
        final rect = box.localToGlobal(Offset.zero) & box.size;
        expect(rect, header, reason: 'header at ${ms}ms');
      }
    }
    await tester.pump(_settle);
    expect(tester.getRect(find.text('STEP 1 / 3')), header);
    expect(tester.getRect(find.byType(LibrarySearchPill)), pill);
  });

  testWidgets('the page under them enters from +40', (tester) async {
    await _pumpLibrary(tester);
    await _push(tester);
    await tester.pump(const Duration(milliseconds: 40));

    final early = tester
        .widget<Transform>(
          find
              .ancestor(
                of: find.byType(NotInLibraryScreen),
                matching: find.byType(Transform),
              )
              .first,
        )
        .transform
        .getTranslation()
        .x;
    expect(early, inExclusiveRange(0, 40));

    await tester.pump(_settle);
    await tester.pump(_settle);
    expect(tester.takeException(), isNull);
  });

  testWidgets('on commit the spec fades in place while photo and name fly', (
    tester,
  ) async {
    await _pumpLibrary(tester);
    await _push(tester);
    await tester.pump(_settle);
    await tester.pump(_settle);

    await tester.enterText(
      find.descendant(
        of: find.widgetWithText(Row, 'SPEC'),
        matching: find.byType(TextField),
      ),
      '3 cup · 60 mm',
    );
    await tester.pump();

    await tester.tap(find.text('ADD MANUALLY'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Past both fades but short of 420: the spec and the chrome are gone, and
    // the name is still mid-flight, uppercased.
    expect(_visibility(tester, find.text('3 cup · 60 mm')), 0);
    expect(find.text('MOKA POT GASKET'), findsWidgets);
    expect(find.text('NOTHING LEAVES THIS PHONE').evaluate(), isNotEmpty);
    expect(_visibility(tester, find.text('NOTHING LEAVES THIS PHONE')), 0);

    await tester.pump(_settle);
    expect(tester.takeException(), isNull);
  });

  for (final isReduced in [false, true]) {
    testWidgets(
      isReduced
          ? 'reduce motion grounds every hero'
          : 'with motion on, the heroes are free to fly',
      (tester) async {
        await _pumpLibrary(tester, disableAnimations: isReduced);
        await _push(tester);
        await tester.pump(_settle);

        final mode = tester.widget<HeroMode>(
          find.descendant(
            of: find.byType(NotInLibraryScreen),
            matching: find.byType(HeroMode),
          ),
        );
        expect(mode.enabled, !isReduced);
      },
    );
  }

  testWidgets('back pops to 07 in 360ms', (tester) async {
    await _pumpLibrary(tester);
    await _push(tester);
    await tester.pump(_settle);
    await tester.pump(_settle);

    unawaited(tester.state<NavigatorState>(find.byType(Navigator)).maybePop());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 361));
    await tester.pump();
    expect(find.byType(NotInLibraryScreen), findsNothing);
    expect(find.text('GO'), findsOneWidget);
  });
}
