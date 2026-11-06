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

  /// One photo large in the middle, the others smaller around it.
  hero,
}

/// What is written under each print when a memory wall is made.
enum CaptionPreset { none, numbers, date }

/// The photos most of a phone screen can show at once; the rest of a
/// batch is laid out the same way and is a pan away.
const memoryWallMax = 20;

/// Where [n] prints go for [layout], as fractions of the wall like every
/// note, below a title strip when [top] leaves room for one. [seed] makes a
/// collage's scatter (and a hero's ring) differ from one shuffle to the
/// next, and the same for the same seed.
List<({double x, double y, double scale, double? rotation})> memoryPositions(
  int n,
  MemoryLayout layout, {
  double top = 0.04,
  String seed = '',
}) {
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
    MemoryLayout.hero => n <= 5 ? 0.62 : (n <= 9 ? 0.52 : 0.44),
    _ => switch (columns) {
      2 => 0.95,
      3 => 0.68,
      _ => 0.52,
    },
  };
  // Rows sit a print's height apart (not spread over the whole wall, which
  // left a few photos stranded at the top and the foot), and the block sits
  // a little above the middle. Many rows still fit, closer together.
  final span = 0.98 - top;
  final rowStep = rows <= 1 ? 0.0 : math.min(span / (rows - 1), 0.46 * scale);
  final rowStart = top + (span - rowStep * (rows - 1)) * 0.3;
  double rowY(int r) => rows <= 1 ? (top + span * 0.3) : rowStart + rowStep * r;

  final out = <({double x, double y, double scale, double? rotation})>[];
  for (var i = 0; i < n; i++) {
    final h = stableHash('$seed#$i');
    final jitter = (h % 1000) / 1000 - 0.5; // -0.5..0.5
    final jitter2 = ((h ~/ 1000) % 1000) / 1000 - 0.5;
    switch (layout) {
      case MemoryLayout.collage:
        final c = i % columns;
        final r = i ~/ columns;
        final x = columns == 1 ? 0.5 : c / (columns - 1);
        out.add((
          x: (x + jitter * 0.12).clamp(0.0, 1.0),
          y: (rowY(r) + jitter2 * 0.06).clamp(0.0, 1.0),
          scale: scale,
          rotation: jitter * 0.22,
        ));
      case MemoryLayout.prints:
        final c = i % columns;
        out.add((
          x: columns == 1 ? 0.5 : c / (columns - 1),
          y: rowY(i ~/ columns),
          scale: scale,
          rotation: 0,
        ));
      case MemoryLayout.film:
        out.add((
          x: i.isEven ? 0.08 : 0.92,
          y: rowY(i ~/ 2),
          scale: scale,
          rotation: 0,
        ));
      case MemoryLayout.timeline:
        // Down the wall, swinging left and right, each step a bit less
        // than a print's height (they alternate sides).
        final steps = math.max(n - 1, 1);
        final step = math.min(span / steps, 0.3 * scale);
        final start = top + (span - step * steps) * 0.3;
        out.add((
          x: i.isEven ? 0.0 : 1.0,
          y: n == 1 ? top + span * 0.3 : start + step * i,
          scale: scale,
          rotation: (i.isEven ? -1 : 1) * 0.04,
        ));
      case MemoryLayout.hero:
        if (i == 0) {
          out.add((x: 0.5, y: top + 0.22, scale: 1.25, rotation: 0));
          continue;
        }
        // The rest in two arcs: beside and below the hero, then a row at
        // the foot.
        final k = i - 1;
        final around = n - 1;
        final t = around == 1 ? 0.5 : k / (around - 1);
        final x = (k.isEven ? 0.0 : 1.0);
        final y = top + 0.02 + t * (0.96 - top);
        out.add((
          x: (x + jitter * 0.06).clamp(0.0, 1.0),
          y: y.clamp(0.0, 1.0),
          scale: scale,
          rotation: jitter * 0.14,
        ));
    }
  }
  return out;
}

/// A memory wall's prints for board [boardId]: each photo a print of its
/// own (editable like any note: moved, turned, captioned, tied, stickered),
/// placed by [layout] within the wall, in [frame], with [caption] written
/// under each ([date] is what the date caption says), plus the threads a
/// timeline ties. [photos] are stored file names, in the order picked.
({List<Note> notes, List<NoteLink> links}) memoryWallNotes(
  List<String> photos,
  String boardId,
  MemoryLayout layout, {
  ThemePack? pack,
  String title = '',
  PhotoFrame frame = PhotoFrame.print,
  CaptionPreset caption = CaptionPreset.none,
  String date = '',
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

  final spots = memoryPositions(n, layout, top: top, seed: boardId);
  for (final (i, file) in shown.indexed) {
    final spot = spots[i];
    place(
      Note(
        guid: uuid.v4(),
        content: switch (caption) {
          CaptionPreset.none => '',
          CaptionPreset.numbers => '${i + 1}',
          CaptionPreset.date => date,
        },
        type: NoteType.photo,
        imagePath: file,
        frame: frame,
        boardId: boardId,
        colorIndex: pack?.paperAt(i),
        createdAt: start,
        x: spot.x,
        y: spot.y,
        scale: spot.scale,
        rotation: spot.rotation,
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
