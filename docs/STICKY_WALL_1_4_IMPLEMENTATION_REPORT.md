# Sticky Wall 1.4 — Implementation report

Version in `pubspec.yaml`: **1.4.0+7** (1.3.0+6 was never uploaded).
Commits: `1ab665e` … this report, on `main`.

How to read the status words used below:

- **implemented**: code is in the repo and covered by automated tests that pass.
- **built**: compiled into an Android or iOS binary.
- **tested in emulator / on a physical device**: actually run there.
- **not done**: not built in this pass. **blocked**: needs something this machine does not have.

Nothing in this pass was **built** or run **on a device or emulator**. Gradle was not run, so the Kotlin change in `MainActivity.kt` has not been compiled. Another agent was using the machine's emulators, and iOS needs macOS. All verification is `flutter analyze`, the Dart test suite, and screenshots rendered in tests.

---

## 1. Baseline vs after

Baseline: 1.3.0+6 (commit `43c35d1`), 197 tests.

| Area | 1.3 | 1.4 | Decision |
|---|---|---|---|
| Board name formatting | Bold / italic / underline per name | Plain name + emoji. Flags from 1.3 saves are read and dropped; the words are kept. | Removed (as asked) |
| Seasonal packs | Pickable only around the occasion | Pickable all year; the pack whose occasion is near is listed first | Lock removed (as asked) |
| Export page | Area, notes and 2×/3×/4× shown at once; PDF hidden in ⋮ | Save image / Export PDF / Share up front; area, notes, 2×/3×/4× and trim under *More options* | Simplified, nothing lost |
| Drag to the foot to delete | Always on | **Off by default**; switch in Customize. Delete in each note's sheet still works. | Default changed |
| Finished checklists | Auto-clean was already off by default | Unchanged: kept, shown as done | Kept |
| Voice note | In the kinds list among the others | Last in the kinds list, under a divider; microphone asked only on first record (unchanged) | Moved |
| Bottom tools | Icons only | Icons with names (Filter, Pen/Sort, layout name, More) | Labels added |
| Other note kinds | Long-press the add button only | An *Other kinds* pill above the add button; long-press still works | Added |
| First run | Sample wall + gesture tips sheet | Sample wall under a welcome: template / blank wall / explore. Tips stay in the ⋮ menu. | Changed |
| Board templates | 3 (Kanban, week, brainstorm), headings only | **45** editable templates, six shelves, EN + VI | Added |
| Theme packs | none | **37** packs (17 free, 20 Pro), applied per board with Undo | Added |
| Templates & themes gallery | none | Search, shelves, live previews drawn by the wall renderer | Added |
| Memory wall | none | Up to 20 photos → 4 layouts × look → board of editable prints | Added |
| All boards | Tabs only | Grid of every board with a rendered picture, note count, open / duplicate (Undo) / delete | Added |
| Share into the app | Opened the editor pre-filled | Board picker → saved directly → Open / Undo; duplicate links refused | Changed |
| Pro refund | Never revoked | Google Play "not owned" revokes the cache; no answer keeps it | Changed |
| Recents screen | Showed notes | Blank while the app lock is on or a private board is open (Android) | Added (not built) |
| Mini map / overview / 3D | none | none | Not added (as asked) |

### Not done in this pass

These are open items, not hidden ones.

- **Tap = select with a small action bar (§4.3).** A tap still opens the editor. The long-press sheet now puts the colours and Pin / Move / Share / Delete first. Changing the primary gesture needs an on-device check: the wall's gesture arena is not exercised by widget tests (see CLAUDE.md).
- **A separate "connect" tool before a thread is drawn.** Dragging from a pin still ties a thread, and *Tie a thread to…* is in the note's sheet.
- **Archive for finished checklists.** There is no archive state. Notes are kept, shown as done, and can be deleted by hand.
- **Quick Customize per board (§5.3).**
  - Not done: the colour, pin, font, string and sticker panel, and the dim / soften / blur slider for busy walls.
  - Done: theme packs set a board's font and pin. Choosing a font in Customize still sets the global default.
- **Last-edited date on board cards.** Notes have no edit time. Cards show the note count.
- **"Find a note on another board, then pan to it".** Not checked in this pass. The existing behaviour is unchanged.
- **Restore preview / merge.** Restore still replaces, with Undo (unchanged).
- **Per-photo frame styles (polaroid / film / tape) and manual crop on memory-wall prints.** Prints use the existing print look; move, turn, resize, caption, threads and stickers work.
- **New artwork.** See §2.

## 2. Assets

