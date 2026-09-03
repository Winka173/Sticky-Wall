# Sticky Wall

A Flutter sticky-notes app that behaves like a real pin-board: pastel paper
notes on a textured wall, written in a handwriting font, that you can drag,
pin, color, and organize across multiple boards. Bilingual (English / Tiếng
Việt). Modeled after the original "Mia Note" Angular + Electron desktop app,
then taken well beyond it.

| Wall (drag, resize, rotate, zoom, threads) | Grid | List | Paper editor |
|---|---|---|---|
| ![Wall](screenshots/mode_wall.png) | ![Grid](screenshots/mode_grid.png) | ![List](screenshots/mode_list.png) | ![Editor](screenshots/editor.png) |

| Lights off (night mode) | Trash (30-day retention) | Photo note | Drawing note |
|---|---|---|---|
| ![Night](screenshots/night.png) | ![Trash](screenshots/trash.png) | ![Photo editor](screenshots/photo_editor.png) | ![Drawing](screenshots/drawing.png) |

| Board export (share / save) | Customize sheet |
|---|---|
| ![Export](screenshots/export.png) | ![Settings](screenshots/settings.png) |

| Green chalkboard | Black chalkboard | Painted wall | Brick |
|---|---|---|---|
| ![Green](screenshots/preview_chalk_green.png) | ![Black](screenshots/preview_chalk_black.png) | ![Plaster](screenshots/preview_plaster.png) | ![Brick](screenshots/preview_brick.png) |

| Cardboard | Cement | Dark planks | Checker tiles |
|---|---|---|---|
| ![Cardboard](screenshots/preview_cardboard.png) | ![Cement](screenshots/preview_cement.png) | ![Dark planks](screenshots/preview_dark_wood.png) | ![Tiles](screenshots/preview_tiles.png) |

| Wood | Kraft paper | Marble | Terrazzo |
|---|---|---|---|
| ![Wood](screenshots/preview_wood.png) | ![Kraft](screenshots/preview_kraft.png) | ![Marble](screenshots/preview_marble.png) | ![Terrazzo](screenshots/preview_terrazzo.png) |

| Denim | Felt | Linen | Customize sheet |
|---|---|---|---|
| ![Denim](screenshots/preview_denim.png) | ![Felt](screenshots/preview_felt.png) | ![Linen](screenshots/preview_linen.png) | ![Settings](screenshots/settings.png) |

## Features

**Notes**
- Six types: **Normal** (multi-line text), **Link** (label + URL),
  **Checklist** (tickable items with done-count), **Drawing** (freehand
  sketch with a color/size pen and eraser, on a canvas whose **paper tone**
  and **guide pattern** — plain, ruled, grid, dots — you pick), **Photo**
  (a print pinned straight on the wall, see below) and **Label** (a strip
  of tape with a word or two on it — the heading of a column or corner of a
  planning board; no pin, no body)
- **Lock in place** (long-press → Lock) holds a note where it is: it cannot
  be dragged, turned or resized, a tidy-up flows the other notes beneath
  it, and a small padlock marks it on the card
- A sketch *is* its card: the canvas runs edge to edge with no margin or
  adhesive strip, and a title / emote / reminder — if any — sits on a small
  label strip beneath it in the note's paper color
- Attach **a photo** (gallery or camera) to any note: it sits above the
  text on the card and full width in the editor, where a corner button
  removes it and the camera button swaps it for another; tap it to open the
  **viewer** (pinch or double-tap to zoom). Add an **emote** sticker, pick a
  **paper color** (or auto-from-id), **pin to top**, and set a **reminder**
  (date + time, optionally **repeating daily / weekly / monthly**) that fires
  a local notification
- **Photo prints** — a photo pinned straight on the wall: a white border,
  the picture at its real aspect ratio, an optional caption written on the
  border. Pick several photos at once (⋮ → *Pin photos on the wall*, or
  long-press empty wall → *Photos here*) and each lands as its own print;
  drag, resize, turn, tie threads and move it between boards like any note
