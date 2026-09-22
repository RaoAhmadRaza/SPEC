# Prompt 00 — Shared responsive foundation

**Must land before any screen prompt.** Every other prompt in this folder calls the
helpers created here. On its own this prompt changes no screen's appearance.

---

## Prompt

> You are working in the SPEC Flutter app at `/Users/ahmadraza/Downloads/SPEC/spec`.
>
> The app has **no responsive infrastructure of any kind**. I verified this by reading
> every file under `lib/`: there is no breakpoint constant, no `isTablet` or
> `shortestSide` read, no `OrientationBuilder`, no `SafeArea` anywhere, and no
> `textScaler` clamp. Each of the thirteen screens clears the status bar with its own
> hardcoded constant (`56`, or `62` in `lib/object/object_tokens.dart:182`) and the
> home indicator with another (`44` in Settings, `108` in Library, `112` in Home and
> Collections, `128` in Not-in-Library). `lib/theme/spec_tokens.dart` shares colour
> (`SpecColors`) and type (`SpecText`) only — there is no shared spacing, radius, or
> duration scale.
>
> Your job is to build the small foundation that the per-screen work will lean on.
> Do not touch any screen in this task. Build the helpers, wire the text-scale clamp,
> add the test harness, and stop.
>
> ### 1. Create `lib/theme/spec_layout.dart`
>
> A single file, no classes beyond what is listed, no configurability beyond it. This
> is the only new abstraction the responsive work is allowed to introduce.
>
> ```
> abstract final class SpecLayout {
>   // Device classes. `shortestSide` so an iPad in landscape stays "expanded".
>   static const double expandedBreakpoint = 600.0;
>   static bool isExpanded(BuildContext) => shortestSide >= expandedBreakpoint
>
>   // Reading room. Display type at 54-108pt is unreadable across a 1280pt line.
>   static const double maxContentWidth = 560.0;
>   static double contentWidth(BuildContext)  // min(available, maxContentWidth)
>
>   // Safe-area-aware chrome insets. The `max(design, real + gap)` shape is
>   // deliberate: at the 402x874 test canvas MediaQuery padding is zero, so this
>   // returns exactly the existing design constant and no test moves a pixel.
>   static double topInset(BuildContext, {required double design})
>       => max(design, MediaQuery.paddingOf(context).top + minTopGap)
>   static double bottomInset(BuildContext, {required double design})
>       => max(design, MediaQuery.paddingOf(context).bottom + minBottomGap)
>   static const double minTopGap = 12.0;
>   static const double minBottomGap = 12.0;
>
>   // Grid columns from available width, given the design's cell width.
>   static int columnsFor(double available, {required double idealCell, required int min, required int max})
>
>   // The clamp the app installs globally. Named here so screens can reason about
>   // the worst case they must survive.
>   static const double maxTextScale = 1.5;
> }
> ```
>
> Requirements:
> - Read `MediaQuery` through the scoped accessors (`MediaQuery.paddingOf`,
>   `MediaQuery.sizeOf`) so a padding change does not rebuild a screen that only
>   reads size. The codebase already uses this style
>   (`lib/object/object_screen.dart:509`, `lib/collections/collections_screen.dart:254`).
> - No mutation, no cached singletons, pure functions only.
> - Document each constant with one line saying what breaks without it. No essays.
>
> ### 2. Clamp the text scale in `lib/main.dart`
>
> `lib/main.dart:46-53` already has a `builder:` that wraps every route in a
> `DefaultTextStyle` and a `SplashGate`, and it does not touch `MediaQuery`. Add one
> `MediaQuery` wrapper inside that builder, outermost of the two existing wrappers:
>
> ```
> MediaQuery(
>   data: MediaQuery.of(context).copyWith(
>     textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: SpecLayout.maxTextScale),
>   ),
>   child: /* existing DefaultTextStyle + SplashGate */,
> )
> ```
>
> Why 1.5 and not "respect whatever the user set": `SpecText` bakes `letterSpacing`
> in **absolute points** (`wordmark` is `-4.6`, `firstObjectHeadline` is `-2.30`,
> `privacy` is `+2.64`, `spec_tokens.dart:102-336`). Letter spacing does not scale
> with text, so past roughly 1.5 the negative tracking on the display faces makes
> glyphs collide into each other regardless of how much room the layout gives them —
> the type itself breaks, not just the box. 1.5 is the honest ceiling for this type
> system. Screens must then survive 1.5 without clipping, and the per-screen prompts
> ask for `FittedBox` on the display faces so 2.0 degrades gracefully rather than
> being silently ignored.
>
> State this tradeoff in a comment at the clamp site, in the codebase's existing
> comment voice (see `lib/app/router.dart:38-43` for the register to match).
>
> ### 3. Add the test harness `test/support/responsive.dart`
>
> Every existing test pins one canvas — `const _canvas = Size(402, 874)` with
> `devicePixelRatio = 3` and a `MediaQueryData(size: _canvas)` that carries no
> padding and no `textScaler` (see `test/settings/settings_screen_test.dart:7,23-31`
> and the same pattern in `test/home/`, `test/collections/`, `test/object/`,
> `test/search/`, `test/library/`, `test/add/`, `test/shell/`). There are no golden
> tests anywhere in the repo.
>
> Add one helper that the per-screen prompts will call, matching that existing
> pattern so the two styles read as one suite:
>
> ```
> const specCanvases = <String, Size>{
>   'tiny':   Size(320, 568),
>   'small':  Size(375, 667),
>   'ref':    Size(402, 874),
>   'large':  Size(430, 932),
>   'tabletPortrait':  Size(810, 1080),
>   'tabletLandscape': Size(1280, 800),
> };
>
> Future<void> pumpResponsive(
>   WidgetTester tester,
>   Widget child, {
>   Size canvas = const Size(402, 874),
>   EdgeInsets padding = EdgeInsets.zero,
>   double textScale = 1.0,
>   bool disableAnimations = true,
> });
>
> // Fails if any RenderFlex/RenderBox overflow was recorded during the pump.
> void expectNoOverflow(WidgetTester tester);
> ```
>
> `expectNoOverflow` must actually catch overflows, which `tester.takeException()`
> alone does not do reliably for paint-time overflow. Assert on
> `tester.takeException()` being null **and** scan `FlutterError` output for
> `overflowed by`. If you cannot make the scan reliable, say so in the file's doc
> comment and fall back to asserting the subject widget's bottom/right against the
> canvas bounds, which is the technique `test/settings/settings_screen_test.dart:78-92`
> already uses ("a long status fits the canvas without overflow").
>
> ### 4. Write one test for the foundation itself
>
> `test/theme/spec_layout_test.dart`, AAA style, matching the existing suite's naming
> ("returns X when Y"):
> - `topInset` returns the design constant when padding is zero (the test-canvas case)
> - `topInset` returns `padding.top + minTopGap` when that exceeds the design constant
> - `isExpanded` is false at 430×932 and true at both 810×1080 and 1280×800
> - `columnsFor` returns the design's column count at the reference width
> - `contentWidth` caps at `maxContentWidth` on a 1280pt-wide parent
> - the clamp in `main.dart` holds: pump `SpecApp` at `textScale: 3.0` and assert the
>   effective `MediaQuery.textScalerOf` scale of a descendant is 1.5
>
> ### Constraints
>
> - **Do not run the app.** No `flutter run`, no hot reload, no terminating the
>   simulator app — `CLAUDE.md` §5 says this breaks the user's running session and has
>   already cost two debugging rounds. Verify with `flutter analyze` and `flutter test`.
> - **Do not add a package.** No `flutter_screenutil`, `sizer`, or
>   `responsive_framework`. `MediaQuery` and `LayoutBuilder` cover all of this.
> - **Do not touch a screen.** Not even to "prove" the helper works. Screens come next,
>   one prompt at a time.
> - **Do not introduce a shared spacing or radius token class.** The per-screen local
>   constants (`_side`, `_top`, `_blockGap`) stay where they are; this foundation makes
>   them safe-area-aware at their call sites, it does not centralise them. That
>   refactor is not what the user asked for and would touch all thirteen screens.
>
> ### Done when
>
> - `flutter analyze` is clean.
> - `flutter test` is fully green, with **zero edits to any existing test** — that is
>   the proof the `max(design, real + gap)` shape is a true no-op at 402×874.
> - `test/theme/spec_layout_test.dart` passes.
> - `grep -rn "SpecLayout" lib/` shows exactly one hit outside `spec_layout.dart`:
>   the clamp in `main.dart`.

---

## Notes for the reviewer

**What this deliberately does not build.** No `ResponsiveBuilder` widget, no
breakpoint-keyed value maps, no orientation-aware layout switcher. Thirteen screens
need safe insets, a width cap, a column count, and a scale ceiling. Four functions
and a constant cover all four. Anything more is scaffolding for a second app.

**Why `max(design, real + gap)` rather than replacing the constants.** Replacing `56`
with `MediaQuery.paddingOf(context).top` would change the layout at every canvas
including 402×874, breaking the whole existing suite and destroying the only pixel
baseline the project has. The `max` shape is a no-op wherever the design constant
already exceeds the real inset — which is the test canvas and most phones — and only
grows where a physical notch demands it.

**The one thing to watch.** `SpecLayout.maxTextScale = 1.5` is a product decision
disguised as a constant: it caps how large a user's system font setting can make SPEC's
text. If accessibility compliance ever requires honouring 2.0, the fix is not raising
this number — it is giving `SpecText`'s display faces em-relative letter spacing so
the tracking scales with the glyphs. Leave that note at the constant.
