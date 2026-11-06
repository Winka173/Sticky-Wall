# Sticky Wall — final implementation report

Baseline: 1.4.2+10 at `f8490aa`. Work: `8618d87` … `HEAD` on `main`.
Evidence: `EVIDENCE/flutter_test_summary.txt`. On the final commit, `flutter test` gives 291 passed and 53 skipped (screenshot generators), and `flutter analyze` reports no issues.

Status words used throughout:

- **DONE & VERIFIED**: code plus automated tests, and run where stated.
- **DONE, NOT NATIVE-VERIFIED**: code and tests, but not exercised on a device or a store.
- **PARTIAL**: some of the requirement is built.
- **BLOCKED**: needs something this machine or account lacks.
- **NOT IMPLEMENTED**: not started.

## Summary by workstream

| Workstream | Status | What exists |
|---|---|---|
| Board Trash (30 days) | DONE & VERIFIED (tests) | Restore brings the board back whole, at its old tab. Files are protected while anything references them. A clock set back never shortens the wait. Backups carry the Trash. Import id collisions are handled. |
| Remove the drag-to-delete tray | DONE & VERIFIED (tests, BlueStacks build) | UI, gesture, setting, strings and tip removed. The old preference is deleted on launch. |
| Remove auto-trash of finished checklists | DONE & VERIFIED (tests) | The sweep code, setting and strings are gone. A regression test with the old switch left on shows nothing is trashed, across two launches. |
| Backup hardening | DONE & VERIFIED (tests) | 300 MB document cap, checked before reading. Record caps: 100k notes, 5k boards, 20k files. Each file is capped at 64 MB. Damaged or oversized files are counted in the preview, not hidden. Deep-nesting and bad-JSON crashes are caught. Old JSON format v2 is unchanged. |
| Editor Save / Discard | DONE & VERIFIED (tests) | Back, tap-outside and ✕ all ask Save / Discard / Keep editing. ✓ saves. An invalid Save keeps the editor open with the reason. A second Back answers "keep editing". |
| Android multi-photo share | DONE, NOT NATIVE-VERIFIED | Every image is kept: in order, de-duplicated, up to 20, 40 MB each and 300 MB in total. The rest are counted aloud. The user chooses to pin them as prints or make a memory wall. A repeated delivery is ignored. The unit tests pass. A share from a real gallery app has not been run (see the release matrix). |
| Interactive first-run guide | DONE & VERIFIED (widget tests) | Three gestures on the real wall: tap, drag, thread. Each advances when done or with Next. Skip ends it. Replay is under More → Interactive guide. It starts from "Explore the sample wall". It never creates, changes or deletes anything. |
| Multi-device sync (Android, Google Drive app folder) | DONE, NOT NATIVE-VERIFIED / provider BLOCKED | The engine and service are tested with 2–3 simulated devices: distinct edits, concurrent edits with conflict copies, delete vs stale copy, edit vs delete, board Trash, threads, media hash checks, locked-board exclusion, offline, newer schema. The Drive adapter compiles into the release APK. It has **never run against Google Drive**: an OAuth client is needed (see `SYNC_DESIGN_AND_LIMITATIONS.md`). |
| iOS sync (iCloud) | NOT IMPLEMENTED / BLOCKED | Needs macOS, Xcode and an iCloud entitlement. Sync is not offered on iOS. |
| Templates / themes / Memory Wall polish | PARTIAL | Earlier in this pass: copy, alignment and first-run layout. The Memory Wall step order is unchanged. No full audit of the 45 templates and 37 themes was done in this run. |
| Toolbar simplification (Arrange merge, Add picker) | NOT IMPLEMENTED in this run | The existing Add: a yellow paper button plus an "Other kinds" picker. |
| iOS / widget / IAP / TalkBack device QA | BLOCKED | No Mac. No store purchase run. No screen-reader session. |

## Files

New:

- `lib/services/sync/sync_engine.dart`, `sync_backend.dart`, `sync_service.dart`, `drive_backend.dart`
- `lib/widgets/sync_sheet.dart`, `lib/widgets/guided_tour.dart`
- Tests: `test/board_trash_test.dart`, `test/share_photos_test.dart`, `test/guided_tour_test.dart`, `test/sync_test.dart`

Changed:

- Models and services: `models/board.dart`, `services/notes_controller.dart`, `note_storage.dart`, `settings_controller.dart`, `backup_service.dart`, `auto_backup.dart`, `image_service.dart`, `share_service.dart`
- Screens: `screens/home_screen.dart`, `home_screen_chrome.dart`, `trash_screen.dart`
- Widgets: `widgets/wall_view.dart`, `wall_view_parts.dart`, `note_dialog.dart`, `board_bar.dart`, `board_picker.dart`, `restore_preview.dart`, `settings_sheet.dart`
- App, docs, dependencies: `main.dart`, ARB files and generated l10n, `PRIVACY.md`, `pubspec.yaml` (adds crypto, http, google_sign_in)

## Removed

- **Drag-to-delete:** `_DropTray`, the `WallView.onTrash` / `trashLabel` parameters, and the `dragToDelete` setting and strings.
- **Finished-checklist sweep:** `sweepCompleted` / `_sweepCompleted`, the `autoTrashDone` setting and its strings.
- **Strings no longer used:** `dropToDelete`, `autoTrashDone*`, `dragToDelete*`.