- The editor *is* the note: same handwriting, same paper color, faint ruled
  lines under each baseline, Save/Cancel on the adhesive strip so they are
  never hidden by the keyboard; validation is inline (the paper shakes).
  Under a text note's field, **bold / italic / bullet** buttons put light
  markup into the text (`**bold**`, `*italic*`, `- item`) and the card
  renders it; search, the trash and the widget read the words without the
  markers
- **Long-press** a note for Edit / Pin / Lock / **View photo** /
  **Duplicate** / **Move** or **Copy to another board** / Share / Save /
  Select / Delete. **Share** renders the note as an
  image; **Save** puts it in the photo gallery
- Delete **peels the note off the wall** and drops it in the **Trash**, with
  an Undo snackbar; in list mode, swipe a row to delete. A link already on
  the wall (ignoring `https://`, `www.` and a trailing slash) is rejected
- A fully ticked checklist fades and shows a big tick; optionally it is
  swept into the trash automatically after a day
- Notes are paper cards with a push-pin, drop shadow and a slight hand-stuck
  tilt; pinned notes straighten and get a gold pin (tap the pin to toggle).
  On the wall you can also **turn** a note by hand (see below); grid and
  list keep every card upright

**Layouts**
- **Wall** — drag notes anywhere; the note last touched shows two grips:
  **resize** with the bottom-right one, **rotate** with the bottom-left one
  — the card turns about its centre under your finger, clicks into place
  (with a tick of haptics) when it comes within a few degrees of upright or
  a quarter turn, and a tap on that grip squares it up again. Grips react
  after a few pixels, not the usual pan slop, so they never feel stuck. Or
  put **two fingers on a note**: twist to turn it, pinch to resize it about
  its centre (each with a small dead band so one does not bleed into the
  other) — two fingers on one card always act on the card, never on the
  wall. The wall runs **1000 px past every edge of the screen** — over two
  screens each way — and the camera can pan exactly that far, so a note can
  be parked anywhere you can look; a dragged card stops at the wall's outer
  edge and comes straight back with the finger. The wall also runs under
  the title and tool rows and the system bar, so a note panned up or down
  stays in view there instead of vanishing at an edge. Drag a note onto the
  **tray** that slides up from the bottom to delete it, or up onto a **board
  tab** to move it to that board (the tab lights up). One camera button sits top right of the
  wall and only when useful: **show everything** (also in ⋮) glides the
  camera out until every note is in view when some are out of frame, and it
  turns into **reset** once the wall is panned or zoomed with everything
  visible.
  **Double-tap** a note to glide the camera
  in on it, and again to glide back out. **Pinch to zoom / pan** the whole
  board — the wall texture and its stains
  travel with the notes, only the lighting stays put (double-tap or the
  reset button snaps back); **long-press** empty space (the empty-wall tip
  included) to stick a note or a batch of photo prints there
- **Threads** — drag from one note's pin to another to tie a yarn thread
  between them — photo prints included; the thread stays tied to the pin
  however the note is turned. **Tap a thread** for its sheet: pick the
  **yarn colour** (seven, classic red first), **write on it** (a paper tag
  hangs from the middle), give it an **arrowhead** for a dependency or a
  flow, or **cut** it (Undo re-ties it exactly as it was)
- **Draw on the wall** (the pen in the toolbar on the wall, or ⋮ → *Draw on
  the wall* from any view) — marker mode: a finger
  draws straight on the wall, behind the notes, in five colours and three
  widths, with an eraser, undo and clear; two fingers still zoom. Strokes
  are stored with the board (as fractions of the wall, like the notes) and
  come along in the export
- **Undo on the wall** — every move, turn, resize, tidy and drag to another
  board is remembered (40 steps); an *Undo* pill appears for a few seconds
  after each change. Nudges of one note in quick succession fold into one
  step, and a dragged selection moves — and undoes — as a whole
