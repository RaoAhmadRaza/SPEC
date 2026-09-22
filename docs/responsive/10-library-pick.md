# Prompt 10 — Library pick screen

**Files:** `lib/library/library_pick_screen.dart`, `library_cell.dart`, `library_chrome.dart`,
`library_empty.dart`, `library_models.dart`, `library_pick_route.dart`, `library_tokens.dart`
**Reached from:** the Add flow — this is the bundled 100-object library picker.
**Depends on:** [00-shared-foundation.md](00-shared-foundation.md)

---

## Prompt

> You are making SPEC's library picker render correctly on every phone and iPad size, in
> `/Users/ahmadraza/Downloads/SPEC/spec`. Read every file under `lib/library/` in full
> first, plus `lib/widgets/keyed_reflow.dart`, which the grid is built on.
>
> ### What the screen is today
>
> ```
> Material(transparency) > DefaultTextStyle > Stack(fit: expand)        // 326
>   ColoredBox
>   SingleChildScrollView(keyboardDismissBehavior: onDrag,
>       padding: _pagePadding(18,56,18,108) + viewInsets.bottom)        // 330-334
>     Column(stretch) = _buildBlocks()                                   // 367-411
>       header row, headline, search pill, filter chips, rule row,
>       KeyedReflow grid, body region (empty / no-match / grid)
>   Positioned(left/right: _barInset 16, bottom: _barBottom 24)          // 340-360
>     LibraryBottomBar (fixed _barHeight 64)
> ```
>
> **This screen is already the app's best grid citizen.** The grid is
> `KeyedReflow<LibraryItem>` (390-409) — a `LayoutBuilder` that computes
> `cellWidth = (maxWidth - (columns-1)*crossGap) / columns`
> (`keyed_reflow.dart:191-195`) — and its cell height comes from `libraryCellHeight(context)`
> (`library_cell.dart:59-78`), which **measures the exact `itemName` (13pt) and `itemSpec`
> (9pt) styles with a `TextPainter` against the live `MediaQuery.textScalerOf`**. So cells
> already grow with text scale and vertical text overflow is already impossible. Preserve
> both mechanisms; other prompts point at them as the precedent.
>
> ### The four things that break
>
> 1. **`LibraryRuleRow` is the overflow.** `library_chrome.dart:144-161` is
>    `Row(mainAxisAlignment: spaceBetween)` with two **non-flexible, un-ellipsised** `Text`
>    children: the count string (e.g. `'LIBRARY · 100 OBJECTS'`, mono 10pt,
>    `letterSpacing: 2.2`) and `'OFFLINE'`. At 320pt the usable width is `320 - 36 = 284pt`;
>    at 1.5 scale the count string alone plausibly exceeds it, and unlike the bottom bar
>    there is no ellipsis on either side. This is the first thing that breaks on this screen.
> 2. **`_gridColumns = 3` is a compile-time constant** (line 30) passed straight into
>    `KeyedReflow`, so the one piece of real responsive machinery on the screen is fed a
>    fixed number. At 810pt wide each cell is ~248pt while `kLibraryThumbHeight` stays 84pt
>    (`library_cell.dart:8`) and `Image.asset(..., fit: BoxFit.cover)` (193-197) crops the
>    thumbnail into an extreme wide letterbox.
> 3. **`LibraryBottomBar`'s `ADD YOUR OWN` chip is not flexible.**
>    `library_chrome.dart:191-217`: the `'Not in the list?'` side is correctly
>    `Flexible` + ellipsis (194-201), but the chip beside it (202-215) is not, inside a
>    fixed `_barHeight = 64` (line 17).
> 4. **The grid builds every cell eagerly.** `KeyedReflow` emits one `AnimatedPositioned`
>    per item unconditionally (`keyed_reflow.dart:205-226`) inside the page's single
>    `SingleChildScrollView`. With the bundled library at 100 objects
>    (`assets/library.json`) that is 100 live cells. It works, but it is why the screen
>    must not grow its item count without revisiting this.
>
> ### What to change
>
> - **Rule row:** wrap both `Text`s in `Flexible` with `maxLines: 1` +
>   `overflow: TextOverflow.ellipsis`. The count string is the one that should yield, so
>   give it the larger flex. Smallest possible fix for the screen's only real overflow.
> - **Derive the column count from width.** Replace the `_gridColumns = 3` constant at the
>   `KeyedReflow` call site (390-409) with
>   `SpecLayout.columnsFor(availableWidth, idealCell: <reference cell width>, min: 3, max: 6)`.
>   At 402pt the reference cell is `(402 - 36 - 2*9) / 3 = 116pt`, so the function **must
>   return exactly 3 at 402pt** — assert it. An 810pt iPad then gets 6, which keeps the
>   thumbnails close to their designed 84pt-tall proportion instead of stretching them.
>   You need the available width, which `KeyedReflow`'s own `LayoutBuilder` has — pass the
>   column count in as a callback, or wrap the call site in its own `LayoutBuilder`. The
>   second is the smaller diff.
> - **Bottom bar chip:** `Flexible` + `maxLines: 1` + ellipsis on the chip label, and
>   `ConstrainedBox(minHeight: 64)` instead of the fixed `_barHeight`.
> - **Insets:** `SpecLayout.topInset(context, design: 56)` and
>   `SpecLayout.bottomInset(context, design: 108)` in `_pagePadding` (line 21 — keep its
>   existing "108 at the bottom clears the floating bar" comment and extend it), plus
>   `SpecLayout.bottomInset(context, design: 24)` for `_barBottom` (line 34). **Both must
>   move together** or the last grid row hides under the bar.
> - **Cap content width on expanded** at `SpecLayout.maxContentWidth` for the header,
>   headline, and search pill — but **not** for the grid, which wants the width. Two caps
>   in one column: put the cap on the non-grid blocks in `_buildBlocks()` and leave the
>   grid full-width. Say so in a comment.
> - **`library_empty.dart`:** `_bodyMaxWidth = 300.0` (line 15) is already a cap and can
>   stay. Add `maxLines` + ellipsis to the no-match and empty-category headlines so they do
>   not wrap to four lines at 1.5.
>
> ### What not to change
>
> - **Do not touch `libraryCellHeight`** (`library_cell.dart:59-78`). It is the correct
>   scale-aware measurement and prompts 05 and 09 both cite it as the model.
> - **Do not touch `KeyedReflow`'s internals** (`lib/widgets/keyed_reflow.dart`). Home and
>   Search may adopt it; changing it while three screens are in flight is how you break
>   two of them. Pass it different parameters, do not edit it.
> - Do not touch the `maxLines: 1` + ellipsis already on the cell name and spec
>   (`library_cell.dart:145-150, 158-163`). Silent truncation of a long object name is the
>   intended behaviour in a dense grid.
> - Do not touch `library_pick_route.dart`'s drag-to-dismiss math (190-198) or its 30pt
>   flight radius (17). The route rises from the bottom by design.
> - Do not touch `keyboardDismissBehavior: onDrag` (line 331). It is correct for a
>   searchable grid.
> - **Do not add lazy building or pagination.** 100 cells works today. Virtualising the
>   grid is a real change with real animation consequences and the user did not ask for it —
>   mention the ceiling, do not raise it.
>
> ### Verification
>
> **Do not run the app** (`CLAUDE.md` §5). `flutter analyze` and `flutter test` only.
>
> Extend `test/library/library_pick_screen_test.dart` (exists, pins `Size(402, 874)`) with
> `pumpResponsive`:
> - `'grid uses three columns at the reference canvas'` — the no-op guard.
> - `'grid uses six columns on a portrait tablet'` — 810×1080.
> - `'rule row does not overflow at text scale 1.5'` — 320×568 at 1.5,
>   `expectNoOverflow`. Today's actual bug; confirm the test fails before the fix.
> - `'bottom bar does not overflow at text scale 1.5'`.
> - `'last grid row scrolls clear of the bottom bar'` — scroll to the end, assert the last
>   cell's bottom is above the bar's top, at 320×568 and at 402×874.
> - `'cell height already grows with text scale'` — a regression guard on
>   `libraryCellHeight`: assert the height at 1.5 exceeds the height at 1.0.
> - `'bottom bar clears a 34pt home indicator'`.
>
> ### Done when
>
> - `flutter analyze` clean; `flutter test` green with no edits to existing assertions.
> - The three-columns-at-402 test passes.
> - The `libraryCellHeight` regression guard passes, proving you did not break the good
>   mechanism while fixing the bad one.

---

## Notes for the reviewer

**This screen shows the codebase already knew the right answer.** `libraryCellHeight`
measures real styles against the real text scaler; `KeyedReflow` derives cell width from a
`LayoutBuilder`. Both are exactly what the other twelve screens lack. The only reason the
screen still breaks is that the column count feeding that machinery is a hardcoded `3` and
one `Row` forgot its `Flexible`s.

**Two caps in one column is the right call here, awkward as it reads.** The grid genuinely
benefits from 810pt of width — six columns of 116pt cells is a better picker than three
columns of 248pt letterboxes. The headline and body copy genuinely do not. Resolving that
with one compromise number would make both worse.

**The 100-cell eager build is worth saying out loud to the user.** It is fine at 100. At
500 bundled objects it is a visible jank on a cold open, and the fix (lazy building) would
cost the reflow animation. That is a product conversation, not a responsiveness one.
