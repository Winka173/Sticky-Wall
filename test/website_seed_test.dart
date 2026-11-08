// Writes the backup files the website's screenshots and clips are taken
// from: an everyday wall, a trip's memory wall and a work board, in English
// and in Vietnamese, with real photos. Not a regression test. Run:
//
//   flutter test test/website_seed_test.dart \
//     --dart-define=WEBSITE_SEED=true --dart-define=WEBSITE_PHOTOS=<folder>
//
// <folder> holds the photos named in [_photoFiles] (openly licensed; their
// credits go with the website kit). The files land in build/website_seed/.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_wall/models/board.dart';
import 'package:sticky_wall/models/draw_stroke.dart';
import 'package:sticky_wall/models/note.dart';
import 'package:sticky_wall/services/backup_service.dart';
import 'package:sticky_wall/services/memory_wall.dart';

const _run = bool.fromEnvironment('WEBSITE_SEED');
const _photoDir = String.fromEnvironment('WEBSITE_PHOTOS');

/// Stored photo name → source file in [_photoDir].
const _photoFiles = {
  'seed_pho.jpg': 'pho-bo.jpg',
  'seed_halong_1.jpg': 'halong-1.jpg',
  'seed_halong_2.jpg': 'halong-2.jpg',
  'seed_hagiang.jpg': 'hagiang-terraces.jpg',
  'seed_sapa.jpg': 'sapa-terraces.jpg',
  'seed_hanoi.jpg': 'hanoi-street.jpg',
  'seed_hoian.jpg': 'hoian-lanterns.jpg',
  'seed_hoian_boats.jpg': 'hoian-boats.jpg',
  'seed_hue.jpg': 'hue-gate.jpg',
  'seed_coffee.jpg': 'ca-phe-sua.jpg',
  'seed_beach.jpg': 'danang-beach.jpg',
};

/// The words of the seed in one language.
class _Words {
  const _Words({
    required this.home,
    required this.trip,
    required this.work,
    required this.thisWeek,
    required this.groceries,
    required this.groceryItems,
    required this.callMom,
    required this.dentist,
    required this.phoCaption,
    required this.recipe,
    required this.voice,
    required this.plants,
    required this.balcony,
    required this.forSaturday,
    required this.tripTitle,
    required this.captions,
    required this.todo,
    required this.doing,
    required this.done,
    required this.workNotes,
    required this.packing,
    required this.packingItems,
    required this.blocks,
    required this.tet,
  });

  final String home, trip, work, thisWeek, groceries, callMom, dentist;
  final String phoCaption, recipe, voice, plants, balcony, forSaturday;
  final String tripTitle, todo, doing, done, packing, blocks, tet;
  final List<(String, bool)> groceryItems, packingItems;
  final List<String> captions;

  /// (text, column 0..2, colour index, pinned)
  final List<(String, int, int, bool)> workNotes;
}

const _en = _Words(
  home: 'Home',
  trip: 'Summer trip',
  work: 'Work',
  thisWeek: 'This week',
  groceries: 'Groceries',
  groceryItems: [
    ('Eggs', true),
    ('Fresh milk', true),
    ('Rice noodles', false),
    ('Coriander & limes', false),
    ('Beef for phở', false),
  ],
  callMom: 'Call Mom on Sunday evening',
  dentist: 'Dentist Thursday 9:30\nbring the insurance card',
  phoCaption: 'Saturday: phở at home',
  recipe: 'Phở broth, step by step',
  voice: 'Gift ideas for Linh',
  plants: 'Water the plants\n- Mon · Wed · Fri\n- **basil** needs more sun',
  balcony: 'Balcony garden',
  forSaturday: 'for Saturday',
  tripTitle: 'Vietnam, summer 2026',
  captions: [
    'Hạ Long Bay',
    'Dawn kayak',
    'Hà Giang',
    'Sa Pa',
    'Old Quarter',
    'Hội An',
    'Basket boats',
    'Huế',
    'Cà phê sữa đá',
    'Đà Nẵng',
  ],
  tet: 'Book tickets home for Tết\nbefore Dec 1',
  todo: 'To do',
  doing: 'Doing',
  done: 'Done',
  workNotes: [
    ('Q4 newsletter draft', 0, 0, false),
    ('Book room for Friday', 0, 3, false),
    ('Reply to print shop', 0, 4, false),
    ('Landing page copy', 1, 1, true),
    ('Menu board photos', 1, 2, false),
    ('Invoice #1042 sent', 2, 3, false),
    ('Team lunch booked ✓', 2, 0, false),
  ],
  packing: 'Packing list',
  packingItems: [
    ('Passport & tickets', true),
    ('Raincoat', true),
    ('Power bank', false),
    ('Sunscreen', false),
    ('Motorbike licence', false),
  ],
  blocks: 'Focus: one thing at a time',
);

