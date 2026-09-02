import 'package:uuid/uuid.dart';

import '../l10n/app_localizations.dart';
import '../models/note.dart';

/// The notes a brand-new wall starts with: four stickies that each teach one
/// gesture, plus a thread between two of them so the yarn is discovered by
/// seeing it, not by reading about it.
class SampleNotes {
  const SampleNotes({required this.notes, required this.links});

  final List<Note> notes;
  final List<NoteLink> links;

  factory SampleNotes.build(AppLocalizations l10n, String boardId) {
    const uuid = Uuid();
    final now = DateTime.now();
    // Slightly staggered creation times keep the list/grid order stable.
    Note note(
      int i,
      String content, {
      required int color,
      required double x,
      required double y,
      NoteType type = NoteType.normal,
      List<ChecklistItem>? checklist,
    }) =>
        Note(
          guid: uuid.v4(),
          content: content,
          createdAt: now.subtract(Duration(minutes: 4 - i)),
          boardId: boardId,
          type: type,
          colorIndex: color,
          x: x,
          y: y,
          checklist: checklist,
        );

    final drag = note(0, l10n.sampleDrag, color: 0, x: 0.06, y: 0.04);
    final longPress = note(1, l10n.sampleLongPress, color: 1, x: 0.56, y: 0.12);
    final checklist = note(
      2,
      l10n.sampleChecklistTitle,
      color: 3,
      x: 0.08,
      y: 0.42,
      type: NoteType.checklist,
      checklist: [
        ChecklistItem(text: l10n.sampleChecklist1),
        ChecklistItem(text: l10n.sampleChecklist2),
        ChecklistItem(text: l10n.sampleChecklist3),
      ],
    );
    final thread = note(3, l10n.sampleThread, color: 2, x: 0.55, y: 0.52);

    return SampleNotes(
      notes: [drag, longPress, checklist, thread],
      links: [NoteLink(thread.guid, drag.guid)],
    );
  }
}
