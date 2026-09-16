# End-to-End Test Cases (mobile-mcp)

Manual end-to-end cases for every user flow. They're driven through
mobile-mcp on the iOS simulator. Bundle id: `com.radiumadam.spec`. Launch
cases live in [launch_test_cases.md](launch_test_cases.md).

**Setup**
- Put 3 synthetic photos in the simulator library: `B22 BULB`, `205/55 R16`,
  `HP 67XL`.
- Stream the app's logs to catch Flutter errors.
- Check data by reading `Documents/spec.sqlite` and `Documents/photos/`.
- The simulator has no camera, so "take photo" falls back to the library
  picker by design (`lib/services/photo_capture.dart`).

## Add entry (07 library → 08 not-in-library → 05 fields sheet)

| ID | Case | Steps | Expected |
|----|------|-------|----------|
| A-01 | Cancel writes nothing | Orb `+` → 07 → `CANCEL` | Back on Home. No new DB rows. |
| A-02 | Library search and category chips | 07: type `tyre`; clear; tap `CAR` | Grid filters to tyre items. `CAR` shows `LIBRARY · 16 OBJECTS`. |
| A-03 | SAVE disabled without a value | 07 → `Bulb` → sheet, value empty | `SAVE` is grey and does nothing. |
| A-04 | Save a library item | `Bulb` → type `B22` → `SAVE` | Sheet and 07 close. Home card shows `B22`, `HOME` zone. `objects` row has spec_kind bulb, spec_value `B22`. |
| A-05 | Location, new zone, reminder, notes | 07 → `Water filter` → `LT1000P` → Location → `+ NEW ZONE` `Garage Shelf` → `REMIND ME` tap → Notes `under sink left` → `SAVE` | Zone `Garage Shelf` created. Object has zone set, remind_every_months cycled from the filter default of 6, and notes saved. |
| A-06 | No-match leads to 08 | 07: type `zzqx widget` | `NOT IN THE LIST.` and `PHOTOGRAPH IT` show. Tap → 08 with name pre-filled. |
| A-07 | 08 with photo | 08: `+ PHOTO` → library picker → pick `205/55 R16` photo → set `SPEC` → `ADD MANUALLY` → `SAVE` | Preview shows the photo, chip reads `RETAKE`. Object saved with a `photos` row, and the file is in `Documents/photos/`. Home card shows the photo. |
| A-08 | 08 needs a name | 08 with NAME cleared | `ADD MANUALLY` is disabled. |
| A-09 | Photo from a library item | 07 → `Cartridge` → sheet photo tile | Record whether a photo can be attached at all. |
| A-10 | Home grid limit | With 4+ objects | Home shows the 3 newest cards plus the Add card. |

## Search (02)

| ID | Case | Steps | Expected |
|----|------|-------|----------|
| S-01 | Pill enables with data | Home with at least 1 object → tap search pill | Search opens with the field focused. Count row reads `N OBJECTS · M PHOTOS`. |
| S-02 | Spec match opens object | Type `B22` → tap result | `1 MATCH` with timing. The row opens 03 for the bulb. |
| S-03 | Notes and zone are searchable | Type `sink` | The water filter is found by its notes. |
| S-04 | No match → add | Type `nonexistent thing` → `ADD IT INSTEAD` | `NOTHING MATCHES.` shows. 07 opens with the query already typed. |
| S-05 | Recents | After S-02, clear the field | A `RECENT` chip `B22` shows. Tapping it re-runs the search. |
| S-06 | Browse by zone and clear scope | Resting search → `BROWSE BY ZONE` row → scoped → `×` | Scoped search shows the zone chip and only that zone's objects. `×` goes back to unscoped. |
| S-07 | Cancel | `CANCEL` | Back on Home. |

## Object detail (03)

| ID | Case | Steps | Expected |
|----|------|-------|----------|
| O-01 | Detail content | Open the water filter | Zone chip, spec `LT1000P`, NOTES `under sink left`. |
| O-02 | Photo viewer | Open the tyre object → tap photo → tap to close | Full-screen viewer opens and closes back to 03. |
| O-03 | Mark replaced | `REPLACED` | `LAST REPLACED` shows today's date. DB `replaced_on` is today. |
| O-04 | Edit and save persists | `Edit` → change spec and notes → `SAVE` → relaunch app | New values shown and still there after a cold launch. |
| O-05 | Edit cancel reverts | `Edit` → change spec → `Cancel` | Original spec shown. DB unchanged. |
| O-06 | Two-tap delete | `•••` → `Delete` → `Yes, delete` | Back on the previous screen, object gone. Row and photo file removed. |
| O-07 | Unwired controls | Tap `Share`; `•••` → `Move to zone` / `Duplicate` / `Set reminder`; long-press photo → `Replace` | Record them as not implemented (expected to do nothing). |

## Collections (06)

