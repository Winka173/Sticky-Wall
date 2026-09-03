import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_wall/util/rich_note.dart';

const _base = TextStyle(fontSize: 10);

List<(String, FontWeight?, FontStyle?)> _runs(String text) => [
  for (final s in noteSpans(text, _base).cast<TextSpan>())
    (s.text!, s.style?.fontWeight, s.style?.fontStyle),
];

void main() {
  test('bold, italic and bullets are rendered, markers dropped', () {
    expect(_runs('Buy **milk** and *eggs*'), [
      ('Buy ', null, null),
      ('milk', FontWeight.bold, null),
      (' and ', null, null),
      ('eggs', null, FontStyle.italic),
    ]);
    expect(_runs('- one\n- two'), [
      ('•  ', null, null),
      ('one', null, null),
      ('\n', null, null),
      ('•  ', null, null),
      ('two', null, null),
    ]);
    expect(plainNoteText('**a** _b_\n* c'), 'a b\n•  c');
  });

  test('markers inside words and unmatched ones are left alone', () {
    expect(plainNoteText('snake_case_name'), 'snake_case_name');
    expect(plainNoteText('2*3*4'), '2*3*4');
    expect(plainNoteText('a ** b'), 'a ** b');
    expect(plainNoteText('lone *star'), 'lone *star');
    expect(hasNoteMarkup('plain'), false);
    expect(hasNoteMarkup('*x*'), true);
  });
}