- **Export the board** (⋮ → *Export board as image*) — a full-screen
  preview of the wall with its notes, threads and marker strokes and
  nothing else: no header, toolbar, grips or button. **Share** it, **save**
  it to the gallery, or **share it as a PDF** (one page the size of the
  picture); choose the **whole wall or just the part in view** (when
  zoomed), **all notes or only the selected ones**, and **2× / 3× / 4×**
  resolution; **trim** the picture by dragging the corners or edges of a
  crop frame over the preview. Laid out exactly as on screen, with a margin
  so a turned card at the edge is not cut off — the board as a plan you can
  send around
- **Home-screen widget** (Android, and iOS with the extension below): *Show
  on the home-screen widget* in the export puts that picture of the board on
  the widget; until then it lists the current board's pinned notes
- **Gesture tips** (⋮ → *Gesture tips*): a short tour of what fingers can do
  on the wall, offered once on a fresh install
- **Tidy up** (⋮ menu) flies every note into a neat grid (squaring up any
  you had turned), or groups them **by color**. Rows are packed from the cards' real rendered heights (an
  offstage measuring pass), so short and long notes sit a pin's length apart
  instead of a card's; when full-size cards will not fit, they shrink to
  three columns
- The **add-note button** is a little sticky note with a pencil, at home on
  any wall; in grid / list and on an empty wall it grows a "New note" label.
  **Long-press** it to pick the note type (text, link, to-do, drawing,
  photo) straight away
- **Grid** — masonry layout; the column count follows the screen width
  (2 on phones, up to 6 on tablets / desktop)
- **List** — compact rows, swipe-to-delete
- Live, diacritic-insensitive search ("tuoi" finds "Tưới") with a result
  count, and a type filter; on the wall, notes that don't match are dimmed in
  place rather than removed. Grid/list add a sort menu (newest, oldest, A–Z,
  Z–A)
- **Multi-select** (⋮ → Select, or long-press → Select): on the wall, draw a
  **lasso** round notes with a finger to add them, and drag any selected
  note to move the whole selection; with a bottom action
  bar: pin / unpin, recolor, move to another board, delete — all at once

**Trash**
- Deleted notes wait in the Trash for **30 days** (the remaining days are
  shown on each; the last 3 turn red), then are purged along with any photo
  no other note uses. Restore, delete forever, or empty the whole trash

**Share to Sticky Wall**
- Share text, a link or a photo from any other app; the note editor opens
  pre-filled (link notes for URLs, photo notes for images). Android is wired
  up (`SEND` / `SEND_MULTIPLE` intent filters, `launchMode="singleTask"`).
- iOS: the Dart side is ready; add a **Share Extension** target in Xcode
  following the `receive_sharing_intent` README (app group + `NSExtension`
  plist entries) to enable it on iOS.

**Home-screen widget** (Android)
- A widget showing the current board's pinned notes; tap to open the app.
  Data is pushed via `home_widget`; the native provider lives in
  `android/app/src/main/kotlin/.../StickyWidgetProvider.kt`.
- iOS: the Dart side already pushes data; add a WidgetKit extension target in
  Xcode (named `StickyWidget`) reading the shared `home_widget` data to enable
  it on iOS.

**Boards**
- Multiple named boards ("My Wall", "Work", …); each remembers its own wall
  texture or **custom wall photo**
- One dialog creates or edits a board: name, an optional **emoji icon**, and
  **bold / italic / underline** for the name, previewed live in the field and
  drawn that way on the tab, in the manage sheet and in "Move to board"
- Switch by tapping a board tab or swiping horizontally in grid/list; the
  content slides in the direction you moved. Tap the selected tab to edit or
  delete it; **long-press and drag** a tab to reorder boards. The "+" that
  adds a board sits after the last tab and stays put once the tabs scroll;
  the active tab is scrolled into view whenever you switch boards or the
  strip changes width (grid / list add a sort button beside it)

**The wall**
- Twenty-one switchable textures: cork, green/black chalkboard, painted
  plaster, brick, wood, kraft paper, marble, terrazzo, denim, felt, linen,
  cardboard, cement, white cotton, white paper, moss, red leather, dark
  marble, dark planks, checker tiles — each under a tuned scrim so writing
  keeps contrast
