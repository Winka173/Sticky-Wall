# Sync across devices: design and limitations

## Scope

- **Provider:** Google Drive's hidden app folder (`appDataFolder`), scope `drive.appdata` only. The app cannot see the user's other Drive files.
- **Platforms:** offered on **Android only**. Not offered on iOS. **Android ↔ iPhone does not sync.** The app says so, and points to backup files for moving between platforms.
- **Off by default:**
  - Never asked for at first run.
  - Never needed to open or edit notes.
  - No Sticky Wall account and no Sticky Wall server.
  - Not gated behind Pro.

## Data model

Every syncable thing is a record keyed by kind:

| Key | Record | Notes |
|---|---|---|
| `b:<id>` | Board | Includes `pos` for tab order. A board in the Trash keeps `deletedAt`. |
| `n:<guid>` | Note | Trashed notes too. |
| `l:<a>\|<b>` | Thread | Its ends are sorted. |
| `m:<kind>:<name>` | Media file | `kind` is photo, wall or audio. Holds the file's SHA-256. |

- **Not synced:**
  - App-lock state, permissions, purchases and Pro state.
  - Settings, and device file paths.
  - Locked boards, unless *Include locked boards* is switched on.
- Each record carries a **Lamport revision** and the **device id** that wrote it. Wall-clock time never decides who wins.

## Storage

- **Device files:** each device writes only `sw-dev-<deviceId>.json`, which holds its full merged view. No device overwrites another's file, so simultaneous syncs cannot lose each other's work.
- **Media:** files are immutable blobs named `sw-blob-<sha256>`.

## Merge (`SyncEngine.merge`)

1. **Local changes.** Anything whose data hash changed since the last sync gets a new revision. A missing record becomes a tombstone.
2. **Remote.** Take the best version of each record across every device file.
3. **Deciding the winner per record:**
   - **Higher revision wins.** Ties go to the larger device id, which is deterministic on every device.
   - **Both sides changed a note:** the winner stays, and the loser is kept as a **copy beside it**.
   - **Edit against delete:** the **edit is kept**, as a new revision.
   - **Stale, unchanged copies:** they keep their old revision and lose to a tombstone, so a deleted board or note never comes back from an old copy.
4. **Tombstones** are kept for 120 days (longer than the 30-day Trash), then forgotten.

## Media transfer

- **Upload before referencing.** Blobs are uploaded before the device file is written. A record whose blob isn't uploaded is left out of the file.
- **Download is checked.** A download is checked against its SHA-256; a mismatch is refused.
- **Local files are never overwritten or deleted by sync.**
- **Missing media** is counted and shown ("N photos or recordings haven't arrived yet").

## Applying merged data (`NotesController.applySync`)

- Files are never deleted.
- The open board stays open.
- Orphan notes land on the first board.
- Threads whose ends are missing are dropped.
- Reminders are re-scheduled.
- Locked boards that were left out are kept exactly as they are.

## Triggers

- 30 s after the last edit.
- When the app resumes.
- When the app goes to the background with a sync pending.
- From *Sync now* in Customize.

## Status shown

| State | Shown |
|---|---|
| Off | Off |
| Idle | Synced *time* |
| Working | Syncing… |
| Offline | Will sync when back online |
| Sign-in needed | Allow access again |
| Drive full | Drive full |
| Failed | Couldn't sync; notes unchanged |

Conflict copies and missing media are shown alongside.

## Privacy

- Data goes only to the user's own Google Drive.
- It is stored as ordinary Drive data, **not end-to-end encrypted**. The app says this for locked boards.
- `PRIVACY.md` has a new section, EN and VI.
- **Play Data safety:** review whether "data stored in the user's own Google Drive at their request" needs declaring. Google's guidance treats user-directed transfers to the user's own account differently from collection by the developer; confirm in Play Console before publishing.

## Verification

| Level | Status |
|---|---|
| Engine and service, 2–3 simulated devices (`test/sync_test.dart`, 12 cases) | **Passed** |
| Release APK builds with `google_sign_in` 7.2 and `http` | **Passed** |
| Launches on BlueStacks (Android 11) without errors | **Passed** |
| Real Google Drive, two physical devices | **BLOCKED**: never run |

The real Google Drive run needs the setup below, done once, by the account owner.

1. **Google Cloud console**, project `play-publisher-513712` or a new one:
   1. Enable the **Google Drive API**.
   2. Set up the **OAuth consent screen**: External, with app name, support email and privacy URL. Add the scope `.../auth/drive.appdata`. Add test users while it is in testing.
   3. **Credentials → Create OAuth client → Android:**
      - package `com.apps.winka.stickywall`
      - SHA-1 of the **upload key**: `keytool -list -v -keystore C:\Users\Winka\sticky-wall-upload.jks`
      - Create a **second** Android client with the SHA-1 of the **Play app-signing key** (Play Console → App integrity).
2. **Test:**
   1. Install from the closed-testing track on two Android phones signed in to the same Google account.
   2. Customize → Sync across devices → turn on → allow.
   3. Run these cases:
      - edits on each phone
      - one phone offline while the other edits
      - delete, then restore a board
      - photos and voice notes
      - turning sync off
      - revoking access in Google account settings

## Not done

- iCloud for iOS.
- Cross-platform sync.
- A "delete the Drive copy" button: the user does this from Drive settings.
- Background sync while the app is closed. Sync runs only while the app is open; this is stated honestly in the docs, not promised in the UI.
- Field-level merge: whole notes win or are copied.
