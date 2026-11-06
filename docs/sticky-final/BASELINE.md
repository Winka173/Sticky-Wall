# Baseline (before this pass)

The source is 1.4.2+10, commit `f8490aa`. It was read from the source, not from the overview HTML.

## Already present

| Feature | Where | Tests |
|---|---|---|
| Note Trash, 30 days | `NotesController.delete` / `restore` / `purge` | `logic_test` |
| Undo | Wall undo, plus a snackbar undo for deletes | `logic_test`, `editor_test` |
| JSON backup v2 | Photos and recordings as base64; weekly auto-backup that keeps 4; restore preview with merge or replace | `restore_test` |
| Locked boards | `isPrivate`, shut per session; hidden in search, widget, trash and reminders | `pro_test` |
| Share sheet | Text, a link, or **the first image only** | `gallery_test` |
| Memory Wall | ≤ 20 photos, 5 layouts, 7 frames, shuffle, hero, captions | `memory_wall_test` |

## Risks found

| Risk | Where |
|---|---|
| Deleting a board **purged** its notes and files at once, skipping the Trash | `deleteBoard` |
| Optional drag-to-delete tray | Off by default |
| Optional auto-trash of finished checklists after one day | Off by default |
| No size limit when reading a backup | Base64 failure threw: a whole backup was refused for one bad file |
| Back and tap-outside in the editor saved without asking | Editor |
| No multi-device sync | — |

The uncommitted files at the start of this pass (`docs/review/`, `output/`, `tool/build_review_overview.py`) were left untouched.