- Or pick **your own photo** as the wall; its brightness is sampled to choose
  a scrim so the writing on it stays legible
- Procedural **stains** layer (water rings, drips, paint splatters, smudges,
  scuffs) drawn per wall; toggleable
- **Lights off**: a night mode that dims the wall, papers, sketches and
  photos to a warm, lamp-lit look (never a grey dark theme) — off / on /
  follow system / on a schedule (e.g. 21:00 → 06:00); quick toggle in the ⋮
  menu
- Subtle vignette for depth

**Fonts & language**
- Eleven note fonts — Patrick Hand, Itim, Dancing Script, Be Vietnam Pro,
  Mali, Sriracha, Mynerve, Fuzzy Bubbles, Amatic SC, Charm and IBM Plex Mono
  — all with full Vietnamese diacritics; Pacifico for the title. Each is
  size-balanced so switching fonts does not reflow the cards, and the font
  picker previews each as a real sample sticky note
- Full English / Tiếng Việt UI, following the system locale or set manually

**First launch**
- A fresh install seeds five sample notes (with one thread tied between two
  of them) that teach the gestures: drag, long-press, tick a checklist, pull
  a thread, plus a doodle so the drawing type is discovered. Delete them like
  any other note

**Data**
- Everything persists locally (no backend). A single corrupt record is
  skipped on load instead of taking every note with it
- Photos are copied into the app's documents folder and referenced by file
  name, so they survive iOS container moves; a file is removed only once no
  note — live or in the trash — refers to it
- **Export** the whole wall to a JSON file (share sheet) and **import** it back

## Getting started

```sh
flutter pub get
flutter emulators                  # list Android emulators (AVDs)
flutter emulators --launch <id>    # boot one, or plug in a phone with USB debugging
flutter run                        # picks the running device; -d <id> to choose
```

Android is the primary target (share intents, home-screen widget,
notifications are all wired up there). The Gradle config pins every plugin to
the app's `compileSdk` and enables core-library desugaring for
`flutter_local_notifications`, so a stock Android SDK 36 install builds it.
Chrome / Edge also run the app for a quick look at the UI, but the native
plugins (notifications, share, widget, gallery) are no-ops there.

Localizations are generated from `lib/l10n/*.arb` on `flutter pub get`
(see `l10n.yaml`). App icon and splash are generated art — a sticky note on
cork drawn by `test/icon_gen_test.dart`, with the safe-zone margins Play and
the App Store mask:

```sh
flutter test --update-goldens test/icon_gen_test.dart   # regenerate art
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

### Release builds

Release builds are minified and shrunk (`proguard-rules.pro` keeps the
notification plugin's Gson serialisation and the home-widget provider). Signing stays out
of the repo: create `android/key.properties` (gitignored) with

```properties
storeFile=/absolute/path/to/upload-keystore.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

and `flutter build appbundle` signs with it. Without the file, release builds
fall back to the debug key so they still install for a smoke test.

## Architecture

State lives in two `ChangeNotifier`s the widgets listen to:

