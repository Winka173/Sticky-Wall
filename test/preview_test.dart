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
import 'package:sticky_wall/theme.dart';

import 'preview_fonts.dart';

Future<void> _loadRealFonts() => loadPreviewFonts();

DateTime _t(int day) => DateTime(2026, 8, day, 9);

List<Note> _sampleNotes() => [
      Note(
        guid: 'a1',
        content: 'Đi chợ cuối tuần',
        boardId: 'default',
        createdAt: _t(1),
        type: NoteType.checklist,
        emoji: '🛒',
        checklist: [
          ChecklistItem(text: 'Sữa và trứng', done: true),
          ChecklistItem(text: 'Rau củ'),
          ChecklistItem(text: 'Cà phê'),
        ],
      ),
      Note(
        guid: 'b2',
        content: 'Tài liệu Flutter',
        url: 'https://docs.flutter.dev',
        boardId: 'default',
        createdAt: _t(2),
      ),
      Note(
        guid: 'c3',
        content: 'Học tiếng Anh 30 phút mỗi ngày',
        boardId: 'default',
        createdAt: _t(3),
        emoji: '📚',
        colorIndex: 2,
      ),
      Note(
        guid: 'd4',
        content: 'Nhớ gọi điện hỏi thăm mẹ',
        boardId: 'default',
        createdAt: _t(4),
        emoji: '❤️',
        pinned: true,
        reminderAt: DateTime(2026, 8, 10, 18),
      ),
      Note(
        guid: 'e5',
        content: 'Bảng màu Material',
        url: 'https://m3.material.io',
        boardId: 'default',
        createdAt: _t(5),
      ),
      Note(
        guid: 'f6',
        content: 'Đặt lịch khám răng thứ Năm tuần sau',
        boardId: 'default',
        createdAt: _t(6),
        colorIndex: 4,
      ),
    ];

void main() {
  for (var i = 0; i < walls.length; i++) {
    testWidgets('preview wall ${walls[i].id}',
        // Screenshot generator, not a regression test. Remove `skip: true`
        // and run: flutter test --update-goldens test/preview_test.dart
        skip: true, (tester) async {
      await _loadRealFonts();
      SharedPreferences.setMockInitialValues({});
      final storage = await NoteStorage.create();
      await storage.saveBoards([Board(id: 'default', name: '', wallIndex: i)]);
      await storage.saveNotes(_sampleNotes());
      await storage.setViewMode(ViewMode.grid);
      await storage.setLanguageCode('vi');

      tester.view.physicalSize = const Size(1170, 2280);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(StickyWallApp(
        settings: SettingsController(storage),
        notes: NotesController(storage, ReminderService()),
      ));

      await tester.runAsync(() async {
        final context = tester.element(find.byType(Scaffold));
        for (final wall in walls) {
          await precacheImage(AssetImage(wall.asset), context);
        }
      });
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(StickyWallApp),
        matchesGoldenFile('preview_${walls[i].id}.png'),
      );
    });
  }
}
