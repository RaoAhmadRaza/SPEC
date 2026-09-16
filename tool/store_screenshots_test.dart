// Renders every SPEC screen, populated, at 4K (3840px tall) into
// build/screenshots/. Lives outside test/ so the normal suite never runs it.
//
//   flutter test tool/store_screenshots_test.dart
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:spec/add/add_value_field.dart';
import 'package:spec/app/router.dart';
import 'package:spec/data/db/spec_database.dart';
import 'package:spec/data/models/spec_models.dart';
import 'package:spec/data/photo_store.dart';
import 'package:spec/main.dart';
import 'package:spec/providers/database.dart';
import 'package:spec/providers/onboarding.dart';
import 'package:spec/providers/photos.dart';
import 'package:spec/providers/reminders.dart';
import 'package:spec/services/reminder_notifications.dart';

/// The design canvas (iPhone 17 Pro), scaled so the long edge is 3840px.
const _canvas = Size(402, 874);
const _longEdge = 3840.0;
final _pixelRatio = _longEdge / _canvas.height;

const _out = 'build/store_screenshots';
const _photos = 'assets/images/components';

const _families = <String, List<String>>{
  'GeneralSans': [
    'assets/fonts/GeneralSans-Regular.otf',
    'assets/fonts/GeneralSans-Medium.otf',
    'assets/fonts/GeneralSans-Semibold.otf',
    'assets/fonts/GeneralSans-Bold.otf',
  ],
  'GeistMono': ['assets/fonts/GeistMono-Regular.ttf'],
};

Future<void> _loadFonts() async {
  for (final MapEntry(key: family, value: assets) in _families.entries) {
    final loader = FontLoader(family);
    for (final asset in assets) {
      loader.addFont(
        File(asset).readAsBytes().then((bytes) => bytes.buffer.asByteData()),
      );
    }
    await loader.load();
  }
}

class _Onboarded extends OnboardingCompleted {
  @override
  Future<bool> build() async => true;
}

/// No platform channel in a test, so reminders go nowhere.
class _NoReminders implements ReminderScheduler {
  @override
  Future<Set<int>> pendingIds() async => {};
  @override
  Future<void> requestPermission() async {}
  @override
  Future<void> schedule(ReminderRequest request) async {}
  @override
  Future<void> cancel(int id) async {}
}

/// One seeded object: the row, its zone, and an optional photo file.
typedef _Seed = ({ObjectsCompanion row, String zone, String? photo});

_Seed _seed({
  required String name,
  required ObjectType type,
  required SpecKind kind,
  required String value,
  required String zone,
  required int daysAgo,
  String? subtitle,
  String? photo,
  String? from,
  String? replacedOn,
  int? remindMonths,
  String? notes,
  List<SpecAttribute> attributes = const [],
}) {
  final at = DateTime(2026, 9, 15, 10).subtract(Duration(days: daysAgo));
  return (
    row: ObjectsCompanion.insert(
      name: name,
      type: type.name,
      specKind: kind.name,
      specValue: value,
      subtitle: Value(subtitle),
      purchasedFrom: Value(from),
      replacedOn: Value(replacedOn),
      remindEveryMonths: Value(remindMonths),
      notes: Value(notes),
      attributes: Value(encodeAttributes(attributes)),
      createdAt: at,
      updatedAt: at,
    ),
    zone: zone,
    photo: photo,
  );
}

