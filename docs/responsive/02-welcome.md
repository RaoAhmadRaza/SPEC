# Prompt 02 — Welcome screen (onboarding 1 of 3)

**File:** `lib/onboarding/welcome_screen.dart` (~420 lines), plus `lib/onboarding/shine_button.dart`
**Route:** `/onboarding/welcome` (`lib/app/router.dart:68-72`) — the redirect target for every
un-onboarded user, so this is the first screen most people ever see.
**Depends on:** [00-shared-foundation.md](00-shared-foundation.md)

---

## Prompt

> You are making SPEC's welcome screen render correctly on every phone and iPad size,
> in `/Users/ahmadraza/Downloads/SPEC/spec`. Read `lib/onboarding/welcome_screen.dart`
> and `lib/onboarding/shine_button.dart` in full first.
>
> ### What the screen is today
>
> `DefaultTextStyle` (181) → `Stack(fit: StackFit.expand)` (187-209) holding: a
> `ColoredBox`, a full-bleed `Image.asset('assets/images/welcome_bg.png', fit: BoxFit.cover)`
> (191-195), a scrim `DecoratedBox` (196-199), a 320×320 glow at
> `Positioned(left: -60, top: 180)` (216-217, 232-234), **six floating chips at fixed
> `Positioned` coordinates** (201, 248-284), and the content column (202-207):
>
> ```
> Padding(_contentPadding = fromLTRB(18, 56, 18, 0))   // line 47
>   Column(crossAxisAlignment: stretch)
>     _buildHeader()        // SKIP row
>     Spacer()              // line 206
>     _buildMessageBlock()  // wordmark, headline, privacy lines, GET STARTED
> ```
>
> There is **no scroll view anywhere in the file** and no `SafeArea`. The only flex is
> that one `Spacer()`. `MediaQuery` is read once, for `disableAnimationsOf` (133), and
> never for sizing.
>
> ### The four things that break
>
> 1. **The message block can overflow the `Column` at large text scale.** `_buildMessageBlock()`
>    (332-377) stacks an 86pt wordmark (`SpecText.welcomeWordmark`, `letterSpacing: -4.3`,
>    `spec_tokens.dart:137-144`), a 26pt headline inside `ConstrainedBox(maxWidth: 320)`
>    (344-345), a two-line privacy block at 11pt with `height: 1.9` and
>    `letterSpacing: 2.64` (356-359), and a 60pt `ShineButton`. With the `Spacer()` above
>    it and **no scroll view to absorb growth**, once the block's height plus the header
>    exceeds the viewport the outer `Column` (204-207) overflows. At 320×568 with the
>    foundation's 1.5 scale ceiling this is reachable.
> 2. **The 86pt wordmark `Row` has no shrink path.** `Row(mainAxisSize: MainAxisSize.min)`
>    of the wordmark plus `™` (381-389), no `Flexible`, no `FittedBox`. Same failure mode
>    as the splash wordmark.
> 3. **The six chips assume a tall portrait canvas.** `Positioned` at `(26,132)`,
>    `(right:22, top:196)`, `(38,296)`, `(right:44, top:322)`, `(120,236)`, `(96,386)`
>    (250-283). On 320×568 the `right:44` chip crowds the content column; on a
>    1280×800 iPad all six cluster in the upper-left quadrant and the right ~960pt of the
>    frame is empty.
> 4. **The 56pt top inset is not safe-area aware** (`_contentPadding`, line 47) and the
>    message block's `bottom: 34` (`_messagePadding`, line 48) is not either — so the
>    GET STARTED button can sit under the home indicator.
>
> ### What to change
>
> - **Make the content column survive growth.** Replace the bare `Column` +
>   `Spacer()` with a scroll view that only scrolls when it has to, preserving the
>   bottom-anchored look at every size that fits:
>   ```
>   SingleChildScrollView(
>     child: ConstrainedBox(
>       constraints: BoxConstraints(minHeight: availableHeight),
>       child: Column(... header, Spacer(), messageBlock ...),
>     ),
>   )
>   ```
>   Get `availableHeight` from a `LayoutBuilder`'s `constraints.maxHeight`. **Critical:**
>   a `Spacer()` inside a `Column` that receives an unbounded height throws
>   `RenderFlex: non-zero flex but incoming height constraints are unbounded` — a hard
>   crash, not a clip. The `ConstrainedBox(minHeight:)` is what keeps the height bounded;
>   do not omit it. (This is the identical bug live in Settings today —
>   `lib/settings/settings_screen.dart:167` inside `SliverFillRemaining` — see
>   [13-settings.md](13-settings.md).)
> - **Wordmark:** `FittedBox(fit: BoxFit.scaleDown)` around the `Row` at 381-389,
>   inside a width-bounded parent. Keep the 86pt token.
> - **Headline:** `_headlineMaxWidth = 320.0` (line 53) is dead at phone widths — the
>   content padding already leaves only 284pt at 320pt wide. Keep it, but on expanded
>   raise the cap to `SpecLayout.maxContentWidth` and centre the whole content column
>   so the block does not stretch across an iPad.
> - **Privacy lines:** add `maxLines: 2` + `overflow: TextOverflow.ellipsis` to the
>   `\n`-joined text at 356-359. Two lines is the design; more is a bug.
> - **Chips:** convert the six `Positioned` coordinates to fractions of the reference
>   402×874 viewport, exactly as in [01-splash.md](01-splash.md) — identical values at
>   the reference canvas, proportional everywhere else. Then, on expanded only, either
>   suppress the two chips that would land under the content column or widen their
>   spread; pick one, and say which in a comment.
> - **Insets:** `SpecLayout.topInset(context, design: 56)` for `_contentPadding.top`,
>   `SpecLayout.bottomInset(context, design: 34)` for `_messagePadding.bottom`.
> - **`ShineButton`:** its `Container` is a hard `height: 60` (`shine_button.dart:5, 37-38`)
>   with a `Center(Text(label))` and no `maxLines`. `'GET STARTED'` is short, but the same
>   widget renders `'ADD MY FIRST OBJECT'` on screen 04 — fix it once here, in the shared
>   widget: `ConstrainedBox(minHeight: 60)` instead of a fixed height, plus `maxLines: 1`
>   and `overflow: TextOverflow.ellipsis` on the label. Note in the commit that this also
>   fixes [04-first-object.md](04-first-object.md).
>   Leave the `LayoutBuilder` at `shine_button.dart:52` alone — it already derives the
>   shine band's travel from `constraints.maxWidth` and is the one genuinely responsive
>   piece of code in the onboarding flow.
>
> ### What not to change
>
> - Do not touch the float drift offsets (`_floatDrifts`, 24-31) or rotations (32-33).
>   Those are ±20pt animation travels and read fine at any size.
> - Do not replace `BoxFit.cover` on the background image. Cover is correct for a
>   full-bleed backdrop at every aspect ratio.
> - Do not restructure the three-screen onboarding flow or its routing
>   (`lib/onboarding/onboarding_routes.dart`). The screens stay presentation-only widgets
>   driven by callbacks, as the comment at lines 23-28 of that file describes.
>
> ### Verification
>
> **Do not run the app** (`CLAUDE.md` §5). `flutter analyze` and `flutter test` only.
>
> Extend `test/welcome_screen_test.dart` (it exists and pins `Size(402, 874)`) using
> `pumpResponsive`:
> - `'message block fits without overflow at every canvas'` — loop `specCanvases`,
>   `expectNoOverflow`.
> - `'scrolls instead of overflowing at text scale 1.5 on a tiny screen'` — 320×568 at
>   1.5: assert no overflow **and** that a `Scrollable` is present with
>   `position.maxScrollExtent > 0`, proving it actually scrolled rather than silently
>   clipping.
> - `'does not scroll at the reference canvas'` — 402×874 at scale 1.0: assert
>   `maxScrollExtent == 0`. This is the guard that the scroll view did not change the
>   design.
> - `'GET STARTED clears a 34pt home indicator'`.
> - `'ShineButton label does not clip at scale 1.5'` — pump it directly with
>   `'ADD MY FIRST OBJECT'`.
>
> ### Done when
>
> - `flutter analyze` clean; `flutter test` green with no edits to existing assertions.
> - The `'does not scroll at the reference canvas'` test passes — that is the proof the
>   design is unchanged.
> - `grep -n "Spacer" lib/onboarding/welcome_screen.dart` shows the `Spacer` still
>   inside a height-bounded parent.

---

## Notes for the reviewer

**The scroll-with-minHeight pattern is the load-bearing change.** It is the standard
Flutter answer to "bottom-anchored content that must survive growth", and it is
strictly better than the alternatives here: `Spacer` alone crashes when unbounded,
`SingleChildScrollView` alone loses the bottom anchor, and `FittedBox` on the whole
column would shrink the body copy to unreadable. Get the `ConstrainedBox(minHeight:)`
right and this screen stops being fragile.

**Fix `ShineButton` here, not in screen 04.** Two screens share it and 04's label is
the longer one. One guard in the shared widget is a smaller diff than two guards at the
call sites, and patching only the screen whose prompt you happen to be holding leaves
the sibling broken.

**Worth flagging to the user.** Six decorative chips positioned by hand against a
402×874 reference is a composition, not a layout. The fractional conversion keeps it
coherent, but on a 1280×800 iPad it will still read as a phone poster stretched wide.
Same question as the splash: is iPad a real target here, or a store requirement?
