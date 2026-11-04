import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/models/board.dart';
import 'package:sticky_wall/models/note.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/services/notes_controller.dart';
import 'package:sticky_wall/services/reminder_service.dart';
import 'package:sticky_wall/services/template_library.dart';
import 'package:sticky_wall/services/theme_packs.dart';
import 'package:sticky_wall/theme.dart';
import 'package:sticky_wall/widgets/stickers.dart';

/// The bundled library, read from disk: what ships is what is checked.
List<BoardTemplateDef> _library() => TemplateLibrary.parse(
  File('assets/templates/templates.json').readAsStringSync(),
);

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

Future<NotesController> _controller() async {
  SharedPreferences.setMockInitialValues({});
  final storage = await NoteStorage.create();
  await storage.saveBoards([Board(id: 'default', name: '')]);
  await storage.saveNotes([]);
  return NotesController(storage, ReminderService());
}

void main() {
  group('Board template library', () {
    final library = _library();

    test('holds 40–60 templates with unique ids', () {
      expect(library.length, inInclusiveRange(40, 60));
      final ids = library.map((t) => t.id).toSet();
      expect(ids.length, library.length);
    });

    test('every shelf has templates', () {
      for (final c in TemplateCategory.values) {
        expect(
          library.where((t) => t.category == c),
          isNotEmpty,
          reason: c.name,
        );
      }
    });

    test('every template is complete, in both languages', () {
      final stickerIds = {for (final s in stickers) s.id};
      for (final t in library) {
        final why = t.id;
        expect(t.name.en, isNotEmpty, reason: why);
        expect(t.name.vi, isNotEmpty, reason: why);
        expect(t.description.en, isNotEmpty, reason: why);
        expect(t.description.vi, isNotEmpty, reason: why);
        expect(t.tags, isNotEmpty, reason: why);
        expect(themePackById(t.theme), isNotNull, reason: '$why theme');
        expect(t.items.length, greaterThanOrEqualTo(3), reason: why);
        for (final item in t.items) {
          expect(item.x, inInclusiveRange(0, 1), reason: why);
          expect(item.y, inInclusiveRange(0, 1), reason: why);
          expect(item.scale, inInclusiveRange(0.6, 1.3), reason: why);
          expect(
            ['label', 'note', 'checklist', 'sticker'],
            contains(item.kind),
            reason: why,
          );
          if (item.kind == 'sticker') {
            expect(stickerIds, contains(item.sticker), reason: why);
            // Templates are free to use: no Pro sticker comes with one.
            final sticker = stickers.firstWhere((s) => s.id == item.sticker);
            expect(sticker.pro, isFalse, reason: '$why ${item.sticker}');
          } else {
            expect(item.text.en, isNotEmpty, reason: why);
            expect(item.text.vi, isNotEmpty, reason: why);
          }
          for (final line in item.items) {
            expect(line.en.isNotEmpty && line.vi.isNotEmpty, isTrue);
          }
        }
        for (final th in t.threads) {
          expect(th.from, inInclusiveRange(0, t.items.length - 1));
          expect(th.to, inInclusiveRange(0, t.items.length - 1));
          expect(th.from, isNot(th.to), reason: why);
        }
      }
    });

    test('no two templates share a layout', () {
      final seen = <String, String>{};
      for (final t in library) {
        final signature = [
          for (final i in t.items)
            '${i.kind}@${i.x.toStringAsFixed(2)},${i.y.toStringAsFixed(2)}',
        ].join('|');
        expect(
          seen[signature],
          isNull,
          reason: '${t.id} has the layout of ${seen[signature]}',
        );
        seen[signature] = t.id;
      }
    });

    test('builds real, editable notes and threads', () {
      final kanban = library.firstWhere((t) => t.id == 'kanban_lite');
      final pack = themePackById('clean_office')!;
      final made = kanban.build('b', 'vi', pack: pack);
      expect(made.notes.length, kanban.items.length);
      expect(made.notes.first.content, 'Cần làm');
      expect(made.notes.first.locked, isTrue, reason: 'headings hold still');
      expect(made.notes.first.sample, isFalse);
      final example = made.notes.firstWhere((n) => n.type == NoteType.normal);
      expect(example.sample, isTrue);
      expect(example.locked, isFalse);
      expect(made.notes.every((n) => n.boardId == 'b'), isTrue);
      // The template's colour slots go through the pack's papers.
      expect(made.notes.first.colorIndex, pack.paperAt(0));

      final story = library.firstWhere((t) => t.id == 'storyboard');
      final built = story.build('s', 'en');
      expect(built.links.length, story.threads.length);
      final ids = {for (final n in built.notes) n.guid};
      expect(
        built.links.every((l) => ids.contains(l.a) && ids.contains(l.b)),
        isTrue,
      );
      expect(built.links.first.arrow, isTrue);
    });

    test(
      'a board from a template; its examples clear, the layout stays',
      () async {
        final c = await _controller();
        final t = library.firstWhere((t) => t.id == 'weekly_planner');
        final board = c.addBoardFromTemplate(
          t,
          'en',
          pack: themePackById('clean_office'),
        );
        expect(c.currentBoardId, board.id);
        expect(board.name, 'Weekly Planner');
        expect(board.themeId, 'clean_office');
        expect(board.fontId, 'bevietnam');
        expect(c.boardNotes.length, t.items.length);
        final labels = c.boardNotes
            .where((n) => n.type == NoteType.label)
            .length;

        final cleared = c.clearSamples(board.id);
        expect(cleared, greaterThan(0));
        expect(c.boardNotes.length, labels);
        c.undoDelete();
        expect(c.boardNotes.length, t.items.length);

        // An example written on is the user's own note: it stays.
        final example = c.boardNotes.firstWhere((n) => n.sample);
        c.update(example.clone()..content = 'Mine now');
        c.clearSamples(board.id);
        expect(c.boardNotes.any((n) => n.content == 'Mine now'), isTrue);
      },
    );
  });

  group('Theme packs', () {
    test('30–40 packs, unique ids and looks', () {
      expect(themePacks.length, inInclusiveRange(30, 40));
      expect(themePacks.map((t) => t.id).toSet().length, themePacks.length);
      final looks = {
        for (final t in themePacks)
          '${t.wall}|${t.font}|${t.pin.name}|${t.papers.join(',')}',
      };
      expect(looks.length, themePacks.length);
    });

    test('every pack points at a real wall and font, readable papers', () {
      for (final t in themePacks) {
        expect(walls.any((w) => w.id == t.wall), isTrue, reason: t.id);
        expect(fontChoices.any((f) => f.id == t.font), isTrue, reason: t.id);
        expect(t.papers, isNotEmpty, reason: t.id);
        expect(t.nameEn.isNotEmpty && t.nameVi.isNotEmpty, isTrue);
        for (final p in t.papers) {
          expect(
            _contrast(noteColor(p, 'x'), AppColors.ink),
            greaterThanOrEqualTo(7),
            reason: '${t.id}: ink on paper $p',
          );
        }
        final stickerIds = {for (final s in stickers) s.id};
        for (final s in t.stickers) {
          expect(stickerIds, contains(s), reason: '${t.id} $s');
        }
      }
    });

    test('every Pro pack has a free twin, shown and used without Pro', () {
      for (final t in themePacks) {
        final free = lookFor(t, pro: false);
        expect(free.pro, isFalse, reason: t.id);
        expect(lookFor(t, pro: true), same(t));
        if (!t.pro) expect(free, same(t));
      }
    });

    test('no pack uses a face too narrow for the app around it', () {
      for (final t in themePacks) {
        expect(t.font, isNot('amatic'), reason: t.id);
      }
    });

    test('free packs use only free things; the rest are marked Pro', () {
      final free = themePacks.where((t) => !t.pro).toList();
      expect(free.length, greaterThanOrEqualTo(12));
      for (final t in free) {
        expect(t.wallStyle.pro, isFalse, reason: t.id);
        expect(fontChoiceById(t.font).pro, isFalse, reason: t.id);
      }
      expect(themePackById('lunar_new_year')!.pro, isTrue);
      expect(themePackById('cork_classic')!.pro, isFalse);
    });

    test('applying a pack changes the look only, and undoes', () async {
      final c = await _controller();
      final a = Note(
        guid: 'a',
        content: 'Keep my words',
        createdAt: DateTime(2026),
        boardId: 'default',
        colorIndex: 0,
        x: 0.2,
        y: 0.3,
      );
      final b = Note(
        guid: 'b',
        content: '',
        type: NoteType.photo,
        imagePath: 'p.jpg',
        createdAt: DateTime(2026, 2),
        boardId: 'default',
      );
      c
        ..seed([a, b], links: const [NoteLink('a', 'b')])
        ..selectBoard('default');
      final pack = themePackById('botanical_green')!;
      final undo = c.applyTheme('default', pack);
      final board = c.currentBoard;
      expect(board.wallIndex, pack.wallIndex);
      expect(board.fontId, 'lora');
      expect(board.pinStyle, 'tack');
      expect(a.colorIndex, pack.paperAt(0));
      expect(a.paper, PaperStyle.lined);
      expect(a.content, 'Keep my words');
      expect((a.x, a.y), (0.2, 0.3));
      expect(b.colorIndex, isNull, reason: 'a print keeps its white');
      expect(c.links.single.style, ThreadStyle.twine);

      undo();
      expect(c.currentBoard.wallIndex, 0);
      expect(c.currentBoard.fontId, '');
      expect(a.colorIndex, 0);
      expect(a.paper, PaperStyle.plain);
      expect(c.links.single.style, ThreadStyle.yarn);
    });
  });

  group('Illustrated stickers', () {
    final manifest =
        (jsonDecode(
                  File(
                    'docs/design/STICKY_VISUAL_ASSET_MANIFEST.json',
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>)['assets']
            as List<dynamic>;

    test('every manifest entry is a bundled file the app lists', () {
      final art = {for (final s in stickers) s.id: s};
      for (final m in manifest.cast<Map<String, dynamic>>()) {
        final file = File(m['path'] as String);
        expect(file.existsSync(), isTrue, reason: m['path'] as String);
        expect(file.lengthSync(), m['bytes']);
        final s = art[m['id']];
        expect(s, isNotNull, reason: m['id'] as String);
        expect(s!.kind, StickerKind.image);
        expect(s.asset, m['path']);
        expect(s.nameEn.isNotEmpty && s.nameVi.isNotEmpty, isTrue);
        expect(s.pro, m['free'] == true ? isFalse : isTrue);
      }
      expect(
        stickers.where((s) => s.kind == StickerKind.image).length,
        manifest.length,
      );
    });

    test('the free app has a real set of illustrated stickers', () {
      final free = stickers.where((s) => !s.pro).length;
      expect(free, greaterThanOrEqualTo(20));
    });
  });
}
