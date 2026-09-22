# Prompt 13 — Settings screen

**Files:** `lib/settings/settings_screen.dart` (257 lines), `settings_route.dart`,
`settings_tokens.dart`, `settings_parts.dart`
**Route:** `/settings` (`lib/app/router.dart:127-131`)
**Depends on:** [00-shared-foundation.md](00-shared-foundation.md)

---

## Prompt

> You are fixing a **crash** and then making SPEC's Settings screen render correctly on
> every phone and iPad size, in `/Users/ahmadraza/Downloads/SPEC/spec`. Read all four files
> under `lib/settings/` in full first.
>
> ### The crash — fix this first, on its own commit
>
> ```
> CustomScrollView                                        // settings_screen.dart:128-181
>   SliverPadding(fromLTRB(18, 56, 18, 44))               // 140
>     SliverFillRemaining(hasScrollBody: false)           // 141
>       Column(crossAxisAlignment: start)                 // 143-175
>         ... back circle, title, rules, privacy, 3 chips, status ...
>         const Spacer()                                  // 167   <-- crash
>         ... version text ...
> ```
>
> `SliverFillRemaining(hasScrollBody: false)` gives its child a *tight* height while the
> child fits the remaining viewport. Once the child's intrinsic height exceeds that space,
> the sliver lets the child determine its own height so the scroll view can reach it — which
> means the `Column` receives an **unbounded** height constraint. A `Spacer` (non-zero flex)
> in a `Column` with unbounded height throws:
>
> ```
> RenderFlex children have non-zero flex but incoming height constraints are unbounded.
> ```
>
> That is a hard exception, not a clipped pixel. Budgeting from the file's own constants —
> `_top 56` + `_bottom 44` + `_blockGap 20 ×5` + back circle 44 + title block ≈68 + two
> rules + privacy block ≈129 + three chips at the 44pt `TapTarget` floor + `_chipGap 4 ×2`
> = 140 + status `minHeight` 22 + version ≈11 — the content is already roughly **560-580pt**
> at scale 1.0. A 320×568 device has 468pt left after its own padding. At the foundation's
> 1.5 text-scale ceiling the title alone goes 54pt → 81pt and the whole block passes 700pt,
> so this crashes on a small phone and is plausible even on the 402×874 test canvas.
>
> `letterSpacing` makes it worse and is easy to miss: `CollectionsText.title` carries
> `-2.70` and `SpecText.privacy` carries `+2.64` in **absolute points**
> (`lib/theme/spec_tokens.dart`), so spacing does not shrink or grow with the glyphs.
>
> **The fix:**
> ```
> SliverFillRemaining(
>   hasScrollBody: false,
>   child: ConstrainedBox(
>     constraints: BoxConstraints(minHeight: /* remaining viewport height */),
>     child: Column(... Spacer() ...),
>   ),
> )
> ```
> The `ConstrainedBox(minHeight:)` re-bounds the height so the `Spacer` is always legal,
> while `minHeight` keeps the version text pinned to the bottom whenever there is room —
> which is the whole point of the `Spacer`. Get the remaining height from a `LayoutBuilder`
> inside the sliver, or use `SliverFillRemaining`'s own constraints.
>
> No existing test catches this: `test/settings/settings_screen_test.dart:7` pins
> `Size(402, 874)` and never sets `textScaler`, and the one overflow-adjacent assertion
> (78-92, "a long status fits the canvas without overflow") only checks
> `version.bottom <= 874` at default scale.
>
> ### Then the responsive work
>
> 1. **No text on the screen has a `maxLines` except the title.** Line 188 sets
>    `maxLines: 1` on `'SETTINGS'`; the counts line (190), all four privacy lines (200), the
>    body copy (202-206), the three chip labels (`settings_parts.dart:59`), the status text
>    (252), and the version line (172) have none. The body copy and the status line are the
>    two that can grow several lines at scale and compound the height budget above.
> 2. **`TapTarget` makes every chip full-width without meaning to.**
>    `lib/widgets/tap_target.dart:8-25` is `GestureDetector > ConstrainedBox(minHeight: 44)
>    > Center(heightFactor: 1, child)`. `widthFactor` is left null, and `Align`/`Center` only
>    shrink-wraps width when `widthFactor != null` or `maxWidth` is infinite — so in the
>    bounded, non-tight cross-axis slot a `Column(crossAxisAlignment: start)` hands it
>    (`settings_screen.dart:220-236`), the `Center` **expands to the full row width** and
>    then centres the visible pill inside it. The chips are therefore not flush with the 18pt
>    left margin as the `crossAxisAlignment: start` implies. This is a layout-correctness bug
>    that a wider screen makes obvious: at 1280pt the pills float in the middle of the row.
> 3. **`_top 56` / `_bottom 44` are fixed guesses** (10-12) with no `SafeArea` anywhere in
>    `lib/settings/`.
> 4. **No content-width cap.** At 1280pt the 54pt title, the privacy paragraph, and the three
>    action pills all stretch the full width.
>
> ### What to change
>
> - **The `Spacer` fix above, first and alone.** Commit it separately with the exception
>   text in the message. It is a crash fix, not a polish.
> - **Bound the growable text:** `maxLines` + `overflow: TextOverflow.ellipsis` on the
>   counts line (190), the privacy body (202-206, allow 4 lines), and the status text (252,
>   allow 2 — it is a `liveRegion` so truncating it loses information; 2 lines plus ellipsis
>   is the compromise). Leave the four fixed privacy lines (200) unbounded — they are short
>   literals and a `maxLines` there would hide a real string change.
> - **Fix `TapTarget`'s width behaviour.** Add `widthFactor: 1` alongside the existing
>   `heightFactor: 1` in `lib/widgets/tap_target.dart:22` so it shrink-wraps its child's
>   width as the `heightFactor` already does for height. **This is a shared widget** — grep
>   for every use (`Settings`'s chips, `CollectionsHeaderRow`'s EDIT/DONE button at
>   `lib/collections/collections_header.dart:44-76`, and others) and check each one, because
>   any call site that was accidentally relying on the full-width expansion will move. Run
>   the whole suite, not just `test/settings/`.
>   If a call site genuinely wants full width, give it an explicit `SizedBox(width:
>   double.infinity)` rather than reverting the fix.
> - **Insets:** `SpecLayout.topInset(context, design: 56)` and
>   `SpecLayout.bottomInset(context, design: 44)` in the `SliverPadding` at 140.
> - **Cap content width on expanded:** wrap the `Column` in
>   `ConstrainedBox(maxWidth: SpecLayout.maxContentWidth)` and centre it.
> - **Chip labels:** `maxLines: 1` + ellipsis in `settings_parts.dart:59`, and confirm
>   `'RESTORE FROM BACKUP'` — the longest — still fits at 1.5 on 320pt after the `TapTarget`
>   fix. If it does not, the pill's horizontal padding (`_chipPadding` h13, line 7) is the
>   thing to reduce, not the label.
>
> ### What not to change
>
> - Do not touch the confirmation flow. `settings_route.dart:140-154` delegates Restore and
>   Delete confirmation to `showObjectSheet` (`lib/object/object_sheet.dart`) — that sheet is
>   covered by [08-object.md](08-object.md), not here.
> - Do not touch `_statusMinHeight = 22` (23) or the `Semantics(liveRegion: true)` wrapper
>   (243-255). A reserved 22pt so the layout does not jump when a status appears is correct,
>   and the live region is an accessibility affordance.
> - Do not touch `_busyOpacity = 0.4` / the `IgnorePointer` during work (211-241, 29).
> - Do not convert the `CustomScrollView` to a `SingleChildScrollView`. The sliver structure
>   is what makes `SliverFillRemaining`'s bottom-pinning work; the fix is to bound it, not to
>   replace it.
> - Do not add switches, pickers, or rows with trailing controls. There are none today,
>   which is why the classic "label collides with its trailing control" bug does not exist
>   on this screen — do not introduce it.
>
> ### Verification
>
> **Do not run the app** (`CLAUDE.md` §5). `flutter analyze` and `flutter test` only.
>
> Extend `test/settings/settings_screen_test.dart` (exists, `_canvas = Size(402, 874)`,
> line 7) with `pumpResponsive`:
> - `'does not throw at text scale 1.5 on a tiny screen'` — 320×568 at 1.5, assert
>   `tester.takeException()` is null. **Confirm this test fails with the unbounded-height
>   exception before your fix.** That confirmation is the deliverable.
> - `'version text stays pinned to the bottom when content fits'` — 402×874 at 1.0, assert
>   the version's bottom is within a few points of the content area's bottom. This is the
>   guard that the `ConstrainedBox` did not kill the `Spacer`'s purpose.
> - `'content scrolls when it does not fit'` — 320×568 at 1.5, `maxScrollExtent > 0`.
> - `'action chips are left-aligned to the page margin'` — assert each chip's left edge is at
>   18pt. The `TapTarget` fix's guard.
> - `'RESTORE FROM BACKUP does not clip at text scale 1.5'` on 320pt.
> - `'content is capped and centred on a landscape tablet'` — 1280×800.
> - `'content clears a 34pt home indicator and a 59pt Dynamic Island'`.
>
> ### Done when
>
> - `flutter analyze` clean.
> - `flutter test` green across the **whole** suite — the `TapTarget` change reaches other
>   screens, so a green `test/settings/` alone is not sufficient evidence.
> - The scale-1.5 no-throw test passes, and you have recorded that it failed before the fix.
> - The existing assertion at `settings_screen_test.dart:78-92` still passes untouched.

---

## Notes for the reviewer

**This is the only screen in the app with a reachable hard crash**, and it is reachable by
a user simply having a large system font size — no unusual device required. It should be
fixed and shipped independently of the rest of the responsive work.

**`Spacer` inside `SliverFillRemaining(hasScrollBody: false)` is a trap worth naming.** The
sliver looks like it guarantees a bounded height, and it does — right up until the content
outgrows the viewport, which is exactly when a `Spacer` stops being needed and starts being
illegal. The same latent shape exists in Welcome's `Column` + `Spacer`
([02-welcome.md](02-welcome.md)); both fixes are the same `ConstrainedBox(minHeight:)`.

**The `TapTarget` fix is the widest-reaching change in this folder.** It is three words of
code in a 25-line shared widget, and it moves every button in the app that uses it.
`widthFactor: 1` is the correct behaviour — a tap target should wrap its target, not the
row — but "correct" here means "different", and the diff's risk lives entirely in the call
sites, not in the widget. Run everything.
