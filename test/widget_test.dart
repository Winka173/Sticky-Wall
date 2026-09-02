import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/main.dart';
import 'package:sticky_wall/models/draw_stroke.dart';
import 'package:sticky_wall/models/note.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/services/notes_controller.dart';
import 'package:sticky_wall/services/reminder_service.dart';
import 'package:sticky_wall/services/settings_controller.dart';

final _epoch = DateTime.fromMillisecondsSinceEpoch(0);

Note _note(String guid, String content, {String url = ''}) => Note(
      guid: guid,
      content: content,
      url: url,
      createdAt: _epoch,
      boardId: 'default',
    );

Future<StickyWallApp> _buildApp({List<Note> notes = const []}) async {
  final storage = await NoteStorage.create();
  await storage.saveNotes(notes);
  return StickyWallApp(
    settings: SettingsController(storage),
    notes: NotesController(storage, ReminderService()),
  );
}

void main() {
  testWidgets('shows empty state when there are no notes', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(await _buildApp());
    expect(find.textContaining('No notes yet'), findsOneWidget);
  });

  testWidgets('renders saved normal and link notes', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(await _buildApp(notes: [
      _note('1', 'hello world'),
      _note('2', 'Flutter docs', url: 'https://docs.flutter.dev'),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('hello world'), findsOneWidget);
    expect(find.text('Flutter docs'), findsOneWidget);
  });

  testWidgets('shows Vietnamese strings when language is vi', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await NoteStorage.create();
    await storage.setLanguageCode('vi');
    await tester.pumpWidget(StickyWallApp(
      settings: SettingsController(storage),
      notes: NotesController(storage, ReminderService()),
    ));
    await tester.pump();

    expect(find.text('Thêm ghi chú'), findsOneWidget);
    expect(find.textContaining('Chưa có ghi chú nào'), findsOneWidget);
  });

  test('note type is inferred from url for legacy data', () {
    expect(_note('a', 'x').type, NoteType.normal);
    expect(_note('b', 'x', url: 'https://a.b').type, NoteType.link);
  });

  test('fromJson converts legacy <br> line breaks', () {
    final note = Note.fromJson({'guid': 'c', 'content': 'l1<br>l2', 'url': ''});
    expect(note.content, 'l1\nl2');
  });

  test('emoji, checklist and reminder survive a JSON round-trip', () {
    final note = Note(
      guid: 'd',
      content: 'Groceries',
      createdAt: _epoch,
      boardId: 'default',
      type: NoteType.checklist,
      emoji: '🛒',
      colorIndex: 2,
      pinned: true,
      reminderAt: DateTime(2026, 8, 8, 9, 30),
      checklist: [ChecklistItem(text: 'milk', done: true)],
    );
    final round = Note.fromJson(note.toJson());
    expect(round.emoji, '🛒');
    expect(round.type, NoteType.checklist);
    expect(round.colorIndex, 2);
    expect(round.pinned, true);
    expect(round.reminderAt, DateTime(2026, 8, 8, 9, 30));
    expect(round.checklist.single.done, true);
  });

  test('drawing canvas survives a JSON round-trip and defaults when absent',
      () {
    final note = Note(
      guid: 'e',
      content: '',
      createdAt: _epoch,
      boardId: 'default',
      type: NoteType.drawing,
      canvas: const DrawCanvas(color: 0xFF2E3A36, pattern: CanvasPattern.grid),
    );
    final round = Note.fromJson(note.toJson());
    expect(round.canvas.color, 0xFF2E3A36);
    expect(round.canvas.pattern, CanvasPattern.grid);
    expect(round.canvas.isDark, true);

    // Notes saved before canvases existed load with the plain default paper.
    final legacy = note.toJson()..remove('canvas');
    expect(Note.fromJson(legacy).canvas, const DrawCanvas());
    expect(const DrawCanvas().isDark, false);
  });

  test('controller adds, deletes and undoes a note', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await NoteStorage.create();
    final c = NotesController(storage, ReminderService());

    final draft = c.draft()..content = 'test';
    c.add(draft);
    expect(c.boardNotes.length, 1);

    c.delete(draft);
    expect(c.boardNotes, isEmpty);
    expect(c.canUndo, true);

    c.undoDelete();
    expect(c.boardNotes.length, 1);
  });
}
