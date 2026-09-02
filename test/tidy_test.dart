import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_wall/l10n/app_localizations.dart';
import 'package:sticky_wall/models/note.dart';
import 'package:sticky_wall/theme.dart';
import 'package:sticky_wall/widgets/note_views.dart';
import 'package:sticky_wall/widgets/wall_view.dart';

final _epoch = DateTime.fromMillisecondsSinceEpoch(0);

Note _note(String guid, String content, {double x = 0, double y = 0}) => Note(
      guid: guid,
      content: content,
      createdAt: _epoch,
      boardId: 'default',
    )
      ..x = x
      ..y = y;

const _noop = NoteCallbacks(
  onEdit: _nothing,
  onTogglePin: _nothing,
  onToggleItem: _nothingIndex,
  onLongPress: _nothing,
);
void _nothing() {}
void _nothingIndex(int _) {}

/// A wall of the given size hosting [notes]; tidy results are applied to the
/// notes in place and the wall rebuilt, like the real controller does.
class _Host extends StatefulWidget {
  const _Host(this.notes, this.handle, this.keys, {required this.size});
  final List<Note> notes;
  final WallHandle handle;
  final Map<String, GlobalKey> keys;
  final Size size;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: buildAppTheme(fontChoices.first),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: SizedBox.fromSize(
            size: widget.size,
            child: WallView(
              notes: widget.notes,
              callbacksFor: (_) => _noop,
              onMove: (_, _, _) {},
              onResize: (_, _) {},
              onBringToFront: (_) {},
              onCreateAt: (_, _) {},
              handle: widget.handle,
              captureKeys: widget.keys,
              onArrange: (placements) => setState(() {
                for (final (note, x, y, scale) in placements) {
                  note
                    ..x = x.clamp(0.0, 1.0)
                    ..y = y.clamp(0.0, 1.0)
                    ..scale = scale;
                }
              }),
            ),
          ),
        ),
      ),
    );
  }
}

Rect _paperRect(WidgetTester tester, GlobalKey key) {
  final box = key.currentContext!.findRenderObject()! as RenderBox;
  return box.localToGlobal(Offset.zero) & box.size;
}

void main() {
  testWidgets('tidy packs rows without overlap or excess air', (tester) async {
    // A mix of one-liners and long notes that wrap to the 6-line cap, so a
    // fixed-height guess would get the rows wrong in both directions.
    final notes = [
      _note('a', 'Milk', x: 0.7, y: 0.6),
      _note('b', 'A much longer note that wraps over several lines on the '
          'card and keeps going well past what a short note needs, so its '
          'row has to be taller than the others around it.', x: 0.1, y: 0.1),
      _note('c', 'Call mum', x: 0.4, y: 0.4),
      _note('d', 'Two lines\nof text', x: 0.9, y: 0.2),
      _note('e', 'Another long one: groceries, then the post office, then '
          'pick up the parcel, then finally remember to water the plants '
          'before they give up on me entirely.', x: 0.2, y: 0.8),
    ];
    final keys = {for (final n in notes) n.guid: GlobalKey()};
    final handle = WallHandle();
    await tester.pumpWidget(
        _Host(notes, handle, keys, size: const Size(392, 1400)));
    await tester.pumpAndSettle();

    handle.tidy();
    // One frame lays the probes out, the next applies the result; then the
    // notes glide into place.
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    // Two columns fit at full size on a 392-wide wall.
    expect(notes.every((n) => n.scale == 1.0), isTrue);

    final rects = {for (final n in notes) n.guid: _paperRect(tester, keys[n.guid]!)};
    final ordered = rects.values.toList()
      ..sort((a, b) => a.top != b.top ? a.top.compareTo(b.top) : a.left.compareTo(b.left));

    // Nothing overlaps.
    for (var i = 0; i < ordered.length; i++) {
      for (var j = i + 1; j < ordered.length; j++) {
        expect(ordered[i].overlaps(ordered[j]), isFalse,
            reason: 'cards $i and $j overlap: ${ordered[i]} vs ${ordered[j]}');
      }
    }

    // Rows are separated by the pin overhang plus a little air — not by
    // the whole height of a card, as the old estimate produced.
    final rowTops = ordered.map((r) => r.top.roundToDouble()).toSet().toList()
      ..sort();
    expect(rowTops.length, 3);
    for (var i = 1; i < rowTops.length; i++) {
      final above = ordered.where((r) => r.top.roundToDouble() == rowTops[i - 1]);
      final bottom = above.map((r) => r.bottom).reduce((a, b) => a > b ? a : b);
      final gap = rowTops[i] - bottom;
      expect(gap, greaterThanOrEqualTo(14), reason: 'row $i too close');
      expect(gap, lessThanOrEqualTo(48), reason: 'row $i too far apart');
    }
  });

  testWidgets('tidy shrinks cards when full size would not fit', (tester) async {
    final notes = [
      for (var i = 0; i < 8; i++)
        _note('$i', 'Note $i with a line or two of text in it', y: i / 8),
    ];
    final keys = {for (final n in notes) n.guid: GlobalKey()};
    final handle = WallHandle();
    await tester.pumpWidget(
        _Host(notes, handle, keys, size: const Size(392, 520)));
    await tester.pumpAndSettle();

    handle.tidy();
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    // Three narrower columns instead of two full-size ones.
    expect(notes.every((n) => n.scale < 1.0), isTrue);
    final lefts = notes.map((n) => n.x).toSet();
    expect(lefts.length, 3);
  });
}
