# SPEC — next session brief

Read this first, then `~/.claude/plans/now-plan-deeply-about-fancy-quail.md`, which is the
approved architecture and phase plan. This file records where the work actually stopped, which
is not the same as where the plan says it should.

Project: `/Users/ahmadraza/Downloads/SPEC/spec`. Flutter 3.47.2, Dart `^3.13.2`.
Git is initialised; 11 commits; working tree clean. `main`, no remote.

---

## The product, in one paragraph

SPEC remembers the boring specifications of physical objects so the user can find them again
standing in a shop aisle: the bulb fitting `B22`, the tyre `205/55 R16`, the cartridge `67XL`.
It is strictly local. No server, no account, no sync. The design file ships twelve screens; four
are built. The shipped pixels make privacy promises in print, and the architecture has to keep
them true.

Design source: `design/Six design screens.zip` (gitignored). Extract it to read
`SPEC Screens.dc.html`, which contains all twelve screens, and `SPEC-flutter-brief.md`.

---

## State of play

**Built and solid** — splash (12), onboarding welcome (09), how-it-works (10), first-object (11).
Checked against the design file frame by frame. 29 tests pass, `flutter analyze` is clean under
strict-casts, strict-inference and strict-raw-types. Debug and release APKs both build.

**Done beyond the screens**

| | |
|---|---|
| Routing | `go_router`, onboarding gate as one `redirect` driven by a `ValueNotifier` |
| State | Riverpod 3 with codegen (`build_runner`, `riverpod_generator`) |
| Persistence | Onboarding flag in `shared_preferences`; survives relaunch, proven by test |
| Splash warmup | Supplied; reads the flag on cold start |
| Platform | Bundle id `com.radiumadam.spec` at all nine sites; portrait locked; backup excluded on Android; `PrivacyInfo.xcprivacy` added |

**Never done, and you must not assume otherwise: the app has never been run on a device or
simulator.** Everything is verified by widget tests, rendered PNG frames and successful builds.
Run it first. That is task zero.

---

## The three gaps the user asked about

### 1. Swiping

- **Backwards works.** Onboarding uses `context.pushNamed`, so there is a real navigation stack.
  Android back and the iOS edge-swipe both pop. Covered by
  `test/app/router_test.dart` → "onboarding pushes a real stack".
- **Forwards does not exist, deliberately.** Do not add a `PageView` without reading the
  reasoning in the plan's "Swiping and gestures" section. Short version: all three screens start
  their entrance animation in `didChangeDependencies`, a `PageView` builds every page in the
  viewport at once, and muting off-screen pages with `TickerMode` does **not** help because
  `Ticker.start()` stamps `_startTime` from the current frame even while muted. The pages would
  finish their entrances off-screen. If forward swipe is genuinely wanted, the cost is an
  `isActive` parameter plus keep-alive wrappers on all three screens, roughly 30 lines of churn
  in files that are otherwise finished.

### 2. Scan (camera) on screen 11 — NOT BUILT

`FirstObjectScreen` already exposes `VoidCallback? onCapture`, and `CaptureFrame` already exposes
`Widget? preview` with a null-aware element that handles both states. **Neither is wired.**
`lib/onboarding/onboarding_routes.dart` does not pass `onCapture`, so tapping the frame flashes
the corner brackets for 120 ms and calls nothing.

`capture_frame.dart` needs **no edits** to accept a live preview. That is by design.

### 3. Pick from device (photo library) on screen 11 — NOT BUILT

No picker at all. Note the design's own fallback logic: the library picker needs no permission on
either platform, so a user who refuses the camera must still be able to finish. Camera denial is
never a dead end.

**Why both were left out:** a captured photo currently has nowhere to go. There is no object, no
database, and no screen that displays a photo. Building capture before its destination was the
over-building the user stopped mid-session. Do phase 2 first.

---

## Phases, and where to resume

Nine phases, 0 to 8, defined in the plan. Status:

| Phase | Work | Status |
|---|---|---|
| 0 | Repo, analysis, bundle id, signing, backup exclusion | done **except release signing** |
| 1 | Riverpod, router, route wrappers, splash gate | done |
| 2 | Data layer | **resume here** |
| 3 | Onboarding persistence, chip carried into the draft | half done |
| 4 | Camera, photo pipeline, permissions, preview wired | not started |
| 5 | Home, Search, Object detail | not started |
| 6 | Add sheet, Collections, Library pick | not started |
| 7 | Reminders, voice, Android OCR, app lock | not started |
| 8 | Export and "Open a SPEC export" | not started |

