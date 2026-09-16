import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/collections/collections_tokens.dart';
import 'package:spec/collections/zone_hero.dart';
import 'package:spec/theme/spec_tokens.dart';

import '../support/fonts.dart';

/// Pushes a page holding the chip over a page holding the row name, and
/// returns the flight's text a third of the way and at the end.
Future<void> _flyToChip(WidgetTester tester) async {
  final navigator = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(size: Size(402, 874)),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Navigator(
          key: navigator,
          // The app's WidgetsApp adds this; a bare Navigator flies nothing.
          observers: [HeroController()],
          onGenerateRoute: (_) => PageRouteBuilder<void>(
            pageBuilder: (_, _, _) => Align(
              alignment: Alignment.topLeft,
              child: zoneNameHero(const ZoneHeroLabel(name: 'Home')),
            ),
          ),
        ),
      ),
    ),
  );

  navigator.currentState!.push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (_, _, _) => Align(
        alignment: Alignment.topRight,
        child: zoneNameHero(const ZoneHeroLabel(name: 'Home', isChip: true)),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(loadSpecFonts);

  test('the tag is the lowercased name, so Search can match it by scope', () {
    expect(zoneHeroTag('Home'), zoneHeroTag('HOME'));
  });

  testWidgets(
    'the name flies into the chip: text shrinks, lime fades in late',
    (tester) async {
      // Arrange
      await _flyToChip(tester);

      // Act: a quarter of the way along the eased flight.
      await tester.pump(const Duration(milliseconds: 40));
      final inFlight = find.byWidgetPredicate(
        (w) =>
            w is Text &&
            w.style!.fontSize! > 9.5 &&
            w.style!.fontSize! < CollectionsText.zoneName.fontSize!,
      );
      final early = tester.widget<Text>(inFlight);
      final earlyFill = tester.widget<Container>(
        find.ancestor(of: inFlight, matching: find.byType(Container)).first,
      );
      await tester.pumpAndSettle();

      // Assert
      expect(
        early.style!.fontSize,
        lessThan(CollectionsText.zoneName.fontSize!),
      );
      expect(
        (earlyFill.decoration! as BoxDecoration).color!.a,
        0,
        reason: 'no lime before the back half of the flight',
      );
      final landed = tester.widget<Text>(find.text('HOME'));
      expect(landed.style!.color, SpecColors.onAccent);
    },
  );
}
