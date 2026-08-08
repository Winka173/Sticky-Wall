import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/main.dart';
import 'package:sticky_wall/models/note.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/services/settings_controller.dart';

Future<StickyWallApp> _buildApp() async {
  final storage = await NoteStorage.create();
  return StickyWallApp(
    storage: storage,
    settings: SettingsController(storage),
  );
}

void main() {
  testWidgets('shows empty state when there are no notes',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(await _buildApp());
    expect(find.textContaining('No notes yet'), findsOneWidget);
  });

  testWidgets('renders saved normal and link notes',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await NoteStorage.create();
    await storage.saveNotes([
      Note(guid: '1', content: 'hello world'),
      Note(guid: '2', content: 'Flutter docs', url: 'https://docs.flutter.dev'),
    ]);

    await tester.pumpWidget(
      StickyWallApp(storage: storage, settings: SettingsController(storage)),
    );

    expect(find.text('hello world'), findsOneWidget);
    expect(find.text('Flutter docs:'), findsOneWidget);
    expect(find.text('https://docs.flutter.dev'), findsOneWidget);
  });

  testWidgets('shows Vietnamese strings when language is vi',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await NoteStorage.create();
    await storage.setLanguageCode('vi');

    await tester.pumpWidget(
      StickyWallApp(storage: storage, settings: SettingsController(storage)),
    );
    await tester.pump();

    expect(find.text('Thêm ghi chú'), findsOneWidget);
    expect(find.textContaining('Chưa có ghi chú nào'), findsOneWidget);
  });

  test('note type is inferred from url', () {
    expect(Note(guid: 'a', content: 'x').type, NoteType.normal);
    expect(Note(guid: 'b', content: 'x', url: 'https://a.b').type,
        NoteType.link);
  });

  test('fromJson converts legacy <br> line breaks', () {
    final note = Note.fromJson({
      'guid': 'c',
      'content': 'line1<br>line2',
      'url': '',
    });
    expect(note.content, 'line1\nline2');
  });
}
