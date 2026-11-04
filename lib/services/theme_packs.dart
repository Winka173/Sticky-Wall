import 'package:flutter/painting.dart';

import '../models/note.dart';
import '../theme.dart';

/// Where a theme pack is shelved in the gallery.
enum ThemeCategory { classic, study, personal, creative, family, seasonal }

/// A complete look for one board: the wall, the papers its notes are cut
/// from, how they are ruled, what holds them up, the handwriting and the
/// thread between them. Applying a pack never touches what the notes say,
/// where they sit, their links or their dates (see
/// `NotesController.applyTheme`).
class ThemePack {
  const ThemePack({
    required this.id,
    required this.nameEn,
    required this.nameVi,
    required this.category,
    required this.wall,
    required this.papers,
    required this.font,
    this.paper = PaperStyle.plain,
    this.pin = PinStyle.classic,
    this.thread = ThreadStyle.yarn,
    this.yarn = 0xFFC62828,
    this.stickers = const [],
  });

  /// Stored on the board (`Board.themeId`); never renamed.
  final String id;
  final String nameEn;
  final String nameVi;
  final ThemeCategory category;

  /// A wall id from `walls` in theme.dart.
  final String wall;

  /// The papers notes take, in turn: indices into `AppColors.notePapers`,
  /// or mixed colours (`customPaper`).
  final List<int> papers;

  /// The ruling put on sheets that can take it.
  final PaperStyle paper;
  final PinStyle pin;

  /// A font id from `fontChoices`.
  final String font;
  final ThreadStyle thread;

  /// The thread colour (ARGB).
  final int yarn;

  /// Sticker ids that suit the pack, offered first in its preview.
  final List<String> stickers;

  String name(String languageCode) => languageCode == 'vi' ? nameVi : nameEn;

  WallStyle get wallStyle => walls.firstWhere((w) => w.id == wall);

  int get wallIndex => walls.indexWhere((w) => w.id == wall);

  /// Anything in it that needs Sticky Wall Pro.
  bool get pro =>
      wallStyle.pro ||
      wallStyle.season != null ||
      papers.any((p) => isCustomPaper(p) || p >= AppColors.freePapers) ||
      paper.pro ||
      pin.pro ||
      fontChoiceById(font).pro ||
      thread.pro ||
      !AppColors.yarns.take(AppColors.freeYarns).contains(yarn);

  /// The paper colour of the note at [i] in a board's reading order.
  int paperAt(int i) => papers[i % papers.length];
}

int _mix(int argb) => customPaper(Color(argb));

