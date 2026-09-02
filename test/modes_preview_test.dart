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

Future<StickyWallApp> _app({
  required ViewMode mode,
  required List<Note> notes,
  List<NoteLink> links = const [],
  int wallIndex = 0,
  NightMode night = NightMode.off,
}) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await NoteStorage.create();
  await storage
      .saveBoards([Board(id: 'default', name: '', wallIndex: wallIndex)]);
  await storage.saveNotes(notes);
  await storage.saveLinks(links);
  await storage.setViewMode(mode);
  await storage.setLanguageCode('vi');
  await storage.setNightMode(night);
  return StickyWallApp(
    settings: SettingsController(storage),
    notes: NotesController(storage, ReminderService()),
  );
}

Future<void> _pump(WidgetTester tester, Widget app,
    {String wallAsset = 'assets/images/wall_cork.jpg'}) async {
  tester.view.physicalSize = const Size(1170, 2280);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app);
  await tester.runAsync(() async {
    final ctx = tester.element(find.byType(Scaffold).first);
    await precacheImage(AssetImage(wallAsset), ctx);
  });
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 130));
  }
}

List<Note> _wallNotes() => [
      Note(guid: 'a', content: 'Nhớ tưới cây', boardId: 'default', createdAt: _t(1), colorIndex: 3, emoji: '🌱', x: 0.05, y: 0.02, scale: 1.15),
      Note(guid: 'b', content: 'Vẽ nhanh', boardId: 'default', createdAt: _t(2), type: NoteType.drawing, colorIndex: 0, strokes: _smiley(), x: 0.55, y: 0.05),
      Note(guid: 'c', content: 'Ghi chú to', boardId: 'default', createdAt: _t(3), pinned: true, colorIndex: 1, x: 0.06, y: 0.5, scale: 1.5),
      Note(guid: 'd', content: 'nhỏ', boardId: 'default', createdAt: _t(4), colorIndex: 2, x: 0.66, y: 0.62, scale: 0.8),
    ];

