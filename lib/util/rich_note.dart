/// Light inline markup for the text on a note — the few things a sticky
/// note ever needs: `**bold**`, `*italic*` or `_italic_`, and a line that
/// starts with `- ` (or `* `, `• `) as a bullet. Anything else is shown
/// exactly as typed, so a stray asterisk or an underscore inside a word
/// (`snake_case`) is left alone: a marker only counts at a word boundary,
/// hugging its text. Web addresses (`https://…`, `www.…`) are left out of
/// the markup, and can be drawn as links (see [noteSpans]).
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/painting.dart';

final _bullet = RegExp(r'^(\s*)[-*•]\s+');
final _marker = RegExp(
  r'\*\*(.+?)\*\*|\*([^*\s](?:[^*]*?[^*\s])?)\*|'
  r'_([^_\s](?:[^_]*?[^_\s])?)_',
);

/// A web address: `http://`, `https://` or `www.` up to the next space.
final _url = RegExp(r'(?:https?://|www\.)[^\s<>"]+', caseSensitive: false);

/// Punctuation that ends a sentence (or closes `**bold**`, `_italic_`)
/// rather than an address.
const _trailing = '.,;:!?\'"*_';

/// Where the web addresses in [line] are, without the full stop, comma or
/// closing bracket of the sentence around them.
List<(int, int)> _urls(String line) => [
  for (final m in _url.allMatches(line))
    if (_trim(line, m.start, m.end) case final end
        when end - m.start > (line.startsWith('www.', m.start) ? 5 : 8))
      (m.start, end),
];

int _trim(String line, int start, int end) {
  while (end > start) {
    final c = line[end - 1];
    final url = line.substring(start, end);
    // A bracket closes the address only when the address opened one.
    final unbalanced =
        c == ')' && ')'.allMatches(url).length > '('.allMatches(url).length;
    if (!_trailing.contains(c) && !unbalanced) break;
    end--;
  }
  return end;
}

/// The web addresses in [text], each once, in the order they appear.
List<String> noteLinks(String text) {
  final out = <String>[];
  for (final line in text.split('\n')) {
    for (final (a, b) in _urls(line)) {
      final url = line.substring(a, b);
      if (!out.contains(url)) out.add(url);
    }
  }
  return out;
}

/// How [noteSpans] draws the web addresses it finds.
class NoteLinkStyle {
  const NoteLinkStyle({
    required this.style,
    required this.recognizer,
    this.plain = const {},
  });

  /// Laid over the run's own style (bold or italic stays).
  final TextStyle style;

  /// Opens the address; the caller owns and disposes it.
  final GestureRecognizer Function(String url) recognizer;

  /// Addresses the user turned back into plain words.
  final Set<String> plain;
}

bool _isWord(String s, int i) =>
    i >= 0 && i < s.length && RegExp(r'\w').hasMatch(s[i]);

/// The text of a note as spans, with the markup applied and the markers
/// themselves gone. [base] is the style plain runs get. With [links], web
/// addresses become links (except the ones it lists as plain).
List<InlineSpan> noteSpans(
  String text,
  TextStyle base, {
  NoteLinkStyle? links,
}) {
  final lines = text.split('\n');
  final out = <InlineSpan>[];
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i];
    final bullet = _bullet.firstMatch(line);
    if (bullet != null) {
      line = line.substring(bullet.end);
      out.add(TextSpan(text: '${bullet.group(1)}•  ', style: base));
    }
    out.addAll(_inline(line, base, links));
    if (i < lines.length - 1) out.add(TextSpan(text: '\n', style: base));
  }
  return out;
}

List<InlineSpan> _inline(String line, TextStyle base, NoteLinkStyle? links) {
  final out = <InlineSpan>[];
  final urls = _urls(line);
  var from = 0;
  var plainStart = 0;
  void emit(String run, TextStyle style) {
    if (links == null) {
      out.add(TextSpan(text: run, style: style));
      return;
    }
    var at = 0;
    for (final (a, b) in _urls(run)) {
      if (a > at) out.add(TextSpan(text: run.substring(at, a), style: style));
      final url = run.substring(a, b);
      out.add(
        links.plain.contains(url)
            ? TextSpan(text: url, style: style)
            : TextSpan(
                text: url,
                style: style.merge(links.style),
                recognizer: links.recognizer(url),
              ),
      );
      at = b;
    }
    if (at < run.length) {
      out.add(TextSpan(text: run.substring(at), style: style));
    }
  }

  void flush(int end) {
    if (end > plainStart) emit(line.substring(plainStart, end), base);
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
    final mark = single ? 1 : 2;
    // A marker that is part of a web address (`…/_draft_/`) is no marker; a
    // whole address inside one (`**www.a.vn**`) still takes its style.
    final inAddress = urls.any(
      (u) =>
          u.$1 < end &&
          start < u.$2 &&
          !(u.$1 >= start + mark && u.$2 <= end - mark),
    );
    if (inAddress ||
        (single && (_isWord(line, start - 1) || _isWord(line, end)))) {
      from = start + 1;
      continue;
    }
    flush(start);
    emit(
      inner,
      base.copyWith(
        fontWeight: bold != null ? FontWeight.bold : null,
        fontStyle: single ? FontStyle.italic : null,
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