/// The packs, free ones first in each shelf. Ids are stored on boards: never
/// rename or reuse one. The whole app takes a board's handwriting, so packs
/// use faces that stay readable at toolbar size (no Amatic SC).
final themePacks = <ThemePack>[
  // --- Free -------------------------------------------------------------
  const ThemePack(
    id: 'cork_classic',
    nameEn: 'Cork Classic',
    nameVi: 'Bảng gỗ bần',
    category: ThemeCategory.classic,
    wall: 'cork',
    papers: [0, 1, 2, 3],
    font: 'patrick',
    stickers: ['star', 'heart', 'check'],
  ),
  const ThemePack(
    id: 'dark_chalk',
    nameEn: 'Dark Chalk',
    nameVi: 'Bảng phấn đen',
    category: ThemeCategory.study,
    wall: 'chalk_black',
    papers: [0, 3, 4],
    font: 'fuzzy',
    yarn: 0xFFF9A825,
    stickers: ['star', 'check'],
  ),
  const ThemePack(
    id: 'green_classroom',
    nameEn: 'Green Classroom',
    nameVi: 'Lớp học bảng xanh',
    category: ThemeCategory.study,
    wall: 'chalk_green',
    papers: [0, 4, 1],
    font: 'itim',
    yarn: 0xFFF9A825,
    stickers: ['check', 'star'],
  ),
  const ThemePack(
    id: 'kraft_workshop',
    nameEn: 'Kraft Workshop',
    nameVi: 'Xưởng giấy kraft',
    category: ThemeCategory.creative,
    wall: 'kraft',
    papers: [4, 0, 2],
    font: 'mynerve',
    yarn: 0xFFEF6C00,
  ),
  const ThemePack(
    id: 'warm_wood',
    nameEn: 'Warm Wood',
    nameVi: 'Gỗ ấm',
    category: ThemeCategory.personal,
    wall: 'wood',
    papers: [0, 4, 1],
    font: 'mali',
  ),
  const ThemePack(
    id: 'denim_patch',
    nameEn: 'Denim Patch',
    nameVi: 'Vải jean',
    category: ThemeCategory.creative,
    wall: 'denim',
    papers: [0, 1, 4],
    font: 'fuzzy',
    yarn: 0xFFF9A825,
  ),
  const ThemePack(
    id: 'felt_board',
    nameEn: 'Felt Board',
    nameVi: 'Bảng nỉ',
    category: ThemeCategory.family,
    wall: 'felt',
    papers: [3, 0, 5],
    font: 'sriracha',
    yarn: 0xFF1565C0,
  ),
  const ThemePack(
    id: 'minimal_cream',
    nameEn: 'Minimal Cream',
    nameVi: 'Kem tối giản',
    category: ThemeCategory.classic,
    wall: 'paper',
    papers: [0, 4, 2],
    font: 'bevietnam',
    yarn: 0xFF3B372F,
  ),
  const ThemePack(
    id: 'clean_office',
    nameEn: 'Clean Office',
    nameVi: 'Văn phòng gọn',
    category: ThemeCategory.study,
    wall: 'cement',
    papers: [3, 2, 0],
    font: 'bevietnam',
    yarn: 0xFF1565C0,
  ),
  const ThemePack(
    id: 'brick_loft',
    nameEn: 'Brick Loft',
    nameVi: 'Tường gạch',
    category: ThemeCategory.creative,
    wall: 'brick',
    papers: [0, 2, 3],
    font: 'itim',
    yarn: 0xFF3B372F,
  ),
  const ThemePack(
    id: 'dark_academia',
    nameEn: 'Dark Academia',
    nameVi: 'Thư viện cổ',
    category: ThemeCategory.study,
    wall: 'dark_wood',
    papers: [4, 0, 5],
    font: 'charm',
    yarn: 0xFFF9A825,
  ),
  const ThemePack(
    id: 'marble_desk',
    nameEn: 'Marble Desk',
    nameVi: 'Bàn đá cẩm thạch',
    category: ThemeCategory.personal,
    wall: 'marble',
    papers: [1, 5, 3],
    font: 'dancing',
    yarn: 0xFF6A1B9A,
  ),
  const ThemePack(
    id: 'rainbow_school',
    nameEn: 'Rainbow School',
    nameVi: 'Cầu vồng tới trường',
    category: ThemeCategory.family,
    wall: 'tiles',
    papers: [0, 1, 2, 3, 4, 5],
    font: 'fuzzy',
    yarn: 0xFF2E7D32,
  ),
  const ThemePack(
    id: 'linen_lilac',
    nameEn: 'Linen Lilac',
    nameVi: 'Vải lanh tím nhạt',
    category: ThemeCategory.personal,
    wall: 'linen',
    papers: [5, 1, 3],
    font: 'mali',
    yarn: 0xFF6A1B9A,
  ),
  const ThemePack(
    id: 'moss_garden',
    nameEn: 'Moss Garden',
    nameVi: 'Vườn rêu',
    category: ThemeCategory.personal,
    wall: 'moss',
    papers: [2, 0, 4],
    font: 'mynerve',
    yarn: 0xFF2E7D32,
  ),
  const ThemePack(
    id: 'terrazzo_pop',
    nameEn: 'Terrazzo Pop',
    nameVi: 'Đá mài sắc màu',
    category: ThemeCategory.creative,
    wall: 'terrazzo',
    papers: [1, 3, 0],
    font: 'sriracha',
    yarn: 0xFFEF6C00,
  ),
  const ThemePack(
    id: 'cardboard_box',
    nameEn: 'Moving Day',
    nameVi: 'Ngày chuyển nhà',
    category: ThemeCategory.family,
    wall: 'cardboard',
    papers: [0, 3, 2],
    font: 'plexmono',
    yarn: 0xFF3B372F,
  ),
  // --- Pro --------------------------------------------------------------
  ThemePack(
    id: 'pastel_kawaii',
    nameEn: 'Pastel Kawaii',
    nameVi: 'Pastel dễ thương',
    category: ThemeCategory.personal,
    wall: 'blush',
    papers: [1, 5, 3, _mix(0xFFFFE3EC)],
    paper: PaperStyle.dots,
    pin: PinStyle.colorful,
    font: 'coiny',
    thread: ThreadStyle.ribbon,
    yarn: 0xFFD81B60,
    stickers: ['heart', 'star', 'party'],
  ),
  const ThemePack(
    id: 'vintage_paper',
    nameEn: 'Vintage Paper',
    nameVi: 'Giấy cổ điển',
    category: ThemeCategory.creative,
    wall: 'leather',
    papers: [10, 11, 4],
    paper: PaperStyle.notebook,
    pin: PinStyle.clip,
    font: 'lora',
    thread: ThreadStyle.twine,
    yarn: 0xFF8D6E63,
  ),
  ThemePack(
    id: 'cozy_study',
    nameEn: 'Cozy Study',
    nameVi: 'Góc học ấm áp',
    category: ThemeCategory.study,
    wall: 'chalk_wine',
    papers: [11, 10, _mix(0xFFF6E7C8)],
    paper: PaperStyle.lined,
    pin: PinStyle.tack,
    font: 'shantell',
    thread: ThreadStyle.twine,
    yarn: 0xFF8D6E63,
    stickers: ['coffee', 'idea', 'later'],
  ),
  const ThemePack(
    id: 'polaroid_studio',
    nameEn: 'Polaroid Studio',
    nameVi: 'Studio ảnh lấy liền',
    category: ThemeCategory.personal,
    wall: 'cotton',
    papers: [11, 0, 8],
    pin: PinStyle.washi,
    font: 'plexmono',
    thread: ThreadStyle.dashed,
    yarn: 0xFF3B372F,
  ),
  ThemePack(
    id: 'ocean_blue',
    nameEn: 'Ocean Blue',
    nameVi: 'Biển xanh',
    category: ThemeCategory.personal,
    wall: 'sky',
    papers: [3, 8, _mix(0xFFD3F1F4), 11],
    pin: PinStyle.magnet,
    font: 'shantell',
    thread: ThreadStyle.ribbon,
    yarn: 0xFF00897B,
  ),
  ThemePack(
    id: 'soft_lavender',
    nameEn: 'Soft Lavender',
    nameVi: 'Oải hương dịu',
    category: ThemeCategory.personal,
    wall: 'linen',
    papers: [5, 8, _mix(0xFFEDE3F6)],
    paper: PaperStyle.dots,
    pin: PinStyle.washi,
    font: 'charm',
    thread: ThreadStyle.ribbon,
    yarn: 0xFF6A1B9A,
  ),
  const ThemePack(
    id: 'botanical_green',
    nameEn: 'Botanical Green',
    nameVi: 'Cây lá xanh',
    category: ThemeCategory.personal,
    wall: 'sage',
    papers: [9, 6, 2],
    paper: PaperStyle.lined,
    pin: PinStyle.tack,
    font: 'lora',
    thread: ThreadStyle.twine,
    yarn: 0xFF2E7D32,
  ),
  const ThemePack(
    id: 'warm_autumn',
    nameEn: 'Warm Autumn',
    nameVi: 'Thu ấm',
    category: ThemeCategory.personal,
    wall: 'leather',
    papers: [4, 7, 10],
    pin: PinStyle.clip,
    font: 'lobster',
    thread: ThreadStyle.twine,
    yarn: 0xFFEF6C00,
  ),
  const ThemePack(
    id: 'moonlight',
    nameEn: 'Moonlight',
    nameVi: 'Ánh trăng',
    category: ThemeCategory.study,
    wall: 'chalk_navy',
    papers: [11, 3, 8],
    pin: PinStyle.magnet,
    font: 'shantell',
    thread: ThreadStyle.dashed,
    yarn: 0xFFF5F2EA,
  ),
  const ThemePack(
    id: 'y2k_pop',
    nameEn: 'Y2K Pop',
    nameVi: 'Y2K rực rỡ',
    category: ThemeCategory.creative,
    wall: 'tiles',
    papers: [6, 1, 8],
    paper: PaperStyle.grid,
    pin: PinStyle.colorful,
    font: 'coiny',
    thread: ThreadStyle.beads,
    yarn: 0xFFD81B60,
    stickers: ['fire', 'party', 'thumbs'],
  ),
  const ThemePack(
    id: 'pixel_retro',
    nameEn: 'Pixel Retro',
    nameVi: 'Pixel hoài cổ',
    category: ThemeCategory.creative,
    wall: 'cement',
    papers: [6, 3, 7],
    paper: PaperStyle.grid,
    pin: PinStyle.magnet,
    font: 'plexmono',
    thread: ThreadStyle.dashed,
    yarn: 0xFF00897B,
  ),
  const ThemePack(
    id: 'travel_journal',
    nameEn: 'Travel Journal',
    nameVi: 'Nhật ký du lịch',
    category: ThemeCategory.personal,
    wall: 'kraft',
    papers: [10, 3, 11],
    paper: PaperStyle.indexCard,
    pin: PinStyle.washi,
    font: 'sedgwick',
    thread: ThreadStyle.dashed,
    yarn: 0xFF1565C0,
  ),
  const ThemePack(
    id: 'scrapbook_craft',
    nameEn: 'Scrapbook Craft',
    nameVi: 'Sổ lưu niệm thủ công',
    category: ThemeCategory.creative,
    wall: 'cardboard',
    papers: [7, 6, 8],
    paper: PaperStyle.indexCard,
    pin: PinStyle.washi,
    font: 'shantell',
    thread: ThreadStyle.twine,
    yarn: 0xFF8D6E63,
  ),
  const ThemePack(
    id: 'kids_colorful',
    nameEn: 'Kids Colorful',
    nameVi: 'Sắc màu cho bé',
    category: ThemeCategory.family,
    wall: 'felt',
    papers: [6, 1, 3, 0],
    pin: PinStyle.colorful,
    font: 'coiny',
    thread: ThreadStyle.beads,
    yarn: 0xFFEF6C00,
    stickers: ['star', 'heart', 'party'],
  ),
  const ThemePack(
    id: 'coffee_notes',
    nameEn: 'Coffee Notes',
    nameVi: 'Ghi chú cà phê',
    category: ThemeCategory.study,
    wall: 'dark_marble',
    papers: [10, 4, 11],
    paper: PaperStyle.lined,
    pin: PinStyle.clip,
    font: 'sedgwick',
    thread: ThreadStyle.twine,
    yarn: 0xFF8D6E63,
    stickers: ['coffee'],
  ),
  // --- Seasonal (Pro, all year) -----------------------------------------
  const ThemePack(
    id: 'lunar_new_year',
    nameEn: 'Lunar New Year',
    nameVi: 'Tết hoa mai',
    category: ThemeCategory.seasonal,
    wall: 'tet',
    papers: [7, 0, 11],
    pin: PinStyle.washi,
    font: 'lobster',
    thread: ThreadStyle.ribbon,
    yarn: 0xFFC62828,
    stickers: ['lixi', 'mai', 'newyear'],
  ),
  const ThemePack(
    id: 'peach_blossom',
    nameEn: 'Peach Blossom',
    nameVi: 'Tết hoa đào',
    category: ThemeCategory.seasonal,
    wall: 'tet_dao',
    papers: [1, 11, 7],
    pin: PinStyle.washi,
    font: 'charm',
    thread: ThreadStyle.ribbon,
    yarn: 0xFFD81B60,
    stickers: ['dao', 'lantern', 'newyear'],
  ),
  const ThemePack(
    id: 'christmas',
    nameEn: 'Christmas',
    nameVi: 'Giáng sinh',
    category: ThemeCategory.seasonal,
    wall: 'xmas',
    papers: [11, 7, 9],
    pin: PinStyle.tack,
    font: 'sedgwick',
    thread: ThreadStyle.beads,
    yarn: 0xFFC62828,
    stickers: ['tree', 'gift', 'snow'],
  ),
  const ThemePack(
    id: 'mid_autumn',
    nameEn: 'Mid-Autumn',
    nameVi: 'Trung thu',
    category: ThemeCategory.seasonal,
    wall: 'moon',
    papers: [4, 10, 0],
    pin: PinStyle.clip,
    font: 'lora',
    thread: ThreadStyle.beads,
    yarn: 0xFFF9A825,
    stickers: ['moon', 'starlantern'],
  ),
  const ThemePack(
    id: 'valentine',
    nameEn: 'Pink Love',
    nameVi: 'Tình yêu hồng',
    category: ThemeCategory.seasonal,
    wall: 'love',
    papers: [1, 7, 11],
    paper: PaperStyle.dots,
    pin: PinStyle.colorful,
    font: 'dancing',
    thread: ThreadStyle.ribbon,
    yarn: 0xFFD81B60,
    stickers: ['rose', 'heart'],
  ),
];