| ID | Case | Steps | Expected |
|----|------|-------|----------|
| C-01 | Zone list with data | Collections tab | Zones with 2-digit counts and spec samples. Totals `N OBJECTS`, `N PHOTOS`. |
| C-02 | Zone → scoped search | Tap a zone with objects | Scoped search lists only that zone's objects. |
| C-03 | New zone and duplicate rejected | `+ NEW ZONE` `Attic` → Done; again with `attic` | `Attic` added. The duplicate is rejected and no second row is created. |
| C-04 | Rename | `EDIT` → tap `Attic` → `Loft` → Done → `DONE` | Row reads `Loft`, and the DB name is updated. |
| C-05 | Delete empty zone | `EDIT` → `×` on `Loft` | Removed immediately. |
| C-06 | Delete zone with objects needs confirm | `EDIT` → `×` on a zone with objects → `DELETE?` | The first tap only shows `DELETE?`. The chip deletes. Objects keep existing. |
| C-07 | Export from Collections | `EXPORT` | The system share sheet opens. |

## Settings, backup and wipe (09)

| ID | Case | Steps | Expected |
|----|------|-------|----------|
| X-01 | Settings content | Home `•••` | `SETTINGS`, correct counts, privacy lines, version `SPEC 1.0.0 (1)`. |
| X-02 | Export backup | `EXPORT BACKUP` → share sheet → `Save to Files` | Zip saved to Files. Status `BACKUP READY`. |
| X-03 | Restore rejects non-SPEC zip | `RESTORE FROM BACKUP` → pick a non-SPEC zip | Status `This file is not a SPEC backup.` Data unchanged. |
| X-04 | Restore confirm is two-tap, and backdrop cancels | Restore → pick the backup → tap backdrop | Nothing changes. |
| X-05 | Delete everything | `DELETE EVERYTHING` → `Yes, delete everything` | Lands on Welcome. DB tables empty, photos folder empty. |
| X-06 | Restore round-trip | After X-05, onboard → Settings → restore the X-02 zip → confirm twice | `RESTORED N OBJECTS`. Objects, zones, notes and photos match before the wipe. |

## Onboarding after wipe (09 → 10 → 11)

| ID | Case | Steps | Expected |
|----|------|-------|----------|
| N-01 | Full onboarding path | Welcome `GET STARTED` → `NEXT` | Reaches `REMEMBER ONE THING.` (03 / 03). |
| N-02 | First object with photo | Capture frame → pick `HP 67XL` → chip `CARTRIDGE` → `ADD MY FIRST OBJECT` | Home shows 1 object with the photo. The row is named `Cartridge`, and the photo file exists. |

## Persistence and stability

| ID | Case | Steps | Expected |
|----|------|-------|----------|
| P-01 | Data survives a cold launch | Terminate → launch after adds and edits | Same objects, photos and edits. |
| P-02 | No errors or crashes across the run | Scan the log stream and `mobile_list_crashes` | No Flutter exceptions. No crash reports. |

## Run — 2026-09-15

Debug build of `899d7c7` on an iPhone 17 Pro Max simulator (iOS 26.2),
driven by mobile-mcp 1.0.4. Every data claim was checked against
`spec.sqlite` and `Documents/photos/`.

**Result: 39 pass, 1 fail (A-09), 1 not implemented (O-07).** No crashes and
no Flutter exceptions. Many bugs turned up inside cases that pass.

| ID | Result | Notes |
|----|--------|-------|
| A-01 | Pass | |
| A-02 | Pass | Fuzzy matching is loose: `tyre` also returns Vacuum bag, Battery, Smoke alarm; `CAR`+`tyre` returns Coolant. |
| A-03 | Pass | |
| A-04 | Pass | Row saved with kind bulb, spec `B22`, zone Home. |
| A-05 | Pass | Zone, reminder (6 months → 12) and notes all saved. `+ NEW ZONE` is invisible (B-01). |
| A-06 | Pass | |
| A-07 | Pass | Camera prompt shows the plist copy. Don't Allow falls back to the library after ~3 s. Photo row and file written; card shows the photo. |
| A-08 | Pass | A name of only spaces also keeps the button disabled. |
| A-09 | **Fail** | A library item can never get a photo. The sheet's photo tile does nothing (B-02). |
| A-10 | Pass | `SEE ALL`, zone chips, rail `+` and card `•••` all do nothing. |
| S-01–S-07 | Pass | Stale results after edit or delete (B-07). |
| O-01–O-06 | Pass | Deleting removes the row, cascades the photo row, and deletes the file. |
| O-07 | Not implemented | Share, Move to zone, Duplicate, Set reminder do nothing. |
| C-01–C-07 | Pass | Focus trap (B-11). Zone delete leaves objects out of every zone (B-12). |
| X-01–X-06 | Pass | A non-SPEC zip is rejected with the right copy. Round-trip restore matches field for field, photo bytes included. |
| N-01–N-02 | Pass | Onboarding object has an empty spec (B-14). |
| P-01–P-02 | Pass | Only log noise is the simulator's CoreHaptics messages. |

## Bugs found

