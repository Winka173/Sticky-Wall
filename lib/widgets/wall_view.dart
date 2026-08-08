import 'package:flutter/material.dart';

import '../models/note.dart';
import 'note_views.dart';

/// The free-form "wall": notes sit at absolute positions and can be dragged
/// anywhere. Tapping empty space creates a note there.
class WallView extends StatefulWidget {
  const WallView({
    super.key,
    required this.notes,
    required this.callbacksFor,
    required this.onMove,
    required this.onBringToFront,
    required this.onCreateAt,
  });

  final List<Note> notes;
  final NoteCallbacks Function(Note) callbacksFor;
  final void Function(Note note, double x, double y) onMove;
  final void Function(Note note) onBringToFront;
  final void Function(double x, double y) onCreateAt;

  @override
  State<WallView> createState() => _WallViewState();
}

class _WallViewState extends State<WallView> {
  static const double _cardWidth = 168;

  // While dragging, the live top-left offset in pixels (not yet committed).
  String? _draggingGuid;
  Offset _dragTopLeft = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final maxLeft = (w - _cardWidth).clamp(0.0, w);

        return Stack(
          children: [
            // Tap empty space to create a note there.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) {
                  final x = (d.localPosition.dx - _cardWidth / 2) / w;
                  final y = (d.localPosition.dy - 30) / h;
                  widget.onCreateAt(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0));
                },
              ),
            ),
            for (final note in widget.notes)
              _positioned(note, w, h, maxLeft),
          ],
        );
      },
    );
  }

  Widget _positioned(Note note, double w, double h, double maxLeft) {
    final dragging = _draggingGuid == note.guid;
    final left = dragging ? _dragTopLeft.dx : note.x * maxLeft;
    final top = dragging ? _dragTopLeft.dy : note.y * (h - 80);

    return Positioned(
      left: left.clamp(0.0, maxLeft),
      top: top.clamp(0.0, (h - 60).clamp(0.0, h)),
      width: _cardWidth,
      child: GestureDetector(
        onPanStart: (_) {
          widget.onBringToFront(note);
          setState(() {
            _draggingGuid = note.guid;
            _dragTopLeft = Offset(note.x * maxLeft, note.y * (h - 80));
          });
        },
        onPanUpdate: (d) => setState(() => _dragTopLeft += d.delta),
        onPanEnd: (_) {
          final x = maxLeft == 0 ? 0.0 : _dragTopLeft.dx / maxLeft;
          final y = (h - 80) == 0 ? 0.0 : _dragTopLeft.dy / (h - 80);
          widget.onMove(note, x, y);
          setState(() => _draggingGuid = null);
        },
        child: AnimatedScale(
          scale: dragging ? 1.06 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: StickyNoteCard(
            note: note,
            cb: widget.callbacksFor(note),
            raised: dragging,
            maxContentLines: 6,
          ),
        ),
      ),
    );
  }
}
