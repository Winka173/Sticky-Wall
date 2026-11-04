# Sticky Wall 1.4.1 — QA matrix

Version 1.4.1+8 on `main`.

Status words:

- **DONE**: in the code and covered by automated tests that pass.
- **VERIFIED ON DEVICE**: run on a phone. Nothing in this release is.
- **BLOCKED**: needs something this machine lacks.
- **DEFERRED**: decided not to do in this pass.

Automated checks on the final commit: `flutter analyze` reports no issues; `flutter test` gives 261 passed and 53 skipped (the skipped ones are screenshot generators).

## Builds and devices

| Target | Compiled | Emulator | Physical device | Note |
|---|---|---|---|---|
| Android release (.aab) | **BLOCKED** | — | — | Needs the upload keystore and `android/key.properties`. Gradle was not run because the machine is shared with another agent. The `MainActivity.kt` recents change has never been compiled. |
| Android debug | not run | not run | not run | Same reason |
| iOS | **BLOCKED** | — | — | Needs macOS and Xcode (widget target, share extension, App Groups, StoreKit) |
| Flutter test VM | yes | — | — | 261 tests |

## Requirements

| # | Requirement | Status | Evidence |
|---|---|---|---|
| P0-1 | Restore preview: version, date, size, counts, conflicts | DONE | `lib/widgets/restore_preview.dart`; `test/restore_test.dart` (counts shown, nothing changes before a choice) |
| P0-2 | Merge or Replace, with Undo | DONE | `NotesController.mergeAll`; `restore_test` (nothing overwritten; merging twice adds nothing) |
| P0-3 | No half-done state on failure | DONE | Files are written before any data changes; on failure the data is untouched |
| P0-4 | Path traversal, newer version, bad JSON | DONE (from 1.3) | `ImageService.writeStored` (only the last path segment); `BackupService.decode` |
| P0-5 | Zip bomb, oversized input | DEFERRED | Backups are JSON (no zip); there is no size cap and the file is read whole |
| P0-6 | Encryption at rest for private boards | DEFERRED | Labels made truthful instead: "Locked board / Bảng có khóa"; the hint says "not encryption" |
| P0-7 | Privacy policy matches system backup behaviour | DONE | `PRIVACY.md` EN + VI |
| P0-8 | Lock leaks: widget, search, trash, reminders, recents | DONE / recents not built | `pro_test` (widget, search, trash); `MainActivity.kt` (uncompiled) |
| P0-9 | Single tap opens the editor | DONE (kept) | `editor_test` |
| P0-10 | Drag-to-delete off, auto-clean off by default | DONE | `editor_test`, `note_storage` defaults |
| P0-11 | Archive done lists | DONE | `NotesController.archive`; `restore_test` |
| P0-12 | Template Pro look: free version shown before Use | DONE | `lookFor` + `TemplatePreview(look:)`; `template_library_test` (every Pro pack has a free twin) |
| P0-13 | Pro purchase, pending, refund, offline | DONE (from 1.4) in tests; not on device | `pro_test` (injected answers). A Play license-test run is needed. |
| P0-14 | Try-on never saves | DONE (from 1.3) | `pro_test` |
| P1-1 | Memory wall frames, 6 or more | DONE: 7 | `lib/widgets/photo_frames.dart`; `memory_wall_test` |
| P1-2 | Shuffle: seeded, undoable, keeps content | DONE | `rearrangePrints`; `memory_wall_test` (same seed gives the same wall; Undo restores) |
| P1-3 | Quick Style (one frame for all), per-print frame | DONE | `setFrames`; `memory_wall_test` |
| P1-4 | Caption presets | DONE: numbers, today's date | `memory_wall_test` |
| P1-5 | Hero image | DONE: hero layout and *Make it the hero* | `memory_wall_test` |
| P1-6 | Export matches the board | DONE: same renderer; *Calm the wall* carried | `board_poster.dart` |
| P1-7 | Board gallery: real thumbnails, last edited, pin | DONE | `board_picker.dart`; `gallery_test` |
| P1-8 | Readable editor face | DONE | `editor_test` |
| P1-9 | Wall dim / soften | DONE | `wall_background.dart`; Customize slider |
| P1-10 | Template layout polish | PARTLY | Illustrated stickers added (`docs/previews/templates_*.jpg`); deeper layout rework deferred |
| P1-11 | Asset catalog tabs (Stickers / Frames / Tapes / Pins / Papers) | PARTLY | Stickers and tapes are shelves in the sticker picker; frames have their own picker; pins and papers stay in Customize and the editor |
| P1-12 | Free has 20–30 original stickers | DONE: see counts | `template_library_test` (≥ 20) |

## Asset counts (from `docs/design/STICKY_VISUAL_ASSET_MANIFEST.json`)

"Generated" counts the cells Codex delivered. "Approved" counts what passed review on the contact sheets. "Integrated" counts the files bundled and listed in `sticker_assets.g.dart`. "In app" counts what the sticker picker shows (it lists every integrated entry).

| Type | Requested | Generated | Approved | Integrated | In app | Free |
|---|---|---|---|---|---|---|
| Illustrated stickers | 150–200 | 126 (batches 1–3) | 126 | 126 | 126 | 36 |
| Washi tapes | 30–40 | 24 | 24 | 24 | 24 | 0 |
| Photo frames | 20–30 | 7 (code) | 7 | 7 | 7 | 3 |
| Pins / clips / magnets | 15–20 | 0 new | — | 6 (from 1.3, code) | 6 | 1 |
| Papers / textures | 20–30 | 0 new | — | 12 colours + mixer, 6 rulings (from 1.3) | — | 6 colours, plain |

Batch 4 (36 stickers, 12 tapes) is in production; this table is updated when it lands.

## Performance (test VM, not a device)

From `test/perf_test.dart`:

| Notes on the board | Open | Search |
|---|---|---|
| 500 | about 1.3 s | about 0.3 s |

Not measured: device FPS, RAM and export time.

Sticker bundle: about 1.6 MB for 150 files. Pictures are decoded at 128–384 px.

## Manual smoke checklist (to run on a physical Android phone)

1. Onboarding:
   1. Pick a template.
   2. Clear the examples.
   3. Restart the app.
2. Add, move, rotate, connect and check notes; restart the app.
3. Share a link from Chrome and a photo from Photos.
4. Memory wall with 20 real photos:
   1. Try each frame.
   2. Shuffle, then Undo.
   3. Set a hero photo.
   4. Export PNG and PDF.
5. Backup and restore:
   1. Back up.
   2. Restore with Add, then Undo.
   3. Restore with Replace, then Undo.
6. App lock and a locked board:
   1. Check the recents thumbnail.
   2. Check the widget.
   3. Check a reminder text.
7. Purchases with a license tester: buy, slow card (pending), refund, then restart. Pro should go off; notes should keep their Pro look.
8. Sticker picker: scroll every shelf, add stickers and tapes, then delete them.
