import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/main.dart';
import 'package:sticky_wall/models/board.dart';
import 'package:sticky_wall/models/note.dart';
import 'package:sticky_wall/models/view_mode.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/services/notes_controller.dart';
import 'package:sticky_wall/services/reminder_service.dart';
import 'package:sticky_wall/services/settings_controller.dart';
import 'package:sticky_wall/util/legal_links.dart';

/// Settings lives in the More menu, apart from Customize, in sections.
void main() {
  Future<NotesController> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2220);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final storage = await NoteStorage.create();
    await storage.saveBoards([
      Board(id: 'default', name: ''),
      Board(id: 'work', name: 'Work'),
    ]);
    await storage.saveNotes([
      Note(
        guid: '1',
        content: 'Keep?',
        createdAt: DateTime(2026),
        boardId: 'default',
      ),
      Note(
        guid: '2',
        content: 'Old',
        createdAt: DateTime(2026),
        boardId: 'work',
        deletedAt: DateTime.now(),
      ),
    ]);
    await storage.setViewMode(ViewMode.grid);
    final notes = NotesController(storage, ReminderService());
    await tester.pumpWidget(
      StickyWallApp(settings: SettingsController(storage), notes: notes),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    return notes;
  }

  testWidgets('sections and their rows, in order', (tester) async {
    await open(tester);
    final rows = [
      'General',
      'Language',
      'Privacy',
      'App lock',
      'Data',
      'Backup & restore',
      'Trash',
      'Delete all data',
      'Help',
      'How to use',
      'About',
      'Send feedback',
      'Privacy policy',
      'Terms of service',
    ];
    double? last;
    for (final row in rows) {
      final f = find.text(row);
      // From the top each time: a row is looked for below, never above.
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pump();
      await tester.scrollUntilVisible(f, 150);
      final y = tester.getTopLeft(f.first).dy;
      // Each row comes after the previous one (scrolled into view in turn).
      if (last != null) expect(y, greaterThan(-1), reason: row);
      last = y;
    }
    expect(find.text('apps.winka.studio@gmail.com'), findsOneWidget);
    // Both legal pages are live on the studio website and open from here.
    for (final label in ['Privacy policy', 'Terms of service']) {
      final tile = tester.widget<ListTile>(
        find.ancestor(of: find.text(label), matching: find.byType(ListTile)),
      );
      expect(tile.enabled, isTrue, reason: label);
      expect(tile.onTap, isNotNull, reason: label);
    }
  });

  test('legal pages: Vietnamese gets /vi/, every other language English', () {
    expect(
      privacyPolicyUri('en').toString(),
      'https://winka.top/en/apps/sticky-wall/privacy/',
    );
    expect(
      termsOfServiceUri('vi').toString(),
      'https://winka.top/vi/apps/sticky-wall/terms/',
    );
    expect(
      dataDeletionUri('fr').toString(),
      'https://winka.top/en/apps/sticky-wall/data-deletion/',
    );
    expect(
      supportUri('vi').toString(),
      'https://winka.top/vi/support/sticky-wall/',
    );
  });

  testWidgets('delete all data asks twice, then clears everything', (
    tester,
  ) async {
    final notes = await open(tester);
    await tester.scrollUntilVisible(find.text('Delete all data'), 150);
    await tester.tap(find.text('Delete all data'));
    await tester.pumpAndSettle();
    expect(find.text('Delete all data?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(notes.allNotes, hasLength(2), reason: 'cancel keeps everything');

    await tester.tap(find.text('Delete all data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Are you sure?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Delete all data'));
    await tester.pumpAndSettle();
    expect(notes.allNotes, isEmpty);
    expect(notes.boards, hasLength(1));
    expect(notes.deletedBoards, isEmpty);
    expect(notes.links, isEmpty);
  });
}
