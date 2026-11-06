import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/note.dart';
import '../theme.dart';
import '../widgets/eraser_icon.dart';
import '../widgets/note_views.dart';
import '../widgets/wall_background.dart';
import 'guide_motion.dart';
import 'practice_wall.dart';
import 'welcome_guide.dart';

/// One short topic of the manual: a title, a line saying what it is about,
/// two to four steps, and one picture.
class ManualTopic {
  const ManualTopic({
    required this.icon,
    required this.title,
    required this.summary,
    required this.steps,
    required this.picture,
  });

  final IconData icon;
  final String title;
  final String summary;
  final List<String> steps;
  final Widget Function() picture;
}

/// The manual's topics, in reading order.
List<ManualTopic> manualTopics(AppLocalizations l10n) => [
  ManualTopic(
    icon: Icons.note_add_outlined,
    title: l10n.manualFirstTitle,
    summary: l10n.manualFirstSummary,
    steps: [
      l10n.manualFirstStep1,
      l10n.manualFirstStep2,
      l10n.manualFirstStep3,
    ],
    picture: () => const _PracticePicture(PracticeStep.add),
  ),
  ManualTopic(
    icon: Icons.open_with,
    title: l10n.manualMoveTitle,
    summary: l10n.manualMoveSummary,
    steps: [
      l10n.manualMoveStep1,
      l10n.manualMoveStep2,
      l10n.manualMoveStep3,
      l10n.manualMoveStep4,
    ],
    picture: () => const _PracticePicture(PracticeStep.move),
  ),
  ManualTopic(
    icon: Icons.timeline,
    title: l10n.manualThreadTitle,
    summary: l10n.manualThreadSummary,
    steps: [
      l10n.manualThreadStep1,
      l10n.manualThreadStep2,
      l10n.manualThreadStep3,
    ],
    picture: () => const _PracticePicture(PracticeStep.tie),
  ),
  ManualTopic(
    icon: Icons.gesture,
    title: l10n.manualDrawTitle,
    summary: l10n.manualDrawSummary,
    steps: [l10n.manualDrawStep1, l10n.manualDrawStep2, l10n.manualDrawStep3],
    picture: () => const _DrawPicture(),
  ),
  ManualTopic(
    icon: Icons.dashboard_outlined,
    title: l10n.manualBoardsTitle,
    summary: l10n.manualBoardsSummary,
    steps: [
      l10n.manualBoardsStep1,
      l10n.manualBoardsStep2,
      l10n.manualBoardsStep3,
    ],
    picture: () => const _BoardsPicture(),
  ),
  ManualTopic(
    icon: Icons.photo_library_outlined,
    title: l10n.manualPhotosTitle,
    summary: l10n.manualPhotosSummary,
    steps: [
      l10n.manualPhotosStep1,
      l10n.manualPhotosStep2,
      l10n.manualPhotosStep3,
    ],
    picture: () => const _PhotosPicture(),
  ),
  ManualTopic(
    icon: Icons.search,
    title: l10n.manualFindTitle,
    summary: l10n.manualFindSummary,
    steps: [l10n.manualFindStep1, l10n.manualFindStep2, l10n.manualFindStep3],
    picture: () => const _FindPicture(),
  ),
];

