import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_wall/models/note.dart';
import 'package:sticky_wall/services/theme_packs.dart';

void main() {
  test('the original catalog keeps its Free and Pro entitlements', () {
    const free = {
      'cork_classic',
      'dark_chalk',
      'green_classroom',
      'kraft_workshop',
      'warm_wood',
      'denim_patch',
      'felt_board',
      'minimal_cream',
      'clean_office',
      'brick_loft',
      'dark_academia',
      'marble_desk',
      'rainbow_school',
      'linen_lilac',
      'moss_garden',
      'terrazzo_pop',
      'cardboard_box',
    };
    const pro = {
      'pastel_kawaii',
      'vintage_paper',
      'cozy_study',
      'polaroid_studio',
      'ocean_blue',
      'soft_lavender',
      'botanical_green',
      'warm_autumn',
      'moonlight',
      'y2k_pop',
      'pixel_retro',
      'travel_journal',
      'scrapbook_craft',
      'kids_colorful',
      'coffee_notes',
      'lunar_new_year',
      'peach_blossom',
      'christmas',
      'mid_autumn',
      'valentine',
    };
    for (final id in free) {
      expect(themePackById(id)!.pro, isFalse, reason: id);
    }
    for (final id in pro) {
      expect(themePackById(id)!.pro, isTrue, reason: id);
    }
    for (final id in ['sunny_kitchen', 'lilac_desk', 'garden_sketches']) {
      final pack = themePackById(id)!;
      expect(pack.pro, isFalse, reason: id);
      expect(lookFor(pack, pro: false), same(pack));
    }
    for (final id in [
      'berry_scrapbook',
      'night_observatory',
      'seaside_postcards',
    ]) {
      final pack = themePackById(id)!;
      expect(pack.pro, isTrue, reason: id);
      expect(lookFor(pack, pro: false).pro, isFalse);
      expect(lookFor(pack, pro: true), same(pack));
    }
  });

  test('old and new paper styles survive note storage without migration', () {
    expect(PaperStyle.values.take(6).map((p) => p.name), [
      'plain',
      'lined',
      'grid',
      'dots',
      'indexCard',
      'notebook',
    ]);
    for (final paper in PaperStyle.values) {
      final note = Note(
        guid: 'paper',
        boardId: 'default',
        content: 'Keep my words',
        createdAt: DateTime(2026),
        paper: paper,
      );
      final restored = Note.fromJson(note.toJson());
      expect(restored.paper, paper);
      expect(restored.content, note.content);
    }
    expect(PaperStyle.flecks.pro, isFalse);
    expect(PaperStyle.stitched.pro, isTrue);
    for (final paper in [PaperStyle.flecks, PaperStyle.stitched]) {
      expect(paper.suits(NoteType.normal), isTrue);
      expect(paper.suits(NoteType.checklist), isTrue);
      expect(paper.suits(NoteType.link), isTrue);
      expect(paper.suits(NoteType.photo), isFalse);
    }
  });
}
