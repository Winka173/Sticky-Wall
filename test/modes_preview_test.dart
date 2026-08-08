import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

Future<void> _fonts() async {
  for (final e in {
    'PatrickHand': 'assets/fonts/PatrickHand-Regular.ttf',
    'Pacifico': 'assets/fonts/Pacifico-Regular.ttf',
  }.entries) {
    await (FontLoader(e.key)..addFont(rootBundle.load(e.value))).load();
  }
}

DateTime _t(int d) => DateTime(2026, 8, d, 9);

List<Note> _notes() => [
      Note(guid: 'a', content: 'Đi chợ cuối tuần', boardId: 'default', createdAt: _t(1), type: NoteType.checklist, colorIndex: 0, x: 0.05, y: 0.02, checklist: [ChecklistItem(text: 'Sữa', done: true), ChecklistItem(text: 'Rau củ')]),
      Note(guid: 'b', content: 'Tài liệu Flutter', url: 'https://docs.flutter.dev', boardId: 'default', createdAt: _t(2), colorIndex: 3, x: 0.5, y: 0.08),
      Note(guid: 'c', content: 'Học tiếng Anh mỗi ngày', boardId: 'default', createdAt: _t(3), colorIndex: 2, x: 0.15, y: 0.4),
      Note(guid: 'd', content: 'Gọi điện cho mẹ', boardId: 'default', createdAt: _t(4), pinned: true, colorIndex: 1, x: 0.55, y: 0.45),
      Note(guid: 'e', content: 'Đặt lịch khám răng', boardId: 'default', createdAt: _t(5), colorIndex: 4, x: 0.28, y: 0.72),
    ];

void main() {
  for (final mode in [ViewMode.wall, ViewMode.list]) {
    testWidgets('mode ${mode.name}', skip: true, (tester) async {
      await _fonts();
      SharedPreferences.setMockInitialValues({});
      final storage = await NoteStorage.create();
      await storage.saveBoards([Board(id: 'default', name: '', wallIndex: 0)]);
      await storage.saveNotes(_notes());
      await storage.setViewMode(mode);
      await storage.setLanguageCode('vi');

      tester.view.physicalSize = const Size(1170, 2280);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(StickyWallApp(
        settings: SettingsController(storage),
        notes: NotesController(storage, ReminderService()),
      ));
      await tester.runAsync(() async {
        final ctx = tester.element(find.byType(Scaffold));
        await precacheImage(const AssetImage('assets/images/wall_cork.jpg'), ctx);
      });
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(StickyWallApp),
        matchesGoldenFile('mode_${mode.name}.png'),
      );
    });
  }
}
