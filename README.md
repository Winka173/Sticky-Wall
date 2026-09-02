# Sticky Wall

A Flutter sticky-notes app that behaves like a real pin-board: pastel paper
notes on a textured wall, written in a handwriting font, that you can drag,
pin, color, and organize across multiple boards. Bilingual (English / Tiếng
Việt). Modeled after the original "Mia Note" Angular + Electron desktop app,
then taken well beyond it.

| Wall (drag, resize, draw, zoom) | Grid | List | Paper editor |
|---|---|---|---|
| ![Wall](screenshots/mode_wall.png) | ![Grid](screenshots/preview_cork.png) | ![List](screenshots/mode_list.png) | ![Editor](screenshots/editor.png) |

| Cork | Green chalkboard | Black chalkboard |
|---|---|---|
| ![Cork](screenshots/preview_cork.png) | ![Green](screenshots/preview_chalk_green.png) | ![Black](screenshots/preview_chalk_black.png) |

| Painted wall | Brick | Wood |
|---|---|---|
| ![Plaster](screenshots/preview_plaster.png) | ![Brick](screenshots/preview_brick.png) | ![Wood](screenshots/preview_wood.png) |

## Features

**Notes**
- Four types: **Normal** (multi-line text), **Link** (label + URL),
  **Checklist** (tickable items with done-count), and **Drawing** (freehand
  sketch with a color/size pen)
- Attach a **photo** (gallery or camera), add an **emote** sticker, pick a
  **paper color** (or auto-from-id), **pin to top**, and set a **reminder**
  (date + time) that fires a local notification
- **Share** a note as an image or **save** it to the photo gallery
  (long-press a note)
- Add / edit / delete with **undo** (delete shows an Undo snackbar), plus
  duplicate prevention
- Notes are paper cards with a push-pin, drop shadow and a slight hand-stuck
  tilt; pinned notes straighten and get a gold pin

**Layouts**
- **Wall** — drag notes anywhere, **resize** each with its corner handle,
  **pinch to zoom / pan** the whole board (reset-zoom button); tap empty
  space to create a note there
- **Grid** — masonry layout (varied heights)
- **List** — compact rows
- Live search, filter by type, sort by newest or by name

**Home-screen widget** (Android)
- A widget showing the current board's pinned notes; tap to open the app.
  Data is pushed via `home_widget`; the native provider lives in
  `android/app/src/main/kotlin/.../StickyWidgetProvider.kt`.
- iOS: the Dart side already pushes data; add a WidgetKit extension target in
  Xcode (named `StickyWidget`) reading the shared `home_widget` data to enable
  it on iOS.

**Boards**
- Multiple named boards ("My Wall", "Work", …); each remembers its own wall
- Switch by tapping a board tab or swiping horizontally in grid/list;
  add / rename / delete boards

**The wall**
- Six switchable textures: cork, green/black chalkboard, painted plaster,
  brick, wood — each under a tuned scrim so writing keeps contrast
- Procedural **stains** layer (water rings, drips, paint splatters, smudges,
  scuffs) drawn per wall; toggleable
- Subtle vignette for depth

**Fonts & language**
- Four handwriting fonts (Patrick Hand, Itim, Dancing Script, Be Vietnam Pro),
  all with full Vietnamese diacritics; Pacifico for the title
- Full English / Tiếng Việt UI, following the system locale or set manually

**Data**
- Everything persists locally (no backend)
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
| `lib/models/` | `Note`, `ChecklistItem`, `Board`, `ViewMode` |
| `lib/services/note_storage.dart` | JSON persistence via `shared_preferences` |
| `lib/services/notes_controller.dart` | Boards + notes + CRUD, undo, move, sort |
| `lib/services/settings_controller.dart` | Font / language / stains |
| `lib/services/reminder_service.dart` | Local notifications (flutter_local_notifications) |
| `lib/services/backup_service.dart` | Export / import JSON |
| `lib/services/image_service.dart` | Pick photo, capture note→PNG, share, save to gallery |
| `lib/services/widget_service.dart` | Push pinned notes to the home-screen widget |
| `lib/widgets/drawing_canvas.dart` | Freehand drawing editor + stroke painter |
| `lib/screens/home_screen.dart` | Header, board bar, toolbar, the three views |
| `lib/widgets/wall_view.dart` | Free drag-and-drop canvas |
| `lib/widgets/note_dialog.dart` | Create/Edit dialog (type, color, pin, reminder, emote) |
| `lib/widgets/note_views.dart` | Sticky card + list tile |
| `lib/widgets/wall_decor.dart` | Procedural stains (CustomPainter) |
| `lib/widgets/settings_sheet.dart` · `board_bar.dart` | Customize sheet, board tabs |
| `lib/theme.dart` | Walls, fonts, palette, theme |
| `test/*_test.dart` | Widget/unit tests + skipped golden generators for screenshots & icon |

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
