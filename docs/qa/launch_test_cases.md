# App Launch — Manual Test Cases (mobile-mcp)

Run on the iOS simulator through mobile-mcp. Bundle id: `com.radiumadam.spec`.

**Cold launch** means `mobile_terminate_app` then `mobile_launch_app`.
**Pass** means every expected result holds. Checks come from screenshots,
`mobile_list_elements_on_screen`, `mobile_list_crashes` and device logs.

Launch flow under test: `SplashGate` shows the splash over the router. The
splash waits for its 4.5 s timeline plus `appStartupProvider` (DB open, then
the onboarding flag from SharedPreferences), with a 3 s grace cap. Then it
fades out over 320 ms. The router sends users who haven't finished onboarding
to `/onboarding/welcome`, and everyone else to `/home`.

## Setup

- First-run cases (L-01 to L-03) need empty app data. Back up the app's data
  container first and restore it afterwards.
- Returning-user cases (L-04 to L-08) run on the restored data.

## Cases

| ID | Case | Steps | Expected |
|----|------|-------|----------|
| L-01 | First-run cold launch shows splash, then Welcome | Empty data. Cold launch. Screenshot at ~1 s, then at ~7 s. | ~1 s: splash with SPEC wordmark on black. ~7 s: Welcome with "Your physical world, remembered.", `GET STARTED` and `SKIP`. |
| L-02 | Splash leaves on time and doesn't get stuck | During L-01, screenshot every ~1 s from launch. | Splash is gone by ~8 s (4.5 s + 3 s grace + fade). Never stuck on the splash. |
| L-03 | Onboarding choice persists across launches | On Welcome tap `SKIP`. Confirm Home. Cold launch. | After SKIP: Home. After relaunch: splash, then Home, not Welcome. |
| L-04 | Returning user cold launch lands on Home | Restored data. Cold launch. Wait ~7 s. | Home shows the SPEC wordmark, the "REMEMBER THE THINGS YOU SHOULDN'T HAVE TO." tagline and a `Home` / `Collections` tab bar. |
| L-05 | No crash on launch | After L-01, L-03 and L-04, check crash reports and SPEC logs from launch. | No new SPEC crash report. No `AsyncValueIsLoadingException`, and no Flutter error in the logs. |
| L-06 | No debug text styling after launch | Screenshot Home after L-04. | Tab bar labels and the `+` show no yellow double underline. |
| L-07 | Collections works right after launch | Cold launch. As soon as Home shows, tap `Collections`. | Collections screen renders. No crash or red error screen. (Regression check for 899d7c7.) |
| L-08 | Warm resume doesn't replay the splash | On Home press HOME. Launch SPEC again (no terminate). | Returns straight to the same screen. No splash. |

## Run — 2026-09-15

Debug build of `899d7c7` on an iPhone 17 Pro Max simulator (iOS 26.2), driven
by mobile-mcp 1.0.4. Timings come from `simctl` screenshots every ~0.5 s,
measured from when the process appeared.

| ID | Result | Evidence |
|----|--------|----------|
| L-01 | Pass | Black ~3.5 s (debug engine start), splash 3.8–8.7 s, Welcome with all expected elements at 9.3 s. |
| L-02 | Pass | Splash on screen ~4.9 s (4.5 s timeline + 320 ms fade). Never stuck. |
| L-03 | Pass | SKIP → Home. `spec.onboarding_done = true` written. Relaunch → splash → Home. |
| L-04 | Pass | Splash → Home with wordmark, tagline and tab bar (5 zones, 0 objects in the DB). |
| L-05 | Pass | `mobile_list_crashes` empty after every launch. Only Flutter log lines were the Impeller notice and the VM service banner. |
| L-06 | Pass | Full-resolution tab bar crop: no yellow underline on labels or `+`. |
| L-07 | Pass | Collections rendered straight after a cold launch. No error screen, no crash. |
| L-08 | Pass | Same PID before and after. Resumed on Collections at the same scroll offset, no splash. |

Side findings (not launch failures):

- Pre-splash black screen ran 3.5–6 s. That's debug JIT start-up; check it on a
  profile or release build before counting it as a real problem.
- Home says "NO ZONES YET" while the DB has 5 zones. `homeCategories` builds
  from objects, not zones (see the stale comment in `lib/providers/home.dart`).
- On Collections, scrolling moves the `SPEC` pill under the status-bar clock.