| Item | Target in the brief | Actually in the repo | Checked by |
|---|---|---|---|
| Theme packs | 30–40 | **37** (17 free / 20 Pro, 5 of them seasonal) | `test/template_library_test.dart`: unique ids and looks, real walls and fonts, ink-on-paper contrast ≥ 7:1, valid stickers, free packs use only free things, no Amatic face |
| Editable board templates | 40–60 | **45** (plans & lists 11, family 8, study 7, personal 7, creative 6, seasonal 6), 268 objects in total | Same test: ids, both languages, coordinates, scales, sticker ids (free only), theme ids, thread indices, no two layouts alike |
| Memory-wall layouts | 20–30 presets | **4** layouts × 8 suggested looks | `test/memory_wall_test.dart`: 24 layout/size cases stay on the wall; prints in rows don't overlap |
| New decoration artwork (stickers, washi, frames, textures) | ≥ 300 | **0 new.** Packs and templates combine what 1.3 shipped: 31 wall textures, 16 fonts, 6 pin styles, 6 paper styles, 5 thread styles, 37 stickers | — |

New artwork is **not done**. Code-drawn vectors at this scale need art direction and review that this pass did not have. The brief also rules out placeholder art. The image tool used for the 1.3 seasonal walls was not run here. This is the largest gap against the brief.

Source and checks:

- Templates are data in `assets/templates/templates.json`. It is written by `tool/gen_templates.py` (`python tool/gen_templates.py`) and validated by the test above.
- The validator caught three real problems while the library was built: a Pro sticker inside a free template, and two pairs of templates with identical layouts.

Previews:

- Contact sheets, rendered by the app's own wall renderer: `docs/previews/templates_1..4.jpg` and `docs/previews/themes_1..4.jpg`.
- To regenerate: run `test/library_sheet_test.dart` (skipped generator; instructions at its top).
- Emoji stickers show as empty boxes in these test renders because the test font has no emoji. On a phone they draw.

## 3. Data changes and 1.3 compatibility

Storage is JSON in `shared_preferences`; there is no database. Every change is a tolerant field:

| Record | Change | Older data | Older app reading 1.4 data |
|---|---|---|---|
| Board | `bold` / `italic` / `underline` dropped | Read, ignored, not written back; name kept | Shows names plain |
| Board | `theme`, `font`, `pin` added (only when set) | Absent → global font and pin | Ignores them; global font and pin |
| Note | `sample` added (only when true) | Absent → false | Ignores it |
| Prefs | `dragToDelete` (default false), `welcomePending` | Absent → off / no welcome | — |

Tests:

- `test/board_dialog_test.dart`: a formatted 1.3 name loads as a plain name and is written back without the flags.
- `test/pro_test.dart`: backup round trips (unchanged, still pass).

Behaviour kept:

- Notes keep their Pro look without Pro. Theme packs set a board's font and pin, and those draw without Pro too.
- Only *choosing* a Pro pack is gated.

## 4. Native: Android and iOS

| Item | Status |
|---|---|
| Android home-screen widget | Unchanged from 1.3. Private boards are never listed (existing test). |
| Android share target | Dart flow changed (board picker, direct save). Intent filters unchanged. Implemented, not run on a device. |
| Android notifications / reboot | Unchanged. Private-board reminders say only that a reminder is due. |
| Android recents privacy | `MainActivity.kt` channel `sticky_wall/privacy`: `setRecentsScreenshotEnabled(false)` on API 33+, `FLAG_SECURE` below. **Not compiled or run.** |
| iOS widget / share extension / App Groups | Unchanged; Xcode target setup in README. **Blocked:** needs macOS and Xcode. |
| iOS recents privacy | **Not done.** |
| Purchases on iOS | `in_app_purchase` path unchanged. The ownership check is Android-only. |

## 5. Security: what is encrypted and what is only gated

- **Nothing is encrypted by the app.** Notes, boards and settings are plain JSON in the app's private storage. Photos and recordings are plain files there.
- Protection comes from Android's app sandbox, plus the app lock and private boards, which gate the UI.
- Private boards while shut keep notes out of the board view, search from other boards, the trash list, the widget, reminder texts and export (export covers only the open board). On Android 13+ / with `FLAG_SECURE` below, the recents thumbnail is also hidden (not yet built).
- README and PRIVACY.md now say plainly that this is a lock in the app, not encryption. No copy in the app or store text claims encryption (checked by grep).
- Per-board encryption with Keystore / Keychain was not attempted. Doing it safely means handling key loss, a biometric change, and restore of an encrypted backup on a new phone. That is a feature of its own, with its own tests and device runs.
- Backups:
  - A crafted file name such as `../x` cannot escape the app folders: only the last path segment is used.
  - A backup from a newer version is refused.
  - Backups are JSON, not zip, so a zip bomb does not apply.
  - A very large backup file is read whole into memory; there is no size cap.

