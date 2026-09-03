import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/main.dart';
import 'package:sticky_wall/models/note.dart';
import 'package:sticky_wall/models/view_mode.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/services/notes_controller.dart';
import 'package:sticky_wall/services/reminder_service.dart';
import 'package:sticky_wall/services/settings_controller.dart';
import 'package:sticky_wall/widgets/board_poster.dart';

/// The app at the shapes it will meet in the wild — a tablet both ways up
/// and a phone on its side — walking every screen and asking for nothing
/// more than "no overflow, no exception". Layout tests, not looks.
final _sizes = <String, (Size, double)>{
  'tablet portrait': (const Size(1600, 2560), 2),
  'tablet landscape': (const Size(2560, 1600), 2),
  'phone landscape': (const Size(2400, 1080), 3),
  'small phone': (const Size(1080, 1920), 3),
};

final _epoch = DateTime(2026);

List<Note> _notes() => [
  Note(
    guid: 'a',
    content: 'Nhớ tưới cây',
    createdAt: _epoch,
    boardId: 'default',
    x: 0.05,
    y: 0.05,
    colorIndex: 3,
  ),
  Note(
    guid: 'b',
    content: 'Đi chợ',
    createdAt: _epoch,
    boardId: 'default',
    x: 0.6,
    y: 0.1,
    type: NoteType.checklist,
    checklist: [
      ChecklistItem(text: 'Sữa'),
      ChecklistItem(text: 'Trứng', done: true),
    ],
  ),
  Note(
    guid: 'c',
    content: 'Tuần này',
    createdAt: _epoch,
    boardId: 'default',
    x: 0.3,
    y: 0.55,
    type: NoteType.label,
    locked: true,
  ),
  Note(
    guid: 'd',
    content: 'Tài liệu',
    url: 'https://flutter.dev',
    createdAt: _epoch,
    boardId: 'default',
    x: 0.7,
    y: 0.7,
    rotation: 0.3,
  ),
];

void main() {
  for (final MapEntry(key: name, value: (size, dpr)) in _sizes.entries) {
    testWidgets('every screen lays out on a $name', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = dpr;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({});
      final storage = await NoteStorage.create();
      await storage.saveNotes(_notes());
      await storage.setViewMode(ViewMode.wall);
      final notes = NotesController(storage, ReminderService());
      notes.connect('a', 'd');
      await tester.pumpWidget(
        StickyWallApp(settings: SettingsController(storage), notes: notes),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'wall');

      // Marker mode and its bar.
      await tester.tap(find.byTooltip('Draw on the wall'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'marker bar');
      await tester.tap(find.byTooltip('Done'));
      await tester.pumpAndSettle();

      // Select mode and its bar.
      await tester.longPress(find.text('Nhớ tưới cây'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'action sheet');
      await tester.tap(find.text('Select notes'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'selection bar');
      await tester.tap(find.byTooltip('Cancel'));
      await tester.pumpAndSettle();

      // The editor.
      await tester.tap(find.text('Nhớ tưới cây'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsWidgets, reason: 'editor open');
      expect(tester.takeException(), isNull, reason: 'editor');
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      // The export page, with its options and crop frame.
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      // On a phone on its side the menu is taller than the screen: it scrolls.
      await tester.ensureVisible(find.text('Export board as image'));
      await tester.tap(find.text('Export board as image'));
      await tester.pumpAndSettle();
      expect(find.byType(BoardPosterPage), findsOneWidget);
      await tester.tap(find.byTooltip('Trim'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'export');
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Customize sheet.
      await tester.tap(find.byIcon(Icons.palette_outlined));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'settings sheet');
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Grid and list.
      notes.viewMode = ViewMode.grid;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'grid');
      notes.viewMode = ViewMode.list;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'list');
    });
  }
}