/// Settings → Help → How to use: the guide again, step by step, and the
/// manual as short topics. Reading it changes nothing.
class HowToUsePage extends StatelessWidget {
  const HowToUsePage({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const HowToUsePage()));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topics = manualTopics(l10n);
    final ground = guideGround(context);
    return Scaffold(
      backgroundColor: ground,
      appBar: AppBar(
        backgroundColor: ground,
        foregroundColor: AppColors.ink,
        title: Text(l10n.howToUse),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _ReplayCard(
                  onTap: () => WelcomeGuide.open(context, replay: true),
                ),
                const SizedBox(height: 24),
                Semantics(
                  header: true,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                    child: Text(
                      l10n.howToUseTopics,
                      style: AppType.heading(context),
                    ),
                  ),
                ),
                for (final (i, topic) in topics.indexed)
                  ListTile(
                    key: Key('manual-topic-$i'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    minVerticalPadding: 10,
                    leading: _TopicBadge(icon: topic.icon, index: i),
                    title: Text(
                      topic.title,
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    subtitle: Text(
                      topic.summary,
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 14,
                        height: 1.35,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.inkSoft,
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ManualTopicPage(start: i),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The topic's icon on a little square of note paper.
class _TopicBadge extends StatelessWidget {
  const _TopicBadge({required this.icon, required this.index});

  final IconData icon;
  final int index;

  @override
  Widget build(BuildContext context) {
    final paper = AppColors.notePapers[index % AppColors.freePapers];
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isNight(context) ? nightPaper(paper) : paper,
        borderRadius: BorderRadius.circular(AppRadii.paper),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26302318),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: AppColors.ink, size: 24),
    );
  }
}

/// "Replay the guide", the first way in: a large sunny card.
class _ReplayCard extends StatelessWidget {
  const _ReplayCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sun = isNight(context)
        ? nightPaper(AppColors.accent)
        : AppColors.accent;
    return Material(
      color: sun,
      borderRadius: BorderRadius.circular(AppRadii.control * 1.5),
      elevation: 2,
      shadowColor: AppColors.shadow,
      child: InkWell(
        key: const Key('manual-replay'),
        borderRadius: BorderRadius.circular(AppRadii.control * 1.5),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(
                Icons.play_circle_outline,
                size: 36,
                color: AppColors.ink,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.guideReplay,
                      style: TextStyle(
                        fontSize: 22 * noteFontScale(context),
                        height: 1.15,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.guideReplayHint,
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 14,
                        height: 1.4,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One topic on a page of its own, with Previous and Next to walk through
/// them all in order. Its picture is still and does nothing.
class ManualTopicPage extends StatefulWidget {
  const ManualTopicPage({super.key, required this.start});

  final int start;

  @override
  State<ManualTopicPage> createState() => _ManualTopicPageState();
}

class _ManualTopicPageState extends State<ManualTopicPage> {
  late int _at = widget.start;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topics = manualTopics(l10n);
    final topic = topics[_at];
    final last = _at == topics.length - 1;
    final ground = guideGround(context);
    final buttonText = const TextStyle(
      fontFamily: 'BeVietnamPro',
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );
    return Scaffold(
      backgroundColor: ground,
      appBar: AppBar(
        backgroundColor: ground,
        foregroundColor: AppColors.ink,
        title: Text(l10n.howToUse),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: AppMetrics.motion(context, milliseconds: 220),
                child: SingleChildScrollView(
                  key: ValueKey('topic-$_at'),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: _body(context, topic, topics.length),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Row(
                  children: [
                    Expanded(
                      child: _at == 0
                          ? const SizedBox.shrink()
                          : OutlinedButton.icon(
                              key: const Key('manual-previous'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 52),
                                textStyle: buttonText,
                              ),
                              onPressed: () => setState(() => _at--),
                              icon: const Icon(Icons.arrow_back, size: 18),
                              label: Text(
                                l10n.howToUsePrevious,
                                textAlign: TextAlign.center,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        key: const Key('manual-next'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          textStyle: buttonText,
                        ),
                        onPressed: last
                            ? () => Navigator.of(context).pop()
                            : () => setState(() => _at++),
                        child: Text(
                          last ? l10n.guideDone : l10n.guideNext,
                          textAlign: TextAlign.center,
                        ),
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
  }

  Widget _body(BuildContext context, ManualTopic topic, int total) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.howToUseTopicOf(_at + 1, total),
          style: AppType.caption(context),
        ),
        const SizedBox(height: 4),
        Semantics(
          header: true,
          child: Text(
            topic.title,
            style: TextStyle(
              fontSize: 32 * noteFontScale(context),
              height: 1.1,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          topic.summary,
          style: const TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 16,
            height: 1.45,
            color: AppColors.inkSoft,
          ),
        ),
        const SizedBox(height: 16),
        _Picture(child: topic.picture()),
        const SizedBox(height: 20),
        for (final (i, step) in topic.steps.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isNight(context)
                          ? nightPaper(AppColors.accent)
                          : AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      textScaler: TextScaler.noScaling,
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    step,
                    style: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 16,
                      height: 1.45,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A topic's picture: still, inert, its words at their drawn size, scaled
/// to the page's width (and never taller than 340).
class _Picture extends StatelessWidget {
  const _Picture({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ExcludeFocus(
      child: IgnorePointer(
        child: MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.noScaling, disableAnimations: true),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 340),
            child: Center(child: FittedBox(child: child)),
          ),
        ),
      ),
    ),
  );
}

/// A step of the practice, as a picture: the lit window and its label.
class _PracticePicture extends StatelessWidget {
  const _PracticePicture(this.step);

  final PracticeStep step;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: SizedBox(
      width: 400,
      height: 520,
      child: PracticeWall(key: ValueKey(step), still: step, top: 0),
    ),
  );
}

/// A cork panel of the pictures' size, with [children] on it.
class _Cork extends StatelessWidget {
  const _Cork({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cork = walls.firstWhere((w) => w.id == 'cork');
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 400,
        height: 300,
        child: Stack(
          children: [
            Positioned.fill(
              child: WallBackground(
                wall: isNight(context) ? cork.atNight : cork,
                decor: false,
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

final _still = NoteCallbacks(
  onEdit: () {},
  onTogglePin: () {},
  onToggleItem: (_) {},
  onLongPress: () {},
);

Widget _card(
  String id,
  String words,
  int paper, {
  double width = 130,
  bool raised = false,
}) => SizedBox(
  width: width,
  child: StickyNoteCard(
    note: Note(
      guid: 'manual-$id',
      content: words,
      createdAt: DateTime(2026),
      boardId: '',
      colorIndex: paper,
    ),
    cb: _still,
    raised: raised,
    maxContentLines: 2,
  ),
);

/// A chalk-white pill of tools floating on the wall.
Widget _toolPill(List<Widget> tools) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  decoration: BoxDecoration(
    color: AppColors.chalk,
    borderRadius: BorderRadius.circular(999),
    boxShadow: const [
      BoxShadow(color: Color(0x40302318), blurRadius: 10, offset: Offset(0, 3)),
    ],
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final (i, t) in tools.indexed) ...[
        if (i > 0) const SizedBox(width: 14),
        SizedBox.square(dimension: 26, child: Center(child: t)),
      ],
    ],
  ),
);

/// Marker lines and a highlighter stroke behind two notes, and the pen,
/// highlighter and eraser in their bar.
class _DrawPicture extends StatelessWidget {
  const _DrawPicture();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _Cork(
      children: [
        const Positioned.fill(child: CustomPaint(painter: _Scribbles())),
        Positioned(left: 34, top: 30, child: _card('d1', l10n.guideNoteMum, 1)),
        Positioned(
          right: 40,
          top: 60,
          child: _card('d2', l10n.guideNoteSaturday, 2),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 16,
          child: Center(
            child: _toolPill([
              Container(
                decoration: const BoxDecoration(
                  color: Color(0x33FFCA28),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, size: 20, color: AppColors.ink),
              ),
              const Icon(Icons.border_color, size: 20, color: AppColors.ink),
              const SizedBox.square(
                dimension: 22,
                child: EraserIcon(color: AppColors.ink),
              ),
              const Icon(Icons.undo, size: 20, color: AppColors.ink),
            ]),
          ),
        ),
      ],
    );
  }
}

class _Scribbles extends CustomPainter {
  const _Scribbles();

  @override
  void paint(Canvas canvas, Size size) {
    final marker = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFFDFBF3);
    // A loop round the first note, and an arrow towards the second.
    canvas
      ..drawOval(const Rect.fromLTWH(18, 22, 166, 140), marker)
      ..drawPath(
        Path()
          ..moveTo(190, 120)
          ..quadraticBezierTo(222, 170, 262, 150),
        marker,
      )
      ..drawPath(
        Path()
          ..moveTo(248, 140)
          ..lineTo(263, 150)
          ..lineTo(250, 164),
        marker,
      );
    canvas.drawLine(
      const Offset(120, 214),
      const Offset(300, 214),
      Paint()
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round
        ..color = const Color(0x66FBC02D),
    );
  }

  @override
  bool shouldRepaint(_Scribbles old) => false;
}

/// Board tabs along the top, a note lifted towards one of them, and the
/// Trash in its corner.
class _BoardsPicture extends StatelessWidget {
  const _BoardsPicture();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget tab(String words, {bool on = false, bool lit = false}) => Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: on ? AppColors.ink : AppColors.chalk,
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: lit ? Border.all(color: AppColors.accent, width: 3) : null,
      ),
      child: Text(
        words,
        style: TextStyle(
          fontFamily: 'BeVietnamPro',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: on ? AppColors.chalk : AppColors.ink,
        ),
      ),
    );
    return _Cork(
      children: [
        Positioned(
          left: 16,
          top: 14,
          child: Row(
            children: [
              tab(l10n.manualTabHome, on: true),
              tab(l10n.manualTabWork, lit: true),
              tab('+'),
            ],
          ),
        ),
        const Positioned.fill(child: CustomPaint(painter: _DragArrow())),
        Positioned(
          left: 40,
          top: 150,
          child: _card('b1', l10n.guideNoteMum, 1),
        ),
        Positioned(
          left: 150,
          top: 74,
          child: Transform.rotate(
            angle: .08,
            child: _card('b2', l10n.guideNoteWater, 0, raised: true),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.chalk,
              shape: BoxShape.circle,
            ),
            child: const Icon(AppIcons.delete, color: AppColors.ink),
          ),
        ),
      ],
    );
  }
}

/// A dashed arc from the lifted note up to the tab it is headed for.
class _DragArrow extends CustomPainter {
  const _DragArrow();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(232, 92)
      ..quadraticBezierTo(206, 64, 150, 52);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = AppColors.chalk;
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 12) {
        canvas.drawPath(m.extractPath(d, d + 7), paint);
      }
    }
    canvas.drawPath(
      Path()
        ..moveTo(162, 44)
        ..lineTo(150, 52)
        ..lineTo(163, 60),
      paint,
    );
  }

  @override
  bool shouldRepaint(_DragArrow old) => false;
}

/// Photo prints on the wall, one with a caption.
class _PhotosPicture extends StatelessWidget {
  const _PhotosPicture();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final print = printColorOf(context);
    Widget photo(List<Color> sky, {String? caption}) => Container(
      width: 120,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      decoration: BoxDecoration(
        color: print,
        boxShadow: const [
          BoxShadow(
            color: Color(0x40302318),
            blurRadius: 8,
            offset: Offset(1, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            height: 96,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: sky,
              ),
            ),
            child: const CustomPaint(painter: _Hills()),
          ),
          SizedBox(
            height: 26,
            child: Center(
              child: Text(
                caption ?? '',
                style: TextStyle(
                  fontSize: 16 * noteFontScale(context),
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return _Cork(
      children: [
        Positioned(
          left: 28,
          top: 40,
          child: Transform.rotate(
            angle: -.07,
            child: photo(const [
              Color(0xFFFFB74D),
              Color(0xFFF06292),
            ], caption: l10n.manualPhotoCaption),
          ),
        ),
        Positioned(
          left: 142,
          top: 92,
          child: Transform.rotate(
            angle: .05,
            child: photo(const [Color(0xFF81D4FA), Color(0xFFB2DFDB)]),
          ),
        ),
        Positioned(
          right: 26,
          top: 30,
          child: Transform.rotate(
            angle: -.03,
            child: photo(const [Color(0xFFFFE082), Color(0xFFA5D6A7)]),
          ),
        ),
      ],
    );
  }
}

/// Two soft hills, so a gradient reads as a photo of somewhere.
class _Hills extends CustomPainter {
  const _Hills();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas
      ..drawPath(
        Path()
          ..moveTo(0, h * .7)
          ..quadraticBezierTo(w * .3, h * .4, w * .6, h * .72)
          ..lineTo(w * .6, h)
          ..lineTo(0, h)
          ..close(),
        Paint()..color = const Color(0x8C2E7D32),
      )
      ..drawPath(
        Path()
          ..moveTo(w * .35, h)
          ..quadraticBezierTo(w * .7, h * .45, w, h * .66)
          ..lineTo(w, h)
          ..close(),
        Paint()..color = const Color(0xA61B5E20),
      )
      ..drawCircle(
        Offset(w * .78, h * .26),
        h * .1,
        Paint()..color = const Color(0xCCFFF8E1),
      );
  }

  @override
  bool shouldRepaint(_Hills old) => false;
}

/// A search typed without accents, the note it found, and the three
/// views.
class _FindPicture extends StatelessWidget {
  const _FindPicture();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _Cork(
      children: [
        Positioned(
          left: 40,
          right: 40,
          top: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.chalk,
              borderRadius: BorderRadius.circular(AppRadii.control * 2),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 20, color: AppColors.inkSoft),
                const SizedBox(width: 8),
                Text(
                  l10n.manualSearchQuery,
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 16,
                    color: AppColors.ink,
                  ),
                ),
                Container(width: 2, height: 18, color: AppColors.ink),
              ],
            ),
          ),
        ),
        Positioned(
          left: 34,
          top: 92,
          child: Opacity(
            opacity: .4,
            child: _card('f1', l10n.guideNoteMum, 1, width: 110),
          ),
        ),
        Positioned(
          left: 148,
          top: 80,
          child: _card('f2', l10n.guideNoteWater, 0, width: 120, raised: true),
        ),
        Positioned(
          right: 26,
          top: 100,
          child: Opacity(
            opacity: .4,
            child: _card('f3', l10n.guideNoteSaturday, 2, width: 100),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 16,
          child: Center(
            child: _toolPill(const [
              Icon(Icons.wallpaper, size: 20, color: AppColors.ink),
              Icon(Icons.grid_view, size: 20, color: AppColors.ink),
              Icon(Icons.view_agenda_outlined, size: 20, color: AppColors.ink),
            ]),
          ),
        ),
      ],
    );
  }
}