| Path | Purpose |
|---|---|
| `lib/models/` | `Note` (+ `NoteType`, `ReminderRepeat`, `NoteLink` with yarn colour / label / arrow), `ChecklistItem`, `Board` (name, icon, formatting, marker strokes), `DrawStroke` / `DrawCanvas`, `ViewMode` |
| `lib/services/note_storage.dart` | JSON persistence via `shared_preferences` (notes, boards, threads, settings) |
| `lib/services/notes_controller.dart` | Boards + notes + CRUD, trash & retention, bulk actions, threads, tidy |
| `lib/services/settings_controller.dart` | Font / language / stains / night mode & schedule |
| `lib/services/reminder_service.dart` | Local notifications, incl. repeating reminders |
| `lib/services/share_service.dart` | Receives shares from other apps (`receive_sharing_intent`) |
| `lib/services/sample_notes.dart` | First-launch sample notes |
| `lib/services/backup_service.dart` | Export / import JSON |
| `lib/services/image_service.dart` | Pick a photo (or several, for prints) / wall photo, capture note→PNG, share, save to gallery |
| `lib/services/widget_service.dart` | Push pinned notes to the home-screen widget |
| `lib/screens/home_screen.dart` | Header, board bar, toolbar, the three views, multi-select |
| `lib/screens/trash_screen.dart` | Trash: restore / delete forever / empty |
| `lib/widgets/wall_view.dart` | Free drag-and-drop canvas, resize / rotate grips, two-finger twist / pinch, lasso, drop tray, marker mode, threads, measured tidy animation |
| `lib/widgets/wall_background.dart` | Wall texture or custom photo + scrim, stains, vignette |
| `lib/widgets/board_poster.dart` | Board export: full-screen preview of wall + notes + threads, share / save as PNG |
| `lib/widgets/peel_away.dart` | "Peel off the wall" delete animation |
| `lib/widgets/drawing_canvas.dart` | Freehand drawing editor (pen, eraser, paper tone + guide pattern) and the painters that draw a sketch anywhere |
| `lib/widgets/note_dialog.dart` | Create/Edit dialog (type, color, pin, reminder + repeat, emote, photo tile) |
| `lib/widgets/note_views.dart` | Sticky card (paper sheet, edge-to-edge sketch, framed photo print, tape label), the animated card turn, list tile, night shade |
| `lib/widgets/photo_viewer.dart` | Full-screen photo (pinch / double-tap to zoom) |
| `lib/widgets/action_sheet.dart` | Bottom action sheet that sizes to its content (long-press menus) |
| `lib/widgets/add_note_button.dart` | The sticky-note-with-a-pencil FAB |
| `lib/widgets/wall_decor.dart` | Procedural stains (CustomPainter) |
| `lib/widgets/board_bar.dart` · `board_dialog.dart` | Reorderable board tabs with a fixed "+" that keep the active tab in view, and the create / edit board dialog (name, icon, bold / italic / underline) |
| `lib/widgets/settings_sheet.dart` | Customize sheet (wall, photo, night, font, trash) |
| `lib/theme.dart` | Walls, fonts, palette (`AppColors`), radii, light + night themes — every control reads its look from here |
| `lib/util/` | `foldText` (diacritic folding), `stableHash` (deterministic ids/seeds), `angles` (normalising a turn, quarter-turn snapping) |
| `test/*_test.dart` | Widget/unit tests (logic, editor, wall grips, tidy packing, wall stability under the keyboard, board dialog, camera) + skipped golden generators for screenshots & icon |

Screenshots are produced by the golden generators: remove `skip: true` in
`test/preview_test.dart` / `test/modes_preview_test.dart`, run
`flutter test --update-goldens` on them, and move the PNGs from `test/` to
`screenshots/`. `test/preview_fonts.dart` loads the real typefaces and the
Material icon font into the test binding, so the screenshots show actual
handwriting and icons rather than the test framework's block glyphs. The
photos in the fixtures are three small scenes (sunset, dusk, meadow) painted
with `dart:ui` into temp PNGs at test time (no binary fixtures in the repo);
they are decoded via `runAsync` *before* the first pump, because an image
that starts loading inside the fake-async zone never finishes.

## iOS widget

The widget's code is in `ios/StickyWidget/` (SwiftUI + WidgetKit, reading the
`group.com.winka.stickyWall` app group the app writes to through
`home_widget`). Xcode has to own the target, so once per checkout:

1. Open `ios/Runner.xcworkspace`; File → New → Target → *Widget Extension*,
   product name `StickyWidget`, no configuration intent, **uncheck** "Include
   Live Activity". Delete the generated Swift files and add the three files
   from `ios/StickyWidget/` to the target instead.
2. Signing & Capabilities: add the **App Groups** capability to both
   `Runner` and `StickyWidget` with `group.com.winka.stickyWall`
   (`Runner/Runner.entitlements` and `StickyWidget/StickyWidget.entitlements`
   already declare it — point each target's *Code Signing Entitlements* build
   setting at its file).
3. Set the extension's deployment target to iOS 16 or later and build.

The Dart side needs nothing more: `WidgetService.init()` sets the app group
at start-up, and the picture is saved into the group container.