const _vi = _Words(
  home: 'Nhà mình',
  trip: 'Chuyến đi hè',
  work: 'Công việc',
  thisWeek: 'Tuần này',
  groceries: 'Đi chợ',
  groceryItems: [
    ('Trứng gà', true),
    ('Sữa tươi', true),
    ('Bánh phở', false),
    ('Rau mùi, chanh', false),
    ('Thịt bò nấu phở', false),
  ],
  callMom: 'Gọi điện cho mẹ tối Chủ nhật',
  dentist: 'Khám răng thứ Năm 9:30\nnhớ mang thẻ bảo hiểm',
  phoCaption: 'Thứ Bảy: nấu phở ở nhà',
  recipe: 'Cách ninh nước dùng phở',
  voice: 'Ý tưởng quà cho Linh',
  plants: 'Tưới cây\n- Thứ 2 · 4 · 6\n- **húng quế** cần thêm nắng',
  balcony: 'Vườn ban công',
  forSaturday: 'cho thứ Bảy',
  tripTitle: 'Việt Nam, hè 2026',
  captions: [
    'Vịnh Hạ Long',
    'Chèo kayak',
    'Hà Giang',
    'Sa Pa',
    'Phố cổ',
    'Hội An',
    'Thuyền thúng',
    'Đại Nội Huế',
    'Cà phê sữa đá',
    'Biển Đà Nẵng',
  ],
  tet: 'Đặt vé về quê ăn Tết\ntrước 1/12',
  todo: 'Cần làm',
  doing: 'Đang làm',
  done: 'Xong',
  workNotes: [
    ('Soạn bản tin quý 4', 0, 0, false),
    ('Đặt phòng họp thứ Sáu', 0, 3, false),
    ('Trả lời nhà in', 0, 4, false),
    ('Viết nội dung trang chủ', 1, 1, true),
    ('Ảnh cho thực đơn', 1, 2, false),
    ('Đã gửi hoá đơn #1042', 2, 3, false),
    ('Đã đặt bàn ăn trưa ✓', 2, 0, false),
  ],
  packing: 'Đồ mang theo',
  packingItems: [
    ('Hộ chiếu, vé', true),
    ('Áo mưa', true),
    ('Sạc dự phòng', false),
    ('Kem chống nắng', false),
    ('Bằng lái xe máy', false),
  ],
  blocks: 'Tập trung: mỗi lúc một việc',
);

final _now = DateTime(2026, 11, 8, 10);
DateTime _ago(int hours) => _now.subtract(Duration(hours: hours));

/// A hand-drawn-looking line through [pts] (fractions of the canvas): each
/// segment is split and nudged a little, as a finger would.
List<Offset> _wobble(List<Offset> pts, int seed) {
  final r = math.Random(seed);
  final out = <Offset>[];
  for (var i = 0; i + 1 < pts.length; i++) {
    final a = pts[i], b = pts[i + 1];
    for (var s = 0; s < 6; s++) {
      final t = s / 6;
      out.add(
        Offset.lerp(a, b, t)! +
            Offset(r.nextDouble() - 0.5, r.nextDouble() - 0.5) * 0.008,
      );
    }
  }
  out.add(pts.last);
  return out;
}