**Phase 3 is half done.** Onboarding persistence landed early, alongside phase 1. What remains is
the other half: the suggestion chip the user picks on screen 11 is still discarded.
`FirstObjectScreen.onAdd` correctly reports `BULB` / `TYRE` / `CARTRIDGE` / `FILTER`, and
`onboarding_routes.dart` throws it away because there is no add flow to receive it.

**Release signing is the user's task, not yours.** They must run
`keytool -genkey -v -keystore ~/keys/spec-upload.jks -keyalg RSA -keysize 4096 -validity 10000 -alias upload`
and create `android/key.properties` (already gitignored). Then wire the Gradle release
`signingConfig`, which currently still points at the debug config.

---

## Order of work for the next session

1. **Run the app.** Boot a simulator or connect the user's Android device. Tap through all four
   screens. Confirm the animations, the back-swipe, and that finishing onboarding does not replay
   on a second launch. Nothing below matters until this is done.
2. **Phase 2, the data layer.** Follow the plan's "Data model" section. It is specific: `.drift`
   SQL files, a Dart search scorer rather than FTS5, attributes as a JSON column, photos as a
   table, `library_term` as a copied string, `PRAGMA foreign_keys = ON` in `beforeOpen`, photos
   keyed by file name and never by path. Read the reasoning before deviating; each of those is a
   trap that was already reasoned through.
3. **Finish phase 3.** Carry the chip from screen 11 into the add draft.
4. **Phase 4, camera and picker**, wired into the two slots that already exist.
5. Then phases 5 to 8 in order.

---

## Rules this codebase is held to

- **The four built screens do not change.** Their 22 tests build them directly with no
  `ProviderScope` and assert on widget depth. Wiring happens in route-level `ConsumerWidget`
  wrappers, from outside, where they add no render object. See
  `lib/onboarding/onboarding_routes.dart` for the pattern. If a change to those screens seems
  necessary, that is the signal to reconsider the approach.
- **Build only what a screen consumes.** The user explicitly stopped an attempt to build the full
  Drift schema for eight screens that do not exist. Drift, `path_provider` and their codegen were
  added and then removed for exactly this reason.
- `package:` imports throughout, never relative.
- Every commit runs `flutter analyze` and `flutter test` first. Both must be clean.
- Commit messages: lowercase type prefix, a body explaining *why*, and the trailer
  `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`.

---

## Traps already hit, so you do not repeat them

- **`AsyncValue.valueOrNull` does not exist in Riverpod 3.** The nullable getter is `.value`.
- **`custom_lint` and `riverpod_lint` cannot be installed.** `custom_lint` 0.8.1 pins analyzer
  `^8.0.0` while `build_runner` 2.16.1 needs `>=13.3.0`. Codegen wins; revisit when custom_lint
  catches up.
- **`sqlite3_flutter_libs` and `sqlcipher_flutter_libs` are end-of-life stubs.** Their own
  description reads "Not used anymore, update to version 3.x of package:sqlite3 instead". And
  therefore **do not use `drift_flutter`**, which still depends on both. Use `drift` directly with
  `NativeDatabase.createInBackground` plus `path_provider`.
- **`sqlite3` 3.x builds native assets via Dart build hooks, and that broke the Android build**
  when Drift was briefly added. Expect to debug this in phase 2. It is not a blocker, but budget
  time for it.
- **Piping a build into `tail` hides its exit code.** A Gradle failure was reported as success this
  session because of it. Redirect to a file and check `$?`.
- **`flutter analyze` rewrites `analysis_options.yaml`**, re-adding platform excludes. Harmless.
- **`pumpAndSettle` never returns on any of these screens.** The ambient loops repeat forever.
  Pump fixed durations, one frame at a time.
- Widget tests must pin the canvas to 402 × 874 at device pixel ratio 3, or layouts overflow on the
  default 800 × 600 test surface.
- `shared_preferences` needs a platform stub in tests. Use `test/support/prefs.dart`.

---

## Open product decisions already made, do not relitigate

Local-only, no server. Riverpod with codegen. Drift over SQLite. Dart search scorer, FTS5 deferred
with a stated adoption trigger. No SQLCipher. Voice on both platforms with on-device recognition
forced in code, accepting Android's `INTERNET` permission and the loss of the kernel-level
no-network guarantee. OCR Android-first, iOS deferred. Biometric app lock in scope. Backup
excluded, with "Open a SPEC export" added as the way back in.

One consequence to hold on to: **the release APK currently ships with no `INTERNET` permission at
all**, which makes the welcome screen's promise enforced by the Android kernel. Phase 7's speech
plugin ends that. When it lands, add the lockfile allowlist test and the source grep described in
the plan's Security section, because they become the only remaining proof.
