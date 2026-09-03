/// Light inline markup for the text on a note — the few things a sticky
/// note ever needs: `**bold**`, `*italic*` or `_italic_`, and a line that
/// starts with `- ` (or `* `, `• `) as a bullet. Anything else is shown
/// exactly as typed, so a stray asterisk or an underscore inside a word
/// (`snake_case`) is left alone: a marker only counts at a word boundary,
/// hugging its text.
library;

import 'package:flutter/painting.dart';

final _bullet = RegExp(r'^(\s*)[-*•]\s+');
final _marker = RegExp(
  r'\*\*(.+?)\*\*|\*([^*\s](?:[^*]*?[^*\s])?)\*|'
  r'_([^_\s](?:[^_]*?[^_\s])?)_',
);

bool _isWord(String s, int i) =>
    i >= 0 && i < s.length && RegExp(r'\w').hasMatch(s[i]);

/// The text of a note as spans, with the markup applied and the markers
/// themselves gone. [base] is the style plain runs get.
List<InlineSpan> noteSpans(String text, TextStyle base) {
  final lines = text.split('\n');
  final out = <InlineSpan>[];
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i];
    final bullet = _bullet.firstMatch(line);
    if (bullet != null) {
      line = line.substring(bullet.end);
      out.add(TextSpan(text: '${bullet.group(1)}•  ', style: base));
    }
    out.addAll(_inline(line, base));
    if (i < lines.length - 1) out.add(TextSpan(text: '\n', style: base));
  }
  return out;
}

List<InlineSpan> _inline(String line, TextStyle base) {
  final out = <InlineSpan>[];
  var from = 0;
  var plainStart = 0;
  void flush(int end) {
    if (end > plainStart) {
      out.add(TextSpan(text: line.substring(plainStart, end), style: base));
    }
  }

  while (from < line.length) {
    final m = _marker.firstMatch(line.substring(from));
    if (m == null) break;
    final start = from + m.start;
    final end = from + m.end;
    final bold = m.group(1);
    final inner = bold ?? m.group(2) ?? m.group(3)!;
    // A single marker must sit at a word boundary; `a*b*c` stays as is.
    final single = bold == null;
    if (single && (_isWord(line, start - 1) || _isWord(line, end))) {
      from = start + 1;
      continue;
    }
    flush(start);
    out.add(
      TextSpan(
        text: inner,
        style: base.copyWith(
          fontWeight: bold != null ? FontWeight.bold : null,
          fontStyle: single ? FontStyle.italic : null,
        ),
      ),
    );
    from = plainStart = end;
  }
  flush(line.length);
  return out;
}

/// The note's text with the markers taken out — bullets become `•` — for
/// search, the trash, the home-screen widget and anywhere else words are
/// read rather than laid out.
String plainNoteText(String text) => noteSpans(
  text,
  const TextStyle(),
).map((s) => (s as TextSpan).text ?? '').join();

/// Whether the text carries any markup worth rendering.
bool hasNoteMarkup(String text) => plainNoteText(text) != text;
