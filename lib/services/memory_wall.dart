import 'dart:math' as math;

import 'package:uuid/uuid.dart';

import '../models/note.dart';
import '../util/stable_hash.dart';
import 'theme_packs.dart';

/// How a memory wall lays its photos out.
enum MemoryLayout {
  /// Prints scattered and tilted, a little overlapping, like a scrapbook.
  collage,

  /// Straight rows of prints, evenly spaced.
  prints,

  /// Two strips of frames running down the wall, no tilt.
  film,

  /// One print after another down the wall, tied in order with threads.
  timeline,
}

/// The photos most of a phone screen can show at once; the rest of a
/// batch is laid out the same way and is a pan away.
const memoryWallMax = 20;

/// A memory wall's prints for board [boardId]: each photo a print of its
/// own (editable like any note: moved, turned, captioned, tied, stickered),
/// placed by [layout] within the wall, plus the threads a timeline ties.
/// [photos] are stored file names, in the order picked.
({List<Note> notes, List<NoteLink> links}) memoryWallNotes(
  List<String> photos,
  String boardId,
  MemoryLayout layout, {
  ThemePack? pack,
  String title = '',
  DateTime? now,
}) {
  const uuid = Uuid();
  final start = now ?? DateTime.now();
  final shown = photos.take(memoryWallMax).toList();
  final n = shown.length;
  final notes = <Note>[];
  var made = 0;
  Note place(Note note) {
    // Staggered so the grid and list keep the order the photos were picked.
    note.createdAt = start.subtract(Duration(seconds: n + 2 - made++));
    notes.add(note);
    return note;
  }

  // The title: a strip of tape across the top, out of the photos' way.
  final top = title.isEmpty ? 0.04 : 0.14;
  if (title.isNotEmpty) {
    place(
      Note(
        guid: uuid.v4(),
        content: title,
        type: NoteType.label,
        boardId: boardId,
        colorIndex: pack?.paperAt(0) ?? 0,
        locked: true,
        createdAt: start,
        x: 0.5,
        y: 0.0,
      ),
    );
  }

  // Columns and size from how many there are: a print is 168 px wide at
  // scale 1, and a phone wall is about 360 px.
  final columns = switch (layout) {
    MemoryLayout.film || MemoryLayout.timeline => 2,
    _ => n <= 4 ? 2 : (n <= 12 ? 3 : 4),
  };
  final rows = (n / columns).ceil();
  final double scale = switch (layout) {
    MemoryLayout.timeline => n <= 4 ? 0.9 : (n <= 8 ? 0.72 : 0.6),
    MemoryLayout.film => rows <= 3 ? 0.85 : (rows <= 5 ? 0.66 : 0.55),
    _ => switch (columns) {
      2 => 0.95,
      3 => 0.68,
      _ => 0.52,
    },
  };
  double rowY(int r) =>
      rows <= 1 ? (top + 0.3) : top + (0.98 - top) * r / (rows - 1);

  for (final (i, file) in shown.indexed) {
    final seed = stableHash('$boardId$file$i');
    final jitter = (seed % 1000) / 1000 - 0.5; // -0.5..0.5
    final jitter2 = ((seed ~/ 1000) % 1000) / 1000 - 0.5;
    double x;
    double y;
    double? rotation;
    switch (layout) {
      case MemoryLayout.collage:
        final c = i % columns;
        final r = i ~/ columns;
        x = columns == 1 ? 0.5 : c / (columns - 1);
        x = (x + jitter * 0.12).clamp(0.0, 1.0);
        y = (rowY(r) + jitter2 * 0.06).clamp(0.0, 1.0);
        rotation = jitter * 0.22;
      case MemoryLayout.prints:
        final c = i % columns;
        final r = i ~/ columns;
        x = columns == 1 ? 0.5 : c / (columns - 1);
        y = rowY(r);
        rotation = 0;
      case MemoryLayout.film:
        final c = i % 2;
        final r = i ~/ 2;
        x = c == 0 ? 0.08 : 0.92;
        y = rowY(r);
        rotation = 0;
      case MemoryLayout.timeline:
        // Down the wall, swinging left and right.
        final steps = math.max(n - 1, 1);
        x = i.isEven ? 0.0 : 1.0;
        y = n == 1 ? top + 0.3 : top + (0.98 - top) * i / steps;
        rotation = (i.isEven ? -1 : 1) * 0.04;
    }
    place(
      Note(
        guid: uuid.v4(),
        content: '',
        type: NoteType.photo,
        imagePath: file,
        boardId: boardId,
        createdAt: start,
        x: x,
        y: y,
        scale: scale,
        rotation: rotation,
      ),
    );
  }

  final prints = notes.where((n) => n.type == NoteType.photo).toList();
  final links = layout == MemoryLayout.timeline
      ? [
          for (var i = 0; i + 1 < prints.length; i++)
            NoteLink(
              prints[i].guid,
              prints[i + 1].guid,
              arrow: true,
              style: pack?.thread ?? ThreadStyle.yarn,
              color: pack?.yarn,
            ),
        ]
      : <NoteLink>[];
  return (notes: notes, links: links);
}