List<Offset> _circle(Offset c, double rx, double ry) => [
  for (var i = 0; i <= 24; i++)
    Offset(
      c.dx + rx * math.cos(i / 24 * 2 * math.pi),
      c.dy + ry * math.sin(i / 24 * 2 * math.pi),
    ),
];

/// A balcony seen from above: the railing, two planters, three pots and
/// an arrow to where the sun comes from.
List<DrawStroke> _balconySketch() {
  const ink = 0xFF37474F, green = 0xFF2E7D32, sun = 0xFFF9A825;
  return [
    DrawStroke(
      color: ink,
      width: 4,
      points: _wobble(const [
        Offset(0.1, 0.2),
        Offset(0.9, 0.2),
        Offset(0.9, 0.85),
        Offset(0.1, 0.85),
        Offset(0.1, 0.2),
      ], 1),
    ),
    DrawStroke(
      color: green,
      width: 5,
      points: _wobble(const [
        Offset(0.16, 0.27),
        Offset(0.55, 0.27),
        Offset(0.55, 0.36),
        Offset(0.16, 0.36),
        Offset(0.16, 0.27),
      ], 2),
    ),
    for (final (i, c) in const [
      Offset(0.25, 0.62),
      Offset(0.42, 0.7),
      Offset(0.7, 0.6),
    ].indexed)
      DrawStroke(
        color: green,
        width: 5,
        points: _wobble(_circle(c, 0.06, 0.05), 10 + i),
      ),
    DrawStroke(
      color: sun,
      width: 6,
      points: _wobble(_circle(const Offset(0.8, 0.1), 0.05, 0.04), 20),
    ),
    DrawStroke(
      color: sun,
      width: 4,
      points: _wobble(const [Offset(0.74, 0.16), Offset(0.62, 0.3)], 21),
    ),
    DrawStroke(
      color: sun,
      width: 4,
      points: _wobble(const [
        Offset(0.62, 0.24),
        Offset(0.62, 0.3),
        Offset(0.68, 0.3),
      ], 22),
    ),
  ];
}

