import 'package:flutter/gestures.dart';
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

  group('web addresses', () {
    TapGestureRecognizer tap(String _) => TapGestureRecognizer();
    List<(String, bool)> links(String text, {Set<String> plain = const {}}) => [
      for (final s in noteSpans(
        text,
        _base,
        links: NoteLinkStyle(
          style: const TextStyle(decoration: TextDecoration.underline),
          recognizer: tap,
          plain: plain,
        ),
      ).cast<TextSpan>())
        (s.text!, s.recognizer != null),
    ];

    test('are found without the punctuation around them', () {
      expect(
        noteLinks(
          'See https://a.vn/x, then www.b.com/y. '
          '(Also https://wiki.org/A_(b)) and http://c.io!',
        ),
        [
          'https://a.vn/x',
          'www.b.com/y',
          'https://wiki.org/A_(b)',
          'http://c.io',
        ],
      );
      expect(noteLinks('https:// and www. alone, a.b.c'), isEmpty);
      expect(noteLinks('x https://a.vn\ny https://a.vn'), ['https://a.vn']);
    });

    test('become links, and the plain ones stay words', () {
      expect(links('Go to https://a.vn now'), [
        ('Go to ', false),
        ('https://a.vn', true),
        (' now', false),
      ]);
      expect(links('Go to https://a.vn now', plain: {'https://a.vn'}), [
        ('Go to ', false),
        ('https://a.vn', false),
        (' now', false),
      ]);
      // Without link styling the text is unchanged.
      expect(_runs('Go to https://a.vn now'), [
        ('Go to https://a.vn now', null, null),
      ]);
    });

    test('keep their underscores and stars out of the markup', () {
      const url = 'https://a.vn/_draft_/*x*/page';
      expect(plainNoteText('Read $url today'), 'Read $url today');
      expect(noteLinks('Read $url today'), [url]);
      // A whole address inside a marker still takes its style.
      final bold = noteSpans(
        '**www.a.vn**',
        _base,
        links: NoteLinkStyle(style: const TextStyle(), recognizer: tap),
      ).cast<TextSpan>().single;
      expect(bold.text, 'www.a.vn');
      expect(bold.style?.fontWeight, FontWeight.bold);
      expect(bold.recognizer, isNotNull);
    });
  });
}
