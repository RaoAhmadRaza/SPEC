import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:spec/app/router.dart';
import 'package:spec/collections/collections_screen.dart';
import 'package:spec/data/db/spec_database.dart';
import 'package:spec/data/photo_store.dart';
import 'package:spec/home/home_card.dart';
import 'package:spec/home/home_header.dart';
import 'package:spec/home/home_tab_bar.dart';
import 'package:spec/onboarding/how_it_works_screen.dart';
import 'package:spec/onboarding/welcome_screen.dart';
import 'package:spec/providers/database.dart';
import 'package:spec/providers/onboarding.dart';
import 'package:spec/providers/photos.dart';
import 'package:spec/settings/settings_route.dart';

import '../support/fonts.dart';
import '../support/prefs.dart';

/// The canvas every number in the design is measured against.
const _canvas = Size(402, 874);

/// A container with an in-memory database and photo store, the database
/// already open.
///
/// Opened up front only to keep these tests about routing. Launching while
/// the database is still opening is covered in app_boot_test.dart.
Future<ProviderContainer> _container(
  WidgetTester tester, {
  bool isOnboarded = false,
}) async {
  final database = SpecDatabase.memory();
  addTearDown(database.close);
  final photos = Directory.systemTemp.createTempSync('spec_router_test');
  addTearDown(() => photos.deleteSync(recursive: true));

  final container = ProviderContainer(
    overrides: [
      specDatabaseProvider.overrideWith((ref) async => database),
      photoStoreProvider.overrideWith((ref) async => PhotoStore(photos)),
      if (isOnboarded)
        onboardingCompletedProvider.overrideWith(_AlreadyOnboarded.new),
    ],
  );
  addTearDown(container.dispose);
  await container.read(specDatabaseProvider.future);
  return container;
}

/// Pumps the router on its own, without the splash overlay, so a test does not
/// have to wait out the 4.5 second launch timeline.
Future<(GoRouter, ProviderContainer)> _pumpRouter(
  WidgetTester tester, {
  bool isOnboarded = false,
}) async {
  tester.view
    ..physicalSize = _canvas * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final container = await _container(tester, isOnboarded: isOnboarded);
  final router = container.read(routerProvider);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  return (router, container);
}

/// The orb breathes forever, so pumpAndSettle would never return.
Future<void> _pumpFrames(WidgetTester tester, int count) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

String _locationOf(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.path;

void main() {
  setUpAll(loadSpecFonts);
  setUp(useInMemoryPrefs);
  _backNavigation();
  _homeShell();

  testWidgets('a first run is redirected into onboarding', (tester) async {
    final (router, _) = await _pumpRouter(tester);

    expect(_locationOf(router), '/onboarding/welcome');
  });

  testWidgets('completing onboarding redirects out of it', (tester) async {
    final (router, container) = await _pumpRouter(tester);
    expect(_locationOf(router), '/onboarding/welcome');

    unawaited(container.read(onboardingCompletedProvider.notifier).complete());
    await tester.pump();
    await tester.pump();

    expect(_locationOf(router), '/home');
  });

  testWidgets('a returning user lands on Home without onboarding', (
    tester,
  ) async {
    final (router, _) = await _pumpRouter(tester, isOnboarded: true);

    expect(_locationOf(router), '/home');
  });
}

class _AlreadyOnboarded extends OnboardingCompleted {
  @override
  Future<bool> build() async => true;
}

void _backNavigation() {
  testWidgets('onboarding pushes a real stack, so back returns a page', (
    tester,
  ) async {
    final (router, _) = await _pumpRouter(tester);
    expect(find.byType(WelcomeScreen), findsOneWidget);

    unawaited(router.pushNamed<void>('onboardingHowItWorks'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(HowItWorksScreen), findsOneWidget);

    // A pushed stack is what makes Android back and the iOS edge-swipe work.
    expect(router.canPop(), isTrue);

    router.pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(HowItWorksScreen), findsNothing);
  });
}

void _homeShell() {
  group('home shell', () {
    testWidgets('Home draws exactly one tab bar and one orb', (tester) async {
      // Arrange & Act
      await _pumpRouter(tester, isOnboarded: true);
      await _pumpFrames(tester, 60);

      // Assert
      expect(find.byType(HomeTabBar), findsOneWidget);
      expect(find.byType(HomeOrb), findsOneWidget);
    });

    testWidgets('the Collections tab shows Collections', (tester) async {
      // Arrange
      await _pumpRouter(tester, isOnboarded: true);
      await _pumpFrames(tester, 60);
      expect(find.byType(CollectionsScreen), findsNothing, reason: 'offstage');

      // Act
      await tester.tap(find.text('Collections'));
      await _pumpFrames(tester, 40);

      // Assert
      expect(find.byType(CollectionsScreen), findsOneWidget);
    });

    testWidgets('the ••• circle opens Settings', (tester) async {
      // Arrange
      final (router, _) = await _pumpRouter(tester, isOnboarded: true);
      await _pumpFrames(tester, 60);

      // Act
      await tester.tap(
        find.descendant(
          of: find.byType(HomeHeaderRow),
          matching: find.byType(HomeDots),
        ),
      );
      await _pumpFrames(tester, 40);

      // Assert: pushed, so the base location stays Home and the top is
      // Settings.
      expect(router.state.uri.path, '/settings');
      expect(find.byType(SettingsRoute), findsOneWidget);
      expect(router.canPop(), isTrue);
    });
  });
}
