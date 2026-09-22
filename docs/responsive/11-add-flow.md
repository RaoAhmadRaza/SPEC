# Prompt 11 — Add flow sheets (steps 04 and 05)

**Files:** `lib/add/add_flow_sheet.dart`, `add_what_sheet.dart`, `add_fields_sheet.dart`,
`add_sheet_route.dart`, `add_sheet_shell.dart`, `add_value_field.dart`, `add_location_row.dart`,
`type_tile.dart`, `photo_drop_card.dart`, `manual_field_row.dart`, `plain_field_theme.dart`,
`add_tokens.dart`, `manual_tokens.dart`
**Entry points:** `showAddFlow` (`add_sheet_route.dart:42-64`) for the two-step flow,
`showAddFields` (73-119) to open step 05 alone.
**Depends on:** [00-shared-foundation.md](00-shared-foundation.md)

---

## Prompt

> You are making SPEC's add-flow bottom sheets render correctly on every phone and iPad
> size, in `/Users/ahmadraza/Downloads/SPEC/spec`. Read every file under `lib/add/` in full
> first (excluding `not_in_library_screen.dart`, which has its own prompt).
>
> ### What the sheets are today
>
> `showAddFlow` pushes a transparent `PageRoute` whose page is `_AddSheetScaffold`
> (`add_sheet_route.dart:207-360`): a `Stack` of a blurred live-Home backdrop (345-357) and
> the sheet, in an `Align(bottomCenter)` + `FractionalTranslation` for the rise (311-319),
> with a vertical drag-dismiss `GestureDetector` (323-329).
>
> `AddFlowSheet` (`add_flow_sheet.dart:33`) is **one continuous glass sheet whose height
> itself animates** between step 04's content height and
> `fullHeight = MediaQuery.sizeOf(context).height - kFieldsSheetTop (96)` (15, 135). Both
> steps are mounted at once — `AddWhatSheet` always (167-191) and `AddFieldsSheet` layered
> via an `OverflowBox` pinned to the top once continued (195-222).
>
> **Step 05's keyboard handling is already correct and deliberate.**
> `add_fields_sheet.dart:375-376` reads `viewInsetsOf(context).bottom` and sets the bottom
> padding to `keyboard + 12` or `_bottomInset (46)`, and the form sits in
> `Expanded(SingleChildScrollView(ClampingScrollPhysics))` (391-424) with the `SAVE` button
> outside it (426). The comment at 388-390 says it plainly: "when the keyboard takes the
> room the blocks scroll instead of overflowing". Preserve this exactly.
>
> ### The five things that break
>
> 1. **`_buildReminderRow` is the clearest overflow in the add flow.**
>    `add_fields_sheet.dart:577-610`, specifically the `Row` at 588:
>    `mainAxisAlignment: spaceBetween`, `crossAxisAlignment: baseline`, two **non-flexible**
>    children — `Text('REMIND ME')` at 10pt with `letterSpacing: 2` (593) and an
>    `AnimatedSwitcher` wrapping the value at 12pt with `letterSpacing: 0.72` (594-604).
>    The longest value is `'EVERY 6 MONTHS'` (`add_kinds.dart:138-143`). At 320pt the sheet
>    padding leaves `320 - 44 = 276pt`; at 1.5 scale the pair exceeds it and **neither child
>    can shrink**.
> 2. **`_buildContextRow` has the same shape, half-fixed.** 433-456: the left side is
>    `Flexible` (440) but `Text(widget.stepLabel)` on the right (453) is not. Lower risk
>    because step labels are short, but it is the same bug.
> 3. **`showAddFields` sizes the sheet to `screenHeight - 96` with no clamp.**
>    `add_sheet_route.dart:92-93`. On a 568pt phone that is 472pt; with a ~300pt keyboard
>    the scroll region above `SAVE` collapses to roughly 172pt. It scrolls, so it does not
>    break — but `kFieldsSheetTop = 96` is subtracted from the height regardless of
>    orientation, so on a 800pt-tall landscape iPad it eats a far larger share of the
>    viewport than it does in portrait.
> 4. **`AddWhatSheet`'s type grid is hardcoded to 3 columns with 96pt tiles.**
>    `add_what_sheet.dart:21` (`_gridColumns = 3`), built as a manual nested
>    `Row`-of-`Expanded` (233-252), with `TypeTile` at a fixed `height: 96`
>    (`type_tile.dart:8`). At 320pt each tile's inner content width is roughly
>    `(320-44-18)/3 - 26 ≈ 60pt`, so labels like `'Clothing'` visibly truncate **at scale
>    1.0** — the `maxLines: 1` + ellipsis at `type_tile.dart:152-163` is doing real work
>    already. At 810pt the same 3 columns make each tile ~250pt wide and still 96pt tall,
>    with the icon and label drifting apart.
> 5. **No `SafeArea` anywhere in the add flow.** Bottom clearance is the hardcoded `46` in
>    both `_sheetPadding` (`add_what_sheet.dart:16`) and `_bottomInset`
>    (`add_fields_sheet.dart:18`).
>
> ### What to change
>
> - **Reminder row:** wrap both children in `Flexible` with `maxLines: 1` +
>   `overflow: TextOverflow.ellipsis`. Give the value the larger flex — the label
>   `'REMIND ME'` is the one that can safely truncate last. Primary fix.
> - **Context row:** `Flexible` + ellipsis on the step label at 453.
> - **Clamp the sheet height.** In both `add_flow_sheet.dart:135` and
>   `add_sheet_route.dart:92-93`, replace `height - kFieldsSheetTop` with a value that is
>   the *smaller* of that and a fraction of the viewport, so a short landscape viewport does
>   not hand 96pt of its 800 to a gap:
>   `min(height - kFieldsSheetTop, height * 0.92)` — or on expanded, cap the sheet's height
>   outright. At 874pt the first term wins (`778 < 804`), so the reference rendering is
>   unchanged; assert that. Also guard the arithmetic: the value must never go negative.
> - **Cap the sheet's width on expanded.** A full-bleed bottom sheet 1280pt wide is wrong
>   at every level. In `add_sheet_shell.dart` (or at the `Align` in
>   `add_sheet_route.dart:311-319`), constrain to `SpecLayout.maxContentWidth` when
>   `SpecLayout.isExpanded(context)` and centre it. Phones stay full-bleed and
>   bit-identical.
> - **Type grid columns from width.** Replace `_gridColumns = 3` at the grid call site with
>   `SpecLayout.columnsFor(availableWidth, idealCell: <reference tile width>, min: 3, max: 5)`.
>   At 402pt the reference tile is `(402 - 44 - 2*9) / 3 ≈ 113pt`, so it **must return 3 at
>   402pt**. The grid is a manual nested `Row` loop (233-252) — keep that structure and make
>   the loop's chunk size the computed column count; do not switch to `GridView`.
>   Keep `TypeTile`'s fixed 96pt height on phones; on expanded let it grow with the cell
>   width or the icon and label will float apart.
> - **Insets:** `SpecLayout.bottomInset(context, design: 46)` for `_sheetPadding.bottom`
>   (`add_what_sheet.dart:16`) and for `_bottomInset` (`add_fields_sheet.dart:18`).
>   **Do not touch the `keyboard + 12` branch** at `add_fields_sheet.dart:376` — when the
>   keyboard is up it already covers the home indicator, so adding the inset there would
>   double-count.
> - **`AddValueField`:** leave the shrink-to-fit alone (see below), but note its caret is a
>   fixed `2×38` with a 20pt floor (11-12) while the value text shrinks from 42pt to a 24pt
>   floor (16, 200). Tie the caret height to the fitted font size so it does not tower over
>   shrunken text. Small, visible.
>
> ### What not to change
>
> - **Do not touch step 05's keyboard handling** (`add_fields_sheet.dart:375-376, 384,
>   388-424`). The `Expanded` + scroll + `SAVE`-outside-the-scroll structure is the correct
>   answer and the comment documents the intent.
> - **Do not touch the `Wrap` for kind chips** (469-485). It already reflows correctly and
>   other prompts cite it as the pattern.
> - **Do not touch `AddValueField`'s `LayoutBuilder` shrink-to-fit** (118, 199-209). It
>   reads `constraints.maxWidth` and shrinks 42pt toward a 24pt floor, then scrolls — the
>   right answer for a single-line value field, and one of only two shrink-to-fit
>   implementations in the app.
> - Do not touch `AddLocationRow`'s fixed `_openHeight = 214` with its internal
>   `ClipRect(SingleChildScrollView)` (14, 275-286). A long zone list scrolls inside a fixed
>   card by design; making the card grow would push `SAVE` around as zones are added.
> - Do not touch the drag-dismiss gesture math (`add_sheet_route.dart:251-252, 266-272`).
> - Do not act on the `ponytail:` note about `AddType.other`'s fallback kind set
>   (`add_kinds.dart:60`). Unrelated.
> - Do not merge the two entry points (`showAddFlow` and `showAddFields`). They exist
>   because the flow can be entered mid-way.
>
> ### Verification
>
> **Do not run the app** (`CLAUDE.md` §5). `flutter analyze` and `flutter test` only.
>
> Extend the existing tests under `test/add/` (they pin `Size(402, 874)`) with
> `pumpResponsive`:
> - `'reminder row does not overflow at text scale 1.5'` — 320×568 at 1.5 with the reminder
>   set to `'EVERY 6 MONTHS'`, `expectNoOverflow`. Today's actual bug; confirm it fails
>   first.
> - `'sheet height is unchanged at the reference canvas'` — assert the sheet's height
>   equals `874 - 96` exactly. The clamp's no-op guard.
> - `'sheet height is clamped on a landscape tablet'` — 1280×800.
> - `'sheet is capped and centred on a landscape tablet'` — width `<= maxContentWidth`.
> - `'sheet is full-bleed on a phone'` — 402×874, width `== 402`. No-op guard.
> - `'type grid uses three columns at the reference canvas'` and `'five on a portrait
>   tablet'`.
> - `'SAVE stays visible with a 300pt keyboard on a tiny screen'` — a regression guard on
>   the handling you are told not to touch.
> - `'context row does not overflow at text scale 1.5'`.
>
> ### Done when
>
> - `flutter analyze` clean; `flutter test` green with no edits to existing assertions.
> - Both no-op guards (reference sheet height, phone full-bleed width) pass.
> - The `SAVE`-with-keyboard guard passes, proving step 05's good behaviour survived.

---

## Notes for the reviewer

**Step 05 is the app's best form.** Scroll region in an `Expanded`, submit button outside
it, keyboard read once and applied as padding, and a comment explaining why. When someone
asks how to build a keyboard-safe sheet in this codebase, this is the file to open. The
prompt is deliberately emphatic about not touching it.

**The reminder row is a two-line fix for a real crash.** Two unprotected `Text`s in a
`spaceBetween` `Row` inside a 276pt budget. It is the highest value-per-line change in the
whole responsive effort.

**The `min(height - 96, height * 0.92)` clamp deserves a comment at the site.** It reads
like a magic formula; what it actually says is "leave a 96pt peek at the top, but never
give away more than 8% of a short viewport". Write that sentence in the code and the next
reader will not undo it.
