import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/main.dart';
import 'package:sticky_wall/models/board.dart';
import 'package:sticky_wall/models/draw_stroke.dart';
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

// A little scribbled smiley as normalized strokes.
List<DrawStroke> _smiley() => [
      DrawStroke(color: 0xFFC62828, width: 6, points: [
        for (var i = 0; i <= 20; i++)
          Offset(0.2 + 0.6 * (i / 20),
              0.5 + 0.25 * (1 - (2 * (i / 20) - 1) * (2 * (i / 20) - 1))),
      ]),
      DrawStroke(color: 0xFF1565C0, width: 6, points: [
        const Offset(0.35, 0.35),
        const Offset(0.35, 0.42),
      ]),
      DrawStroke(color: 0xFF1565C0, width: 6, points: [
        const Offset(0.65, 0.35),
        const Offset(0.65, 0.42),
      ]),
    ];

void main() {
  testWidgets('mode wall features', skip: true, (tester) async {
    await _fonts();
    SharedPreferences.setMockInitialValues({});
    final storage = await NoteStorage.create();
    await storage.saveBoards([Board(id: 'default', name: '', wallIndex: 0)]);
    await storage.saveNotes([
      Note(guid: 'a', content: 'Nhớ tưới cây', boardId: 'default', createdAt: _t(1), colorIndex: 3, emoji: '🌱', x: 0.05, y: 0.02, scale: 1.15),
      Note(guid: 'b', content: 'Vẽ nhanh', boardId: 'default', createdAt: _t(2), type: NoteType.drawing, colorIndex: 0, strokes: _smiley(), x: 0.55, y: 0.05),
      Note(guid: 'c', content: 'Ghi chú to', boardId: 'default', createdAt: _t(3), pinned: true, colorIndex: 1, x: 0.06, y: 0.5, scale: 1.5),
      Note(guid: 'd', content: 'nhỏ', boardId: 'default', createdAt: _t(4), colorIndex: 2, x: 0.66, y: 0.62, scale: 0.8),
    ]);
    await storage.setViewMode(ViewMode.wall);
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
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }

    await expectLater(
      find.byType(StickyWallApp),
      matchesGoldenFile('mode_wall.png'),
    );
  });
}
