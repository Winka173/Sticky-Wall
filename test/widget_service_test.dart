import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_wall/models/note.dart';
import 'package:sticky_wall/services/widget_service.dart';
import 'package:sticky_wall/theme.dart';

Note _note(String guid, {NoteType type = NoteType.normal}) => Note(
  guid: guid,
  content: '',
  type: type,
  createdAt: DateTime(2026),
  boardId: 'default',
);

void main() {
  test('the widget opens a note or a new note from its links', () {
    final open = WidgetTap.parse(Uri.parse('stickywall://note/abc-1'));
    expect(open, isA<WidgetOpenNote>());
    expect((open! as WidgetOpenNote).guid, 'abc-1');

    final add = WidgetTap.parse(Uri.parse('stickywall://new?board=b%202'));
    expect(add, isA<WidgetNewNote>());
    expect((add! as WidgetNewNote).boardId, 'b 2');

    // A plain tap on the widget, or anything else, just opens the app.
    expect(WidgetTap.parse(null), isNull);
    expect(WidgetTap.parse(Uri.parse('')), isNull);
    expect(WidgetTap.parse(Uri.parse('stickywall://note')), isNull);
    expect(WidgetTap.parse(Uri.parse('https://example.com/note/x')), isNull);
  });

  test('a to-do line says how far along the list is', () {
    final list = _note('l', type: NoteType.checklist)
      ..content = 'Shopping'
      ..checklist = [
        ChecklistItem(text: 'milk', done: true),
        ChecklistItem(text: 'eggs'),
        ChecklistItem(text: ' '),
      ];
    expect(
      WidgetService.lineFor(list, 'To-do', 'Drawing', 'Photo', 'Voice'),
      'Shopping · 1/2',
    );

    final untitled = _note('u', type: NoteType.checklist)
      ..checklist = [ChecklistItem(text: 'a')];
    expect(
      WidgetService.lineFor(untitled, 'To-do', 'Drawing', 'Photo', 'Voice'),
      'To-do · 0/1',
    );

    // An empty list and other kinds carry no count.
    expect(
      WidgetService.lineFor(
        _note('e', type: NoteType.checklist),
        'To-do',
        'Drawing',
        'Photo',
        'Voice',
      ),
      'To-do',
    );
    expect(
      WidgetService.lineFor(
        _note('t')..content = '**Call** mum',
        'To-do',
        'Drawing',
        'Photo',
        'Voice',
      ),
      'Call mum',
    );
  });

  test("a line's dot is the note's paper, or a print's white", () {
    final note = _note('p')..colorIndex = 2;
    expect(WidgetService.dotColor(note), noteColor(2, 'p'));
    expect(
      WidgetService.dotColor(_note('ph', type: NoteType.photo)),
      AppColors.printPaper,
    );
  });
}
