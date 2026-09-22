# Prompt 04 — First Object screen (onboarding 3 of 3)

**Files:** `lib/onboarding/first_object_screen.dart` (~440 lines), `lib/onboarding/capture_frame.dart`,
`lib/onboarding/shine_button.dart`
**Route:** `/onboarding/first-object` (`lib/app/router.dart:78-82`)
**Depends on:** [00-shared-foundation.md](00-shared-foundation.md), and the `ShineButton`
fix specified in [02-welcome.md](02-welcome.md)

---

## Prompt

> You are making SPEC's "First Object" onboarding screen render correctly on every
> phone and iPad size, in `/Users/ahmadraza/Downloads/SPEC/spec`. Read
> `lib/onboarding/first_object_screen.dart`, `lib/onboarding/capture_frame.dart`, and
> `lib/onboarding/shine_button.dart` in full first.
>
> **This is the highest-risk screen in the app for short viewports.** It is the only
> screen with no flex widget of any kind — no `Expanded`, no `Flexible`, no `Spacer`,
> no `LayoutBuilder`, no scroll view. Content height is the straight arithmetic sum of
> fixed blocks.
>
> ### What the screen is today
>
> `DefaultTextStyle` (223) → `Stack(fit: StackFit.expand)` (229-267): `ColoredBox`,
> `Image.asset('assets/images/first_object_bg.png', fit: BoxFit.cover)` (233-237),
> scrim, then:
>
> ```
> Padding(_contentPadding = fromLTRB(18, 56, 18, 0))        // line 35
>   Column(crossAxisAlignment: stretch)                     // 244-257
>     header row ("03 / 03" pill + SKIP)
>     SizedBox(_blockGap + _headlineOffset = 22)             // 248
>     headline "REMEMBER\nONE THING."   // 46pt, height 0.92, ls -2.30 — largest in the app
>     SizedBox(_blockGap + _bodyPull = 10)                   // 250
>     body copy in ConstrainedBox(maxWidth: 310)             // 15pt, height 1.5
>     SizedBox(_blockGap + _framePush = 20)                  // 252
>     CaptureFrame                                           // FIXED height 236  <-- the problem
>     SizedBox(_blockGap = 18)                                // 254
>     Wrap(spacing: 8, runSpacing: 8) of suggestion chips     // 361-366 — correctly a Wrap
> Positioned(left: 16, right: 16, bottom: _bottomInset = 24)  // 259-264
>   ShineButton "ADD MY FIRST OBJECT" (height 60) + caption
> ```
>
> ### The arithmetic that breaks it
>
> Summing the file's own constants at **default** text scale:
> `56` (top) + ~`40` (header) + `22` + ~`85` (46pt headline, 2 lines at height 0.92) +
> `10` + ~`68` (body, ~3 wrapped lines at 310pt) + `20` + **`236`** (`capture_frame.dart:5`) +
> `18` + ~`40` (chip `Wrap`) ≈ **595pt of content**.
>
> A 320×568 screen has 568pt. The `Positioned` bottom block (a 60pt `ShineButton` plus
> caption at `bottom: 24`) then **overlaps** the tail of the suggestion chips rather than
> erroring, because the outer `Column` sits inside a `Padding` inside a `Stack` with no
> bounding box — so Flutter suppresses the overflow banner and the breakage ships
> silently. At 1.5 text scale the 46pt headline and the body copy push this well past
> 700pt on every phone.
>
> ### The four things to fix
>
> 1. **No scroll fallback at all.** This is the root cause; everything else is secondary.
> 2. **`CaptureFrame` is a hard 236pt** (`capture_frame.dart:5, 67-68`) that cannot
>    compress to make room.
> 3. **The 46pt headline has no shrink path** (307-313), no `maxLines`, no `FittedBox`.
> 4. **Neither inset is safe-area aware** (`_contentPadding.top = 56` line 35,
>    `_bottomInset = 24` line 47).
>
> ### What to change
>
> - **Wrap the content `Column` in a scroll view with a bottom reserve.** This is the
>   primary fix:
>   ```
>   SingleChildScrollView(
>     padding: EdgeInsets.only(bottom: bottomBlockHeight + gap),
>     child: Column(...existing children...),
>   )
>   ```
>   The `padding.bottom` must reserve room for the `Positioned` bottom block so the last
>   chip can scroll clear of the button instead of hiding under it. The codebase already
>   solves exactly this: `lib/library/library_pick_screen.dart:21` uses a `108` bottom
>   page padding with the comment "108 at the bottom clears the floating bar", and
>   `lib/add/not_in_library_screen.dart:24` uses `128`. Follow that precedent and name
>   the constant with the same kind of comment.
>   Do **not** add a `Spacer` or `Expanded` inside this scroll view — unbounded height
>   plus non-zero flex is a hard `RenderFlex` crash.
> - **Let the capture frame breathe down.** Change `_frameHeight = 236.0` from a fixed
>   `height:` to a `ConstrainedBox(maxHeight: 236, minHeight: someFloor)` driven by
>   available height, or simply keep 236 now that the page scrolls. **Prefer the second**
>   — once the page scrolls, a fixed 236pt frame is no longer a failure, and shrinking a
>   camera viewfinder hurts the actual task. Only add the constraint if the scroll
>   fallback proves insufficient in the tests below. State which you chose and why.
> - **Headline:** `FittedBox(fit: BoxFit.scaleDown)` around the 46pt headline (307-313),
>   inside a width-bounded parent, plus `maxLines: 2`. Keep the 46pt token.
> - **Cap content width on expanded.** `_bodyMaxWidth = 310.0` (line 42) stays for
>   phones; on `SpecLayout.isExpanded(context)` raise to `SpecLayout.maxContentWidth` and
>   centre the column, so the frame is not a 1244pt-wide letterbox on an iPad.
> - **Insets:** `SpecLayout.topInset(context, design: 56)`,
>   `SpecLayout.bottomInset(context, design: 24)`.
> - **`ShineButton`:** already covered by [02-welcome.md](02-welcome.md) — the fixed
>   `height: 60` becomes `ConstrainedBox(minHeight: 60)` with `maxLines: 1` + ellipsis on
>   the label. `'ADD MY FIRST OBJECT'` is the longest label the widget carries, so verify
>   the fix here even though the edit lands in the other prompt. If 02 has not been done
>   yet, do that edit as part of this task and note it.
>
> ### What not to change
>
> - **Keep the `Wrap`** at 361-366. Using `Wrap` for the suggestion chips instead of a
>   `Row` is already correct — chips reflow to a new line instead of overflowing. Do not
>   "improve" it into a horizontal scroller.
> - Do not touch the `BoxFit.contain` on the captured photo
>   (`lib/onboarding/onboarding_routes.dart:79-82`). The comment there explains it:
>   `contain` so a portrait label photo is not cropped. Cover would break the feature.
> - Do not touch the bracket/ring animation geometry in `capture_frame.dart`
>   (`_bracketSize = 26`, `_ringSize = 76`, scale 0.82→1.5, lines 6-16). Those are
>   decorative and correct.
> - Do not touch `_bobDistance = 9.0` (line 28) — chip bob animation, not layout.
>
> ### Verification
>
> **Do not run the app** (`CLAUDE.md` §5). `flutter analyze` and `flutter test` only.
>
> Extend `test/first_object_screen_test.dart` (exists, pins `Size(402, 874)`) with
> `pumpResponsive`:
> - `'suggestion chips are never hidden behind the action button'` — loop
>   `specCanvases`; scroll to the bottom; assert the last chip's rect does not intersect
>   the `ShineButton`'s rect. **This is the test that catches today's actual bug** — the
>   silent overlap — and it must fail if you revert the bottom reserve. Verify that.
> - `'page scrolls at 320x568'` — assert `maxScrollExtent > 0`.
> - `'page does not scroll at the reference canvas'` — 402×874 at scale 1.0,
>   `maxScrollExtent == 0`. The design must be untouched.
> - `'headline shrinks rather than clipping at text scale 1.5'` — 320×568 at 1.5,
>   `expectNoOverflow`, headline width `<= 320`.
> - `'capture frame is fully visible at every canvas'` — rect containment per canvas.
> - `'action button clears a 34pt home indicator'`.
>
> ### Done when
>
> - `flutter analyze` clean; `flutter test` green with no edits to existing assertions.
> - The chip-vs-button overlap test passes, and you have confirmed it fails on the
>   pre-change code.
> - The reference-canvas no-scroll test passes.

---

## Notes for the reviewer

**This screen is the clearest example of why the whole exercise is needed.** ~595pt of
rigid content on a 568pt device, with the failure *hidden* because the `Stack` parent
suppresses the overflow banner. Nobody would have found this by looking at the
simulator on a modern iPhone.

**Prefer the scroll fallback over shrinking the viewfinder.** Once the page scrolls,
236pt is a fine frame height. Compressing a camera preview to fit a short screen makes
the one action this screen exists for harder. Reach for the `ConstrainedBox` only if the
tests show scrolling alone is not enough.

**The overlap test is the valuable artifact here.** It encodes the invariant "the
pinned bottom block never covers scrollable content", which is a pattern repeated on
three other screens (Library, Not-in-Library, Object). Consider whether the same
assertion belongs in a shared test helper once those prompts land.
