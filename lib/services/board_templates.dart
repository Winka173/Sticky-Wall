import 'package:uuid/uuid.dart';

import '../l10n/app_localizations.dart';
import '../models/note.dart';
import '../theme.dart';

/// What a new board can start from: nothing, or a few tape labels laid out
/// as a planning board — locked, so the notes stuck under them can be moved
/// and tidied without nudging the headings.
enum BoardTemplate { blank, kanban, week, brainstorm }

/// The headings [template] puts on board [boardId], as fractions of the wall
/// like every note.
List<Note> templateNotes(
  BoardTemplate template,
  AppLocalizations l10n,
  String boardId,
) {
  const uuid = Uuid();
  final now = DateTime.now();
  var order = 0;
  Note label(String text, double x, double y, int color) => Note(
    guid: uuid.v4(),
    content: text,
    type: NoteType.label,
    locked: true,
    colorIndex: color,
    boardId: boardId,
    x: x,
    y: y,
    // Staggered so the list and grid keep the headings in reading order.
    createdAt: now.subtract(Duration(seconds: 60 - order++)),
  );

  switch (template) {
    case BoardTemplate.blank:
      return const [];
    case BoardTemplate.kanban:
      // Three columns across the top; their notes go underneath.
      return [
        label(l10n.kanbanTodo, 0.0, 0.0, 0),
        label(l10n.kanbanDoing, 0.5, 0.0, 3),
        label(l10n.kanbanDone, 1.0, 0.0, 2),
      ];
    case BoardTemplate.week:
      // Monday to Sunday down the left edge; the rest of the wall is for
      // what each day holds.
      final days = [
        l10n.dayMonday,
        l10n.dayTuesday,
        l10n.dayWednesday,
        l10n.dayThursday,
        l10n.dayFriday,
        l10n.daySaturday,
        l10n.daySunday,
      ];
      return [
        for (final (i, day) in days.indexed)
          label(day, 0.0, i / 6 * 0.9, i % AppColors.notePapers.length),
      ];
    case BoardTemplate.brainstorm:
      // One idea in the middle to tie the others to with threads.
      return [label(l10n.brainstormCenter, 0.5, 0.4, 0)];
  }
}