/// Oldest first. The newest three are the Home grid, so their specs are
/// short enough to sit on one line.
final _seeds = <_Seed>[
  _seed(
    name: 'Jeans',
    type: ObjectType.clothing,
    kind: SpecKind.waist,
    value: '32 / 32',
    zone: 'Clothing',
    daysAgo: 40,
    subtitle: "Levi's 511 Slim",
    from: "Levi's",
  ),
  _seed(
    name: 'Wiper blades',
    type: ObjectType.car,
    kind: SpecKind.wiper,
    value: '24" / 16"',
    zone: 'Car',
    daysAgo: 34,
    subtitle: 'Front pair',
    from: 'Bosch',
    replacedOn: '2026-02-02',
    remindMonths: 12,
  ),
  _seed(
    name: 'Living room paint',
    type: ObjectType.home,
    kind: SpecKind.paint,
    value: 'Polished Pebble',
    zone: 'Home',
    daysAgo: 28,
    subtitle: 'Dulux matt emulsion',
    notes: 'Two coats. Leftover tin under the stairs.',
  ),
  _seed(
    name: 'Engine oil',
    type: ObjectType.car,
    kind: SpecKind.oil,
    value: '5W-30',
    zone: 'Car',
    daysAgo: 21,
    subtitle: 'Fully synthetic, 4.5 L',
    replacedOn: '2026-05-20',
    remindMonths: 12,
  ),
  _seed(
    name: 'Router',
    type: ObjectType.device,
    kind: SpecKind.serial,
    value: '7Q2K-94XD',
    zone: 'Devices',
    daysAgo: 16,
    subtitle: 'TP-Link Archer AX55',
  ),
  _seed(
    name: 'Front tyres',
    type: ObjectType.car,
    kind: SpecKind.tyre,
    value: '225/45 R17',
    zone: 'Car',
    daysAgo: 9,
    subtitle: 'Tyre',
    photo: 'tyre.png',
    from: 'Michelin',
    replacedOn: '2024-10-02',
    remindMonths: 24,
    attributes: [
      SpecAttribute(label: 'LOAD', value: '94'),
      SpecAttribute(label: 'SPEED', value: 'W'),
      SpecAttribute(label: 'PSI', value: '36'),
    ],
  ),
  _seed(
    name: 'Camera SD card',
    type: ObjectType.device,
    kind: SpecKind.model,
    value: '128GB',
    zone: 'Devices',
    daysAgo: 7,
    subtitle: 'SanDisk Extreme SDXC',
    photo: 'sd card.png',
    from: 'SanDisk',
    attributes: [
      SpecAttribute(label: 'CLASS', value: 'U3 V30'),
      SpecAttribute(label: 'READ', value: '200 MB/s'),
      SpecAttribute(label: 'WRITE', value: '90 MB/s'),
    ],
  ),
  _seed(
    name: 'Fridge water filter',
    type: ObjectType.home,
    kind: SpecKind.filter,
    value: 'DA29-00020B',
    zone: 'Kitchen',
    daysAgo: 5,
    subtitle: 'Samsung fridge filter',
    photo: 'filter refg.png',
    from: 'Samsung',
    replacedOn: '2026-03-01',
    remindMonths: 6,
    notes: 'Twist a quarter turn left to release.',
    attributes: [
      SpecAttribute(label: 'LITRES', value: '1,100'),
      SpecAttribute(label: 'LIFE', value: '6 months'),
      SpecAttribute(label: 'FITS', value: 'RS68'),
    ],
  ),
  _seed(
    name: 'Running shoes',
    type: ObjectType.clothing,
    kind: SpecKind.shoe,
    value: '44',
    zone: 'Clothing',
    daysAgo: 2,
    subtitle: 'Sneakers',
    photo: 'sneakers.png',
    from: 'Nike',
    attributes: [
      SpecAttribute(label: 'UK', value: '9'),
      SpecAttribute(label: 'US', value: '10'),
    ],
  ),
  _seed(
    name: 'Bedroom bulb',
    type: ObjectType.home,
    kind: SpecKind.bulb,
    value: 'E27',
    zone: 'Home',
    daysAgo: 1,
    subtitle: 'Bulb',
    photo: 'bulb.png',
    from: 'Philips',
    replacedOn: '2026-01-10',
    remindMonths: 6,
    attributes: [
      SpecAttribute(label: 'WATTS', value: '9W'),
      SpecAttribute(label: 'LUMENS', value: '806'),
      SpecAttribute(label: 'TONE', value: '2700K'),
    ],
  ),
  _seed(
    name: 'Printer ink',
    type: ObjectType.product,
    kind: SpecKind.sku,
    value: '67XL',
    zone: 'Office',
    daysAgo: 0,
    subtitle: 'Ink cartridge',
    photo: 'ink cartridge.png',
    from: 'HP',
    replacedOn: '2026-07-02',
    remindMonths: 3,
    notes: 'Black only. Colour one lasts forever.',
    attributes: [
      SpecAttribute(label: 'COLOUR', value: 'Black'),
      SpecAttribute(label: 'PAGES', value: '240'),
      SpecAttribute(label: 'YIELD', value: 'High'),
    ],
  ),
];

