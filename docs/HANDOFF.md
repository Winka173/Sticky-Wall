# Sticky Wall: handoff

State on **7 Nov 2026**, at commit `5536b37` on `main`. Read this first, then
the documents it points to.

## 1. Where things stand

| | |
|---|---|
| App | Flutter sticky-notes app, Android first. Package `com.apps.winka.stickywall`; iOS bundle `com.winka.stickyWall`. Fully local, no backend. |
| Version in `pubspec.yaml` | `1.5.2+13` |
| Google Play | **1.5.2 (13)** rolled out on **closed testing** (`alpha`, group `testers-community@googlegroups.com`). Production has never been released; it is done by hand in Play Console. |
| Next release | versionCode **14** or higher (`python tool/play.py codes` prints the highest seen). |
| Checks | `flutter analyze` clean; full suite **376 tests passed** at `2b271aa`. Only docs have changed since. |
| Working tree | Clean. `.agents/` (the screenshot skill) is gitignored on purpose. |

## 2. Read these

| File | What it covers |
|---|---|
| `README.md` | Feature list, file-by-file architecture, iOS widget setup |
| `AGENTS.md` | Commit/push workflow, release rules |
| `docs/release/PLAY_CONSOLE_API_GUIDE.md` | **Everything about Google Play**: section 0 is the publish recipe, section 3 a fresh machine, section 5 store graphics, section 10 Drive sync on Android and iOS |
| `docs/sticky-final/SYNC_DESIGN_AND_LIMITATIONS.md` | How sync merges, what it never touches |
| `docs/sticky-final/IMPLEMENTATION_REPORT.md`, `RELEASE_MATRIX.md` | What was built and verified, and what is blocked |
| `docs/sticky-final/PRO_AND_PUBLISH_CHECKLIST.md` | Pro product and store checklist |
| `docs/design/*_HANDOFF.md` | Visual polish, How to use, themes: per-area notes |
| `PRIVACY.md` | Privacy policy (EN + VI); keep it true when features change |

## 3. Working rules (the owner's)

- **Language:** talk to the owner in Vietnamese. Code, comments, commits and
  docs are in English. Every user-visible string goes into both
  `lib/l10n/app_en.arb` and `app_vi.arb`, then `flutter gen-l10n`; the
  generated files are committed. The ARB files use CRLF line endings.
- **Autonomy:** improve what you find without asking, then report at the end.
  Commit each finished task and push to `main`.
- **Ask first** before anything outward-facing or destructive: anything
  written to Play other than a requested "publish" (listing text, graphics,
  products), uninstalling the app from a device (it wipes the notes), deleting
  data.
- **"publish"** from the owner means the whole recipe in section 0 of the
  Play guide: bump the version, write both changelogs, analyze and test,
  commit and push, then `cd android && fastlane android publish`.
- **Shared working tree:** another session may be editing the same checkout.
  `git add` only the exact files you changed; check
  `git diff --cached --stat` before committing; never commit untracked files
  you did not create. Never force-push.
- **No mentions of AI tools or assistants** anywhere in the source, comments or
  docs.
- **Secrets** stay outside the repo and are never printed or committed:
  `~/.secrets/play-publisher.json`, the upload keystore,
  `android/key.properties`.

## 4. Build, test and look at it

```sh
flutter pub get && flutter analyze
timeout 1500 flutter test --timeout 150s --dart-define=STICKY_SYNC=true
flutter build apk --release --obfuscate --split-debug-info=build/symbols-apk --dart-define=STICKY_SYNC=true
adb -s <device> install -r build/app/outputs/flutter-apk/app-release.apk
```

- Devices on this machine: BlueStacks at `127.0.0.1:5555` / `5575` (its adb port
  moves; read `status.adb_port` in `bluestacks.conf`). Always pass `-s`.
- In Git Bash, set `MSYS_NO_PATHCONV=1` before `adb` commands with `/sdcard/...`.
- **After any visible UI change** the manual's pictures must be regenerated, or
  `test/manual_assets_freshness_test.dart` fails:
  ```sh
  flutter test test/manual_assets_test.dart --dart-define=MANUAL_ASSETS=true --dart-define=STICKY_SYNC=true
  dart format lib/welcome/manual_image_ratios.dart
  ```
- Widget tests boot the real app: `SharedPreferences.setMockInitialValues({})`,
  `NoteStorage.create()`, seed with `storage.saveNotes`, pump `StickyWallApp`
  (see `_pumpApp` in `test/editor_test.dart`).