/// A short mono WAV: a soft hum that rises and falls like speech, so the
/// cassette plays something. [seconds] long.
Uint8List _voiceWav(int seconds) {
  const rate = 16000;
  final n = rate * seconds;
  final data = ByteData(44 + n * 2);
  void str(int at, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(at + i, s.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  data.setUint32(4, 36 + n * 2, Endian.little);
  str(8, 'WAVEfmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, rate, Endian.little);
  data.setUint32(28, rate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  str(36, 'data');
  data.setUint32(40, n * 2, Endian.little);
  for (var i = 0; i < n; i++) {
    final t = i / rate;
    final env =
        (math.sin(t * 2.3) * 0.5 + 0.5) * (math.sin(t * 7.1) > -0.3 ? 1 : 0.1);
    final v =
        math.sin(2 * math.pi * 180 * t) * 0.5 +
        math.sin(2 * math.pi * 260 * t) * 0.3;
    data.setInt16(44 + i * 2, (v * env * 2500).round(), Endian.little);
  }
  return data.buffer.asUint8List();
}

({List<Board> boards, List<Note> notes, List<NoteLink> links}) _seed(
  _Words w, {
  required bool wide,
}) {
  final boards = <Board>[
    Board(id: 'default', name: w.home, icon: '🏠', themeId: 'cork_classic'),
    Board(
      id: 'trip',
      name: w.trip,
      icon: '🏝️',
      wallIndex: 6,
      themeId: 'travel_journal',
    ),
    Board(id: 'work', name: w.work, icon: '💼', wallIndex: 2),
  ];

  final notes = <Note>[
    // ---- Home ----
    Note(
      guid: 'h-label',
      content: w.thisWeek,
      type: NoteType.label,
      boardId: 'default',
      createdAt: _ago(200),
      colorIndex: 4,
      locked: true,
      x: 0.06,
      y: 0.02,
    ),
    Note(
      guid: 'h-groceries',
      content: w.groceries,
      emoji: '🛒',
      type: NoteType.checklist,
      checklist: [
        for (final (t, d) in w.groceryItems) ChecklistItem(text: t, done: d),
      ],
      boardId: 'default',
      createdAt: _ago(30),
      colorIndex: 0,
      x: 0.05,
      y: 0.12,
      rotation: -0.04,
    ),
    Note(
      guid: 'h-mom',
      content: w.callMom,
      emoji: '❤️',
      boardId: 'default',
      createdAt: _ago(50),
      colorIndex: 1,
      pinned: true,
      reminderAt: DateTime(2026, 11, 8, 19),
      repeat: ReminderRepeat.weekly,
      x: 0.6,
      y: 0.09,
    ),
    Note(
      guid: 'h-pho',
      content: w.phoCaption,
      type: NoteType.photo,
      imagePath: 'seed_pho.jpg',
      frame: PhotoFrame.polaroid,
      boardId: 'default',
      createdAt: _ago(20),
      x: 0.62,
      y: 0.36,
      rotation: 0.07,
    ),
    Note(
      guid: 'h-dentist',
      content: w.dentist,
      emoji: '🦷',
      boardId: 'default',
      createdAt: _ago(70),
      colorIndex: 2,
      reminderAt: DateTime(2026, 11, 12, 9, 30),
      x: 0.04,
      y: 0.44,
      rotation: 0.03,
    ),
    Note(
      guid: 'h-recipe',
      content: w.recipe,
      url: 'https://en.wikipedia.org/wiki/Ph%E1%BB%9F',
      type: NoteType.link,
      boardId: 'default',
      createdAt: _ago(90),
      colorIndex: 3,
      x: 0.07,
      y: 0.66,
      rotation: -0.05,
    ),
    Note(
      guid: 'h-voice',
      content: w.voice,
      type: NoteType.audio,
      audioPath: 'seed_voice.m4a',
      audioMs: 42000,
      boardId: 'default',
      createdAt: _ago(10),
      colorIndex: 5,
      x: 0.58,
      y: 0.68,
      rotation: -0.06,
    ),
    Note(
      guid: 'h-plants',
      content: w.plants,
      emoji: '🌱',
      paper: PaperStyle.lined,
      boardId: 'default',
      createdAt: _ago(120),
      colorIndex: 2,
      x: 0.08,
      y: 0.86,
      rotation: 0.04,
    ),
    Note(
      guid: 'h-balcony',
      content: w.balcony,
      type: NoteType.drawing,
      strokes: _balconySketch(),
      canvas: const DrawCanvas(pattern: CanvasPattern.grid),
      boardId: 'default',
      createdAt: _ago(150),
      x: 0.62,
      y: 0.9,
      rotation: 0.05,
      scale: 0.9,
    ),
    Note(
      guid: 'h-tet',
      content: w.tet,
      emoji: '🧧',
      boardId: 'default',
      createdAt: _ago(40),
      colorIndex: 1,
    ),
    Note(
      guid: 'h-st-coffee',
      content: '',
      type: NoteType.sticker,
      sticker: 'art_phin_coffee',
      boardId: 'default',
      createdAt: _ago(5),
      x: 0.9,
      y: 0.55,
      scale: 0.8,
      rotation: 0.1,
    ),
    Note(
      guid: 'h-st-seedling',
      content: '',
      type: NoteType.sticker,
      sticker: 'art_seedling',
      boardId: 'default',
      createdAt: _ago(4),
      x: 0.42,
      y: 0.83,
      scale: 0.7,
    ),
  ];

  // ---- Trip: a memory wall in Polaroids ----
  const tripPhotos = [
    'seed_halong_1.jpg',
    'seed_halong_2.jpg',
    'seed_hagiang.jpg',
    'seed_sapa.jpg',
    'seed_hanoi.jpg',
    'seed_hoian.jpg',
    'seed_hoian_boats.jpg',
    'seed_hue.jpg',
    'seed_coffee.jpg',
    'seed_beach.jpg',
  ];
  final memory = memoryWallNotes(
    tripPhotos,
    'trip',
    MemoryLayout.collage,
    title: w.tripTitle,
    frame: PhotoFrame.polaroid,
    now: _ago(24 * 60),
  );
  var photoIndex = 0;
  for (final n in memory.notes) {
    if (n.type == NoteType.photo) n.content = w.captions[photoIndex++];
  }
  notes.addAll(memory.notes);
  notes.addAll([
    Note(
      guid: 't-packing',
      content: w.packing,
      emoji: '🎒',
      type: NoteType.checklist,
      checklist: [
        for (final (t, d) in w.packingItems) ChecklistItem(text: t, done: d),
      ],
      boardId: 'trip',
      createdAt: _ago(24 * 70),
      colorIndex: 0,
      x: 0.86,
      y: 0.04,
      rotation: 0.05,
      scale: 0.85,
    ),
    Note(
      guid: 't-st-hat',
      content: '',
      type: NoteType.sticker,
      sticker: 'art_conical_hat',
      boardId: 'trip',
      createdAt: _ago(24 * 59),
      x: 0.12,
      y: 0.02,
      scale: 0.7,
    ),
  ]);

  // ---- Work: three columns on a chalkboard ----
  for (final (i, title) in [w.todo, w.doing, w.done].indexed) {
    notes.add(
      Note(
        guid: 'w-col$i',
        content: title,
        type: NoteType.label,
        boardId: 'work',
        createdAt: _ago(300 + i),
        colorIndex: 4,
        locked: true,
        x: 0.04 + i * 0.33,
        y: 0.04,
      ),
    );
  }
  final rows = [0, 0, 0];
  for (final (j, (text, col, color, pinned)) in w.workNotes.indexed) {
    notes.add(
      Note(
        guid: 'w-n$j',
        content: text,
        boardId: 'work',
        createdAt: _ago(100 - j),
        colorIndex: color,
        pinned: pinned,
        x: [0.02, 0.33, 0.64][col],
        y: 0.16 + rows[col]++ * 0.2,
        scale: 0.85,
      ),
    );
  }
  notes.add(
    Note(
      guid: 'w-focus',
      content: w.blocks,
      emoji: '🎯',
      boardId: 'work',
      createdAt: _ago(400),
      colorIndex: 1,
      x: 0.36,
      y: 0.82,
      rotation: -0.03,
    ),
  );

  final links = <NoteLink>[
    NoteLink(
      'h-groceries',
      'h-pho',
      color: 0xFFC62828,
      label: w.forSaturday,
      arrow: true,
    ),
    const NoteLink('h-recipe', 'h-pho', color: 0xFF1565C0),
    ...memory.links,
    const NoteLink('w-n3', 'w-n4', color: 0xFFF9A825, arrow: true),
  ];
  _place(notes, wide: wide);
  notes.removeWhere((n) => n.x.isNaN);
  return (boards: boards, notes: notes, links: links);
}

typedef _Spot = (double x, double y, double scale, double rotation);

/// Where each note sits on a phone (tall) or a tablet / desktop (wide)
/// screen; a note left out of a layout is dropped from that seed. Fractions
/// of the free wall, like every note.
void _place(List<Note> notes, {required bool wide}) {
  final Map<String, _Spot> spots = wide
      ? const {
          'h-label': (0.01, 0.0, 1.0, 0),
          'h-groceries': (0.01, 0.2, 1.0, -0.03),
          'h-mom': (0.42, 0.03, 1.0, 0.02),
          'h-recipe': (0.2, 0.86, 1.0, -0.04),
          'h-pho': (0.2, 0.04, 1.1, 0.05),
          'h-plants': (0.43, 0.7, 1.0, -0.02),
          'h-dentist': (0.62, 0.0, 1.0, -0.03),
          'h-voice': (0.62, 0.62, 1.0, 0.04),
          'h-tet': (0.82, 0.04, 1.0, 0.03),
          'h-balcony': (0.84, 0.86, 0.9, -0.04),
          'h-st-coffee': (0.99, 0.42, 0.8, 0.1),
          'h-st-seedling': (0.06, 0.98, 0.6, 0),
          't-title': (0.45, 0.0, 1.4, 0),
          't-packing': (0.995, 0.08, 0.85, 0.05),
          't-st-hat': (0.33, 0.0, 0.6, -0.1),
          'w-focus': (0.995, 0.55, 1.0, -0.03),
        }
      : const {
          'h-label': (0.02, 0.0, 1.0, 0),
          'h-groceries': (0.02, 0.08, 1.0, -0.02),
          'h-dentist': (0.03, 0.5, 1.0, 0.02),
          'h-recipe': (0.04, 0.76, 1.0, -0.04),
          'h-mom': (0.98, 0.02, 1.0, 0.03),
          'h-pho': (0.94, 0.25, 1.0, 0.05),
          'h-voice': (0.98, 0.55, 1.0, -0.04),
          'h-balcony': (0.95, 0.82, 0.8, -0.04),
          't-title': (0.5, 0.0, 1.3, 0),
          't-st-hat': (0.0, 0.0, 0.55, -0.1),
          'w-focus': (0.5, 0.92, 0.8, -0.03),
        };
  // The trip's ten prints, scattered like a scrapbook.
  final List<_Spot?> prints = wide
      ? const [
          (0.0, 0.1, 1.15, -0.06),
          (0.18, 0.06, 1.15, 0.05),
          (0.36, 0.12, 1.15, -0.03),
          (0.54, 0.08, 1.15, 0.06),
          (0.72, 0.11, 1.15, -0.05),
          (0.03, 0.62, 1.15, 0.04),
          (0.21, 0.66, 1.15, -0.05),
          (0.39, 0.6, 1.15, 0.03),
          (0.57, 0.65, 1.15, -0.04),
          (0.75, 0.62, 1.15, 0.05),
        ]
      : const [
          (0.02, 0.06, 0.85, -0.05),
          null,
          (0.98, 0.14, 0.85, 0.05),
          (0.03, 0.38, 0.85, 0.04),
          (0.97, 0.47, 0.85, -0.04),
          (0.02, 0.7, 0.85, -0.03),
          null,
          (0.98, 0.8, 0.85, 0.05),
          null,
          null,
        ];
  // The work board: three columns of cards under their headings.
  const seedX = [0.02, 0.33, 0.64];
  final colX = wide ? const [0.02, 0.33, 0.64] : const [0.03, 0.5, 0.95];
  final cardScale = wide ? 1.0 : 0.7;
  final rowStep = wide ? 0.27 : 0.2;
  final rows = [0, 0, 0];
  var print = 0;
  for (final n in notes) {
    var s = spots[n.guid];
    if (n.boardId == 'trip' && n.type == NoteType.label) s = spots['t-title'];
    if (n.boardId == 'trip' && n.type == NoteType.photo) s = prints[print++];
    if (n.guid.startsWith('w-col')) {
      final c = int.parse(n.guid.substring(5));
      s = (colX[c], 0.0, wide ? 1.0 : 0.66, 0.0);
    }
    if (n.guid.startsWith('w-n')) {
      final c = seedX.indexOf(n.x);
      s = (
        colX[c],
        (wide ? 0.2 : 0.08) + rows[c]++ * rowStep,
        cardScale,
        (rows[c] % 3 - 1) * 0.015,
      );
    }
    if (s == null) {
      n.x = double.nan;
      continue;
    }
    n
      ..x = s.$1
      ..y = s.$2
      ..scale = s.$3
      ..rotation = s.$4;
  }
}

void main() {
  test('website seed backups', skip: !_run, () async {
    final photos = <String, Uint8List>{
      for (final e in _photoFiles.entries)
        e.key: File('$_photoDir/${e.value}').readAsBytesSync(),
    };
    final audios = {'seed_voice.m4a': _voiceWav(42)};
    final out = Directory('build/website_seed')..createSync(recursive: true);
    for (final (code, words) in [('en', _en), ('vi', _vi)]) {
      for (final wide in [false, true]) {
        final s = _seed(words, wide: wide);
        final json = BackupService().encode(
          s.boards,
          s.notes,
          s.links,
          photos,
          const {},
          audios,
        );
        final shape = wide ? 'wide' : 'phone';
        File(
          '${out.path}/sticky_wall_seed_${code}_$shape.json',
        ).writeAsStringSync(json);
      }
    }
  });
}
