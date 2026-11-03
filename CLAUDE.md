# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Sticky Wall is a Flutter sticky-notes app (Android first, iOS second, web only for a quick look — native plugins are no-ops there). Fully local: no backend. `README.md` has the full feature list, a file-by-file architecture table, the iOS widget setup and the Play release checklist; read it before larger changes.

## Commands

```sh
flutter pub get                       # also regenerates lib/l10n/app_localizations*.dart
flutter analyze                       # must be clean (strict-casts/inference/raw-types, see analysis_options.yaml)
flutter test                          # all tests
flutter test test/logic_test.dart     # one file
flutter test test/editor_test.dart --plain-name "rotate grip"   # one test by name substring
flutter run -d <device-id>
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
```

On Windows from the Bash tool, wrap `flutter test` in `timeout` (golden/image tests can hang) and set `MSYS_NO_PATHCONV=1` before `adb` commands that take `/sdcard/...` paths.

Generated assets:
- Screenshots in `screenshots/`: flip `skip: true` → false in `test/preview_test.dart` / `test/modes_preview_test.dart`, run `flutter test --update-goldens <file>`, flip back, move the PNGs from `test/` to `screenshots/`. Regenerate when cards, the board bar or toolbars change visibly.
- App icon / splash: `flutter test --update-goldens test/icon_gen_test.dart`, then `dart run flutter_launcher_icons` and `dart run flutter_native_splash:create`.

## Architecture

