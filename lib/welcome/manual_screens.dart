import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme.dart';
import '../widgets/eraser_icon.dart';
import '../widgets/wall_background.dart';
import 'guide_motion.dart';

/// What is open on the little phone in a manual step.
enum ManualLayer {
  home,
  more,
  add,
  note,
  board,
  newBoard,
  wallHere,
  thread,
  settings,
  customize,
  editor,
  voice,
  reminder,
  export,
  systemShare,
  boardPick,
  search,
  views,
  pen,
  undo,
}

/// Places on the little phone a finger can go.
enum ManualTarget {
  search,
  share,
  palette,
  tabOpen,
  tabWork,
  tabPlus,
  noteA,
  noteB,
  pinB,
  gripB,
  threadMid,
  wall,
  wallLow,
  pen,
  layout,
  more,
  add,

  /// The [ManualSpot.index]th icon in a sheet's top row, the editor's
  /// tools, the marker bar or the export buttons.
  row,

  /// The [ManualSpot.index]th line of the open menu, sheet or page.
  item,
  editorSave,
  mic,
  undo,
}

class ManualSpot {
  const ManualSpot(this.target, [this.index = 0]);
  const ManualSpot.item(this.index) : target = ManualTarget.item;
  const ManualSpot.row(this.index) : target = ManualTarget.row;

  final ManualTarget target;
  final int index;
}

enum ManualMove { tap, hold, drag, pinch }

/// What a drag carries along.
enum ManualCarry { note, yarn, stroke, resize, lasso }

/// One move of the hand.
class ManualBeat {
  const ManualBeat.tap(this.at, {this.then})
    : move = ManualMove.tap,
      to = null,
      carry = null;
  const ManualBeat.hold(this.at, {this.then})
    : move = ManualMove.hold,
      to = null,
      carry = null;
  const ManualBeat.drag(
    this.at,
    ManualSpot this.to, {
    this.carry = ManualCarry.note,
    this.then,
  }) : move = ManualMove.drag;
  const ManualBeat.pinch(this.at, {this.then})
    : move = ManualMove.pinch,
      to = null,
      carry = null;

  final ManualMove move;
  final ManualSpot at;
  final ManualSpot? to;
  final ManualCarry? carry;

  /// What opens once the move is made.
  final ManualLayer? then;
}

/// A manual step, shown: the moves on a little phone, from [start].
class ManualShow {
  const ManualShow(
    this.beats, {
    this.start = ManualLayer.home,
    this.tied = false,
    this.stroke = false,
  });

  final List<ManualBeat> beats;
  final ManualLayer start;

  /// The two notes are already tied by a thread.
  final bool tied;

  /// A line is already drawn on the wall.
  final bool stroke;
}

// --- The little phone ---------------------------------------------------

const double _w = 300;
const double _h = 540;

// Where things sit on the home screen.
const _noteA = Rect.fromLTWH(24, 136, 116, 58);
const _noteB = Rect.fromLTWH(152, 198, 116, 58);
const _pinA = Offset(82, 140);
const _pinB = Offset(210, 202);
const _barY = 506.0;

// Milliseconds for each part of a move.
const _approach = 420;
const _lead = 500;
const _tail = 1500;

int _pressOf(ManualMove m) => switch (m) {
  ManualMove.tap => 220,
  ManualMove.hold => 820,
  ManualMove.drag => 180,
  ManualMove.pinch => 160,
};
int _travelOf(ManualMove m) => switch (m) {
  ManualMove.drag => 780,
  ManualMove.pinch => 760,
  _ => 0,
};
int _afterOf(ManualMove m) => m == ManualMove.tap ? 420 : 380;
int _beatLength(ManualBeat b) =>
    _approach + _pressOf(b.move) + _travelOf(b.move) + _afterOf(b.move);

/// One line of a menu, sheet or page.
typedef _Line = (IconData? icon, String label);

/// Plays a [ManualShow] on a little phone: a hand taps, holds and drags,
/// menus and sheets open as in the app, with the app's own words. It plays
/// twice and rests on its last screen with the last place to tap ringed.
/// Still (the last screen) when motion is reduced.
class ManualPlayer extends StatefulWidget {
  const ManualPlayer({super.key, required this.show});