/// Ids by object name, filled while seeding.
final _ids = <String, int>{};

/// The real app over an in-memory archive holding [_seeds].
Future<GoRouter> _boot(
  WidgetTester tester, {
  bool isOnboarded = true,
  bool shouldSettle = true,
}) async {
  tester.view
    ..physicalSize = _canvas * _pixelRatio
    ..devicePixelRatio = _pixelRatio;
  addTearDown(tester.view.reset);
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.withData(<String, Object>{});

  final database = SpecDatabase.memory();
  addTearDown(database.close);
  final photoDir = Directory.systemTemp.createTempSync('spec_shots');
  addTearDown(() => photoDir.deleteSync(recursive: true));
  final store = PhotoStore(photoDir);

  final container = ProviderContainer(
    overrides: [
      specDatabaseProvider.overrideWith((ref) async => database),
      photoStoreProvider.overrideWith((ref) async => store),
      reminderSchedulerProvider.overrideWithValue(_NoReminders()),
      if (isOnboarded) onboardingCompletedProvider.overrideWith(_Onboarded.new),
    ],
  );
  addTearDown(container.dispose);

  await tester.runAsync(() async {
    await container.read(specDatabaseProvider.future);
    if (!isOnboarded) return;
    final objects = container.read(objectRepositoryProvider);
    for (final seed in _seeds) {
      final photo = seed.photo;
      final names = photo == null
          ? const <String>[]
          : [await store.add(File('$_photos/$photo'))];
      _ids[seed.row.name.value] = await objects.create(
        seed.row,
        zoneName: seed.zone,
        photoFileNames: names,
      );
    }
  });

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const SpecApp()),
  );
  if (shouldSettle) await _settle(tester, rounds: 8);
  return container.read(routerProvider);
}

/// Animations loop forever (the orb breathes, carets blink), so never
/// pumpAndSettle. Real time passes between rounds so streams deliver and
/// photos decode.
Future<void> _settle(WidgetTester tester, {int rounds = 5}) async {
  for (var round = 0; round < rounds; round++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }
}

