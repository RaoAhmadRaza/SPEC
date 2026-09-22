# Prompt 12 — Not-in-Library screen (manual add)

**Files:** `lib/add/not_in_library_screen.dart`, `not_in_library_route.dart`,
`library_search_pill.dart`, `manual_field_row.dart`, `manual_return_bar.dart`,
`manual_add_button.dart`, `manual_heroes.dart`, `photo_drop_card.dart`
**Reached from:** the library picker's `ADD YOUR OWN` action, or a no-match result.
**Depends on:** [00-shared-foundation.md](00-shared-foundation.md)

---

## Prompt

> You are making SPEC's manual-add screen render correctly on every phone and iPad size,
> in `/Users/ahmadraza/Downloads/SPEC/spec`. Read `lib/add/not_in_library_screen.dart` in
> full first, plus the six widgets it composes.
>
> ### What the screen is today
>
> ```
> Material(color: bg) > DefaultTextStyle > HeroMode > Stack(fit: expand)   // 315-347
>   SingleChildScrollView(controller: _scroll,
>       padding: _pagePadding(18,56,18,128) with bottom + keyboard)        // 318-339
>     Column(stretch):
>       header (Hero), LibrarySearchPill (Hero), verdict block,
>       PhotoDropCard (FIXED height 210), ManualFieldRow x2 (NAME, SPEC),
>       no-photo hint
>   Positioned(left/right: 16, bottom: _bottomInsets.bottom + keyboard)    // 340-344
>     ManualReturnBar (56) + ADD MANUALLY button (58) + privacy caption
> ```
>
> **This screen has the most sophisticated keyboard handling in the app and it is
> hand-rolled.** `_revealFocusedField()` (224-232) schedules two post-frame callbacks —
> one to let layout settle after the inset change, one to scroll — then
> `_scrollFocusedFieldClear()` (234-271) measures the focused row's `RenderBox` global
> `top`/`bottom` against the pinned bottom block's global top (via `_returnBarKey` /
> `_buttonKey`) and either `jumpTo` (reduced motion) or `animateTo` the difference. It re-runs
> on every `didChangeDependencies` (168-172), so every keyboard show/hide triggers it, and
> on both field focus changes (157-158). The comment at 220-223 explains why it is
> necessary: "the page's viewport runs the full height of the screen".
>
> **Do not replace this with a naive `scrollPadding`.** It exists because the bottom block
> is `Positioned` outside the scroll view, so the framework's own
> `Scrollable.ensureVisible` has no idea the block is there. Understand it before touching
> anything near it.
>
> ### The three things that break
>
> 1. **The fixed 210pt photo card plus a 128pt bottom reserve is a lot of rigid height.**
>    `_pagePadding` bottom is `128` (line 24, "clears the pinned button block") and
>    `PhotoDropCard` is `height: 210` (line 30 — note the same widget is 132pt in the add
>    sheet, `photo_drop_card.dart:12`). On a 568pt screen with a ~300pt keyboard up, the
>    usable scroll window between the search pill and the pinned block is very small. The
>    page scrolls, so this is compression rather than breakage — but the reveal math has to
>    fight for every point.
> 2. **`ManualFieldRow`'s label column is a fixed `SizedBox(width: 56)`**
>    (`manual_field_row.dart:11, 133-136`) with no ellipsis. `'NAME'` and `'SPEC'` are short
>    mono strings so this is low risk today, but at 1.5 scale a 56pt column holding scaled
>    mono text will clip, and the widget takes an arbitrary `label`.
> 3. **Nothing is safe-area aware.** `_pagePadding.top = 56` (24),
>    `_bottomInsets = fromLTRB(16, 0, 16, 24)` (33). The bottom block's `Positioned`
>    already adds the keyboard inset (343) but never the home indicator.
>
> ### What to change
>
> - **Insets:** `SpecLayout.topInset(context, design: 56)` for `_pagePadding.top`, and
>   `SpecLayout.bottomInset(context, design: 24)` for `_bottomInsets.bottom`.
>   **Critical:** line 343 is `bottom: _bottomInsets.bottom + keyboard`. When the keyboard
>   is up, the keyboard already covers the home indicator, so adding the safe-area inset on
>   top of the keyboard would push the block up by 34pt too far. Use the safe-area-aware
>   value **only when `keyboard == 0`**. Write that condition explicitly with a comment —
>   it is the kind of thing that gets "simplified" back into a bug.
>   Then check `_pagePadding.bottom = 128` still exceeds the pinned block's actual height
>   at the new inset, or the last field hides under it.
> - **`ManualFieldRow` label:** add `maxLines: 1` + `overflow: TextOverflow.ellipsis` to the
>   label `Text`, and change the fixed `SizedBox(width: 56)` to a
>   `ConstrainedBox(minWidth: 56)` so a scaled label can claim a little more room. Keep 56
>   as the design width.
> - **Photo card height:** make the 210pt a maximum rather than a fixed value —
>   `ConstrainedBox(maxHeight: 210)` inside an `AspectRatio` or simply cap it against a
>   fraction of the available height so a short viewport with the keyboard up gives the
>   fields more room. Compute the fraction so that at 402×874 with no keyboard the card is
>   **exactly 210pt**; assert that.
>   The image inside uses `BoxFit.contain` here (`photo_drop_card.dart:138`), unlike the
>   library thumb's `cover`, so a shorter card letterboxes rather than crops — which means
>   shrinking it is safe. Good.
> - **Cap content width on expanded.** `_bodyMaxWidth = 300.0` (29) already caps the verdict
>   body. Add a `ConstrainedBox(maxWidth: SpecLayout.maxContentWidth)` around the whole
>   scroll `Column` and centre it, and apply the same cap to the pinned bottom block so the
>   `ADD MANUALLY` button is not 1248pt wide on an iPad.
> - **Re-verify the reveal math at the new sizes.** `_scrollFocusedFieldClear()` (234-271)
>   computes `clearance` and `overlap` from measured global rects, so it should survive the
>   changes — but it has never been exercised at 320×568 or with a safe-area inset. Add the
>   tests below and read the failure carefully if any of them fail: the bug will be in the
>   measurement's assumptions, not in your insets.
>
> ### What not to change
>
> - **Do not replace `_revealFocusedField` / `_scrollFocusedFieldClear`** (224-271) with
>   `scrollPadding` or `ensureVisible`. The pinned block is outside the scroll view;
>   the framework cannot see it. This code exists for a reason the comment states.
> - Do not touch the `didChangeDependencies` re-run hook (168-172). It is what makes the
>   reveal fire on keyboard changes.
> - **Do not touch the Hero tags** (`manual_heroes.dart`, `kLibrarySearchTag`). The header
>   and search pill deliberately "fly onto themselves" across the push from the library
>   picker (see the comment at `not_in_library_route.dart:20-24`) so they appear to hold
>   still. Changing their geometry changes that illusion — if your width cap alters the
>   pill's rect, run the Hero tests in `test/add/` and `test/library/`.
> - Do not touch `ManualReturnBar`'s "always laid out, hidden takes no touches" structure
>   (`manual_return_bar.dart:31-32`). It is laid out unconditionally so appearing never
>   shifts the button beneath it — a deliberate anti-jump measure.
> - Do not touch `sentenceCase` (610-614) or the verdict branching (375-425).
> - Do not add a length cap to the name/spec fields. That is a data decision, not layout.
>
> ### Verification
>
> **Do not run the app** (`CLAUDE.md` §5). `flutter analyze` and `flutter test` only.
>
> Extend the existing `test/add/` coverage for this screen with `pumpResponsive`:
> - `'photo card is 210pt tall at the reference canvas with no keyboard'` — the no-op guard.
> - `'focused SPEC field is never covered by the pinned block'` — the load-bearing test.
>   Run it at 320×568, 402×874, and 1280×800, each with
>   `viewInsets: EdgeInsets.only(bottom: 300)`: focus the field, pump the two post-frame
>   frames the reveal needs (`pumpAndSettle` may not be enough given the double
>   `addPostFrameCallback` — the project's README documents a `pumpAndSettle` gotcha, read
>   it), then assert the field's rect does not intersect the bottom block's rect.
> - `'bottom block clears a 34pt home indicator when the keyboard is closed'`.
> - `'bottom block is not pushed too high when the keyboard is open'` — the double-count
>   guard: with `viewInsets: bottom 300` **and** `padding: bottom 34`, assert the block's
>   bottom is at exactly 300, not 334.
> - `'field label does not clip at text scale 1.5'`.
> - `'content and bottom block are capped on a landscape tablet'` — 1280×800.
>
> ### Done when
>
> - `flutter analyze` clean; `flutter test` green with no edits to existing assertions,
>   Hero tests included.
> - The 210pt-at-reference guard passes.
> - The keyboard double-count guard passes — that is the one your inset change could
>   plausibly break.

---

## Notes for the reviewer

**The keyboard double-count is the trap.** `bottom: _bottomInsets.bottom + keyboard`
(line 343) is correct today precisely because `_bottomInsets.bottom` is a dumb constant.
Making it safe-area-aware silently adds the home-indicator inset on top of a keyboard that
already covers the home indicator. The fix is a condition, not a bigger number, and the
test asserting `bottom == 300` rather than `334` is what proves it.

**The hand-rolled reveal is worth preserving and worth documenting.** It is the only place
in the app that measures real `RenderBox` geometry to solve a layout problem, and it is
solving one Flutter genuinely does not: a `Positioned` overlay that the `Scrollable` cannot
see. If anything in this prompt tempts a rewrite, re-read the comment at 220-223 first.

**Note the inconsistency, do not fix it.** `PhotoDropCard` is 210pt here and 132pt in the
add sheet (`photo_drop_card.dart:12`), and the two search-pill/caret implementations
(`lib/widgets/square_caret_field.dart` vs `lib/collections/square_caret_field.dart`) differ
in caret height. Both are real duplication. Neither is a responsiveness bug, and folding
them in would make this diff unreviewable.
