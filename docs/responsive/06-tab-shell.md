# Prompt 06 — Tab shell (nav chrome)

**Files:** `lib/shell/tab_shell.dart`, `lib/shell/home_shell_route.dart`, `lib/home/home_tab_bar.dart`
**Wraps:** Home (tab 1) and Collections (tab 2)
**Depends on:** [00-shared-foundation.md](00-shared-foundation.md). Must be coordinated with
[05-home.md](05-home.md) and [07-collections.md](07-collections.md) — all three share the
bottom-clearance number.

---

## Prompt

> You are making SPEC's tab shell — the floating tab bar and orb that sit over Home and
> Collections — render correctly on every phone and iPad size, in
> `/Users/ahmadraza/Downloads/SPEC/spec`. Read `lib/shell/tab_shell.dart`,
> `lib/shell/home_shell_route.dart`, and `lib/home/home_tab_bar.dart` in full first.
>
> ### What the shell is today
>
> ```
> SpecTabShell > Stack(fit: expand)                                     // tab_shell.dart:118-145
>   for each SpecTab: HeroMode > Offstage > TickerMode > IgnorePointer
>                     > Opacity > Transform.translate(child)             // 150-192
>   Positioned(left: kTabBarInset, right: kTabBarInset, bottom: kTabBarBottom)
>     _pushFade(HomeTabBar)                                              // 122-133
>   Positioned(left: 0, right: 0, bottom: kOrbBottom)
>     _pushFade(Center(HomeOrb))                                        // 134-143
> ```
>
> `HomeTabBar` (`home_tab_bar.dart:29-93`) is `SizedBox(height: kTabBarHeight = 64)` →
> `GlassSurface` (pill, radius 999) → `Row(mainAxisAlignment: spaceBetween)` of two
> `_Tab` widgets, each itself a `SizedBox(height: 64)` wrapping an icon + label `Row`
> (95-140). Constants: `kTabBarHeight = 64`, `kTabBarInset = 16`, `kTabBarBottom = 24`,
> `kOrbSize = 66`, `kOrbBottom = 32` (lines 9-13).
>
> There is **no `Scaffold` and no `bottomNavigationBar`** — this is a hand-placed
> floating bar. There is no `SafeArea`, no `MediaQuery.paddingOf` read, and no
> width/orientation check anywhere in either file.
>
> ### The three things that break
>
> 1. **`kTabBarBottom = 24` and `kOrbBottom = 32` do not account for the home indicator.**
>    On a device with a 34pt bottom inset the bar sits 24pt from the physical bottom edge —
>    i.e. inside the gesture area, where a swipe-up meant for the system will instead
>    hit a tab.
> 2. **The bar stretches edge-to-edge on wide screens and never becomes a rail.**
>    `Positioned(left: 16, right: 16)` on a 1280pt-wide iPad gives a 1248pt-wide pill
>    holding two `spaceBetween` tabs, leaving a ~1000pt void between them. Nothing in
>    either file checks width or orientation, and there is no `NavigationRail` anywhere
>    in the codebase.
> 3. **`_Tab`'s 19pt icon + 15pt label `Row` is inside a hard `SizedBox(height: 64)`**
>    (`home_tab_bar.dart:95-140`) with no `Flexible` and no scroll. At 1.5 scale the label
>    grows and gets clipped by the enclosing `GlassSurface`'s `ClipRRect`
>    (`home_glass.dart:55-56`) — silently, since a clip produces no overflow banner.
>
> ### What to change
>
> - **Make the bottom offsets safe-area aware.**
>   `bottom: SpecLayout.bottomInset(context, design: kTabBarBottom)` at tab_shell.dart:125,
>   and the same with `design: kOrbBottom` at 137. At the 402×874 test canvas (zero
>   padding) these return 24 and 32 unchanged.
> - **Export the shell's total chrome height as one constant and consume it everywhere.**
>   Today Home hardcodes `112` (`home_screen.dart:13`) and Collections hardcodes `112`
>   (`collections_screen.dart:22`) to clear this bar, with no link back to
>   `kTabBarHeight + kTabBarBottom`. Add to `home_tab_bar.dart` (or `tab_shell.dart`,
>   wherever the constants already live):
>   ```
>   /// What a scrolling tab must pad at the bottom so its last item clears the
>   /// floating bar and orb. Home and Collections both read this; changing the bar's
>   /// size must not require editing two other files.
>   double specShellChromeHeight(BuildContext context) =>
>       SpecLayout.bottomInset(context, design: kTabBarBottom) + kTabBarHeight + <existing slack>;
>   ```
>   Pick `<existing slack>` so the function returns exactly **112** at zero padding, which
>   is what both screens use today. That keeps every current test green while removing the
>   magic number. Then replace the `112` in both screens with a call to it. Coordinate
>   with prompts 05 and 07 so all three land together.
> - **Bound the tab label.** Add `Flexible` + `maxLines: 1` +
>   `overflow: TextOverflow.ellipsis` to `_Tab`'s label, and change the outer
>   `SizedBox(height: 64)` to `ConstrainedBox(minHeight: 64)` so the pill can grow a little
>   rather than clipping. Keep `kTabBarHeight` as the design height.
> - **Cap the bar's width on expanded.** The smallest honest fix: clamp the pill to
>   `SpecLayout.maxContentWidth` and centre it, so on an iPad it reads as a floating pill
>   rather than a stretched strip. Implement by replacing
>   `Positioned(left: 16, right: 16)` with a `Positioned(left: 0, right: 0)` + `Center` +
>   `ConstrainedBox(maxWidth: ...)`, where the max is
>   `isExpanded ? maxContentWidth : double.infinity` so phones are bit-identical.
> - **Do not build a `NavigationRail`.** See the note below — raise it with the user
>   instead.
>
> ### What not to change
>
> - Do not touch the tab-switch animation: `_switchDuration = 360ms`,
>   `_switchTravel = 24.0`, `_breathePeriod`, `_breatheScale`, `_pushFadeCurve`
>   (tab_shell.dart:6-17).
> - **Do not touch `HeroMode(enabled: isCurrent)` at tab_shell.dart:172.** It disables
>   Hero participation for the offstage tab so two trees cannot both claim a tag. Removing
>   or reordering it produces duplicate-flight crashes that are painful to diagnose.
> - Do not touch the `Offstage`/`TickerMode`/`IgnorePointer` stack at 150-192. That is the
>   keep-both-tabs-alive mechanism and it is correct.
> - Do not touch the glass blur values (`_barBlur = 30`, `_orbBlur = 24`,
>   `_glassSaturation = 2.0`, home_tab_bar.dart:15-17) or the shadow geometry (55-57,
>   210-213).
> - Do not change `kOrbSize = 66`. A 66pt primary action target is correct at every size.
>
> ### Verification
>
> **Do not run the app** (`CLAUDE.md` §5). `flutter analyze` and `flutter test` only.
>
> Extend `test/shell/tab_shell_test.dart` (exists, pins `Size(402, 874)`) with
> `pumpResponsive`:
> - `'chrome height is 112 at zero padding'` — the guard that the extracted constant is a
>   no-op. Assert `specShellChromeHeight` equals the literal both screens use today.
> - `'tab bar clears a 34pt home indicator'` — assert the bar's bottom edge is at least
>   34pt above the canvas bottom.
> - `'orb clears a 34pt home indicator'`.
> - `'tab bar is capped and centred on a landscape tablet'` — 1280×800: assert the pill's
>   width `<= SpecLayout.maxContentWidth` and that it is horizontally centred.
> - `'tab bar spans the full inset width on a phone'` — 402×874: assert width is
>   `402 - 2 * kTabBarInset`. The no-op guard for the cap.
> - `'tab labels do not clip at text scale 1.5'` — 320×568 at 1.5, `expectNoOverflow`,
>   and assert each label's rect is inside the pill's rect.
>
> ### Done when
>
> - `flutter analyze` clean; `flutter test` green with no edits to existing assertions.
> - `grep -rn "112" lib/home/home_screen.dart lib/collections/collections_screen.dart`
>   returns nothing — both now call the shared function.
> - The phone-width and 112-at-zero-padding tests pass, proving the phone rendering is
>   untouched.

---

## Notes for the reviewer

**The `112` duplication is the real find here.** Two screens independently hardcode a
number whose correctness depends on three constants in a third file. That is a latent bug
waiting for someone to change `kTabBarHeight`. Extracting it is a smaller diff than
leaving it and is the only change in this prompt that fixes something other than tablets.

**On the `NavigationRail` question — do not build it.** A rail is not a CSS tweak: it
changes the shell from `Stack`-over-content to a side-by-side layout, which moves the
content origin, invalidates the fixed `56`/`112` insets on both tabs, relocates the orb
(the app's primary action), and rewrites every `Positioned` in both child screens. That is
a redesign of the app's navigation, and the user asked for responsiveness, not a
redesign. Cap and centre the pill, which fixes the "stretched strip" ugliness for a few
lines, and put the rail question to the user with this cost attached.

**Landscape only exists on iPad.** `android/app/src/main/AndroidManifest.xml:14` is
`screenOrientation="portrait"` and `ios/Runner/Info.plist:62-71` locks iPhone to portrait
while allowing iPad all four. So every landscape concern in this prompt is an iPad
concern. If iPad is not a shipping target, the cap-and-centre change is still worth doing
(it is four lines) but the rail conversation is moot.