Future<void> _shoot(WidgetTester tester, String name) async {
  await _settle(tester, rounds: 3);
  await tester.runAsync(() async {
    final ui.Image image = await captureImage(tester.binding.rootElement!);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final file = File('$_out/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder.first, warnIfMissed: false);
  await _settle(tester);
}

/// Taps a point on the 402 × 874 design canvas, for icon-only buttons.
Future<void> _tapAt(WidgetTester tester, double x, double y) async {
  await tester.tapAt(Offset(x, y));
  await _settle(tester);
}

/// The orb awaits a database read before the sheet opens, which under the
/// test clock sometimes needs another round of real time.
Future<void> _openAdd(WidgetTester tester) async {
  for (var attempt = 0; attempt < 5; attempt++) {
    await _tapAt(tester, 201, 809);
    await _settle(tester);
    if (find.text('ADD YOUR OWN').evaluate().isNotEmpty) return;
  }
}

Future<void> _openObject(WidgetTester tester, String name) async {
  final router = await _boot(tester);
  unawaited(router.push('/object/${_ids[name]}'));
  await _settle(tester);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFonts();
  });

  testWidgets('00 splash', (tester) async {
    await _boot(tester, isOnboarded: false, shouldSettle: false);
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.runAsync(() async {
      final ui.Image image = await captureImage(tester.binding.rootElement!);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('$_out/00_splash.png').create(recursive: true);
      await File('$_out/00_splash.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
    });
    await _settle(tester, rounds: 8);
  });

  testWidgets('01-03 onboarding', (tester) async {
    await _boot(tester, isOnboarded: false);
    await _shoot(tester, '01_welcome');
    await _tap(tester, find.text('GET STARTED'));
    await _shoot(tester, '02_how_it_works');
    await _tap(tester, find.text('NEXT'));
    await _shoot(tester, '03_first_object');
  });

  testWidgets('04 home', (tester) async {
    await _boot(tester);
    await _shoot(tester, '04_home');
  });

  testWidgets('05 search all', (tester) async {
    await _boot(tester);
    await _tap(tester, find.text('SEE ALL ›'));
    await _shoot(tester, '05_search_all');
  });

  testWidgets('06 search typed', (tester) async {
    final router = await _boot(tester);
    unawaited(router.pushNamed(RouteNames.search));
    await _settle(tester);
    await tester.enterText(find.byType(EditableText).first, 'car');
    await _settle(tester, rounds: 8);
    await _shoot(tester, '06_search_query');
  });

  testWidgets('07 search scoped to a zone', (tester) async {
    final router = await _boot(tester);
    unawaited(
      router.pushNamed(RouteNames.search, queryParameters: {'scope': 'Car'}),
    );
    await _settle(tester);
    await _shoot(tester, '07_search_zone');
  });

  testWidgets('08 object detail', (tester) async {
    await _openObject(tester, 'Printer ink');
    await _shoot(tester, '08_object_detail');
  });

  testWidgets('09 object detail, due', (tester) async {
    await _openObject(tester, 'Fridge water filter');
    await _shoot(tester, '09_object_detail_due');
  });

  testWidgets('10 object edit', (tester) async {
    await _openObject(tester, 'Running shoes');
    await _tap(tester, find.text('Edit'));
    await _shoot(tester, '10_object_edit');
  });

  testWidgets('11 object actions', (tester) async {
    await _openObject(tester, 'Front tyres');
    await _tapAt(tester, 359, 82);
    await _shoot(tester, '11_object_actions');
  });

  testWidgets('12 photo viewer', (tester) async {
    await _openObject(tester, 'Bedroom bulb');
    await _tapAt(tester, 139, 493);
    await _shoot(tester, '12_photo_viewer');
  });

  testWidgets('13 collections', (tester) async {
    await _boot(tester);
    await _tap(tester, find.text('Collections'));
    await _shoot(tester, '13_collections');
  });

  testWidgets('14-17 add flow', (tester) async {
    await _boot(tester);
    await _openAdd(tester);
    await _shoot(tester, '14_add_what');
    await _tap(tester, find.text('Bulb'));
    await tester.enterText(
      find.descendant(
        of: find.byType(AddValueField),
        matching: find.byType(EditableText),
      ),
      'B22',
    );
    await _shoot(tester, '15_add_step2');
    if (find.text('CONTINUE').evaluate().isNotEmpty) {
      await _tap(tester, find.text('CONTINUE'));
      await _shoot(tester, '16_add_step3');
    }
  });

  testWidgets('17 add your own', (tester) async {
    await _boot(tester);
    await _openAdd(tester);
    await _tap(tester, find.text('ADD YOUR OWN'));
    await _shoot(tester, '17_add_your_own');
  });

  testWidgets('18 settings', (tester) async {
    await _boot(tester);
    await _tapAt(tester, 361, 78);
    await _shoot(tester, '18_settings');
  });
}
