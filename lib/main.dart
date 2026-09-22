import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:spec/app/router.dart';
import 'package:spec/app/splash_gate.dart';
import 'package:spec/providers/reminders.dart';
import 'package:spec/theme/spec_layout.dart';
import 'package:spec/theme/spec_tokens.dart';

void main() {
  // Routes photo imports through the system Photo Picker, which returns a
  // scoped URI and needs no permission. One line deletes the whole Android
  // 13/14 media-permission matrix.
  final picker = ImagePickerPlatform.instance;
  if (picker is ImagePickerAndroid) picker.useAndroidPhotoPicker = true;

  runApp(const ProviderScope(child: SpecApp()));
}

class SpecApp extends ConsumerWidget {
  const SpecApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Starts reminder notifications syncing with the objects and keeps them
    // alive. Listened, not watched or awaited: it must neither rebuild the
    // app nor hold the splash.
    ref.listen(reminderSyncProvider, (_, _) {});

    return MaterialApp.router(
      title: 'SPEC',
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: SpecColors.bg,
      ),
      // The splash sits above the router so it can cross-fade out while the
      // first route fades in underneath.
      //
      // The base text style wraps everything once. No screen sits inside a
      // Material, so without it any text a screen does not wrap itself — the
      // tab bar, Collections, a Hero mid-flight — falls back to Flutter's
      // debug style: yellow, double-underlined.
      //
      // The text scale is capped rather than followed all the way up.
      // `SpecText` bakes letterSpacing in absolute points — the wordmark
      // tracks -4.6 — and tracking does not grow with the glyphs, so past
      // roughly 1.5 the display faces collide into themselves no matter how
      // much room the layout gives them. 1.5 is the honest ceiling for this
      // type system; screens are built to survive it.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: MediaQuery.textScalerOf(context)
              .clamp(maxScaleFactor: SpecLayout.maxTextScale),
        ),
        child: DefaultTextStyle(
          style: const TextStyle(
            fontFamily: SpecFonts.display,
            color: SpecColors.ink,
            decoration: TextDecoration.none,
          ),
          child: SplashGate(child: child!),
        ),
      ),
    );
  }
}