- Dragging a wall note in a test: `tester.startGesture`, then one `moveBy`
  past the slop (`tester.drag`'s first step is swallowed by the wall pan).
- Images in tests are decoded with `tester.runAsync` *before* the first pump;
  fixture photos are painted with `dart:ui`, there are no binary fixtures.
- Keyboard-inset bugs are reproduced with `tester.view.viewInsets` and
  `padding.bottom = 0` (`test/wall_stability_test.dart`).
- The wall's gesture recognizers need `gestureSettings` from `MediaQuery`.
  Tests don't exercise this, so gesture changes need a check on a device: a
  note drag starts after the 36 px pan slop, the grips after ~6 px.

## 5. Recent work (1.5.x)

- **1.5.0 (11)**: first store build with sync switched on (`STICKY_SYNC=true`);
  Settings page; How to use with a little animated phone per step; share
  button; arrows to off-screen notes.
- **1.5.1 (12)**: wall responsiveness, refreshed guide, Pro rainbow colour for
  threads.
- **1.5.2 (13)**:
  - Six new Free and Pro themes; paper flecks and stitched papers.
  - Note menu: *Zoom to note* and *Size and turn* removed (pinch and the
    grips do both).
  - **Stacks:** the notes underneath peek out in their own papers. The stack
    sheet has a take-out button per note (`NotesController.takeOutOfStack`)
    and *Unstack all*. Undo restores the pile (`_Placement` saves `stack`).
- **Release tooling** (`d813b94`): `fastlane android publish | preflight |
  images`, `tool/play.py codes | complete`, the full Play guide, and the
  `app-store-screenshots` skill pinned in `skills-lock.json`.
- **Sync docs** (`5536b37`): Play guide section 10.
- **Purchases**: Play guide section 11, how every app handles in-app
  purchases.

## 6. Open items

Owner only (accounts and hardware):

1. **Google Cloud for sync** (Play guide 10.1): Drive API, OAuth consent
   screen with `drive.appdata`, two Android OAuth clients (upload key SHA-1 is
   in the guide; the app-signing SHA-1 is in Play Console → App integrity).
   The repo cannot tell whether this is done. Until it is, turning sync on in
   the app fails with *Allow access again*.
2. **Production release** in Play Console when closed testing is done
   (if the developer account is personal, Google first wants 12 testers on
   closed testing for 14 days).
3. **Play Data safety** form: check it covers voice recordings (on device),
   purchases, and opt-in sync to the user's own Drive.
4. **License-tester purchase** of `sticky_wall_pro` on a real device.
5. **A Mac with Xcode** for anything on iOS.

Not done in code:

- **Sync has never run against real Google Drive.** Engine and service are
  covered by `test/sync_test.dart` with simulated devices. Once 10.1 is done,
  run the test list in Play guide 10.3 and record it in
  `SYNC_DESIGN_AND_LIMITATIONS.md`.
- **iOS sync is not built.** The plan is Google Drive on iOS too, so iPhone and
  Android share data (Play guide 10.2: iOS OAuth client in the same Cloud
  project, `GIDClientID` and URL scheme in `Info.plist`, open the gate in
  `lib/main.dart`, fix the `syncExplain` / `syncPrivacy` strings, privacy
  policy). It needs the iOS client ID and a Mac to test.
- **iOS in general** has never been built or run: widget extension, share
  extension, App Groups, StoreKit.
- **Store marketing screenshots** have not been made with the
  `app-store-screenshots` skill yet (Play guide section 5). The current Play
  images are the older ones. Uploading new ones (`fastlane android images`)
  replaces all of them, so it needs the owner's go-ahead.
- Purchases trust Google Play's answer, with no signature check and no
  server: the owner's decision for every app (Play guide section 11). A refund
  takes Pro away on the next start, once Play clearly says so.
- No encryption of locked boards; they are a UI lock, and the privacy policy
  says so.
- No background sync while the app is closed; no field-level merge (a whole
  note wins, the other is kept as a copy).

## 7. Things that cost time before

- Releases come back as `versionCode N is not above M` from preflight when
  the code was already uploaded, even to a discarded draft: bump and rebuild.
- `keytool -printcert -jarfile` prints nothing for the release APK (no v1
  signature); use `apksigner verify --print-certs`.
- Writing long scripts through a Bash heredoc breaks on quoting: write the
  script to a file first.
- In widget tests, a two-finger pinch on the wall does not move the camera; a
  one-finger pan on the `InteractiveViewer` does.
- After `_bringToFront`, a note's index in `boardNotes` changes: find notes by
  `guid` in tests.
- `flutter_native_splash:create` rewrites the Android theme files: restore the
  `NormalTheme` / `LaunchTheme` parents afterwards (see README / app lock
  notes).
