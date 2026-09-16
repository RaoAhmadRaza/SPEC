import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/data/db/spec_database.dart';
import 'package:spec/data/photo_store.dart';
import 'package:spec/home/home_tab_bar.dart';
import 'package:spec/main.dart';
import 'package:spec/onboarding/welcome_screen.dart';
import 'package:spec/providers/database.dart';
import 'package:spec/providers/photos.dart';
import 'package:spec/providers/reminders.dart';
import 'package:spec/splash/splash_screen.dart';

import '../support/database.dart';
import '../support/fonts.dart';
import '../support/prefs.dart';
import '../support/reminders.dart';

const _canvas = Size(402, 874);

/// The splash's own timeline: 4500 ms of animation plus a 320 ms exit fade.
const _splash = Duration(milliseconds: 4820);

/// Long enough that the first route builds while the database is still
/// opening, which is what a cold start on a device looks like.
const _slowOpen = Duration(milliseconds: 300);

/// The prefs key onboarding writes when it finishes.
const _onboardingDoneKey = 'spec.onboarding_done';

void main() {
  setUpAll(loadSpecFonts);
  setUp(useInMemoryPrefs);

  group('a returning user', () {
    setUp(() => useInMemoryPrefs(initial: {_onboardingDoneKey: true}));

    Future<void> bootWithSlowDatabase(WidgetTester tester) async {
      tester.view
        ..physicalSize = _canvas * 3
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final photos = Directory.systemTemp.createTempSync('spec_boot_test');
      addTearDown(() => photos.deleteSync(recursive: true));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            specDatabaseProvider.overrideWith((ref) async {
              await Future<void>.delayed(_slowOpen);
              final database = SpecDatabase.memory();
              ref.onDispose(database.close);
              return database;
            }),
            photoStoreProvider.overrideWith((ref) async => PhotoStore(photos)),
            reminderSchedulerProvider.overrideWithValue(
              FakeReminderScheduler(),
            ),
          ],
          child: const SpecApp(),
        ),
      );
      // Frame by frame: the orb breathes forever.
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    /// Unmounts the app so the database's live queries close their timers
    /// before the test ends.
    Future<void> unmount(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    }

    testWidgets('lands on Home while the database is still opening', (
      tester,
    ) async {
      await bootWithSlowDatabase(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(HomeTabBar), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('tab bar labels carry no debug underline', (tester) async {
      await bootWithSlowDatabase(tester);

      final labels = tester.widgetList<RichText>(
        find.descendant(
          of: find.byType(HomeTabBar),
          matching: find.byType(RichText),
        ),
      );
      expect(labels, isNotEmpty);
      for (final label in labels) {
        expect(label.text.style?.decoration, isNot(TextDecoration.underline));
      }
      await unmount(tester);
    });
  });

  testWidgets('the app boots through the splash into onboarding', (
    tester,
  ) async {
    tester.view
      ..physicalSize = _canvas * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(withInMemoryDatabase(const SpecApp()));

    // The splash covers the first route rather than replacing it.
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(WelcomeScreen), findsOneWidget);

    // Pump a frame at a time until the splash lifts, since the glow loop
    // repeats forever and pumpAndSettle would never return.
    var elapsed = Duration.zero;
    const frame = Duration(milliseconds: 16);
    while (elapsed < _splash + const Duration(milliseconds: 200)) {
      if (find.byType(SplashScreen).evaluate().isEmpty) break;
      await tester.pump(frame);
      elapsed += frame;
    }

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(WelcomeScreen), findsOneWidget);

    // Reminder sync holds a live query from launch; unmounting closes its
    // timer before the test ends.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });
}
