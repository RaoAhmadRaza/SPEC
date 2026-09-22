# Prompt 01 — Splash screen

**File:** `lib/splash/splash_screen.dart` (379 lines)
**Depends on:** [00-shared-foundation.md](00-shared-foundation.md)
**Shown by:** `lib/app/splash_gate.dart:22-35`, stacked over every route until startup resolves.

---

## Prompt

> You are making SPEC's splash screen render correctly on every phone and iPad size,
> in `/Users/ahmadraza/Downloads/SPEC/spec`. Read `lib/splash/splash_screen.dart` in
> full before changing anything.
>
> ### What the screen is today
>
> A pure absolute-positioned `Stack(fit: StackFit.expand)` (line 194) with no
> `Scaffold`, no `SafeArea`, and no scroll view. Five layers: a `ColoredBox`
> background (197), a 640×640 glow blob (`_glowSize = 640.0`, line 21, built 233-262),
> four "ghost" spec strings at fixed offsets (199-218), a `Center` holding the
> wordmark/rule/tagline column (219, built 272-291), and a `Positioned(bottom: 52)`
> progress bar + caption block (220-224, built 346-379).
>
> The comment at line 55 records the design viewport as **402 × 874 pt** and nothing
> in the code enforces or adapts to it. There is no `MediaQuery` read for sizing
> anywhere in the file, no `LayoutBuilder`, no `Expanded`, no `Flexible`, no `Spacer`.
> `initState` sets `SystemUiMode.immersive` (121) and `_run()` restores `edgeToEdge`
> (145) just before `onDone()`, so the status-bar region is hidden rather than avoided.
>
> ### The four things that break
>
> 1. **The wordmark is the hard failure.** `_buildWordmark()` (293-310) is a
>    `Row(mainAxisSize: MainAxisSize.min)` of four individually animated letters at
>    `SpecText.wordmark` — **92pt, `letterSpacing: -4.6`, `height: 0.9`**
>    (`lib/theme/spec_tokens.dart:104-111`) — plus a `™` in a `Padding(top: 10)`.
>    No `Flexible`, no `FittedBox`, no `maxLines`. At 320pt wide the four glyphs plus
>    trademark are already near the full width; at the foundation's 1.5 text-scale
>    ceiling they exceed any phone width and clip. This `Row` is the single most
>    likely overflow in the file.
> 2. **The four ghost strings assume an 874pt-tall portrait canvas.** They are
>    `Positioned` at `left: 34, top: 214` (200-202), `right: 32, top: 266` (204-207),
>    `left: 52, bottom: 268` (209-212), `right: 44, bottom: 238` (214-217). On a
>    1280×800 iPad landscape these four cluster into two tight bands near the top and
>    bottom edges instead of spreading across the frame. On 320×568 the top pair
>    (214, 266) and bottom pair (268, 238) nearly meet in the middle.
> 3. **Nothing is safe-area aware.** The bottom block sits at a hardcoded
>    `bottom: 52` (223). Immersive mode hides the system bars during the splash, but
>    `edgeToEdge` is restored at line 145 *while the splash is still painted* (the gate
>    cross-fades it out), so the home indicator can land on the progress caption for a
>    frame or two.
> 4. **The 640pt glow and 212pt rule are fixed absolutes.** The glow bleeding off both
>    edges at 320pt is intentional (comment, lines 19-20) and must stay intentional.
>    The 212pt rule (333-334) and 96pt progress bar (354-356) are centred, so they are
>    safe — but on a 1280pt-wide iPad they read as a hairline lost in space.
>
> ### What to change
>
> - **Wordmark:** wrap `_buildWordmark()`'s `Row` in a `FittedBox(fit: BoxFit.scaleDown)`
>   inside a width-bounded parent (`SpecLayout.contentWidth(context)` minus a side
>   gutter). `scaleDown` only ever shrinks, so the reference canvas is untouched and a
>   narrow screen or a large text scale shrinks the wordmark to fit instead of clipping
>   it. Do **not** reduce the 92pt token — the design size stays 92pt, `FittedBox` is
>   the escape valve.
> - **Centre column:** give the `Column` at 273-291 a `ConstrainedBox(maxWidth:
>   SpecLayout.maxContentWidth)` so on an iPad the wordmark, rule, and tagline stay a
>   readable block rather than floating in a 1280pt field. The tagline
>   (`'REMEMBER THE SPECS\nFORGET THE SEARCH'`, 283-287) keeps its explicit `\n` — add
>   `maxLines: 2` and `overflow: TextOverflow.ellipsis` so a scale increase truncates
>   rather than pushing the rule off-centre.
> - **Ghosts:** replace the four literal offsets with fractions of the actual canvas.
>   Read `MediaQuery.sizeOf(context)` once in `build`, and express each ghost as the
>   current value divided by the 402×874 reference (e.g. `top: 214` becomes
>   `size.height * (214 / 874)`, `left: 34` becomes `size.width * (34 / 402)`). At the
>   reference canvas this is arithmetically identical, so no test moves. Put the
>   reference size in two named constants next to the existing line-55 comment so the
>   ratio is legible.
> - **Bottom block:** `bottom: SpecLayout.bottomInset(context, design: 52)`.
> - **Glow:** leave `_glowSize = 640.0` alone on phones. On expanded
>   (`SpecLayout.isExpanded(context)`) scale it by the same height ratio so it still
>   reads as an atmospheric wash rather than a small disc in the middle of an iPad.
>
> ### What not to change
>
> - Do not add a scroll view. This screen is displayed for under a second and must
>   never be scrollable.
> - Do not touch the animation timings, curves, or the `_letterRise = 26.0` /
>   `_fadeRise = 8.0` travel distances (lines 39, 43). Those are pixel travels for
>   entrance motion, not layout, and they read correctly at every size.
> - Do not remove the immersive-mode calls (121, 145). The restore point is
>   deliberate.
> - Do not convert the `Stack` to a `Column`. The absolute layering is the design.
>
> ### Verification
>
> **Do not run the app** — no `flutter run`, no hot reload, no terminating the
> simulator app (`CLAUDE.md` §5). Use `flutter analyze` and `flutter test` only.
>
> Add to `test/splash/` (create it if absent), using `pumpResponsive` from
> `test/support/responsive.dart`:
> - `'wordmark fits the width at every canvas'` — loop `specCanvases`, assert the
>   wordmark's painted width is `<= canvas.width` and `expectNoOverflow`.
> - `'wordmark shrinks rather than clips at text scale 1.5'` — 320×568 at 1.5, assert
>   no overflow and that the rendered wordmark width is `<= 320`.
> - `'ghost strings stay inside the canvas on a landscape tablet'` — 1280×800, assert
>   each ghost's rect is within bounds and that no two of the four overlap.
> - `'bottom block clears a 34pt home indicator'` — reference canvas with
>   `padding: EdgeInsets.only(bottom: 34)`, assert the caption's bottom is at least
>   34pt above the canvas bottom.
>
> ### Done when
>
> - `flutter analyze` clean; `flutter test` green with **no edits to existing tests**.
> - The four new tests pass.
> - At 402×874 with zero padding and no text scaling, every computed value in the file
>   equals its previous literal. Prove it in the PR body by listing the ratios
>   (`874 * 214/874 == 214`).

---

## Notes for the reviewer

**The ratio trick is the whole idea here.** This screen is a fixed composition, not a
document — there is no content to reflow, only a picture to hold together. Converting
absolutes to fractions of the reference viewport keeps the composition's proportions at
any aspect ratio and is provably a no-op at 402×874. Trying to make it a flex layout
would fight the design.

**`FittedBox(scaleDown)` over shrinking the token.** The 92pt wordmark is the brand
mark; the design size must survive in the tokens. `scaleDown` never enlarges, so the
reference rendering is bit-identical and only constrained cases shrink. This is the
same instinct already in the codebase at `fitSpecStyle`
(`lib/object/object_parts.dart:159-181`), which shrinks the 108pt spec toward a 56pt
floor — reuse that precedent in the comment.

**Open question worth raising with the user.** On a 1280×800 iPad this screen will look
sparse no matter how the numbers scale, because it is a portrait poster. If iPad is a
real target rather than an App Store checkbox, the honest answer is a second
composition for expanded, not a stretched first one. Ask before building it.
