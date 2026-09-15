import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:spec/add/add_draft.dart';
import 'package:spec/add/add_entry.dart';
import 'package:spec/add/add_kinds.dart';
import 'package:spec/add/add_sheet_route.dart';
import 'package:spec/app/router.dart';
import 'package:spec/data/models/spec_models.dart';
import 'package:spec/data/zone_repository.dart' as zones;
import 'package:spec/onboarding/first_object_draft.dart';
import 'package:spec/onboarding/first_object_screen.dart';
import 'package:spec/onboarding/how_it_works_screen.dart';
import 'package:spec/onboarding/welcome_screen.dart';
import 'package:spec/providers/database.dart';
import 'package:spec/providers/onboarding.dart';
import 'package:spec/providers/photos.dart';

/// Route-level wiring for onboarding 09 to 11.
///
/// The screens themselves stay pure presentation driven by callbacks, so their
/// widget tests keep building them directly with no `ProviderScope`. These
/// wrappers sit outside the screens and add no render object, which is what
/// keeps those tests' widget-depth assertions valid.
class WelcomeRoute extends ConsumerWidget {
  const WelcomeRoute({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WelcomeScreen(
      onStart: () => context.pushNamed(RouteNames.howItWorks),
      onSkip: () =>
          unawaited(ref.read(onboardingCompletedProvider.notifier).complete()),
    );
  }
}

class HowItWorksRoute extends ConsumerWidget {
  const HowItWorksRoute({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HowItWorksScreen(
      onNext: () => context.pushNamed(RouteNames.firstObject),
      onSkip: () =>
          unawaited(ref.read(onboardingCompletedProvider.notifier).complete()),
    );
  }
}

class FirstObjectRoute extends ConsumerStatefulWidget {
  const FirstObjectRoute({super.key});

  @override
  ConsumerState<FirstObjectRoute> createState() => _FirstObjectRouteState();
}

class _FirstObjectRouteState extends ConsumerState<FirstObjectRoute> {
  /// The photo the user has taken, before it is copied into the store. Held
  /// here rather than saved on capture, so backing out of onboarding leaves
  /// nothing behind.
  File? _photo;

  @override
  Widget build(BuildContext context) {
    return FirstObjectScreen(
      onLater: () =>
          unawaited(ref.read(onboardingCompletedProvider.notifier).complete()),
      onCapture: () => unawaited(_capture()),
      onAdd: (suggestion) => unawaited(_add(suggestion)),
      // Contain, on the frame's own dark tile: a cover crop cuts the text off
      // a portrait shot of a label, and the label is the point.
      preview: _photo == null
          ? null
          : Image.file(
              _photo!,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
    );
  }

  Future<void> _capture() async {
    final photo = await ref.read(photoCaptureProvider).takePhoto();
    if (photo == null || !mounted) return;
    setState(() => _photo = photo);
  }

  /// ADD MY FIRST OBJECT: step 05 of the add flow, pre-filled with the chip
  /// and the photo, so the spec is typed rather than saved empty.
  ///
  /// Only SAVE writes the object and ends onboarding. Dismissing the sheet
  /// comes back here with nothing written.
  Future<void> _add(String suggestion) async {
    final shape = firstObjectShape(suggestion);
    // This route is gone once onboarding completes, so the save holds the
    // container rather than this widget's ref.
    final container = ProviderScope.containerOf(context, listen: false);
    final stored = await container.read(objectRepositoryProvider).zoneNames();
    if (!mounted) return;
    // Nothing has seeded the default zones yet, so the starters alone would
    // file a first cartridge under Kitchen. The type's own zone leads instead.
    final zone = zones.defaultZoneFor(
      ObjectType.values.byName(shape.type.name),
    );
    final choices = zoneChoices(stored);
    await showAddFields(
      context,
      type: shape.type,
      initialKind: shape.kind,
      name: shape.name,
      photo: _photo,
      pickPhoto: container.read(photoCaptureProvider).takePhoto,
      zone: zone,
      zones: [
        if (!choices.any(
          (choice) => choice.toLowerCase() == zone.toLowerCase(),
        ))
          zone,
        ...choices,
      ],
      stepLabel: '03 / 03',
      onSave: (draft) => unawaited(_save(container, draft, shape.name)),
    );
  }

  /// A failed write is reported inside [saveDraft] and never strands the user
  /// in onboarding: they can add the object again from Home.
  static Future<void> _save(
    ProviderContainer container,
    SpecDraft draft,
    String libraryTerm,
  ) async {
    await saveDraft(container, draft, libraryTerm: libraryTerm);
    await container.read(onboardingCompletedProvider.notifier).complete();
  }
}
