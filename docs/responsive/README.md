# Responsive Prompts — SPEC

One prompt per screen. Each prompt is self-contained: it states the verified current
layout, the target device matrix, the required changes, the constraints, and the
verification gate. Hand a single file to an agent (or work it yourself) without
needing the others — except `00-shared-foundation.md`, which **must land first**
because every screen prompt calls into the helpers it creates.

## Order of work

| # | Doc | Surface | Blocking risk today |
|---|-----|---------|---------------------|
| 00 | [00-shared-foundation.md](00-shared-foundation.md) | `lib/theme/spec_layout.dart`, `lib/main.dart`, test harness | No responsive infra exists at all |
| 01 | [01-splash.md](01-splash.md) | `lib/splash/splash_screen.dart` | 92pt wordmark, 4 absolutely-placed ghosts |
| 02 | [02-welcome.md](02-welcome.md) | `lib/onboarding/welcome_screen.dart` | 86pt wordmark, 6 absolutely-placed chips, no scroll |
| 03 | [03-how-it-works.md](03-how-it-works.md) | `lib/onboarding/how_it_works_screen.dart` | 3 cards in a fixed `Expanded`, no scroll |
| 04 | [04-first-object.md](04-first-object.md) | `lib/onboarding/first_object_screen.dart` | ~595pt of fixed content on a 568pt screen |
| 05 | [05-home.md](05-home.md) | `lib/home/` | 170pt fixed cards, hardcoded 2 columns |
| 06 | [06-tab-shell.md](06-tab-shell.md) | `lib/shell/`, `lib/home/home_tab_bar.dart` | Floating bar never becomes a rail; fixed bottom offsets |
| 07 | [07-collections.md](07-collections.md) | `lib/collections/` | 54pt title in an unprotected `Row` |
| 08 | [08-object.md](08-object.md) | `lib/object/` | Action-bar labels in an unprotected `Row` |
| 09 | [09-search.md](09-search.md) | `lib/search/` | `kSearchRowHeight = 83.0` is a hard height |
| 10 | [10-library-pick.md](10-library-pick.md) | `lib/library/` | Rule row overflow; 3 columns at any width |
| 11 | [11-add-flow.md](11-add-flow.md) | `lib/add/` (what + fields sheets) | Reminder row overflow; `height - 96` sheet |
| 12 | [12-not-in-library.md](12-not-in-library.md) | `lib/add/not_in_library_screen.dart` | 210pt photo card + pinned block on a short screen |
| 13 | [13-settings.md](13-settings.md) | `lib/settings/` | `Spacer()` inside `SliverFillRemaining` → hard crash |

## Ground truth these prompts were written against

Verified by reading every file in `lib/` on 2026-09-21:

- **No responsive infrastructure exists.** No breakpoint constant, no `isTablet`,
  no `shortestSide` read, no `OrientationBuilder`, no device-class helper anywhere.
- **No `SafeArea` anywhere in `lib/`.** Every screen clears the status bar with a
  hardcoded constant (`56`, or `62` on Object) and the home indicator with another
  (`44`/`108`/`112`/`128`).
- **`textScaler` is never clamped.** `lib/main.dart`'s `builder:` wraps a
  `DefaultTextStyle` and a `SplashGate` and does not touch `MediaQuery`, so a system
  font scale of 2.0+ reaches every screen unmodified. The only scale-aware sizing in
  the app is `fitSpecStyle` (`lib/object/object_parts.dart:159`) and
  `libraryCellHeight` (`lib/library/library_cell.dart:59`).
- **Shared tokens cover colour and type only.** `lib/theme/spec_tokens.dart` holds
  `SpecColors` (~45 colours) and `SpecText` (28 styles, 9.5pt → 92pt, with
  `letterSpacing` pre-multiplied to absolute points so it does **not** scale with
  text). There is no shared spacing, radius, or duration scale — every screen
  redeclares its own `_side`/`_top`/`_blockGap` constants.
- **Orientation is locked to portrait on phones.** `android/app/src/main/AndroidManifest.xml:14`
  is `screenOrientation="portrait"`; `ios/Runner/Info.plist:62-71` locks iPhone to
  portrait but allows iPad all four orientations. No `SystemChrome.setPreferredOrientations`
  call exists in Dart. **Landscape is reachable only on iPad.**
- **Every widget test pins one canvas: `Size(402, 874)`** with
  `devicePixelRatio = 3` and `MediaQueryData(size:)` carrying **no padding** and
  **no `textScaler`**. There are **no golden tests** in the repo (`matchesGoldenFile`
  and `setSurfaceSize` appear nowhere), so no pixel baseline constrains a refactor —
  but the 402×874 assertions do, and they must keep passing.

## Target matrix every prompt is written against

| Class | Size (logical) | Device | Reachable |
|-------|----------------|--------|-----------|
| Tiny | 320 × 568 | iPhone SE 1st gen | Portrait |
| Small | 375 × 667 | iPhone SE 2/3, 8 | Portrait |
| Reference | 402 × 874 | iPhone 16 / test canvas | Portrait |
| Large | 430 × 932 | iPhone 16 Pro Max | Portrait |
| Tablet portrait | 810 × 1080 | iPad 10.9" | Portrait |
| Tablet landscape | 1280 × 800 | iPad 10.9" rotated | iPad only |

Text scale: `1.0`, `1.3`, `2.0`. Safe-area padding: `top: 0` (test), `top: 47`
(notch), `top: 59` (Dynamic Island); `bottom: 0` and `bottom: 34`.

## House rules that apply to every prompt

1. **Never run the app.** `flutter run`, hot reload, and terminating the simulator
   app are forbidden (`CLAUDE.md` §5 — it has already cost two debugging rounds).
   Verification is `flutter analyze` and `flutter test` only.
2. **Surgical changes.** Every changed line traces to the responsive goal. Do not
   restyle, rename, or "improve" adjacent code.
3. **No new dependencies.** No `flutter_screenutil`, no `sizer`, no
   `responsive_framework`. `MediaQuery` and `LayoutBuilder` are enough.
4. **The 402×874 design stays pixel-identical.** Every change must be a no-op at
   the reference canvas with zero padding and `TextScaler.noScaling`. That is what
   keeps the existing suite green and is the cheapest proof the refactor is safe.