## Releasing to Google Play

What the repo already has: a release build type that minifies and shrinks
(`android/app/build.gradle.kts`, rules in `proguard-rules.pro`), version
name and code taken from `pubspec.yaml`'s `version:`, the store icon and
feature graphic in `store/`, phone screenshots in `screenshots/`, and the
privacy policy in [PRIVACY.md](PRIVACY.md).

What only you can do, once:

1. **Upload key.** Create it and keep it out of the repo (`android/.gitignore`
   already ignores it):

   ```powershell
   keytool -genkey -v -keystore $env:USERPROFILE\sticky-wall-upload.jks `
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

   Then write `android/key.properties`:

   ```properties
   storeFile=C:/Users/<you>/sticky-wall-upload.jks
   storePassword=...
   keyAlias=upload
   keyPassword=...
   ```

   Without this file release builds are signed with the debug key, which
   Play rejects.

2. **Build the bundle** (bump `version:` in `pubspec.yaml` first — Play needs
   a higher build number every upload):

   ```powershell
   flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
   ```

   The bundle lands in `build/app/outputs/bundle/release/app-release.aab`.
   If the build ends with "failed to strip debug symbols", `flutter doctor`
   is missing the Android cmdline-tools or licences; fix that and rebuild, or
   the bundle ships larger than it needs to.

3. **Play Console.** Create the app, upload the bundle to a testing track,
   then fill in *App content*: privacy policy URL (publish PRIVACY.md — the
   raw GitHub URL or GitHub Pages both work), Data safety (no data collected
   or shared; everything stays on the device), content rating questionnaire,
   target audience (not designed for children), ads (none), app access (no
   login). The listing needs `store/icon_512.png`, `store/feature_graphic_1024x500.png`
   and at least two screenshots from `screenshots/`.

   Personal developer accounts created after November 2023 must run a closed
   test with at least 12 testers for 14 days before production is unlocked.

Permissions worth knowing when you fill in the forms: notifications and
`SCHEDULE_EXACT_ALARM` for reminders (user-granted; the app falls back to
inexact alarms when denied), `RECEIVE_BOOT_COMPLETED` to re-arm reminders
after a reboot, and `WRITE_EXTERNAL_STORAGE` only up to Android 10 for
*Save image*. `USE_EXACT_ALARM` is deliberately not requested: Play limits
it to alarm-clock and calendar apps.

## Assets & credits

- Wall textures: [ambientCG](https://ambientcg.com) — Cork004,
  PaintedPlaster017, Concrete046, Bricks104, Planks021, Paper004 (kraft),
  Marble012, Terrazzo013, Fabric069 (denim), Fabric034 (felt), Fabric030
  (linen), Cardboard004, Concrete034 (cement), Fabric019 (cotton), Paper001,
  Ground037 (moss), Leather011, Marble006 (dark marble), Planks020 (dark
  planks), Tiles074 (checker). License: CC0.
- Fonts (Google Fonts, SIL OFL — licence files next to each in
  `assets/fonts/`):
  [Patrick Hand](https://fonts.google.com/specimen/Patrick+Hand),
  [Itim](https://fonts.google.com/specimen/Itim),
  [Dancing Script](https://fonts.google.com/specimen/Dancing+Script),
  [Be Vietnam Pro](https://fonts.google.com/specimen/Be+Vietnam+Pro),
  [Mali](https://fonts.google.com/specimen/Mali),
  [Sriracha](https://fonts.google.com/specimen/Sriracha),
  [Mynerve](https://fonts.google.com/specimen/Mynerve),
  [Fuzzy Bubbles](https://fonts.google.com/specimen/Fuzzy+Bubbles),
  [Amatic SC](https://fonts.google.com/specimen/Amatic+SC),
  [Charm](https://fonts.google.com/specimen/Charm),
  [IBM Plex Mono](https://fonts.google.com/specimen/IBM+Plex+Mono),
  [Pacifico](https://fonts.google.com/specimen/Pacifico). All include the
  Vietnamese subset.