- **Boot** (`lib/main.dart`): creates `NoteStorage`, `ReminderService`, `ImageService`, then two `ChangeNotifier`s — `NotesController` (boards, notes, threads, trash, tidy, bulk actions, undo) and `SettingsController` (font, language, stains, night mode). Widgets listen to them directly; there is no other state-management package. On first run it seeds `SampleNotes` laid out for the actual screen size. The home-screen widget is synced by a listener on both controllers.
- **Persistence** (`lib/services/note_storage.dart`): everything is JSON in `shared_preferences` under fixed keys. Loading decodes record by record and skips malformed ones — keep `fromJson` tolerant of missing/new fields, since old installs and JSON backups (`backup_service.dart`, `version: 1`) must still load.
- **Photos** are copied into the app documents folder and stored on notes/boards by **file name only**, resolved at runtime by `ImageService.resolve` (survives iOS container moves). A file is deleted only when no live or trashed note references it — the controller is given `deletePhoto`/`deleteWallImage` callbacks for this.
- **Wall coordinates**: `Note.x`/`y` are fractions (0..1) of the wall area, not pixels, so layouts travel across screen sizes; `scale` is a size multiplier and `rotation` is radians (null = the default guid-derived tilt). Marker strokes on a board are stored the same way. The wall extends `WallView.pad` (1000 px) past every screen edge, and the camera can pan exactly that far.
- **Three views of the same notes** (`ViewMode`: wall / grid / list) live in `lib/screens/home_screen.dart`; the free canvas with grips, two-finger twist/pinch, lasso, drop tray, threads and the measured tidy animation is `lib/widgets/wall_view.dart`. The big screens are split with Dart `part` files so private members stay shared: `home_screen_actions.dart` (note long-press actions), `home_screen_chrome.dart` (header, tool pill, menus, marker mode), `home_screen_widgets.dart` (private widgets), `wall_view_parts.dart`, and `note_dialog_pieces.dart` (the editor's sections). Methods in those `extension … on _XState` blocks call `_update(...)` instead of the protected `setState`.
- **Keyboard**: hand-built tappables (cards, tabs, swatches, tiles) are wrapped in `KeyboardTappable` (`lib/widgets/keyboard_tappable.dart`): Tab focus ring, Enter/Space = tap, Shift+F10 / menu key = long-press. Wrap new custom tappables the same way.
- **Card rendering** is shared by the wall, grid, list, export (`board_poster.dart`) and share-as-image: `lib/widgets/note_views.dart`. Change a card's look there, once.
- **Look and feel**: `lib/theme.dart` owns walls, fonts, palette (`AppColors`), radii and the light + "lights off" themes. Night mode is a dimmed warm theme, never a grey dark theme. Controls should read colors/sizes from here instead of hard-coding them.
- **Text helpers** in `lib/util/`: `foldText` (diacritic-insensitive search — "tuoi" finds "Tưới"), `stableHash` (deterministic seeds/tilts from ids), `rich_note` (the light `**bold**` / `*italic*` / `- item` markup; search, trash and the widget read text with markers stripped).
- **Native pieces**: Android widget `android/app/src/main/kotlin/com/apps/winka/stickywall/StickyWidgetProvider.kt` (application id `com.apps.winka.stickywall`); iOS widget code in `ios/StickyWidget/` (app group `group.com.winka.stickyWall`). The widget's keys (`title`, `line1..6`, `empty`, `mode`, `look`, `textSize`, `wall`) and colours must stay in step across `widget_service.dart`, `widget_settings_sheet.dart`, the Kotlin provider and the Swift view. Release rules in `android/app/proguard-rules.pro` keep the notification plugin's Gson classes and the widget provider.
- **App lock**: `MainActivity` is a `FlutterFragmentActivity` (local_auth needs it). In `res/values*/styles.xml` only `LaunchTheme` has an AppCompat parent; `NormalTheme` must stay a platform theme — as AppCompat it dims the whole Flutter surface ~8% once the device has shown a lock prompt. `flutter_native_splash:create` rewrites these files: restore the parents afterwards.
- **Pro** (`ProController`, product `sticky_wall_pro`): Pro papers / walls / fonts / pins / marker and yarn colours are appended (indices or ARGB persist) and flagged (`AppColors.freePapers` / `freeMarkers` / `freeYarns`, `WallStyle.pro`, `FontChoice.pro`, `PinStyle.pro`, `PaperStyle.pro`, `ThreadStyle.pro`, `Sticker.pro`). Gate *choosing* them via `ProScope.unlockedOf(context)` and `showProSheet`; never stop rendering what a note already has. A note's default colour comes from the free papers only; dark walls start the marker at `AppColors.markerChalk`, not `markers.last`. Walls, fonts and pins can be *tried on* from Customize (`SettingsController.tryWall/tryFont/tryPin`, cleared when the sheet closes). A mixed paper colour lives in `colorIndex` as ARGB (≥ `customPaperBase`). Private boards (`Board.isPrivate`) are shut per session in `NotesController` (`isOpen`, `openPrivateBoard`, `shutPrivateBoards` on background); anything that lists notes across boards must skip shut ones, reminders go through `_syncReminder` (hidden text), and the widget never shows a private board's notes.

## Conventions

- **Localization**: every user-visible string goes into both `lib/l10n/app_en.arb` (template) and `lib/l10n/app_vi.arb`. The generated `app_localizations*.dart` files are committed — regenerate them (`flutter pub get` or `flutter gen-l10n`) and commit them with the ARB change.
- Fonts must include the full Vietnamese subset; each font is size-balanced in `theme.dart` so switching fonts does not reflow cards.
- Lints enforce single quotes, `final` locals, ordered directives, `unawaited_futures`, `use_build_context_synchronously`, no `print`.

## Testing notes

- Widget tests boot the real app: `SharedPreferences.setMockInitialValues({})`, `NoteStorage.create()`, seed notes with `storage.saveNotes`, then pump `StickyWallApp` with a `NotesController(storage, ReminderService())` (see `_pumpApp` in `test/editor_test.dart`).
- Dragging a wall note in tests: use `tester.startGesture` + one `moveBy` past the slop; `tester.drag`'s first slop-sized step is swallowed by the competing wall pan.
- Images used in tests must be decoded via `tester.runAsync` *before* the first pump — an image that starts loading inside the fake-async zone never finishes. Fixture photos are painted with `dart:ui` at test time (no binary fixtures); `test/preview_fonts.dart` loads real fonts and the Material icon font for goldens.
- Keyboard-inset layout bugs are reproduced in widget tests by setting `tester.view.viewInsets` with `padding.bottom = 0` (see `test/wall_stability_test.dart`); an emulator with a floating keyboard never changes insets.
- The wall's `RawGestureDetector` recognizers need `gestureSettings` from `MediaQuery`, otherwise `InteractiveViewer` wins every drag on a real device. Tests don't catch this (`gestureSettings` is null there), so gesture changes need an on-device check. On a device, a note drag starts only after the 36 px pan slop; the resize/rotate grips use an eager ~6 px recognizer.