## 6. Pro: purchase, refund, offline

- **Pending purchase:** Pro unlocks only once Google Play reports the purchase as paid (since 1.3).
- **Refund or revoked order:**
  - At start, `ProController.checkOwnership` asks Google Play which purchases the account holds (`queryPastPurchases`).
  - A successful answer without a paid `sticky_wall_pro` revokes the cached unlock.
  - An error, no Play, or offline keeps the cache, so a paying user is never locked out by a bad connection.
  - Tested with an injected answer in `test/pro_test.dart`.
  - **Limits:** a refund made while the phone stays offline is not noticed until the next start with Play reachable. There is no server-side receipt check because there is no backend. On iOS, refunds are not checked.
- **What stays after a revoke:** notes and boards keep their Pro look; choosing new Pro things stops.
- **Prompts:** one soft prompt, ever (unchanged). Pro packs and memory-wall looks show a lock and open the Pro sheet. Seasonal packs are all-year once owned.

## 7. Tests

Commands:

```sh
flutter analyze                       # No issues found
flutter test                          # 246 passed, 53 skipped (screenshot generators)
flutter test test/template_library_test.dart test/gallery_test.dart test/memory_wall_test.dart test/perf_test.dart
```

Added in 1.4:

| Test file | What it covers |
|---|---|
| `test/template_library_test.dart` | Library and pack validators, building, clearing examples, applying a pack with Undo |
| `test/gallery_test.dart` | Template from the "+" tab; free theme with Undo; Pro theme offers Pro; welcome (blank / template / explore); all boards and duplicate with Undo; share straight onto a board, duplicate link refused, Undo |
| `test/memory_wall_test.dart` | Layouts × sizes stay on the wall, ordering, timeline threads, the sheet |
| `test/perf_test.dart` | Wall of 50 / 200 / 500 notes |
| Updated tests | Back saves, reminder presets, export *More options*, drag-to-delete setting, plain board names, seasonal all year, refund revocation |

Performance, **in the test environment** (no GPU and no real frame clock, so these are not device numbers):

| Notes | Open | 10-step drag | Diacritic search | Switch to grid |
|---|---|---|---|---|
| 50 | 763 ms | 67 ms | 87 ms | 87 ms |
| 200 | 781 ms | 88 ms | 176 ms | 39 ms |
| 500 | 1317 ms | 123 ms | 329 ms | 42 ms |

Visual QA:

- 12 test-rendered screens were checked by eye (wall, 320 dp, welcome, kinds, gallery, theme applied, new board, all boards, export, memory sheet) and all 8 contact sheets.
- One defect found and fixed: Amatic SC made the whole UI unreadable when a pack used it.

Not run:

- Golden comparisons for the new screens on both languages at 320 dp with large text (only spot checks).
- Integration tests on a device.
- Profile-mode frame timings.

## 8. Remaining blockers and a launch checklist

Blockers:

1. **Android release build.** Run `flutter build appbundle --release --obfuscate --split-debug-info=build/symbols`. It needs the machine free of the other agent, and the upload keystore plus `android/key.properties` (still owed). This also compiles the `MainActivity.kt` change for the first time.
2. **On-device pass (Android, physical phone).**
   - First run (all three choices).
   - Templates & themes.
   - Memory wall with real gallery photos (permissions, 20-photo cap, cancel deletes copies).
   - Share in from Chrome and Photos.
   - Recents thumbnail with lock / private board.
   - The *Other kinds* pill and labelled tools on a 360 dp phone.
   - Drag-to-delete off / on.
   - Export *More options*.
   - Purchase, pending, and refund in a license-test account (refund then restart).
3. **iOS.** Needs macOS and Xcode: widget target, share extension, App Groups, a recents snapshot cover, StoreKit testing.
4. **Artwork.** The 300-asset decoration library is not started (§2).
5. **Play Console.**
   - Merchant profile, then create `sticky_wall_pro` with a price.
   - Data safety: unchanged, nothing collected.
   - Store text: may now mention templates, themes and memory wall; must not claim encryption.
   - Closed test of 12 testers for 14 days if the account is personal.
6. **Review material.** `store/gioi-thieu.html` still describes 1.3 and should be refreshed with 1.4 screens.
