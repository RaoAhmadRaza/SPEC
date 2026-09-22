# Prompt 07 — Collections screen (tab 2)

**Files:** all ten files in `lib/collections/` — `collections_screen.dart`, `collections_route.dart`,
`collections_header.dart`, `collections_chips.dart`, `collections_models.dart`,
`collections_tokens.dart`, `square_caret_field.dart`, `zone_hero.dart`, `zone_list.dart`,
`zone_row.dart`
**Depends on:** [00-shared-foundation.md](00-shared-foundation.md), and the shared chrome-height
constant from [06-tab-shell.md](06-tab-shell.md).

---

## Prompt

> You are making SPEC's Collections screen render correctly on every phone and iPad size,
> in `/Users/ahmadraza/Downloads/SPEC/spec`. Read all ten files under `lib/collections/`
> in full first.
>
> ### What the screen is today
>
> ```
> DefaultTextStyle > Stack(fit: expand)                                 // 244
>   ColoredBox(bg)
>   Positioned(top: _top = 56, left: 0, right: 0,
>              bottom: MediaQuery.viewInsetsOf(context).bottom)         // 248-254
>     _pushFade > CustomScrollView                                      // 256
>       _box(_buildTop())        // header row, title "MY\nSTUFF", totals
>       _box(_buildRule())
>       _box(_buildEmptyBlock()) // AnimatedSize
>       SliverPadding(horizontal: _side = 18) > AnimatedZoneList        // 262-269
>       _box(CollectionsChips, top: _blockGap, bottom: _bottom = 112)   // 270-287
>   Positioned 1px scroll hairline                                      // 293-305
> ```
>
> This screen is **already the best keyboard citizen in the app**: line 254 sets the
> content region's `bottom` to `MediaQuery.viewInsetsOf(context).bottom`, so the scroll
> area genuinely shrinks above the keyboard rather than padding around it. Preserve that.
>
> `AnimatedZoneList` is a `SliverReorderableList` (`zone_list.dart:154`). `ZoneRow`
> (`zone_row.dart:212-256`) is a `Row` of: drag handle slot, 58pt thumb, gap,
> `Expanded(Column(name, specs))`, gap, count/confirm chip, remove slot — the one
> `Expanded` in the whole directory (232) and the reason rows are already width-safe.
>
> ### The four things that break
>
> 1. **`CollectionsTitle` is the module's likeliest overflow.**
>    `collections_header.dart:114-128` is `Row(mainAxisAlignment: spaceBetween,
>    crossAxisAlignment: end)` with **neither child flexible**: the 54pt title
>    (`CollectionsText.title`, `height: 0.9`, `letterSpacing: -2.70`,
>    `collections_tokens.dart:59-66`) and a right-hand `Column` of totals lines. At 1.5
>    scale the title alone approaches the full phone width. No `maxLines` is set on the
>    `'MY\nSTUFF'` text either (line 118).
> 2. **The chip row is a plain `Row` with no fallback.** `collections_chips.dart:199-224`
>    holds `+ NEW ZONE` and optionally `EXPORT`, neither `Flexible`, with no `Wrap` and no
>    horizontal scroll. It only survives today because both labels are short and fixed.
>    Note the codebase already has the right pattern elsewhere: `lib/add/add_fields_sheet.dart:469-485`
>    uses `Wrap(spacing: 8, runSpacing: 8)` for its kind chips, and
>    `lib/library/library_chrome.dart:42-61` uses a horizontal `SingleChildScrollView`.
> 3. **The Hero-active zone name has no truncation.** `zone_hero.dart:100-106` sets
>    `overflow: TextOverflow.visible` on the flying name, while the same row's resting name
>    is `maxLines: 1` + ellipsis (`zone_row.dart:302-303`). So one name truncates in one
>    state and paints over the count/remove controls in the other. At 320pt the row's text
>    column is only about 180pt wide.
> 4. **`_top = 56` and `_bottom = 112` are fixed guesses** (`collections_screen.dart:21-22`),
>    with `112` duplicating the shell's chrome height — see
>    [06-tab-shell.md](06-tab-shell.md).
>
> ### What to change
>
> - **Title row:** wrap the 54pt title in `Flexible` + `FittedBox(fit: BoxFit.scaleDown)`
>   and the totals `Column` in `Flexible`. Add `maxLines: 2` to the `'MY\nSTUFF'` text
>   (two lines is the design). Keep the 54pt token. Do the same for
>   `CollectionsEmptyBlock`'s 42pt `'NO ZONES\nYET.'` (line 148) — it sits in a growable
>   `Column` so it wraps rather than overflowing today, but it will wrap to four lines at
>   1.5 and push the body copy off the block.
> - **Chip row:** convert the `Row` at 199-224 to `Wrap(spacing: _chipGap, runSpacing: _chipGap)`.
>   At the reference canvas with two short chips this lays out identically to the `Row` —
>   verify that in a test. `Wrap` over a horizontal scroller because there are two chips,
>   not twenty, and a scroller hides the second one.
> - **Hero name:** change `overflow: TextOverflow.visible` (zone_hero.dart:105) to
>   `TextOverflow.ellipsis` with `maxLines: 1`, matching the resting state. **Then check
>   the flight:** the shuttle at `zone_hero.dart:46-80` casts
>   `(fromHeroContext.widget as Hero).child as ZoneHeroLabel` (53-54) and its
>   non-reduced-motion branch reads only `from.name`, never `to.name`, so both ends must
>   keep rendering identical text. Ellipsis on both ends preserves that. Run the existing
>   Hero tests in `test/collections/` and `test/search/`.
>   While you are in that file: the cast at 53-54 will throw if a `Hero`'s child is ever
>   wrapped in another widget. **Do not fix that now** — it is pre-existing and unrelated
>   to responsiveness — but mention it to the user.
> - **Insets:** `SpecLayout.topInset(context, design: 56)` at line 248, and replace the
>   `_bottom = 112` at line 22 with the shared `specShellChromeHeight(context)` from
>   prompt 06. **Do not touch line 254's `viewInsetsOf` read** — that is the keyboard
>   handling and it is already right.
> - **Cap content width on expanded.** Wrap the `CustomScrollView`'s slivers in a centred
>   `SliverConstrainedCrossAxis` (or put the cap in each `_box`) at
>   `SpecLayout.maxContentWidth`. A 54pt display title and 26pt zone names spread across
>   1280pt is unreadable, and `Column(crossAxisAlignment: stretch)` (line 319) currently
>   stretches every row to the full physical width.
> - **The caret is a fixed height that ignores text scale.** `_caretHeight = 24.0`
>   (`square_caret_field.dart:12`, used at 141-146) stays 24pt while the glyphs it sits
>   beside double. The file already reads `MediaQuery.textScalerOf(context)` at line 178
>   for caret *placement* — use the same scaler to size the caret. Small fix, visible
>   payoff, and it is the one place in the file already wired for it.
>
> ### What not to change
>
> - **Do not touch `MediaQuery.viewInsetsOf(context).bottom` at line 254.** This is the
>   only screen in the app that shrinks its viewport for the keyboard instead of padding
>   around it. It is the pattern the others should copy.
> - Do not touch the reorder animation constants (`_leaveScale = 0.97`,
>   `_liftScale = 1.02`, `zone_list.dart:13-15`) or the drag shadow (193-198).
> - Do not act on the `ponytail:` note at `zone_list.dart:158-160` (per-crossing haptics)
>   or at `square_caret_field.dart:166-168` (caret pins right on overflow). Both are
>   deliberate, documented simplifications and neither is a responsiveness issue.
> - Do not unify `lib/collections/square_caret_field.dart` with the near-duplicate
>   `lib/widgets/square_caret_field.dart`. They differ (`_caretHeight` 24 vs 20,
>   `_underlineHeight` present in one). That de-duplication is real work but it is **not**
>   this task — mention it, do not do it.
> - Do not change `kZoneNameMaxLength`'s value. It is defined outside this directory and
>   the input cap is what keeps names short enough for the row to work.
>
> ### Verification
>
> **Do not run the app** (`CLAUDE.md` §5). `flutter analyze` and `flutter test` only.
>
> Extend `test/collections/collections_screen_test.dart` (exists, `_canvas = Size(402, 874)`,
> line 15) with `pumpResponsive`:
> - `'title row does not overflow at text scale 1.5'` — 320×568 at 1.5, `expectNoOverflow`.
> - `'chip row lays out identically to the reference at 402x874'` — capture both chips'
>   rects before and after the `Wrap` change, or assert exact expected positions. This is
>   the no-op guard.
> - `'chips wrap to a second line at text scale 1.5 on a tiny screen'` — assert the second
>   chip's `top` is below the first chip's `bottom`.
> - `'a maximum-length zone name never paints over the row controls'` — pump a name at
>   `kZoneNameMaxLength` at 320pt; assert the name's rect does not intersect the count
>   chip's rect, **in both the resting and Hero-ready states** (`zone_row.dart:297-299`
>   selects between them).
> - `'keyboard shrinks the scroll region'` — set `viewInsets: EdgeInsets.only(bottom: 300)`
>   and assert the scroll viewport's height dropped by 300. A regression guard on the one
>   thing this screen already does right.
> - `'content is capped and centred on a landscape tablet'` — 1280×800.
> - `'content clears a 34pt home indicator and a 59pt Dynamic Island'`.
>
> ### Done when
>
> - `flutter analyze` clean; `flutter test` green with no edits to existing assertions,
>   **including the zone Hero tests**.
> - The chip-row no-op test and the keyboard-shrink test both pass.
> - `grep -n "112" lib/collections/collections_screen.dart` returns nothing.

---

## Notes for the reviewer

**Collections is the reference implementation for keyboard handling.** Line 254's
`viewInsetsOf` read is the correct pattern and the other twelve screens either pad around
the keyboard (Home, Library, Search, Object) or hand-roll a reveal (Not-in-Library). When
the per-screen work is done, this is the one to point at.

**The Hero truncation change is the one with a blast radius.** `zone_hero.dart`'s shuttle
reads only the *source* name and relies on both ends being textually identical; the tag
itself is derived from the lowercased name (`zoneHeroTag`, line 9). Changing overflow on
one end only would be invisible in tests and wrong in motion. Change both, run the Hero
tests, and read `_paint` (83-108) to understand that the painted font size and the animated
`Rect` are interpolated independently — which is why a long name looks wrong mid-flight
today.

**Two things to raise with the user rather than fix.** The brittle
`as ZoneHeroLabel` cast (`zone_hero.dart:53-54`) and the duplicated `SquareCaretField`.
Both are real, neither is about responsiveness, and folding them into this change would
make the diff hard to review.
