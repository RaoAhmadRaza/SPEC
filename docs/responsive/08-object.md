# Prompt 08 — Object screen (detail)

**Files:** all 18 files under `lib/object/` — chiefly `object_screen.dart`, `object_tokens.dart`,
`object_layout.dart`, `object_action_bar.dart`, `object_photos.dart`, `object_parts.dart`,
`object_table.dart`, `object_inline_edit.dart`, `object_sheet.dart`, `object_viewer.dart`,
`object_hero.dart`, `object_page_route.dart`
**Route:** `/object/:id` (`lib/app/router.dart:108-126`), always pushed from a Home card or a
Search result row and flown in from it.
**Depends on:** [00-shared-foundation.md](00-shared-foundation.md)

---

## Prompt

> You are making SPEC's Object detail screen render correctly on every phone and iPad
> size, in `/Users/ahmadraza/Downloads/SPEC/spec`. Read every file under `lib/object/` in
> full first. This is the largest and most carefully built screen in the app — most of it
> is already right, and the correct diff here is small and surgical.
>
> ### What is already right (do not undo any of it)
>
> - **`object_screen.dart:521-530` has a real `LayoutBuilder`** that computes
>   `contentWidth = maxWidth - page.horizontal` and
>   `minHeight = max(0, maxHeight - page.top - barArea)`.
> - **`fitSpecStyle` (`object_parts.dart:159-181`) shrinks the 108pt spec toward a 56pt
>   floor using the real `MediaQuery.textScalerOf(context)`** (read at
>   `object_screen.dart:773`). This is the only genuinely scale-aware type sizing in the
>   app and is the model the other screens' prompts copy.
> - **Keyboard handling is thorough.** `viewInsetsOf(context).bottom` (509) shrinks the
>   scroll viewport (539), rides the floating action bar above the keyboard (579), and
>   `InlineValue`'s `scrollPadding` (`object_inline_edit.dart:13-18`) adds
>   `page.bottom + barHeight = 126` so a focused field clears the floating bar too.
> - **`BodyWithFoot` (`object_layout.dart:14-100`)** is a custom render object emulating
>   CSS `margin-top: auto` — it places the foot at `max(minHeight, natural)`. It is correct
>   and cheaper than nesting scroll views.
>
> ### The four things that break
>
> 1. **`ObjectActionBar`'s label `Row` is the app's clearest overflow risk.**
>    `object_action_bar.dart:96-134` is `mainAxisAlignment: spaceBetween` over three text
>    labels (`Edit`/`Cancel`, `Share`/`·`, and the pill) with **no `Flexible` or `Expanded`
>    on any of them**, inside a fixed `barHeight = 62` (`object_tokens.dart:212`). Tight at
>    320pt even at scale 1.0; a `RenderFlex` overflow at 1.5.
> 2. **`MetaRow`'s label is not flexible next to a flexible value.**
>    `object_parts.dart:146-148`: the label is a bare `Text`, the value is `Flexible`. So
>    the value yields and the label never does — at large scale the label pushes the value
>    to nothing and then overflows anyway.
> 3. **No content-width cap.** `ObjectMetrics` (`object_tokens.dart:180-218`) has no
>    `maxContentWidth`. On a 1280pt iPad the 108pt spec, the table, and the action bar all
>    stretch the full width. Worse, `PhotoPair` (`object_photos.dart:92-112`) is a fixed
>    `photoRowHeight = 158` with an `Expanded(flex: 2)` / `Expanded()` split — so the main
>    photo becomes roughly 824×158 and `BoxFit.cover` crops it savagely.
> 4. **`page.top = 62` is a fixed constant** (`object_tokens.dart:182`), not a
>    `MediaQuery.paddingOf` read, and the header circles float over the scroll content
>    (558-573) so nothing protects them from the notch.
>
> ### What to change
>
> - **Action bar:** wrap each of the three labels in `Flexible` with `maxLines: 1` +
>   `overflow: TextOverflow.ellipsis`, and change the bar's fixed `barHeight` usage to a
>   `ConstrainedBox(minHeight: ObjectMetrics.barHeight)`. Keep the 62pt design value.
>   **Then check the bar's bottom offset math** (`object_screen.dart:579`) still agrees
>   with `barArea` in the `LayoutBuilder` (527-530) — if the bar can now grow, the
>   reserved `barArea` must grow with it, or the last content row hides underneath.
>   That linkage is the one thing in this prompt that is easy to get subtly wrong.
> - **`MetaRow`:** wrap the label in `Flexible` too, with ellipsis. Two `Flexible`s with a
>   fixed `SizedBox(width: 16)` between them (line 147) is the right shape.
> - **Add a content-width cap.** Put `maxContentWidth` in `ObjectMetrics` (it is the one
>   token class in the app that already holds metrics, `object_tokens.dart:180-218`, so it
>   is the natural home) and apply it in the `LayoutBuilder` at 521-530: clamp
>   `contentWidth` to `min(available, ObjectMetrics.maxContentWidth)` and centre the body.
>   Because `contentWidth` already feeds `fitSpecStyle`, the 108pt spec will then size
>   itself against the capped width for free — that is why the cap belongs there and not
>   in a wrapper widget.
> - **`PhotoPair`:** make the row's height proportional rather than fixed. Replace
>   `photoRowHeight = 158` as a hard height with an `AspectRatio` on the pair, derived from
>   the reference: at 402pt wide the pair is `402 - 44 = 358pt` across and 158pt tall, so
>   the ratio is about `2.27:1`. Using `AspectRatio(aspectRatio: 358/158)` reproduces 158pt
>   exactly at the reference width and scales sanely at 810pt. Keep the `flex: 2` / `flex: 1`
>   split and the `BoxFit.cover`.
> - **Insets:** `SpecLayout.topInset(context, design: 62)` where `ObjectMetrics.page.top`
>   is consumed (the `LayoutBuilder` at 527 and the header `Positioned` at 558-573 both
>   read it — change both or the circles drift out of agreement with the content).
>   `SpecLayout.bottomInset(context, design: 44)` for `page.bottom`.
> - **`object_sheet.dart`:** `maxHeight = MediaQuery.sizeOf(context).height - page.top`
>   (153-157) is unclamped. Add `SpecLayout.maxContentWidth` to the sheet's width on
>   expanded so the `•••` menu is not a 1280pt-wide strip, and leave the height math alone.
>
> ### What not to change
>
> - **Do not touch `fitSpecStyle` or `specFloor = 56`.** It is the correct mechanism and
>   other prompts point at it as the precedent.
> - **Do not touch `BodyWithFoot`** (`object_layout.dart`). Rewriting a working custom
>   render object to "simplify" it is exactly the kind of change that costs a week.
> - **Do not touch the Hero machinery.** `object_hero.dart`'s `SpecHero` (45-83),
>   `PhotoHero` (87-123), and `ZoneChipHero` (189-274) lerp `TextStyle`, `BorderRadius`,
>   and `EdgeInsets` between captured source geometry and the resting style. The source
>   geometry arrives in `ObjectRouteArgs` (`object_route.dart:39-42`) captured once at push
>   time. Your width cap changes the *destination* geometry, so **run every Hero test in
>   `test/object/`, `test/home/`, and `test/search/`** and look at what the flight
>   interpolates before and after. If a flight breaks, fix the destination, not the Hero.
> - **Do not touch `object_page_route.dart`'s `_EdgeSwipe`.** It reimplements the iOS
>   edge-back gesture because `CupertinoPageRoute`'s is private. The comment says so. Its
>   `_edgeWidth = 20 + MediaQuery.paddingOf(context).left` (158) is already inset-aware.
> - **Do not touch `object_viewer.dart`'s `Rect.lerp` flight** (134-205). It is
>   deliberately not a `Hero` (see the comment at 18-23).
> - Do not add a `Scaffold` or convert the floating header/bar into slivers. The
>   float-over-scroll structure is the design.
>
> ### Verification
>
> **Do not run the app** (`CLAUDE.md` §5). `flutter analyze` and `flutter test` only.
>
> Extend `test/object/object_screen_test.dart` (exists, pins `Size(402, 874)`) with
> `pumpResponsive`:
> - `'action bar does not overflow at text scale 1.5'` — 320×568 at 1.5,
>   `expectNoOverflow`. The primary fix's guard.
> - `'last content row clears the action bar at text scale 1.5'` — the `barArea` linkage
>   guard: scroll to the bottom, assert the last row's bottom is above the bar's top.
> - `'photo pair is 158pt tall at the reference canvas'` — the `AspectRatio` no-op guard.
> - `'photo pair keeps its aspect ratio on a portrait tablet'` — 810×1080.
> - `'content is capped at maxContentWidth on a landscape tablet'` — 1280×800.
> - `'spec text still shrinks toward the floor at text scale 1.5'` — a regression guard on
>   `fitSpecStyle` now that `contentWidth` is capped.
> - `'header circles clear a 59pt Dynamic Island'`.
> - `'inline edit field clears the action bar when the keyboard is up'` — set
>   `viewInsets: EdgeInsets.only(bottom: 300)`, focus a field, assert no overlap.
>
> ### Done when
>
> - `flutter analyze` clean; `flutter test` green with **no edits to existing assertions**,
>   Hero tests included.
> - The 158pt-at-reference test passes, proving the `AspectRatio` conversion is exact.
> - The bar-clearance test fails if you revert the `barArea` linkage — check that.

---

## Notes for the reviewer

**This screen is where the codebase already knows how to do responsiveness.** A
`LayoutBuilder` feeding a width to a scale-aware type fitter, viewport shrinking for the
keyboard, a custom render object for the one layout Flutter does not express well. The
diff should read as extending that work, not as bolting responsiveness onto a naive
screen.

**The `barArea` linkage is the subtle part.** `object_screen.dart:527-530` reserves
`page.top + barArea` out of the available height, and the bar itself is positioned
independently at 579. Today both are computed from the same fixed `barHeight = 62`, so they
cannot disagree. Making the bar growable breaks that coupling unless the reserve grows
too — and the failure mode is content silently hiding under a floating bar, which no
overflow banner will report.

**The Hero caution is not boilerplate.** Three flight types land on this screen from two
different source screens, with source geometry captured at push time and never
recomputed. A width cap changes where things land. Read `object_hero.dart` before, and run
the cross-screen tests after.
