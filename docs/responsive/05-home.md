# Prompt 05 — Home screen (tab 1)

**Files:** `lib/home/home_screen.dart`, `home_header.dart`, `home_card.dart`, `home_empty.dart`,
`home_glass.dart`, `home_tokens.dart`
**Route:** `/home` via `HomeShellRoute` (`lib/app/router.dart:83-87`) — the app's default landing route.
**Depends on:** [00-shared-foundation.md](00-shared-foundation.md). Pairs with
[06-tab-shell.md](06-tab-shell.md), which owns the floating bar this screen pads around.

---

## Prompt

> You are making SPEC's Home screen render correctly on every phone and iPad size, in
> `/Users/ahmadraza/Downloads/SPEC/spec`. Read every file under `lib/home/` in full
> first. Home has no `Scaffold` and no nav bar of its own — the floating tab bar and orb
> belong to `lib/shell/tab_shell.dart`, covered by a separate prompt.
>
> ### What the screen is today
>
> ```
> DefaultTextStyle > Stack(fit: expand)                      // 238-280
>   ColoredBox + Image.asset('assets/images/home_bg.png', BoxFit.cover) + scrim
>   SingleChildScrollView(padding: _pagePadding)             // 257-264
>     Column(stretch) = _buildBlocks()                       // 284-333
>       HomeHeaderRow, wordmark, tagline, search pill, HomeCategoryRail,
>       then either HomeEmptyState or HomeSectionRule + _buildGrid()
>   Positioned(top/left/right: 0) 1px scroll hairline        // 266-278
> ```
>
> `_pagePadding = EdgeInsets.fromLTRB(18, 56, 18, 112)` (line 13) — the comment at 11-12
> spells out the assumption: "56 top for the status bar", "112 at the bottom so the last
> tile can scroll clear of the shell's floating bar and orb". Both are hardcoded guesses,
> not `MediaQuery.paddingOf` reads. There is **no `SafeArea` anywhere in `lib/home/` or
> `lib/shell/`**, and the only `MediaQuery` call in either directory is
> `disableAnimationsOf` (home_screen.dart:150, tab_shell.dart:83).
>
> **The grid is hand-rolled, not a `GridView`.** `_buildGrid()` (348-384) is a `Column`
> of `Row`s, each holding exactly **two** `Expanded` tiles (372, 374), separated by
> `SizedBox(height: _gridGap = 9.0)` (31, 368), with a `SizedBox(height: kCardHeight)`
> filler when the last row is odd (377). `lib/widgets/keyed_reflow.dart` — which *does*
> have a real column/cell-geometry engine driven by a `LayoutBuilder` — is **not used
> here** (confirmed by grep).
>
> ### The four things that break
>
> 1. **`kCardHeight = 170` is a hard height with unbounded text inside it.**
>    `home_card.dart:12` feeds `Container(height: 170)` at 241; inside sits a content
>    `Column` (105-166) containing the 32pt `cardSpec` / 27pt `cardSpecTall` Hero text
>    (137-141) **with no `maxLines` or `overflow`**, a 9.5pt `cardSub`, and a name row.
>    At 1.5 scale that column needs roughly half again the vertical space the rigid 170pt
>    box gives it. Only two `Text`s in all of `lib/home/` have overflow guards: the object
>    name (153-154) and the zone chip label (310-311).
> 2. **The 72pt wordmark `Row` has two rigid children and `spaceBetween`.**
>    `home_header.dart:72-118`: the 72pt `SPEC` wordmark with `letterSpacing: -3.24`
>    (`home_tokens.dart:78-85`) plus `™` on one side, the mono column
>    `LOCAL/PRIVATE/YOURS/ALWAYS` on the other. Neither is `Flexible`. At 320pt wide the
>    usable width is `320 - 36 = 284pt`; this is the most likely horizontal `RenderFlex`
>    overflow in the directory, and it is *guaranteed* at 1.5 scale on any phone.
> 3. **The grid is permanently 2 columns.** Two `Expanded` tiles per `Row` regardless of
>    width. On an 810pt-wide iPad each tile is ~390pt wide and 170pt tall — a
>    3.4-to-1 letterbox with `BoxFit.cover` cropping the photo hard. No overflow, but the
>    card composition is destroyed.
> 4. **Both insets are fixed guesses.** `56` top and `112` bottom, where the `112` must
>    stay in agreement with the shell's `kTabBarBottom = 24` / `kOrbBottom = 32` /
>    `kTabBarHeight = 64` (`home_tab_bar.dart:9-13`). Change one and the other must move.
>
> ### What to change
>
> - **Card height becomes a floor, not a ceiling.** Replace
>   `Container(height: kCardHeight)` (home_card.dart:241) with
>   `ConstrainedBox(constraints: BoxConstraints(minHeight: kCardHeight))`. Then, because
>   the manual grid's odd-row filler (`home_screen.dart:377`) and the two tiles in a `Row`
>   must stay the same height, wrap each grid `Row`'s children so the row sizes to the
>   taller card — `IntrinsicHeight` around the `Row`, or `CrossAxisAlignment.stretch` with
>   the row's height driven by the taller child. `IntrinsicHeight` is the smaller diff;
>   it costs an extra layout pass on a 4-tile grid, which is acceptable at this scale.
>   Note the cost in a comment.
> - **Bound the card's spec text.** Add `maxLines: 1` + `overflow: TextOverflow.ellipsis`
>   to the `cardSpec`/`cardSpecTall` Hero text (home_card.dart:137-141). **Careful:** this
>   text is a Hero endpoint (`objectSpecTag`, line 136) whose other end is the Object
>   screen's 108pt spec, which is protected by `fitSpecStyle`
>   (`lib/object/object_parts.dart:159-181`). Changing truncation on one end of a Hero
>   changes what the flight interpolates. Prefer matching the Object screen's approach —
>   shrink-to-fit — over ellipsis if the flight looks wrong; at minimum, verify the
>   existing Hero tests in `test/home/` and `test/object/` still pass.
> - **Wordmark:** `FittedBox(fit: BoxFit.scaleDown)` around the 72pt wordmark, and wrap
>   the mono side column in `Flexible`. Keep the 72pt token.
> - **Make the grid's column count derive from width.** Use
>   `SpecLayout.columnsFor(availableWidth, idealCell: <the reference tile width>, min: 2, max: 4)`
>   inside a `LayoutBuilder` in `_buildGrid()`. Compute the reference tile width from the
>   current design: `(402 - 18 - 18 - 9) / 2 ≈ 178.5`. At 402pt this must return exactly
>   **2** — assert that in a test. An 810pt iPad then gets 4, a 1280pt landscape iPad 4
>   (capped), and the card composition survives.
>   The generic engine for this already exists in `lib/widgets/keyed_reflow.dart:180-231`
>   (columns, crossGap, mainGap, cellHeight, `LayoutBuilder`-driven cell width). **Read it
>   before hand-rolling more grid math** — if adopting it is a smaller change than
>   extending the manual `Row` loop, adopt it; it is already used by the Library grid.
>   Say which you chose and why.
> - **Cap content width on expanded.** Even with 4 columns, a 1280pt line of body text is
>   unreadable. Wrap the scroll view's `Column` in
>   `ConstrainedBox(maxWidth: SpecLayout.maxContentWidth)` **only for the header blocks**,
>   or centre the whole column at a wider cap (e.g. 900pt) so the grid still uses the
>   space. Pick one and justify it in a comment — the grid wants width, the prose does not.
> - **Insets:** `SpecLayout.topInset(context, design: 56)` and
>   `SpecLayout.bottomInset(context, design: 112)`. The bottom value must stay derived
>   from the shell's constants, not duplicated — coordinate with
>   [06-tab-shell.md](06-tab-shell.md) and export the shell's total chrome height as one
>   named constant rather than leaving `112` as a magic number in two files.
>
> ### What not to change
>
> - Do not touch the scroll hairline logic (`_hairlineOffset = 8.0`, line 44; 171-174;
>   266-278). An 8pt scroll threshold is size-independent.
> - Do not touch the entrance animation `dy` offsets (291, 299, 302, 309, 315, 403-404)
>   or `_enterDuration`/`_pressDuration` (37-41).
> - Do not touch `kCardRadii`'s 20/6 corner-cut pairs (home_card.dart:16-41). That shape
>   is the brand language, shared with `StepCard` and the sheets.
> - Do not add a `Scaffold`. Home is deliberately a bare `Stack` under the shell.
> - Do not change `_recentLimit = 3` (line 35). It is a product decision about how many
>   recents show before the Add tile, not geometry — raising it on tablets is a separate
>   conversation with the user.
>
> ### Verification
>
> **Do not run the app** (`CLAUDE.md` §5). `flutter analyze` and `flutter test` only.
>
> Extend `test/home/home_screen_test.dart` (exists, `_canvas = Size(402, 874)`, line 13)
> with `pumpResponsive`:
> - `'grid uses two columns at the reference canvas'` — the guard that the column-count
>   change is a no-op at 402×874.
> - `'grid uses four columns on a portrait tablet'` — 810×1080.
> - `'cards grow rather than clipping at text scale 1.5'` — 320×568 at 1.5,
>   `expectNoOverflow`, and assert the card's height is `> 170`.
> - `'both cards in a row share a height'` — give two objects markedly different spec
>   lengths, assert equal card heights. This is the `IntrinsicHeight` guard.
> - `'wordmark fits the width at every canvas'` — loop `specCanvases`.
> - `'last tile scrolls clear of the shell chrome'` — scroll to bottom, assert the last
>   card's bottom is above `canvas.height - shellChromeHeight`.
> - `'content clears a 34pt home indicator and a 59pt Dynamic Island'` — reference canvas
>   with both paddings set.
>
> ### Done when
>
> - `flutter analyze` clean; `flutter test` green with **no edits to existing
>   assertions** — including the Hero tests in `test/home/` and `test/object/`.
> - The two-columns-at-402 test passes.
> - `grep -n "112" lib/home/home_screen.dart` no longer shows a bare magic number.

---

## Notes for the reviewer

**The Hero coupling is the trap in this prompt.** The card's spec text is one end of a
flight whose other end is the Object screen's 108pt shrink-to-fit spec. Adding ellipsis
to one end without looking at the other produces a flight that visibly changes its text
mid-air. Whoever does this must read `lib/object/object_hero.dart:45-83` and
`lib/object/object_parts.dart:159-181` before touching `home_card.dart:137`.

**`keyed_reflow.dart` is the reuse opportunity.** It is already a
`LayoutBuilder`-driven, column-count-parameterised, animated grid, and the Library screen
already runs on it. Home hand-rolls a worse version of the same thing. Adopting it here
is the lazier fix *and* the more consistent one — but it changes the grid's animation
behaviour, so it needs its own look before committing.

**The width-cap question is genuinely open.** A grid wants all the width it can get; body
copy wants 560pt. Home has both. Two caps in one column is slightly awkward but correct;
one compromise cap is simpler and slightly wrong for both. Flag the choice for the user
rather than deciding silently.