| ID | Severity | Where | Bug |
|----|----------|-------|-----|
| B-01 | High | `lib/add/add_location_row.dart:267-275` | Zone picker rows fade in 30 ms apart, but the fade is tied to a 300 ms open animation, so row *n* ends at opacity `(300−30n)/200`. With 5 stored zones plus 5 suggestions, `Garage` sits at 15% and `+ NEW ZONE` and its name field at **0%**. They still work, but nobody can see them. Every user hits this. |
| B-02 | High | Add flow, 07 → 05 | The photo tile on the fields sheet is display-only. Only the "Add your own" (08) path takes a photo, so nothing picked from the 100-item library can have one. |
| B-07 | Medium | Search | Results don't refresh after an object is edited or deleted from them. A deleted object stays listed and opens a ghost detail page whose actions do nothing. |
| B-11 | Medium | `lib/collections/collections_chips.dart:89-91` | A refused new-zone name (duplicate or too long) calls `requestFocus()` again on every blur. Any other tap, like renaming a zone, snaps focus back. No message; the only way out is to erase the text. |
| B-12 | Medium | Collections zone delete | Objects in a deleted zone disappear from Collections (`3 OBJECTS` but zone counts add up to 2), export as `zone: null`, then silently move to a type-default zone on the next launch. |
| B-03 | Medium | 08 not-in-library, 03 edit mode, Collections new zone and rename | The keyboard covers the focused field. On 08 the scroll jumps back to the top whenever focus moves, hiding the field being typed into. |
| B-14 | Medium | Onboarding 11 | The first object is saved with an empty spec. The screen has no field for "the one number". |
| B-08 | Low | Photo viewer, capture preview | Photos are cropped to fill the frame, so the label (e.g. `HP 67XL`) can be cut off. |
| B-13 | Low | Settings export | `BACKUP READY` shows even when the share sheet was cancelled and nothing was saved. |
| B-04 | Low | Home zone rail, Search browse-by-zone | Zone names are forced to title case: `Garage Shelf` shows as `Garage shelf`. |
| B-05 | Low | Object detail 03 | The object's name (e.g. "Bulb") appears nowhere on its detail page. |
| B-15 | Low | Add flow | A CAR library item (Tyre) defaults its location to Home, not Car. |
| B-16 | Low | Library 07 | None of the 100 library items has an image, so every tile is blank. |
| B-17 | Low | Collections | Scrolled content passes under the status bar clock. |

## Re-test after fixes — 2026-09-15 (master `1958c00`)

Five parallel fix branches were merged. `flutter analyze` finds no issues and
`flutter test` passes 467 tests. Re-tested with mobile-mcp on a fresh
simulator build. No crashes and no Flutter exceptions.

| Item | Result | Evidence |
|------|--------|----------|
| B-01 invisible `+ NEW ZONE` | Fixed | With 10 zones in the picker, Garage and `+ NEW ZONE` are fully opaque. |
| B-02 photo on library items | Fixed | Tyre from 07: the 05 tile opened the picker, and the object saved with a photo row and file. |
| B-03 keyboard covers field | Fixed on 03 and Collections | The LAST REPLACED edit field and the new-zone field stay above the bar and keyboard. 08 is covered by widget tests only. |
| B-04 zone casing | Fixed | The rail shows stored names. |
| B-05 name on 03 | Fixed | "Bulb" / "Tyre" shows under the spec. |
| B-07 stale search | Fixed | Deleting from a result set drops it from `2 MATCHES` to `1 MATCH`, and the query is kept. |
| B-08 cropped photos | Fixed | Viewer and 11 preview show the whole photo. |
| B-11 focus trap | Fixed | A taken name shows `ALREADY A ZONE`, and the field stays usable. |
| B-12 zone delete | Fixed | Deleting Attic refiled both filters into Home at once; counts add up. |
| B-13 BACKUP READY | Fixed | Dismissed share sheet leaves no status, in both Settings and Collections. |
| B-14 onboarding spec | Fixed | ADD MY FIRST OBJECT opened step 05 (`CARTRIDGE · OTHER`); saved spec `67XL` in zone Other. |
| B-15 location default | Fixed | Tyre defaults to Car. |
| Library search | Fixed | `tyre` returns only Tyre and Bike tyre. |
| Share | Works | System sheet: "Plain Text and 1 Document". |
| Move to zone | Works | From the Home card `•••`; the DB zone and card chip update. |
| Duplicate | Works | New row with the same spec, notes, reminder and zone. |
| Set reminder | Works | `REMIND ME · EVERY 3 MONTHS`, `NEXT DUE · 15 DEC 2026`. |
| Replace / Remove photo | Works | New file swapped in, old file deleted. Remove took two taps and left 0 rows and 0 files. |
| SEE ALL / zone chips | Works | Lists every object; a chip opens scoped search. |
| Rail `+` | Works | Switches to Collections with the name field focused above the keyboard. |
| Reminders | Works | Permission is asked lazily; after Allow, 2 notifications are pending (future-dated). The overdue Bulb gets no notification, a lime `DUE` chip, and a lime NEXT DUE. |

Still open:
- **B-16:** library images need artwork.
- **Rail `+` typing (needs a finger test):** the first key typed into the field it focuses may drop. Seen only with scripted typing.
- **Notification delivery:** not observed firing; due dates are months away.
- **Android:** reminder receivers not added.