  final ManualShow show;

  @override
  State<ManualPlayer> createState() => _ManualPlayerState();
}

class _ManualPlayerState extends State<ManualPlayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(vsync: this)
    ..addStatusListener((s) {
      if (s != AnimationStatus.completed || !mounted) return;
      if (++_plays < 2) _clock.forward(from: 0);
    });
  int _plays = 0;

  int get _total =>
      _lead +
      widget.show.beats.fold<int>(0, (sum, b) => sum + _beatLength(b)) +
      _tail;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_clock.duration == null) _play();
  }

  @override
  void didUpdateWidget(ManualPlayer old) {
    super.didUpdateWidget(old);
    if (old.show != widget.show) _play();
  }

  void _play() {
    _plays = 0;
    _clock.duration = Duration(milliseconds: _total);
    if (guideMoves(context)) {
      _clock.forward(from: 0);
    } else {
      _clock.value = 1;
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ExcludeSemantics(
      child: IgnorePointer(
        child: MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.noScaling),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 440),
            child: FittedBox(
              child: Container(
                width: _w + 16,
                height: _h + 16,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(34),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: SizedBox(
                    width: _w,
                    height: _h,
                    child: AnimatedBuilder(
                      animation: _clock,
                      builder: (context, _) => _Frame(
                        show: widget.show,
                        ms: (_clock.value * _total).round(),
                        total: _total,
                        l10n: l10n,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The phone at [ms] into the show.
class _Frame extends StatelessWidget {
  const _Frame({
    required this.show,
    required this.ms,
    required this.total,
    required this.l10n,
  });

  final ManualShow show;
  final int ms;
  final int total;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    var layer = show.start;
    var noteShift = Offset.zero;
    var noteScale = 1.0;
    Offset? yarnTo;
    final strokes = <(Offset, Offset)>[];
    Rect? lasso;
    var hand = const Offset(_w / 2, _h + 60);
    var pressed = false;
    var spread = 0.0;
    Offset? ring;
    var clock = _lead;
    final atRest = ms >= total - _tail;

    for (final beat in show.beats) {
      final start = clock;
      final press = start + _approach;
      final travel = press + _pressOf(beat.move);
      final end = travel + _travelOf(beat.move);
      final from = _spot(beat.at, layer);
      final to = beat.to == null ? from : _spot(beat.to!, layer);
      final shift = _shiftFor(beat.at, noteShift);
      final fromAt = from + shift;
      clock = end + _afterOf(beat.move);
      if (ms < start) break;
      ring = beat.move == ManualMove.drag ? to : fromAt;
      if (ms < press) {
        final t = Curves.easeInOutCubic.transform((ms - start) / _approach);
        hand = Offset.lerp(hand, fromAt, t)!;
        break;
      }
      // Pressed, maybe moving.
      final moving = ms < end;
      final p = beat.move == ManualMove.drag || beat.move == ManualMove.pinch
          ? Curves.easeInOutCubic.transform(
              ((ms - travel) / math.max(1, end - travel)).clamp(0.0, 1.0),
            )
          : 0.0;
      hand = beat.move == ManualMove.drag
          ? Offset.lerp(fromAt, to, p)!
          : fromAt;
      if (beat.move == ManualMove.pinch) spread = moving ? p : 0;
      if (beat.move == ManualMove.drag) {
        switch (beat.carry!) {
          case ManualCarry.note:
            if (moving) {
              noteShift += (to - fromAt) * p;
            } else {
              noteShift += to - fromAt;
            }
          case ManualCarry.yarn:
            yarnTo = hand;
          case ManualCarry.stroke:
            strokes.add((fromAt, hand));
          case ManualCarry.resize:
            noteScale = 1 + .45 * p;
          case ManualCarry.lasso:
            lasso = Rect.fromPoints(fromAt, hand);
        }
      }
      pressed = moving;
      if (moving) {
        // The menu opens when a tap lands or a hold is long enough.
        final opensAt = beat.move == ManualMove.tap
            ? press + 80
            : beat.move == ManualMove.hold
            ? travel
            : end;
        if (ms >= opensAt && beat.then != null) layer = beat.then!;
        break;
      }
      layer = beat.then ?? layer;
      if (beat.carry == ManualCarry.yarn) yarnTo = to;
    }

    final fade = atRest
        ? 1 - ((ms - (total - _tail)) / 300).clamp(0.0, 1.0)
        : 1.0;
    final selected = _selectedNote();
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(child: _home(layer, noteShift, noteScale, selected)),
        if (show.tied)
          Positioned.fill(
            child: CustomPaint(painter: _YarnLine(_pinA, _pinB + noteShift)),
          ),
        if (yarnTo != null)
          Positioned.fill(
            child: CustomPaint(painter: _YarnLine(_pinB + noteShift, yarnTo)),
          ),
        if (show.stroke || strokes.isNotEmpty)
          Positioned.fill(
            child: CustomPaint(
              painter: _Strokes([
                if (show.stroke)
                  (const Offset(40, 300), const Offset(250, 400)),
                ...strokes,
              ]),
            ),
          ),
        if (lasso != null)
          Positioned.fromRect(
            rect: lasso,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.chalk, width: 2),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),
        ..._overlay(layer),
        if (atRest && ring != null) _ringAt(ring, 1),
        if (fade > 0 && ms > _lead - 200) ...[
          if (spread > 0) ...[
            _ringAt(hand - Offset(30 + 40 * spread, 30 + 40 * spread), fade),
            _ringAt(hand + Offset(30 + 40 * spread, 30 + 40 * spread), fade),
          ] else if (pressed)
            _ringAt(hand, fade),
          Positioned(
            left: hand.dx - 16,
            top: hand.dy - 4,
            child: Opacity(opacity: fade, child: const _Hand()),
          ),
        ],
      ],
    );
  }

  /// A drag that starts on the note picks it up where it now is.
  Offset _shiftFor(ManualSpot at, Offset noteShift) => switch (at.target) {
    ManualTarget.noteB || ManualTarget.pinB || ManualTarget.gripB => noteShift,
    _ => Offset.zero,
  };

  bool _selectedNote() =>
      show.beats.any((b) => b.at.target == ManualTarget.gripB);

  Widget _ringAt(Offset at, double opacity) => Positioned(
    left: at.dx - 20,
    top: at.dy - 20,
    child: Opacity(
      opacity: opacity,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.accent.withValues(alpha: .25),
          border: Border.all(color: AppColors.accent, width: 3),
        ),
      ),
    ),
  );

  // --- Places -------------------------------------------------------------

  Offset _spot(ManualSpot s, ManualLayer layer) => switch (s.target) {
    ManualTarget.search => const Offset(196, 30),
    ManualTarget.share => const Offset(230, 30),
    ManualTarget.palette => const Offset(264, 30),
    ManualTarget.tabOpen => const Offset(52, 82),
    ManualTarget.tabWork => const Offset(138, 82),
    ManualTarget.tabPlus => const Offset(200, 82),
    ManualTarget.noteA => _noteA.center,
    ManualTarget.noteB => _noteB.center,
    ManualTarget.pinB => _pinB,
    ManualTarget.gripB => _noteB.bottomRight - const Offset(4, 4),
    ManualTarget.threadMid =>
      Offset.lerp(_pinA, _pinB, .5)! + const Offset(0, 8),
    ManualTarget.wall => const Offset(110, 330),
    ManualTarget.wallLow => const Offset(200, 400),
    ManualTarget.pen => const Offset(85, _barY),
    ManualTarget.layout => const Offset(127, _barY),
    ManualTarget.more => const Offset(169, _barY),
    ManualTarget.add => const Offset(262, 496),
    ManualTarget.editorSave => const Offset(258, 134),
    ManualTarget.mic => const Offset(150, 250),
    ManualTarget.undo => const Offset(222, 446),
    ManualTarget.row => _rowSpot(layer, s.index),
    ManualTarget.item => _itemSpot(layer, s.index),
  };

  Offset _rowSpot(ManualLayer layer, int i) => switch (layer) {
    ManualLayer.editor =>
      i == 5 ? const Offset(262, 398) : Offset(44 + i * 36.0, 398),
    ManualLayer.pen => Offset(_penX[i], _barY),
    ManualLayer.export => Offset(60 + i * 90.0, 478),
    _ => () {
      final sheet = _sheetOf(layer);
      final n = sheet.top.length;
      return Offset(16 + (_w - 32) * (i + .5) / n, sheet.y + 44 + 28);
    }(),
  };

  Offset _itemSpot(ManualLayer layer, int i) => switch (layer) {
    ManualLayer.more => Offset(117, _moreTop + 4 + i * 28 + 14),
    ManualLayer.views => Offset(146, _viewsTop + 4 + i * 28 + 14),
    ManualLayer.settings => _settingsSpot(i),
    _ => () {
      final sheet = _sheetOf(layer);
      return Offset(
        _w / 2,
        sheet.y + 44 + (sheet.top.isEmpty ? 0 : 62) + i * 32 + 16,
      );
    }(),
  };

  // --- The home screen ----------------------------------------------------

  Widget _home(
    ManualLayer layer,
    Offset noteShift,
    double noteScale,
    bool selected,
  ) {
    final cork = walls.firstWhere((w) => w.id == 'cork');
    final searching = layer == ManualLayer.search;
    final marking = layer == ManualLayer.pen;
    return Stack(
      children: [
        Positioned.fill(child: WallBackground(wall: cork, decor: false)),
        // Header: the name, then search, share and customize.
        if (searching)
          Positioned(
            left: 14,
            right: 14,
            top: 12,
            height: 36,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.chalk,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 18, color: AppColors.inkSoft),
                  const SizedBox(width: 8),
                  Text(l10n.manualSearchQuery, style: _ui(14)),
                ],
              ),
            ),
          )
        else ...[
          Positioned(
            left: 16,
            top: 12,
            child: Text(
              l10n.appTitle,
              style: const TextStyle(
                fontFamily: 'Pacifico',
                fontSize: 21,
                color: AppColors.chalk,
              ),
            ),
          ),
          for (final (x, icon) in [
            (196.0, Icons.search),
            (230.0, Icons.ios_share),
            (264.0, Icons.palette_outlined),
          ])
            Positioned(
              left: x - 11,
              top: 19,
              child: Icon(icon, size: 22, color: AppColors.chalk),
            ),
        ],
        // Board tabs.
        Positioned(
          left: 12,
          top: 66,
          child: Row(
            children: [
              _tab(l10n.defaultBoardName, on: true),
              const SizedBox(width: 6),
              _tab(l10n.manualTabWork),
              const SizedBox(width: 6),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.chalk, width: 1.5),
                ),
                child: const Icon(Icons.add, size: 18, color: AppColors.chalk),
              ),
            ],
          ),
        ),
        // Two notes.
        _paper(
          _noteA,
          l10n.guideNoteMum,
          AppColors.notePapers[1],
          faded: searching,
        ),
        _paper(
          _noteB.shift(noteShift),
          l10n.guideNoteWater,
          AppColors.notePapers[0],
          scale: noteScale,
          grips: selected,
        ),
        // The tool pill, or the marker bar while drawing.
        Positioned(
          left: 12,
          top: _barY - 22,
          child: marking ? _markerBar() : _toolPill(),
        ),
        // The yellow paper that adds a note.
        Positioned(
          left: 240,
          top: 474,
          child: Transform.rotate(
            angle: .05,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x55000000),
                    blurRadius: 6,
                    offset: Offset(1, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.edit, size: 20, color: AppColors.ink),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tab(String name, {bool on = false}) => Container(
    width: 80,
    height: 32,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: on ? const Color(0x33FDFBF3) : null,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.chalk, width: on ? 2 : 1),
    ),
    child: Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontFamily: 'BeVietnamPro',
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: AppColors.chalk,
      ),
    ),
  );

  Widget _paper(
    Rect at,
    String words,
    Color color, {
    double scale = 1,
    bool faded = false,
    bool grips = false,
  }) => Positioned(
    left: at.left,
    top: at.top,
    child: Opacity(
      opacity: faded ? .35 : 1,
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: at.width,
          height: at.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 16, 8, 6),
                  decoration: BoxDecoration(
                    color: color,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x55000000),
                        blurRadius: 5,
                        offset: Offset(1, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    words,
                    maxLines: 2,
                    style: const TextStyle(
                      fontFamily: 'PatrickHand',
                      fontSize: 15,
                      height: 1.1,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: at.width / 2 - 6,
                top: -2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD84343),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              if (grips) ...[
                for (final (x, icon) in [
                  (-10.0, Icons.rotate_right),
                  (at.width - 12, Icons.open_in_full),
                ])
                  Positioned(
                    left: x,
                    top: at.height - 12,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: AppColors.ink,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 13, color: AppColors.chalk),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    ),
  );

  Widget _toolPill() => Container(
    height: 44,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: AppColors.overlayDark,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        for (final (icon, label) in [
          (Icons.filter_alt_outlined, l10n.toolFilter),
          (Icons.gesture, l10n.toolPen),
          (Icons.grid_view, l10n.toolLayout),
          (Icons.more_vert, l10n.toolMore),
        ])
          SizedBox(
            width: 42,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: AppColors.chalk),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 8.5,
                    color: AppColors.chalk,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );

  static const _penX = [34.0, 74.0, 114.0, 154.0, 206.0];

  Widget _markerBar() => SizedBox(
    width: 240,
    height: 44,
    child: Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.overlayDark,
              borderRadius: BorderRadius.circular(22),
            ),
          ),
        ),
        for (final (i, child) in [
          const Icon(Icons.edit, size: 18, color: AppColors.chalk),
          const Icon(Icons.border_color, size: 18, color: AppColors.chalk),
          const SizedBox.square(
            dimension: 18,
            child: EraserIcon(color: AppColors.chalk),
          ),
          const Icon(Icons.undo, size: 18, color: AppColors.chalk),
        ].indexed)
          Positioned(left: _penX[i] - 21, top: 13, child: child),
        Positioned(
          left: _penX[4] - 39,
          top: 9,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(l10n.done, style: _ui(12, weight: FontWeight.w700)),
          ),
        ),
      ],
    ),
  );

  // --- What opens over it -------------------------------------------------

  static const _moreTop = 476.0 - 9 * 28 - 8;
  static const _viewsTop = 476.0 - 3 * 28 - 8;

  List<_Line> get _moreLines => [
    (Icons.dashboard_customize_outlined, l10n.galleryTitle),
    (Icons.add_photo_alternate_outlined, l10n.pinPhotos),
    (Icons.checklist_rtl, l10n.select),
    (Icons.auto_awesome_mosaic_outlined, l10n.arrange),
    (Icons.fit_screen_outlined, l10n.fitAll),
    (Icons.image_outlined, l10n.exportBoard),
    (Icons.delete_outline, l10n.trash),
    (Icons.dark_mode_outlined, l10n.lightsOff),
    (Icons.settings_outlined, l10n.settingsTitle),
  ];

  List<Widget> _overlay(ManualLayer layer) => switch (layer) {
    ManualLayer.home || ManualLayer.search || ManualLayer.pen => const [],
    ManualLayer.more => [_popup(12, _moreTop, 210, _moreLines)],
    ManualLayer.views => [
      _popup(80, _viewsTop, 132, [
        (Icons.wallpaper, l10n.viewWall),
        (Icons.grid_view, l10n.viewGrid),
        (Icons.view_agenda_outlined, l10n.viewList),
      ]),
    ],
    ManualLayer.undo => [_undoBar()],
    ManualLayer.settings => [_settingsPage()],
    ManualLayer.editor => [_scrim(), _editor()],
    ManualLayer.voice => [_scrim(), _voice()],
    ManualLayer.export => [_exportPage()],
    _ => [_scrim(), _sheet(_sheetOf(layer))],
  };

  Widget _scrim() =>
      const Positioned.fill(child: ColoredBox(color: Color(0x66000000)));

  Widget _popup(double left, double top, double width, List<_Line> lines) =>
      Positioned(
        left: left,
        top: top,
        width: width,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: _card(),
          child: Column(
            children: [
              for (final (icon, label) in lines)
                SizedBox(
                  height: 28,
                  child: Row(
                    children: [
                      const SizedBox(width: 10),
                      Icon(icon, size: 16, color: AppColors.ink),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _ui(12.5),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );

  BoxDecoration _card() => BoxDecoration(
    color: AppColors.paper,
    borderRadius: BorderRadius.circular(12),
    boxShadow: const [
      BoxShadow(color: Color(0x66000000), blurRadius: 14, offset: Offset(0, 4)),
    ],
  );

  _Sheet _sheetOf(ManualLayer layer) => switch (layer) {
    ManualLayer.add => _Sheet(
      l10n.addToWall,
      top: [
        (AppIcons.note, l10n.typeNormal),
        (AppIcons.checklist, l10n.typeChecklist),
        (AppIcons.photo, l10n.typePhoto),
        (AppIcons.link, l10n.typeLink),
        (AppIcons.voice, l10n.typeAudio),
        (AppIcons.drawing, l10n.typeDrawing),
      ],
      lines: [
        (Icons.label_outline, l10n.typeLabel),
        (AppIcons.sticker, l10n.typeSticker),
        (Icons.photo_library_outlined, l10n.memoryWall),
      ],
    ),
    ManualLayer.note => _Sheet(
      l10n.guideNoteWater,
      top: [
        (Icons.push_pin_outlined, l10n.pinShort),
        (Icons.drive_file_move_outlined, l10n.move),
        (Icons.ios_share, l10n.share),
        (Icons.download_outlined, l10n.saveShort),
        (Icons.delete_outline, l10n.delete),
      ],
      lines: [
        (Icons.edit_outlined, l10n.edit),
        (Icons.inventory_2_outlined, l10n.archiveNote),
        (Icons.anchor, l10n.lockInPlace),
        (Icons.layers_outlined, l10n.stackNotes),
        (Icons.timeline, l10n.tieThreadTo),
        (Icons.checklist_rtl, l10n.select),
      ],
    ),
    ManualLayer.board => _Sheet(
      l10n.defaultBoardName,
      lines: [
        (Icons.edit_outlined, l10n.editBoard),
        (Icons.lock_outline, l10n.boardMakePrivate),
        (Icons.palette_outlined, l10n.changeTheme),
        (Icons.cleaning_services_outlined, l10n.clearSamples),
        (Icons.delete_outline, l10n.deleteBoard),
      ],
    ),
    ManualLayer.newBoard => _Sheet(
      l10n.newBoard,
      lines: [
        (Icons.crop_square, l10n.newBoardBlank),
        (Icons.dashboard_customize_outlined, l10n.newBoardFromTemplate),
        (Icons.photo_library_outlined, l10n.memoryWall),
      ],
    ),
    ManualLayer.wallHere => _Sheet(
      l10n.addToWall,
      lines: [
        (AppIcons.note, l10n.noteHere),
        (Icons.add_photo_alternate_outlined, l10n.photosHere),
        (AppIcons.sticker, l10n.stickerHere),
      ],
    ),
    ManualLayer.thread => _Sheet(
      l10n.thread,
      lines: [
        (Icons.palette_outlined, l10n.color),
        (Icons.edit_outlined, l10n.threadLabelHint),
        (Icons.arrow_right_alt, l10n.threadArrow),
        (Icons.content_cut, l10n.cutThread),
      ],
    ),
    ManualLayer.customize => _Sheet(
      l10n.customize,
      lines: [
        (Icons.wallpaper, l10n.wallSection),
        (Icons.dark_mode_outlined, l10n.nightSection),
        (Icons.text_fields, l10n.fontSection),
        (Icons.push_pin_outlined, l10n.pinSection),
      ],
    ),
    ManualLayer.reminder => _Sheet(
      l10n.reminder,
      lines: [
        (Icons.schedule, l10n.remindInHour),
        (Icons.wb_twilight, l10n.remindTonight),
        (Icons.wb_sunny_outlined, l10n.remindTomorrow),
        (Icons.edit_calendar_outlined, l10n.remindPick),
        (Icons.repeat, l10n.repeat),
      ],
    ),
    ManualLayer.boardPick => _Sheet(
      l10n.shareWhere,
      lines: [
        (Icons.dashboard_outlined, l10n.defaultBoardName),
        (Icons.dashboard_outlined, l10n.manualTabWork),
      ],
    ),
    ManualLayer.systemShare => _Sheet(
      l10n.share,
      top: [
        (Icons.message_outlined, ''),
        (Icons.mail_outline, ''),
        (null, l10n.appTitle),
        (Icons.cloud_outlined, ''),
      ],
      lines: const [],
    ),
    _ => _Sheet('', lines: const []),
  };

  Widget _sheet(_Sheet s) => Positioned(
    left: 0,
    right: 0,
    top: s.y,
    bottom: 0,
    child: Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.inkHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(
            height: 32,
            child: Center(
              child: Text(
                s.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _ui(14, weight: FontWeight.w700),
              ),
            ),
          ),
          if (s.top.isNotEmpty)
            SizedBox(
              height: 62,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    for (final (icon, label) in s.top)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (icon == null)
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.sticky_note_2_outlined,
                                  size: 18,
                                  color: AppColors.ink,
                                ),
                              )
                            else
                              Icon(icon, size: 22, color: AppColors.ink),
                            const SizedBox(height: 4),
                            Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _ui(9.5),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          for (final (icon, label) in s.lines)
            SizedBox(
              height: 32,
              child: Row(
                children: [
                  const SizedBox(width: 20),
                  Icon(icon, size: 18, color: AppColors.ink),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _ui(13),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
        ],
      ),
    ),
  );

  List<(bool header, IconData? icon, String label)> get _settingsLines => [
    (true, null, l10n.settingsGeneral),
    (false, Icons.translate, l10n.languageSection),
    (false, Icons.widgets_outlined, l10n.widgetSection),
    (true, null, l10n.privacySection),
    (false, Icons.lock_outline, l10n.appLock),
    (true, null, l10n.settingsData),
    (false, Icons.sync, l10n.syncTitle),
    (false, Icons.history, l10n.autoBackup),
    (false, Icons.ios_share, l10n.exportData),
    (false, Icons.download, l10n.importData),
    (false, Icons.delete_outline, l10n.trash),
    (true, null, l10n.settingsHelp),
    (false, Icons.help_outline, l10n.howToUse),
  ];

  Offset _settingsSpot(int index) {
    var y = 64.0;
    var item = 0;
    for (final (header, _, _) in _settingsLines) {
      final height = header ? 28.0 : 33.0;
      if (!header) {
        if (item == index) return Offset(_w / 2, y + height / 2);
        item++;
      }
      y += height;
    }
    return Offset(_w / 2, y);
  }

  Widget _settingsPage() => Positioned.fill(
    child: ColoredBox(
      color: AppColors.paper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 56,
            child: Row(
              children: [
                const SizedBox(width: 14),
                const Icon(Icons.arrow_back, size: 20, color: AppColors.ink),
                const SizedBox(width: 16),
                Text(
                  l10n.settingsTitle,
                  style: TextStyle(
                    fontSize: 20 * 1.0,
                    color: AppColors.ink,
                    fontFamily: fontChoices.first.family,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (final (header, icon, label) in _settingsLines)
            SizedBox(
              height: header ? 28 : 33,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: header
                    ? Align(
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          label,
                          style: _ui(11.5, color: AppColors.inkSoft),
                        ),
                      )
                    : Row(
                        children: [
                          Icon(icon, size: 18, color: AppColors.ink),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _ui(13),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _editor() => Positioned(
    left: 16,
    top: 110,
    width: 268,
    height: 310,
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.notePapers[0],
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 14)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 48,
            color: const Color(0x2EFFFFFF),
            child: Row(
              children: [
                const SizedBox(width: 14),
                const Icon(Icons.close, size: 20, color: AppColors.ink),
                const SizedBox(width: 14),
                const Icon(Icons.text_fields, size: 20, color: AppColors.ink),
                const Spacer(),
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.ink,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 18,
                    color: AppColors.chalk,
                  ),
                ),
                const SizedBox(width: 6),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(
              l10n.guideNoteWater,
              style: const TextStyle(
                fontFamily: 'PatrickHand',
                fontSize: 18,
                color: AppColors.ink,
              ),
            ),
          ),
          for (var i = 0; i < 4; i++)
            Container(
              height: 1,
              margin: const EdgeInsets.fromLTRB(16, 26, 16, 0),
              color: const Color(0x22000000),
            ),
          const Spacer(),
          SizedBox(
            height: 44,
            child: Row(
              children: [
                const SizedBox(width: 10),
                for (final icon in [
                  Icons.photo_camera_back_outlined,
                  Icons.alarm_add,
                  Icons.palette_outlined,
                  AppIcons.sticker,
                  AppIcons.pin,
                ])
                  SizedBox(
                    width: 36,
                    child: Icon(icon, size: 19, color: AppColors.ink),
                  ),
                const Spacer(),
                const Icon(
                  AppIcons.delete,
                  size: 19,
                  color: AppColors.deleteIcon,
                ),
                const SizedBox(width: 14),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _voice() => Positioned(
    left: 16,
    top: 110,
    width: 268,
    height: 310,
    child: Container(
      color: AppColors.notePapers[0],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: AppColors.ink,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic, size: 32, color: AppColors.chalk),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              l10n.recordHint,
              textAlign: TextAlign.center,
              style: _ui(12.5),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _undoBar() => Positioned(
    left: 50,
    width: 200,
    top: 430,
    height: 32,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.undoMove,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _ui(12, color: AppColors.chalk),
            ),
          ),
          Text(
            l10n.undo,
            style: _ui(12, color: AppColors.accent, weight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );

  Widget _exportPage() {
    final cork = walls.firstWhere((w) => w.id == 'cork');
    return Positioned.fill(
      child: ColoredBox(
        color: AppColors.ink,
        child: Stack(
          children: [
            Positioned(
              left: 16,
              top: 16,
              child: Text(
                l10n.exportBoard,
                style: _ui(15, color: AppColors.chalk, weight: FontWeight.w600),
              ),
            ),
            Positioned(
              left: 50,
              top: 64,
              width: 200,
              height: 340,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: WallBackground(wall: cork, decor: false),
                    ),
                    Positioned(
                      left: 20,
                      top: 40,
                      child: Container(
                        width: 70,
                        height: 40,
                        color: AppColors.notePapers[1],
                      ),
                    ),
                    Positioned(
                      left: 100,
                      top: 90,
                      child: Container(
                        width: 70,
                        height: 40,
                        color: AppColors.notePapers[0],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            for (final (i, (icon, label)) in [
              (Icons.download_outlined, l10n.saveImage),
              (Icons.picture_as_pdf_outlined, l10n.exportPdf),
              (Icons.ios_share, l10n.share),
            ].indexed)
              Positioned(
                left: 60 + i * 90.0 - 42,
                top: 456,
                width: 84,
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.chalk,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 20, color: AppColors.ink),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _ui(10.5, color: AppColors.chalk),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

TextStyle _ui(
  double size, {
  Color color = AppColors.ink,
  FontWeight weight = FontWeight.w500,
}) => TextStyle(
  fontFamily: 'BeVietnamPro',
  fontSize: size,
  fontWeight: weight,
  color: color,
);

/// A bottom sheet's contents and where it starts.
class _Sheet {
  _Sheet(this.title, {this.top = const [], required this.lines});

  final String title;
  final List<_Line> top;
  final List<_Line> lines;

  double get y =>
      _h - (44 + (top.isEmpty ? 0 : 62) + lines.length * 32 + 16).toDouble();
}

/// The pointing hand: white with an ink outline, so it shows on cork and
/// on paper alike.
class _Hand extends StatelessWidget {
  const _Hand();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 40,
    height: 40,
    child: Stack(
      children: [
        Icon(
          Icons.touch_app,
          size: 40,
          color: AppColors.chalk,
          shadows: [Shadow(color: Color(0x88000000), blurRadius: 6)],
        ),
        Icon(Icons.touch_app_outlined, size: 40, color: AppColors.ink),
      ],
    ),
  );
}

class _YarnLine extends CustomPainter {
  const _YarnLine(this.a, this.b);

  final Offset a;
  final Offset b;

  @override
  void paint(Canvas canvas, Size size) => paintGuideYarn(canvas, a, b);

  @override
  bool shouldRepaint(_YarnLine old) => old.a != a || old.b != b;
}

class _Strokes extends CustomPainter {
  const _Strokes(this.lines);

  final List<(Offset, Offset)> lines;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = AppColors.chalk;
    for (final (a, b) in lines) {
      final mid = Offset.lerp(a, b, .5)! + const Offset(30, -40);
      canvas.drawPath(
        Path()
          ..moveTo(a.dx, a.dy)
          ..quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_Strokes old) => true;
}
