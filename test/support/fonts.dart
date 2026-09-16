import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The real bundled faces, keyed by the family names the theme asks for.
const _families = <String, List<String>>{
  'GeneralSans': [
    'assets/fonts/GeneralSans-Regular.otf',
    'assets/fonts/GeneralSans-Medium.otf',
    'assets/fonts/GeneralSans-Semibold.otf',
    'assets/fonts/GeneralSans-Bold.otf',
  ],
  'GeistMono': ['assets/fonts/GeistMono-Regular.ttf'],
};

/// Loads SPEC's own fonts into a widget test.
///
/// Without this the test framework substitutes a font whose metrics are not
/// the designer's, and a layout authored to the point against a fixed canvas
/// overflows for reasons that would never happen on a device.
Future<void> loadSpecFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
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