ThemePack? themePackById(String id) =>
    themePacks.where((t) => t.id == id).firstOrNull;

/// The free pack closest to each Pro one: what a template that suggests a
/// Pro look is made in without Pro, shown before it is used.
const _freeTwins = {
  'pastel_kawaii': 'marble_desk',
  'vintage_paper': 'kraft_workshop',
  'cozy_study': 'dark_academia',
  'polaroid_studio': 'minimal_cream',
  'ocean_blue': 'clean_office',
  'soft_lavender': 'linen_lilac',
  'botanical_green': 'moss_garden',
  'warm_autumn': 'warm_wood',
  'moonlight': 'dark_chalk',
  'y2k_pop': 'terrazzo_pop',
  'pixel_retro': 'clean_office',
  'travel_journal': 'kraft_workshop',
  'scrapbook_craft': 'cardboard_box',
  'kids_colorful': 'rainbow_school',
  'coffee_notes': 'dark_academia',
  'lunar_new_year': 'brick_loft',
  'peach_blossom': 'marble_desk',
  'christmas': 'green_classroom',
  'mid_autumn': 'dark_academia',
  'valentine': 'marble_desk',
};

/// [pack] itself when it is free (or Pro is unlocked), else its free twin.
ThemePack lookFor(ThemePack pack, {required bool pro}) => pack.pro && !pro
    ? themePackById(_freeTwins[pack.id] ?? 'cork_classic')!
    : pack;
