# Prompt 03 — How It Works screen (onboarding 2 of 3)

**Files:** `lib/onboarding/how_it_works_screen.dart` (~440 lines), `lib/onboarding/step_card.dart`
**Route:** `/onboarding/how-it-works` (`lib/app/router.dart:73-77`)
**Depends on:** [00-shared-foundation.md](00-shared-foundation.md)

---

## Prompt

> You are making SPEC's "How It Works" onboarding screen render correctly on every
> phone and iPad size, in `/Users/ahmadraza/Downloads/SPEC/spec`. Read
> `lib/onboarding/how_it_works_screen.dart` and `lib/onboarding/step_card.dart` in full
> before changing anything.
>
> ### What the screen is today
>
> This is the **best-structured screen in the onboarding flow** and the change here is
> correspondingly small. `DefaultTextStyle` (211) → `Stack(fit: StackFit.expand)`
> (217-261): background `ColoredBox`, `Image.asset('assets/images/how_it_works_bg.png',
> fit: BoxFit.cover)` (221-225), scrim, then:
>
> ```
> Padding(_contentPadding = fromLTRB(18, 56, 18, 0))     // line 54
>   Column(crossAxisAlignment: stretch)
>     header pill "02 / 03"
>     SizedBox(_sectionGap + _headlineOffset = 24)        // 236
>     headline "THREE\nSECONDS."                          // 40pt, height 0.92, ls -2.00
>     SizedBox(_sectionGap + _kickerPull = 12)            // 238
>     kicker "THAT IS THE WHOLE PRODUCT"                  // 9.5pt
>     SizedBox(_sectionGap + _stackOffset = 26)           // 240
>     Expanded(                                           // 241-250  <-- the good part
>       Padding(bottom: _bottomBarInset + _buttonHeight = 82)
>         Center(_buildCardStack())                       // 3 StepCards, _cardGap 26
>     )
> Positioned(left: 16, right: 16, bottom: _bottomBarInset = 24)  // 254-259
>   _buildBottomBar()   // dots + NEXT button, _buttonHeight = 58
> ```
>
> That `Expanded` + `Center` (241-250) is the only flex-adaptive content region in the
> whole onboarding flow, and the comment at line 25 states the intent explicitly: the
> card group should "centre on any screen height". Preserve that design.
>
> ### The three things that break
>
> 1. **`StepCard`'s fixed 64pt leading square does not scale with its text.**
>    `step_card.dart:64-87` is `Row([_LeadingSquare(64×64), SizedBox(width: 14),
>    Expanded(Column(label, title, body))])`. `_leadingSize = 64.0` (line 9) is a hard
>    `Container` size (102-104) while the adjacent 19pt `cardTitle` and 13pt `cardBody`
>    — **neither of which has `maxLines`** (68-85) — wrap freely. At 1.5 scale each card
>    roughly doubles in height while `_cardGap = 26` stays fixed, so three cards plus two
>    gaps overrun the `Expanded` region.
> 2. **`Center` inside `Expanded` clips silently.** When the card stack's intrinsic
>    height exceeds the `Expanded` region, `Center` does not throw a `RenderFlex`
>    overflow — it lets the child overhang and the `Stack` clips it. Cards get cut off
>    top and bottom **with no debug banner**, which is worse than a crash because it
>    ships unnoticed. There is no scroll view in this file to absorb it.
> 3. **The 56pt top inset and 24pt bottom inset are not safe-area aware** (lines 54, 67).
>
> ### What to change
>
> - **Let the card region scroll when, and only when, it must.** Replace
>   `Center(_buildCardStack())` inside the `Expanded` with:
>   ```
>   SingleChildScrollView(
>     child: ConstrainedBox(
>       constraints: BoxConstraints(minHeight: regionHeight),
>       child: Center(child: _buildCardStack()),
>     ),
>   )
>   ```
>   where `regionHeight` comes from a `LayoutBuilder` wrapping the `Expanded`'s child.
>   At every size where the cards fit, `Center` still centres them exactly as today and
>   `maxScrollExtent` is zero — the design is untouched. When they do not fit, the region
>   scrolls instead of clipping.
> - **Cap the stack's width on expanded.** Wrap `_buildCardStack()` in
>   `ConstrainedBox(maxWidth: SpecLayout.maxContentWidth)`. Three cards spanning 1244pt
>   on an iPad puts the 64pt leading square an absurd distance from its own text.
> - **Give `StepCard`'s text a ceiling.** In `step_card.dart`, add `maxLines: 2` +
>   `overflow: TextOverflow.ellipsis` to `cardTitle` and `maxLines: 3` + ellipsis to
>   `cardBody` (the `Expanded` column at 68-85). Three onboarding cards with fixed
>   copy have a known worst case; unbounded wrapping is not a feature here.
> - **Let the leading square track the text scale.** `_leadingSize = 64.0` should become
>   `64.0 * clamped scale` via `MediaQuery.textScalerOf(context).scale(...)`, or simply
>   `textScaler.scale(64.0)` clamped to a ceiling so it cannot dominate the card. A 64pt
>   icon next to doubled 19pt type looks broken; this is the smallest fix that keeps the
>   card visually balanced. Do not make it a `LayoutBuilder` — it does not need one.
> - **Insets:** `SpecLayout.topInset(context, design: 56)` at line 54,
>   `SpecLayout.bottomInset(context, design: 24)` for `_bottomBarInset` at its two use
>   sites (245-247 reserve and 254-259 `Positioned`). Keep them consistent — the reserve
>   and the bar must move together or the NEXT button will overlap the last card.
>
> ### What not to change
>
> - **Do not remove the `Expanded` + `Center`.** It is the correct structure and the
>   reason this screen is the healthiest of the three. The scroll view goes *inside* it.
> - Do not touch `_riseDistance = 9.0` (line 21) or the per-card phase offsets
>   (185-190). That is the undulation animation, not layout.
> - Do not change the corner-cut radii (30-47, the 22/6 pairs). That shape is the brand
>   language and appears on Home's cards too.
> - Do not touch the bottom bar's dot geometry (`_dotSize = 7`, `_activeDotWidth = 22`,
>   69-71). Three fixed dots at any width is correct.
>
> ### Verification
>
> **Do not run the app** (`CLAUDE.md` §5). `flutter analyze` and `flutter test` only.
>
> Extend `test/how_it_works_screen_test.dart` (exists, pins `Size(402, 874)`) with
> `pumpResponsive`:
> - `'all three cards are fully visible at every canvas'` — loop `specCanvases`; for each
>   `StepCard`, assert its rect is entirely within the canvas. This is the test that
>   catches the silent `Center` clip, which `expectNoOverflow` alone will not.
> - `'card region scrolls rather than clipping at text scale 1.5 on a tiny screen'` —
>   320×568 at 1.5: assert `maxScrollExtent > 0` and all three cards reachable.
> - `'card region does not scroll at the reference canvas'` — 402×874 at 1.0:
>   `maxScrollExtent == 0`.
> - `'NEXT button never overlaps the last card'` — loop all canvases, assert the last
>   `StepCard`'s bottom is above the bottom bar's top.
> - `'bottom bar clears a 34pt home indicator'`.
>
> ### Done when
>
> - `flutter analyze` clean; `flutter test` green with no edits to existing assertions.
> - The reference-canvas no-scroll test passes.
> - The card-visibility test fails if you revert the scroll change — check that, it is
>   the only way to know the test is real.

---

## Notes for the reviewer

**Silent clipping is the interesting bug here.** `Column`/`Row` overflow paints a
yellow-and-black banner in debug, so it gets caught. `Center` with an oversized child
inside a clipping `Stack` produces no banner at all — content just vanishes off the
edges. That is why the verification asks for a rect-containment assertion per card
rather than relying on `expectNoOverflow`.

**This screen needs the least work, so resist doing more.** The `Expanded` + `Center`
structure is already right. The change is: add a scroll fallback inside it, cap the
width on tablets, bound the card text, and scale the leading square. Nothing else.

**The 64pt square is a judgement call.** Scaling it with text keeps the card balanced
but grows the card further, which pushes the stack toward the scroll fallback sooner.
The alternative — leaving it fixed — keeps cards shorter but looks wrong at 1.5. Scaling
is the better trade because the scroll fallback now exists. Say so in the comment so the
next reader does not "fix" it back.
