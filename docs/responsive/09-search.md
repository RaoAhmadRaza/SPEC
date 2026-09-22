# Prompt 09 — Search screen

**Files:** all 13 files under `lib/search/` — chiefly `search_screen.dart`, `search_tokens.dart`,
`search_pill.dart`, `search_result_row.dart`, `search_result_list.dart`, `search_chips.dart`,
`search_empty.dart`, `search_waveform.dart`, `search_header.dart`, `search_page_route.dart`
**Route:** `/search` with optional `?scope=` and `?all=1` (`lib/app/router.dart:88-107`)
**Depends on:** [00-shared-foundation.md](00-shared-foundation.md)

---

## Prompt

> You are making SPEC's Search screen render correctly on every phone and iPad size, in
> `/Users/ahmadraza/Downloads/SPEC/spec`. Read every file under `lib/search/` in full
> first.
>
> ### What the screen is today
>
> ```
> Material(type: transparency)   // required: the live TextField has no other Material ancestor
>   > DefaultTextStyle > ColoredBox
>     > Padding(_pagePadding = fromLTRB(18, 56, 18, 0))         // line 19
>       > Column(stretch)                                        // 277-316
>           _entrance(SearchHeaderRow)      // fixed, does not scroll
>           SizedBox(_blockGap = 22)
>           _buildPill()                    // Hero pill with the live TextField — fixed
>           SizedBox(22)
>           Expanded(                        // 298 — the only flex
>             _entrance(SingleChildScrollView(
>               padding: EdgeInsets.only(bottom: viewInsets + _blockGap),   // 302
>               child: Column(_buildBelowPill()),
>             )))
> ```
>
> `_buildBelowPill()` (373-382) is `[SearchCountRow, SearchResultList, _buildBodyRegion(),
> optional RecentChips]`. `SearchResultList` (`search_result_list.dart:27-39`) is a
> `KeyedReflow<SearchResult>` with `cellHeight: kSearchRowHeight (83.0)` — rows are
> absolutely positioned by index, not laid out by a `ListView`.
>
> Note the structure is the **inverse** of Object's: here the header and pill are fixed
> `Column` children and only the region below scrolls. There is no `LayoutBuilder` and no
> `DraggableScrollableSheet` anywhere in the directory.
>
> ### The five things that break
>
> 1. **`kSearchRowHeight = 83.0` is a hard height, not a minimum.**
>    `search_result_row.dart:78-88` applies it to an `AnimatedContainer`, and
>    `KeyedReflow` positions every row by that exact `cellHeight`. Inside is a 17pt name
>    and 10pt zone with `v14` padding. At 1.5 scale the text needs more than 83pt and gets
>    clipped — and because `KeyedReflow` places rows by index arithmetic, a taller row
>    does not push the next one down, it overlaps it.
> 2. **`_Spec` in the result row has no `maxLines` or `overflow` at all.**
>    `search_result_row.dart:156-186`. It is the trailing non-`Expanded` child after the
>    54pt thumb and gaps, so a long spec squeezes the `Expanded` name/zone column and then
>    overflows the `Row`. Name and zone are guarded (98-110); the spec is not.
> 3. **The keyboard only pads the scroll region — the pill holding the focused field never
>    moves.** `viewInsetsOf(context).bottom` is read at 273 and used only in the scroll
>    padding at 302. The header and pill are outside the `Expanded`, so on a 568pt screen
>    with a ~300pt keyboard the visible result area collapses to almost nothing while the
>    pill stays put. Compare `lib/collections/collections_screen.dart:254`, which shrinks
>    its whole content region, and `lib/object/object_screen.dart:509,539,579`, which
>    shrinks the viewport *and* moves the floating bar.
> 4. **The scope chip can overflow before the field yields.**
>    `search_pill.dart:219-243`: `_ScopeChip` is a fixed-size sibling placed *before*
>    `Expanded(field)` (197-209) and contains an unbounded-width zone-name Hero label. A
>    long scoped zone name at 320pt overflows the pill.
>    Same class of bug in `search_empty.dart:121,207-236` — the `ADD TO {ZONE}` button
>    label has no truncation inside a fixed 56pt container.
> 5. **The waveform is a fixed 5 bars, 20pt wide** (`search_waveform.dart:8,13-15`). This
>    is **correct** — see "what not to change".
>
> ### What to change
>
> - **`kSearchRowHeight` becomes a minimum, and `KeyedReflow` must be told about it.**
>   This is the primary fix and the only one with real depth. Two options:
>   1. Keep `KeyedReflow` and make `cellHeight` scale-aware — compute it once per build
>      from `MediaQuery.textScalerOf(context)` the way
>      `libraryCellHeight` already does (`lib/library/library_cell.dart:59-78`, which
>      measures its exact styles with a `TextPainter` and returns a height). **Do this
>      one.** The precedent exists, it is a dozen lines, and it keeps the animated
>      index-positioned list that the screen's motion design depends on.
>   2. Replace `KeyedReflow` with a `ListView` of intrinsically-sized rows. Rejected: it
>      throws away the reflow animation and is a much larger diff.
>   Export the computed height as `searchRowHeight(BuildContext)` alongside the existing
>   constant, and keep `kSearchRowHeight = 83.0` as the reference value the function
>   returns at scale 1.0. Assert that equality in a test.
> - **Bound `_Spec`:** `maxLines: 1` + `overflow: TextOverflow.ellipsis`
>   (`search_result_row.dart:178-182`). **Careful:** this `Text` is the source end of the
>   `obj-$id-spec` Hero whose destination is the Object screen's 108pt shrink-to-fit spec
>   (`lib/object/object_hero.dart:45-83`). Read that before changing truncation, and run
>   the Hero tests in both `test/search/` and `test/object/`.
> - **Shrink the whole content region for the keyboard, not just the scroll padding.**
>   Move the `viewInsets` subtraction up: make the outer `Padding`/`Column` bottom-bounded
>   by `viewInsetsOf(context).bottom` the way Collections does at
>   `collections_screen.dart:248-254`. The pill then stays visible above the keyboard with
>   the results scrolling in the remaining gap, instead of the results being squeezed to
>   nothing beneath a pill that never moved.
> - **Scope chip:** wrap the zone-name label in `Flexible` with `maxLines: 1` + ellipsis,
>   so the chip yields before the pill overflows. Same treatment for the
>   `ADD TO {ZONE}` button label in `search_empty.dart:121`, and change that button's fixed
>   56pt height to `ConstrainedBox(minHeight: 56)`.
> - **Insets:** `SpecLayout.topInset(context, design: 56)` at line 19.
> - **Cap content width on expanded.** Result rows spanning 1244pt put a 54pt thumb an
>   absurd distance from a 26pt spec. Wrap the `Column` at 277-316 in
>   `ConstrainedBox(maxWidth: SpecLayout.maxContentWidth)` and centre it.
>   `search_empty.dart`'s `_bodyMaxWidth = 300.0` (line 15) can stay as-is — it is already
>   a cap.
>
> ### What not to change
>
> - **Leave the waveform alone.** `search_waveform.dart`'s five bars at
>   `_barHeights = [7,14,18,11,6]` (line 8), `_barWidth = 2.0`, `_barGap = 2.5`,
>   `_boxHeight = 18.0` (13-15) total a fixed 20×18pt footprint as the trailing
>   non-flexible child of the pill's `Row`, with `Expanded(field)` absorbing all remaining
>   space. That is exactly right: it is a decorative activity indicator, not a data
>   visualisation, and making the bar count width-derived would add code and change
>   nothing a user perceives. Same for `StaticWaveform` (162-185), which exists so the
>   Hero flight does not need a second `AnimationController`.
> - **Do not touch `Material(type: MaterialType.transparency)`** at line 277. The live
>   `TextField` requires a `Material` ancestor and there is none otherwise.
> - Do not touch `search_page_route.dart`'s timings or the `delegatedTransition`
>   `_fadeBehind` interval (13, 76-91). The behind-screen fading out over the first 48% of
>   a 420ms push is a deliberate choice.
> - Do not add a `createRectTween` to the pill Hero. The shuttle (`search_pill.dart:93-134`)
>   lerps border, blur, and highlight and delays the content cross-fade to the last 40%.
>   Adding a rect tween is a motion-design change, not a responsiveness fix.
> - Do not add a loading state. There is deliberately none — the waveform's `querying`
>   state (line 246) is the only in-flight signal. Adding a spinner is a product decision.
>
> ### Verification
>
> **Do not run the app** (`CLAUDE.md` §5). `flutter analyze` and `flutter test` only.
>
> Extend `test/search/search_screen_test.dart` (exists, pins `Size(402, 874)`) with
> `pumpResponsive`:
> - `'row height is 83 at scale 1.0'` — the no-op guard on the computed height.
> - `'rows do not overlap at text scale 1.5'` — pump several results at 1.5 on 320×568;
>   assert each row's rect does not intersect the next. **This is the test that catches
>   today's actual bug**; confirm it fails before your change.
> - `'a long spec never overflows the result row'` — 320pt, a spec of 80 characters,
>   `expectNoOverflow`.
> - `'the pill stays visible when the keyboard is up'` — `viewInsets: bottom 300` on
>   320×568: assert the pill's rect is fully above 268pt and that at least one result row
>   is still visible.
> - `'a long scoped zone name does not overflow the pill'` — scope set to a
>   maximum-length zone name at 320pt.
> - `'content is capped and centred on a landscape tablet'` — 1280×800.
> - `'ADD TO ZONE button does not clip a long zone name at scale 1.5'`.
>
> ### Done when
>
> - `flutter analyze` clean; `flutter test` green with **no edits to existing assertions**,
>   Hero tests included.
> - The 83-at-scale-1.0 test passes.
> - The row-overlap test passes and you have confirmed it fails on the pre-change code.

---

## Notes for the reviewer

**The row-overlap bug is the most interesting defect in the app.** Most fixed-height
containers clip when their content grows — annoying but obvious. `KeyedReflow` positions
rows by `index * cellHeight`, so a row whose *content* grows past `cellHeight` does not
push its neighbour down; it draws on top of it. No overflow banner, no clipping artifact,
just two results occupying the same space. That is why the fix is a scale-aware
`cellHeight` rather than a `minHeight` on the row.

**`libraryCellHeight` is the pattern to copy, not reinvent.**
`lib/library/library_cell.dart:59-78` already does exactly this: measure the exact
`TextStyle`s with a `TextPainter` against the ambient `TextScaler`, sum the fixed parts,
return a height. The Library grid runs on the same `KeyedReflow` and does not have this
bug *because* it does that. Search should do the same thing the same way.

**The keyboard change is a behaviour change, not just a layout fix.** Today the pill stays
put and the results get squeezed; after the change the whole region shrinks and the pill
rides up. That is better and matches Collections and Object — but it is visible, so it
belongs in the commit message rather than buried.
