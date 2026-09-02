# Sticky Wall

A Flutter sticky-notes app that behaves like a real pin-board: pastel paper
notes on a textured wall, written in a handwriting font, that you can drag,
pin, color, and organize across multiple boards. Bilingual (English / Tiếng
Việt). Modeled after the original "Mia Note" Angular + Electron desktop app,
then taken well beyond it.

| Wall (drag, resize, draw, zoom, threads) | Grid | List | Paper editor |
|---|---|---|---|
| ![Wall](screenshots/mode_wall.png) | ![Grid](screenshots/mode_grid.png) | ![List](screenshots/mode_list.png) | ![Editor](screenshots/editor.png) |

| Lights off (night mode) | Trash (30-day retention) | Cork | Green chalkboard |
|---|---|---|---|
| ![Night](screenshots/night.png) | ![Trash](screenshots/trash.png) | ![Cork](screenshots/preview_cork.png) | ![Green](screenshots/preview_chalk_green.png) |

| Black chalkboard | Painted wall | Brick | Wood |
|---|---|---|---|
| ![Black](screenshots/preview_chalk_black.png) | ![Plaster](screenshots/preview_plaster.png) | ![Brick](screenshots/preview_brick.png) | ![Wood](screenshots/preview_wood.png) |

## Features

**Notes**
- Four types: **Normal** (multi-line text), **Link** (label + URL),
  **Checklist** (tickable items with done-count), and **Drawing** (freehand
  sketch with a color/size pen)
- Attach a **photo** (gallery or camera), add an **emote** sticker, pick a
  **paper color** (or auto-from-id), **pin to top**, and set a **reminder**
  (date + time, optionally **repeating daily / weekly / monthly**) that fires
  a local notification
- The editor *is* the note: same handwriting, same paper color, faint ruled
  lines under each baseline, Save/Cancel on the adhesive strip so they are
  never hidden by the keyboard; validation is inline (the paper shakes)
- **Long-press** a note for Edit / Pin / **Move to another board** / Share /
  Save / Select / Delete. **Share** renders the note as an image; **Save**
  puts it in the photo gallery
- Delete **peels the note off the wall** and drops it in the **Trash**, with
  an Undo snackbar; in list mode, swipe a row to delete. A link already on
  the wall (ignoring `https://`, `www.` and a trailing slash) is rejected
- A fully ticked checklist fades and shows a big tick; optionally it is
  swept into the trash automatically after a day
- Notes are paper cards with a push-pin, drop shadow and a slight hand-stuck
  tilt; pinned notes straighten and get a gold pin (tap the pin to toggle)

**Layouts**
- **Wall** — drag notes anywhere, **resize** the active note with its corner
  handle, **pinch to zoom / pan** the whole board (double-tap or the
  reset button snaps back); **long-press** empty space to stick a note there
- **Threads** — drag from one note's pin to another to tie a red yarn thread
  between them; tap a thread to cut it (Undo re-ties it)
- **Tidy up** (⋮ menu) flies every note into a neat grid, or groups them
  **by color**
- **Grid** — masonry layout; the column count follows the screen width
  (2 on phones, up to 6 on tablets / desktop)
- **List** — compact rows, swipe-to-delete
- Live, diacritic-insensitive search ("tuoi" finds "Tưới") with a result
  count, and a type filter; on the wall, notes that don't match are dimmed in
  place rather than removed. Grid/list add a sort menu (newest, oldest, A–Z,
  Z–A)
- **Multi-select** (⋮ → Select, or long-press → Select) with a bottom action
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
- Multiple named boards ("My Wall", "Work", …), each with an optional emoji
  icon; each remembers its own wall texture or **custom wall photo**
- Switch by tapping a board tab or swiping horizontally in grid/list; the
  content slides in the direction you moved. Tap the selected tab to rename /
  set an icon / delete it; **long-press and drag** a tab to reorder boards

**The wall**
- Six switchable textures: cork, green/black chalkboard, painted plaster,
  brick, wood — each under a tuned scrim so writing keeps contrast
- Or pick **your own photo** as the wall; its brightness is sampled to choose
  a scrim so the writing on it stays legible
- Procedural **stains** layer (water rings, drips, paint splatters, smudges,
  scuffs) drawn per wall; toggleable
- **Lights off**: a night mode that dims the wall and papers to a warm,
  lamp-lit look (never a grey dark theme) — off / on / follow system / on a
  schedule (e.g. 21:00 → 06:00); quick toggle in the ⋮ menu