void main() {
  testWidgets('mode wall features', skip: true, (tester) async {
    await _fonts();
    final app = await _app(
      mode: ViewMode.wall,
      notes: _wallNotes(),
      // A red thread ties the sketch to the big note.
      links: const [NoteLink('b', 'c')],
    );
    await _pump(tester, app);
    await expectLater(
        find.byType(StickyWallApp), matchesGoldenFile('mode_wall.png'));
  });

  testWidgets('night mode', skip: true, (tester) async {
    await _fonts();
    final app = await _app(
      mode: ViewMode.wall,
      notes: _wallNotes(),
      links: const [NoteLink('a', 'd')],
      wallIndex: 3, // plaster: the dimming is most visible on a light wall
      night: NightMode.on,
    );
    await _pump(tester, app, wallAsset: 'assets/images/wall_plaster.jpg');
    await expectLater(
        find.byType(StickyWallApp), matchesGoldenFile('night.png'));
  });

  testWidgets('trash', skip: true, (tester) async {
    await _fonts();
    final now = DateTime.now();
    final app = await _app(mode: ViewMode.grid, notes: [
      Note(guid: 'a', content: 'Nháp bài viết cũ', boardId: 'default', createdAt: _t(1), colorIndex: 2)
        ..deletedAt = now.subtract(const Duration(days: 2)),
      Note(guid: 'b', content: 'Đi chợ', boardId: 'default', createdAt: _t(2), type: NoteType.checklist, colorIndex: 0, checklist: [ChecklistItem(text: 'Sữa', done: true), ChecklistItem(text: 'Trứng', done: true)])
        ..deletedAt = now.subtract(const Duration(days: 12)),
      Note(guid: 'c', content: 'Link tham khảo', url: 'https://docs.flutter.dev', boardId: 'default', createdAt: _t(3), colorIndex: 3)
        ..deletedAt = now.subtract(const Duration(days: 28)),
      Note(guid: 'd', content: 'Còn giữ trên tường', boardId: 'default', createdAt: _t(4), colorIndex: 1),
    ]);
    await _pump(tester, app);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thùng rác (3)'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 130));
    }
    await expectLater(
        find.byType(StickyWallApp), matchesGoldenFile('trash.png'));
  });

  testWidgets('mode grid', skip: true, (tester) async {
    await _fonts();
    final app = await _app(mode: ViewMode.grid, notes: [
      Note(guid: 'a', content: 'Đi chợ cuối tuần', boardId: 'default', createdAt: _t(1), type: NoteType.checklist, colorIndex: 0, checklist: [ChecklistItem(text: 'Sữa', done: true), ChecklistItem(text: 'Rau củ'), ChecklistItem(text: 'Trứng')]),
      Note(guid: 'b', content: 'Tài liệu Flutter', url: 'https://docs.flutter.dev', boardId: 'default', createdAt: _t(2), colorIndex: 3),
      Note(guid: 'c', content: 'Học tiếng Anh mỗi ngày,\n30 phút buổi sáng', boardId: 'default', createdAt: _t(3), colorIndex: 2, emoji: '📚'),
      Note(guid: 'd', content: 'Gọi điện cho mẹ', boardId: 'default', createdAt: _t(4), pinned: true, colorIndex: 1, reminderAt: DateTime(2026, 9, 10, 18)),
      Note(guid: 'e', content: 'Bản vẽ ý tưởng', boardId: 'default', createdAt: _t(5), type: NoteType.drawing, colorIndex: 4, strokes: _smiley()),
      Note(guid: 'f', content: 'Ý tưởng', boardId: 'default', createdAt: _t(6), colorIndex: 5),
    ]);
    await _pump(tester, app);
    await expectLater(
        find.byType(StickyWallApp), matchesGoldenFile('mode_grid.png'));
  });

  testWidgets('mode list', skip: true, (tester) async {
    await _fonts();
    final app = await _app(mode: ViewMode.list, notes: [
      Note(guid: 'a', content: 'Đi chợ cuối tuần', boardId: 'default', createdAt: _t(1), type: NoteType.checklist, colorIndex: 0, checklist: [ChecklistItem(text: 'Sữa', done: true), ChecklistItem(text: 'Rau củ')]),
      Note(guid: 'b', content: 'Tài liệu Flutter', url: 'https://docs.flutter.dev', boardId: 'default', createdAt: _t(2), colorIndex: 3),
      Note(guid: 'c', content: 'Học tiếng Anh mỗi ngày', boardId: 'default', createdAt: _t(3), colorIndex: 2, emoji: '📚'),
      Note(guid: 'd', content: 'Gọi điện cho mẹ', boardId: 'default', createdAt: _t(4), pinned: true, colorIndex: 1),
      Note(guid: 'e', content: 'Bản vẽ ý tưởng', boardId: 'default', createdAt: _t(5), type: NoteType.drawing, colorIndex: 4, strokes: _smiley()),
    ]);
    await _pump(tester, app);
    await expectLater(
        find.byType(StickyWallApp), matchesGoldenFile('mode_list.png'));
  });

  testWidgets('editor', skip: true, (tester) async {
    await _fonts();
    final app = await _app(mode: ViewMode.grid, notes: [
      Note(
        guid: 'a',
        content: 'Nhớ gọi điện hỏi thăm mẹ,\nhỏi sức khỏe của bà nữa',
        boardId: 'default',
        createdAt: _t(1),
        colorIndex: 1,
        emoji: '❤️',
        pinned: true,
        reminderAt: DateTime(2026, 9, 10, 18),
      ),
    ]);
    await _pump(tester, app);
    await tester.tap(find.textContaining('Nhớ gọi điện'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 130));
    }
    await expectLater(
        find.byType(StickyWallApp), matchesGoldenFile('editor.png'));
  });
}
