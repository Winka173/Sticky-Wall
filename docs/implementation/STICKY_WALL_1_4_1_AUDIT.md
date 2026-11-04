# Sticky Wall 1.4.1 — audit of 1.4 and what changed

The baseline is `main` at `e9cee4b` (1.4.0+7, 246 tests). Every claim below was checked in the source and the tests, not taken from the product page.

## 1. 1.4 claims, checked

| Claim (1.4 docs) | In the source | Verdict |
|---|---|---|
| 7 note types + stickers | `NoteType` in `lib/models/note.dart` | True |
| 45 editable templates in 6 shelves | `assets/templates/templates.json`, validated by `test/template_library_test.dart` | True |
| 37 themes, 17 free | `lib/services/theme_packs.dart`; the test counts free ≥ 12 (17 by inspection) | True |
| 31 wall surfaces, 16 fonts | `walls`, `fontChoices` in `lib/theme.dart` | True |
| Memory wall: 20 photos, 4 layouts, 1 frame | `lib/services/memory_wall.dart` | True (now 5 layouts, 7 frames) |
| Board gallery, three-way first run, *Other kinds* | `board_picker.dart`, `home_screen.dart` `_welcome`, `_moreKindsButton` | True |
| Android widget runs; iOS target not integrated | Kotlin provider present; Swift files present, no Xcode target | True |
| 246 tests | `flutter test`: 246 passed, 53 skipped (generators) | True at `e9cee4b` |
| No original artwork | No new art files in 1.4 | True; fixed in 1.4.1 (§3) |
| Private boards are a lock in the app, not encryption | Notes are plain JSON in `shared_preferences` | True. The 1.4 label "Private board" over-promised; renamed (§2) |
| Privacy policy said data "never leaves the device" | `PRIVACY.md` vs `android:allowBackup` plus `data_extraction_rules.xml` cloud include | **Wrong**: Android backup copies app data to the user's Google backup. Fixed (§2) |

## 2. P0 changes

| Item | Change | Source |
|---|---|---|
| Restore preview | Before any restore: date, size, version and counts (boards, notes, trashed notes, photos, voice notes, threads, stickers, locked boards); overlap with what is here; *Add to what is here* or *Replace everything*. Undo either way. A file-write failure changes nothing. | `lib/widgets/restore_preview.dart`, `NotesController.mergeAll` / `backupOverlap`, `settings_sheet.dart` `_applyBackup` |
| Merge semantics | Nothing here is overwritten. Boards with the same id share; notes with the same id are left as they are here; loading the same backup twice adds nothing. Threads are added where both ends exist. | `test/restore_test.dart` |
| Restore safety | Path traversal already blocked (only the last path segment is used); newer-version backups refused. Backups are JSON, not zip. | `ImageService.writeStored`, `BackupService.decode` |
| Honest lock | "Private board" → "Locked board" / "Bảng có khóa". The hint says it is a lock in the app, not encryption. Recents screen blank while a locked board is open (Android, from 1.4; not compiled yet). | ARB files, `MainActivity.kt` |
| Encryption at rest | **Not done.** It needs a Keystore/Keychain key, a policy for biometric change and key loss, and encrypted backups. Shipping it untested would risk locking people out of their notes. Labels are made truthful instead. | — |
| Privacy policy | Says Android backup and iCloud Backup may copy app data, locked boards included. | `PRIVACY.md` (EN + VI) |
| Pro / refund | From 1.4: Google Play "not owned" revokes the cache; offline keeps it. Unchanged here. | `ProController.checkOwnership` |
| Tap = editor | Kept (as decided). | — |
| Destructive actions | Drag-to-delete off by default; auto-clean off; Undo on delete, archive, shuffle, frames, theme. | — |

## 3. Visual work

| Target in the brief | Requested | Generated | Approved | Integrated (in app) |
|---|---|---|---|---|
| Stickers | 150–200 | see `STICKY_VISUAL_ASSET_MANIFEST.json` | all integrated were approved by eye on contact sheets | count in the manifest; every entry is listed in the picker |
| Washi tapes | 30–40 | as above | as above | as above |
| Photo frames | 20–30 | 7 styles drawn in code | 7 | 7 (3 free, 4 Pro) |
| Pins / clips / magnets | 15–20 | 0 new (6 code-drawn styles from 1.3) | — | 6 |
| Papers / textures | 20–30 | 0 new (6 rulings, 12 papers + mixer from 1.3) | — | — |

The final counts are in the QA matrix: `docs/release/STICKY_WALL_1_4_1_QA_MATRIX.md`.

## 4. UX changes

- **Templates with a Pro look**: without Pro, the board is made in the pack's free twin. The preview shows the twin and the sheet says so before *Use*. Nothing switches to cork behind the user's back.
- **All boards**: pinned boards first, then the most recently edited, with "edited today / yesterday / date".
- **Archive**: any note can be put away on an Archive board (kept, with Undo). A finished list says it is done.
- **Editor**: a switch between the handwriting and a readable face (Be Vietnam Pro), remembered.
- **Calm the wall**: a slider in Customize washes a light wall toward paper or deepens a dark one. It is carried into the export.
- **Memory wall**:
  - 7 frames and caption presets (numbers, today's date).
  - A hero-photo layout.
  - *Shuffle the photos*: seeded, so the same seed gives the same wall.
  - *One frame for every photo*.
  - Per-print frame and *Make it the hero*.
  - All of these have Undo and move only the prints.
- **Templates**: the emoji stand-ins became the free illustrated stickers, and 16 templates gained one sticker where there was room.

## 5. Deferred or dropped

- **Encryption at rest**: see §2.
- **iOS targets**: need macOS and Xcode.
- **Device builds and tests**: not run in this pass. The other agent holds the emulators, and the release build needs the keystore.
- **Template layout overhaul (Batch C)**:
  - Done: stickers added, validator kept.
  - Not done: the deeper rework of sample text and note sizes. A few three-column headings still wrap in Vietnamese at 0.72 scale.
- **Theme moodboards (Batch A) and store graphics (Batch D)**: not commissioned.
- **Sticker fallback on 1.1**: a 1.1 app cannot be changed; a sticker from a newer backup still shows as an empty note there.
