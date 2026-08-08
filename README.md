# Sticky Wall

A Flutter sticky-notes / bookmarks app, modeled after the original "Mia Note"
Angular + Electron desktop app.

## Features

- Two note types: **Normal** (free multi-line text) and **Link** (a label + URL)
- Add / edit / delete notes, with duplicate prevention and delete confirmation
- Live search across note content and URLs
- Filter by type (All / Normal / Link)
- Ascending / descending sort toggle
- List or grid view toggle
- Link notes open in the system browser
- All data and view settings persist locally on the device (no backend)

## Getting started

```sh
flutter pub get
flutter run
```

## Structure

| Path | Purpose |
|---|---|
| `lib/models/note.dart` | Note model (guid, content, url) |
| `lib/services/note_storage.dart` | Local persistence via `shared_preferences` |
| `lib/screens/home_screen.dart` | Main screen: toolbar, list/grid of notes |
| `lib/widgets/note_dialog.dart` | Create/Edit note dialog with validation |
| `lib/widgets/note_views.dart` | List tile and grid card renderings |
| `lib/theme.dart` | Palette and theme (gradient, pink notes, peachpuff links) |