- Subtle vignette for depth

**Fonts & language**
- Four handwriting fonts (Patrick Hand, Itim, Dancing Script, Be Vietnam Pro),
  all with full Vietnamese diacritics; Pacifico for the title. The font
  picker previews each as a real sample sticky note
- Full English / Tiếng Việt UI, following the system locale or set manually

**First launch**
- A fresh install seeds four sample notes (with one thread tied between two
  of them) that teach the gestures: drag, long-press, tick a checklist, pull
  a thread. Delete them like any other note

**Data**
- Everything persists locally (no backend). A single corrupt record is
  skipped on load instead of taking every note with it
- Photos are copied into the app's documents folder and referenced by file
  name, so they survive iOS container moves; files no longer referenced by
  any note are removed
- **Export** the whole wall to a JSON file (share sheet) and **import** it back

## Getting started

```sh
flutter pub get
flutter run
```

Localizations are generated from `lib/l10n/*.arb` on `flutter pub get`
(see `l10n.yaml`). App icon and splash are generated art:

```sh
flutter test --update-goldens test/icon_gen_test.dart   # regenerate art
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Architecture

State lives in two `ChangeNotifier`s the widgets listen to:

| Path | Purpose |
|---|---|
| `lib/models/` | `Note` (+ `ReminderRepeat`, `NoteLink`), `ChecklistItem`, `Board`, `ViewMode` |
| `lib/services/note_storage.dart` | JSON persistence via `shared_preferences` (notes, boards, threads, settings) |
| `lib/services/notes_controller.dart` | Boards + notes + CRUD, trash & retention, bulk actions, threads, tidy |
| `lib/services/settings_controller.dart` | Font / language / stains / night mode & schedule |
| `lib/services/reminder_service.dart` | Local notifications, incl. repeating reminders |
| `lib/services/share_service.dart` | Receives shares from other apps (`receive_sharing_intent`) |
| `lib/services/sample_notes.dart` | First-launch sample notes |
| `lib/services/backup_service.dart` | Export / import JSON |
| `lib/services/image_service.dart` | Pick photo / wall photo, capture note→PNG, share, save to gallery |
| `lib/services/widget_service.dart` | Push pinned notes to the home-screen widget |
| `lib/screens/home_screen.dart` | Header, board bar, toolbar, the three views, multi-select |
| `lib/screens/trash_screen.dart` | Trash: restore / delete forever / empty |
| `lib/widgets/wall_view.dart` | Free drag-and-drop canvas, threads, tidy animation |
| `lib/widgets/wall_background.dart` | Wall texture or custom photo + scrim, stains, vignette |
| `lib/widgets/peel_away.dart` | "Peel off the wall" delete animation |
| `lib/widgets/drawing_canvas.dart` | Freehand drawing editor + stroke painter |
| `lib/widgets/note_dialog.dart` | Create/Edit dialog (type, color, pin, reminder + repeat, emote) |
| `lib/widgets/note_views.dart` | Sticky card + list tile |
| `lib/widgets/wall_decor.dart` | Procedural stains (CustomPainter) |
| `lib/widgets/settings_sheet.dart` · `board_bar.dart` | Customize sheet (wall, photo, night, font, trash), reorderable board tabs |
| `lib/theme.dart` | Walls, fonts, palette (`AppColors`), light + night themes |
| `lib/util/` | `foldText` (diacritic folding), `stableHash` (deterministic ids/seeds) |
| `test/*_test.dart` | Widget/unit tests + skipped golden generators for screenshots & icon |

Screenshots are produced by the golden generators: remove `skip: true` in
`test/preview_test.dart` / `test/modes_preview_test.dart`, run
`flutter test --update-goldens` on them, and move the PNGs from `test/` to
`screenshots/`.

## Assets & credits

- Wall textures: [ambientCG](https://ambientcg.com) — Cork004,
  PaintedPlaster017, Concrete046, Bricks104, Planks021. License: CC0.
- Fonts (Google Fonts, SIL OFL, copies in `assets/fonts/`):
  [Patrick Hand](https://fonts.google.com/specimen/Patrick+Hand),
  [Itim](https://fonts.google.com/specimen/Itim),
  [Dancing Script](https://fonts.google.com/specimen/Dancing+Script),
  [Be Vietnam Pro](https://fonts.google.com/specimen/Be+Vietnam+Pro),
  [Pacifico](https://fonts.google.com/specimen/Pacifico). All include the
  Vietnamese subset.
