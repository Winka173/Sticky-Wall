# Data migrations and backup

## Board Trash

### Storage

- Deleted boards move from the `boards` list to a new `deletedBoards` key in `shared_preferences`. They keep two extra fields:
  - `deletedAt`
  - `deletedIndex`, the tab position they had
- Their notes stay in `notes`, still pointing at the board. Nothing is copied or purged.

### Where boards in the Trash are hidden

Through `_shut(boardId)`, they are hidden from:

- search across boards
- the note Trash list
- reminders, which are cancelled on delete and re-scheduled on restore
- the widget, which only lists boards in use

### Restoring

- The board goes back to its old tab position, with its notes, threads, drawing, theme and wall photo.
- **Same id in use:** an import that brings a board with the same id first gives the board in the Trash a fresh id, so its notes move with it and are never taken over.

### Expiry

- A board in the Trash is purged on launch once `now − deletedAt > 30 days`.
- If the phone's clock is set back, the board simply waits longer.

### Purging and files

- **Purge:** each note on the board is purged the normal way. The wall photo goes only if no board, in use or in the Trash, still uses it.
- **When a file is deleted:** a photo or recording file is deleted only when no note anywhere (live, in the note Trash, or on a board in the Trash) refers to it.

## Retired settings

- `autoTrashDone` and `dragToDelete` are removed from preferences in `NoteStorage.create()` and never read again.
- No code path trashes finished checklists any more.

## Backup format

The format stays **version 2**.

### Additions

- Optional `deletedBoards` (boards in the Trash). Their notes are already in `notes`, and their wall photos are in `wallPhotos`.
- Older apps ignore `deletedBoards`. Those notes then show on no board; nothing is lost on the newer app.

### Limits when reading

| What | Limit |
|---|---|
| Whole document | 300 MB, checked before the file is read |
| Notes | 100,000 |
| Boards | 5,000 |
| Files | 20,000 |
| One photo or recording | 64 MB |

- A damaged base64 entry, or one over the cap, is **left out and counted**. The restore preview shows "Files that can't be read (left out)".
- Malformed or over-nested JSON is reported as "not JSON". Before, it could crash.

### Restoring

- **Replace** replaces boards in the Trash too.
- **Merge** adds the backup's boards in the Trash unless that id is already here.
- Undo after a restore puts back the previous Trash as well.

### Weekly auto-backup

- Unchanged: it runs on app open at most weekly and keeps 4.
- It now includes boards in the Trash.
