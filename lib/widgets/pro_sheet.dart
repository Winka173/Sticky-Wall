import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/note.dart';
import '../services/pro_controller.dart';
import '../services/template_library.dart';
import '../services/theme_packs.dart';
import '../theme.dart';
import 'demo_loop.dart';
import 'note_views.dart';
import 'photo_frames.dart';
import 'pro_demos.dart';
import 'settings_sheet.dart' show pinStyleLabel, wallLabel;
import 'stickers.dart';

export 'pro_demos.dart' show ProPerk;

/// Opens the Sticky Wall Pro sheet. A stage plays a short film of each part
/// of Pro ([focus] first, the part that was tapped); below it every part by
/// group (a tap plays it), Free beside Pro counted from the app's own
/// catalogues, and at the foot the store's price, Unlock and Restore. Every
/// Pro thing in the app (a paper, wall, font or pin with the small Pro
/// mark) opens it when tapped without Pro.
Future<void> showProSheet(BuildContext context, {ProPerk? focus}) {
  // Read here, above the sheet's own route, so the sheet works wherever
  // it is opened from.
  final pro = ProScope.maybeOf(context);
  _loadPrice(pro);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: pro == null
          ? _ProBody(pro: null, focus: focus)
          : ListenableBuilder(
              listenable: pro,
              builder: (context, _) => _ProBody(pro: pro, focus: focus),
            ),
    ),
  );
}

/// A price that failed to load is asked for again when the sheet opens.
void _loadPrice(ProController? pro) {
  if (pro != null && pro.price == null) pro.loadProduct().ignore();
}

/// One part of Pro: what it is called, a line for the list and the words
/// shown under its film.
class _Part {
  const _Part(this.perk, this.title, this.line, this.body);

  final ProPerk perk;
  final String title, line, body;
}

String _list(Iterable<String> names) => names.join(', ');

String _threadName(AppLocalizations l10n, ThreadStyle s) => switch (s) {
  ThreadStyle.yarn => l10n.threadYarn,
  ThreadStyle.twine => l10n.threadTwine,
  ThreadStyle.ribbon => l10n.threadRibbon,
  ThreadStyle.dashed => l10n.threadDashed,
  ThreadStyle.beads => l10n.threadBeads,
};

/// Every part of Pro, in the groups the sheet lists them in. Counts and
/// names come from the catalogues, so the sheet never promises more or
/// less than the app has.
List<(String, List<_Part>)> _groups(AppLocalizations l10n) {
  final proWalls = walls.where((w) => w.pro && w.season == null).toList();
  final seasonWalls = walls.where((w) => w.season != null).length;
  final seasonStickers = stickers.where((s) => s.pack.season != null).length;
  return [
    (
      l10n.proGroupWall,
      [
        _Part(
          ProPerk.themePacks,
          l10n.proPacksTitle(themePacks.where((p) => p.pro).length),
          l10n.proPacksLine,
          l10n.proPacksBody,
        ),
        _Part(
          ProPerk.walls,
          l10n.proWallsTitle(proWalls.length),
          _list(proWalls.map((w) => wallLabel(l10n, w.id))),
          l10n.proWallsBody,
        ),
        _Part(
          ProPerk.seasons,
          l10n.proSeasonsTitle,
          _list([
            l10n.packTet,
            l10n.packChristmas,
            l10n.packMidAutumn,
            l10n.packValentine,
          ]),
          l10n.proSeasonsBody(seasonWalls, seasonStickers),
        ),
        _Part(
          ProPerk.fonts,
          l10n.proFontsTitle(fontChoices.where((f) => f.pro).length),
          _list(fontChoices.where((f) => f.pro).map((f) => f.label)),
          l10n.proFontsBody,
        ),
      ],
    ),
    (
      l10n.proGroupPaper,
      [
        _Part(
          ProPerk.papers,
          l10n.proPapersTitle(
            AppColors.notePapers.length - AppColors.freePapers,
          ),
          l10n.proPapersLine,
          l10n.proPapersBody,
        ),
        _Part(
          ProPerk.paperStyles,
          l10n.proPaperStylesTitle(
            PaperStyle.values.where((s) => s.pro).length,
          ),
          _list(
            PaperStyle.values
                .where((s) => s.pro)
                .map((s) => paperStyleLabel(l10n, s)),
          ),
          l10n.proPaperStylesBody,
        ),
        _Part(
          ProPerk.pins,
          l10n.proPinsTitle(PinStyle.values.where((p) => p.pro).length),
          _list(
            PinStyle.values
                .where((p) => p.pro)
                .map((p) => pinStyleLabel(l10n, p)),
          ),
          l10n.proPinsBody,
        ),
        _Part(
          ProPerk.stickers,
          l10n.proStickersTitle(stickers.where((s) => s.pro).length),
          l10n.proStickersLine,
          l10n.proStickersBody,
        ),
        _Part(
          ProPerk.frames,
          l10n.proFramesTitle(PhotoFrame.values.where((f) => f.pro).length),
          _list(
            PhotoFrame.values
                .where((f) => f.pro)
                .map((f) => photoFrameName(l10n, f)),
          ),
          l10n.proFramesBody,
        ),
      ],
    ),
    (
      l10n.proGroupMore,
      [
        _Part(
          ProPerk.threads,
          l10n.proThreadsTitle(
            ThreadStyle.values.where((s) => s.pro).length,
            AppColors.yarns.length - AppColors.freeYarns,
          ),
          _list(
            ThreadStyle.values
                .where((s) => s.pro)
                .map((s) => _threadName(l10n, s)),
          ),
          l10n.proThreadsBody,
        ),
        _Part(
          ProPerk.markers,
          l10n.proMarkersTitle(
            AppColors.markers.length - AppColors.freeMarkers,
          ),
          l10n.proMarkersLine,
          l10n.proMarkersBody,
        ),
        _Part(
          ProPerk.privateBoards,
          l10n.proPrivateTitle,
          l10n.proPrivateLine,
          l10n.proPrivateBody,
        ),
      ],
    ),
  ];
}

class _ProBody extends StatefulWidget {
  const _ProBody({required this.pro, this.focus});

  final ProController? pro;

  /// The part that brought the person here, played first.
  final ProPerk? focus;

  @override
  State<_ProBody> createState() => _ProBodyState();
}

class _ProBodyState extends State<_ProBody> {
  final _scroll = ScrollController();
  late ProPerk _shown = widget.focus ?? ProPerk.themePacks;
  bool _restoring = false;

  /// The answer to the last Restore, shown under the buttons.
  String? _restoreNote;

  @override
  void initState() {
    super.initState();
    // The template count in the table; it shows once the library is read.
    if (TemplateLibrary.loaded == null) {
      unawaited(
        TemplateLibrary.load().then((_) {
          if (mounted) setState(() {});
        }, onError: (Object _) {}),
      );
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Plays [perk] on the stage and brings the stage into view.
  void _show(ProPerk perk) {
    setState(() => _shown = perk);
    if (!_scroll.hasClients) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(0);
    } else {
      unawaited(
        _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeInOutCubic,
        ),
      );
    }
  }

  Future<void> _restore(AppLocalizations l10n) async {
    final pro = widget.pro;
    if (pro == null) return;
    setState(() {
      _restoring = true;
      _restoreNote = null;
    });
    final found = await pro.restore();
    if (!mounted) return;
    setState(() {
      _restoring = false;
      _restoreNote = found ? l10n.proRestored : l10n.proRestoreNone;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pro = widget.pro;
    final unlocked = pro?.unlocked ?? false;
    final status = pro?.status ?? ProStatus.unavailable;
    final price = pro?.price;

    final String? note = unlocked
        ? null
        : switch (status) {
            ProStatus.pending => l10n.proPending,
            ProStatus.failed => l10n.proFailed,
            ProStatus.unavailable => l10n.proUnavailable,
            ProStatus.idle || ProStatus.loading => null,
          };

    // What Pro adds scrolls; the price and Unlock stay in view at the foot,
    // so the way to buy is never below the fold.
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(child: _content(l10n, unlocked)),
          const Divider(height: 1),
          Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: _actions(l10n, pro, unlocked, status, price, note),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(AppLocalizations l10n, bool unlocked) {
    final groups = _groups(l10n);
    final all = [for (final g in groups) ...g.$2];
    final part = all.firstWhere(
      (p) => p.perk == _shown,
      orElse: () => all.first,
    );
    final size = MediaQuery.sizeOf(context);
    // The stage keeps the film's 16:9 up to the column's width; a short
    // (landscape) screen keeps room for the words under it.
    final width = size.width.clamp(0.0, 640.0) - 40;
    final stageHeight = (width * 9 / 16).clamp(
      140.0,
      (size.height * .36).clamp(140.0, 340.0),
    );
    return SingleChildScrollView(
      key: const Key('pro-sheet'),
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  l10n.proTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: widget.focus == null ? 28 : 22,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (widget.focus == null) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.proPitch,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Container(
                key: const Key('pro-stage'),
                height: stageHeight,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(AppRadii.control * 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: DemoLoop(
                  key: ValueKey(part.perk),
                  label: '${part.title}. ${part.line}',
                  replayLabel: l10n.proReplay,
                  builder: (context, t) => proDemo(context, part.perk, t),
                ),
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 220),
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topLeft,
                  children: [...previous, ?current],
                ),
                child: Column(
                  key: ValueKey(part.perk),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        part.title,
                        key: const Key('pro-stage-title'),
                        style: const TextStyle(
                          fontSize: 22,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      part.body,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.3,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              for (final g in groups) ...[
                const SizedBox(height: 22),
                Semantics(
                  header: true,
                  child: Text(
                    g.$1,
                    style: const TextStyle(
                      fontSize: 17,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                for (final p in g.$2)
                  _PartRow(
                    part: p,
                    shown: p.perk == part.perk,
                    onTap: () => _show(p.perk),
                  ),
              ],
              const SizedBox(height: 22),
              const _Compare(),
              const SizedBox(height: 16),
              Text(
                l10n.proAlwaysFree,
                style: const TextStyle(fontSize: 14, color: AppColors.inkSoft),
              ),
              const SizedBox(height: 8),
              Text(
                unlocked ? l10n.proKeepsLook : l10n.proTryHint,
                style: const TextStyle(fontSize: 14, color: AppColors.inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actions(
    AppLocalizations l10n,
    ProController? pro,
    bool unlocked,
    ProStatus status,
    String? price,
    String? note,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (unlocked)
          Semantics(
            liveRegion: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: AppColors.ink),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l10n.proUnlocked,
                    style: const TextStyle(
                      fontSize: 18,
                      color: AppColors.ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Row(
            children: [
              TextButton(
                style: TextButton.styleFrom(minimumSize: const Size(44, 52)),
                onPressed: pro == null || _restoring
                    ? null
                    : () => _restore(l10n),
                child: _restoring
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.proRestore),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    // The theme's label style, larger: a bare TextStyle
                    // here would drop the app's font for the system one.
                    textStyle: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(fontSize: 18),
                  ),
                  onPressed: pro != null && pro.canBuy ? pro.buy : null,
                  child: status == ProStatus.loading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.chalk,
                          ),
                        )
                      : Text(
                          price == null
                              ? l10n.proBuyNoPrice
                              : l10n.proBuy(price),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ),
            ],
          ),
        for (final line in [?note, ?_restoreNote])
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Semantics(
              liveRegion: true,
              child: Text(
                line,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.ink),
              ),
            ),
          ),
      ],
    );
  }
}

/// One part in the list: the last frame of its film, its name and one
/// line. A tap plays it on the stage.
class _PartRow extends StatelessWidget {
  const _PartRow({
    required this.part,
    required this.shown,
    required this.onTap,
  });

  final _Part part;
  final bool shown;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      selected: shown,
      label: l10n.proPlayIt('${part.title}. ${part.line}'),
      excludeSemantics: true,
      child: InkWell(
        key: Key('pro-part-${part.perk.name}'),
        borderRadius: BorderRadius.circular(AppRadii.control),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 92,
                height: 52,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(AppRadii.control),
                  border: Border.all(
                    color: shown ? AppColors.proInk : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: IgnorePointer(child: proDemo(context, part.perk, 1)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      part.title,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      part.line,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                shown ? Icons.play_circle : Icons.play_circle_outline,
                color: shown ? AppColors.proInk : AppColors.inkSoft,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Free beside Pro, counted from the app's own catalogues.
class _Compare extends StatelessWidget {
  const _Compare();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    int count<T>(Iterable<T> all, bool Function(T) pro) =>
        all.where(pro).length;
    final templates = TemplateLibrary.loaded?.length;
    final freeStickers = count(stickers, (s) => !s.pro);
    final rows = <(String, String, String)>[
      (l10n.proRowNotes, l10n.proNoLimits, l10n.proNoLimits),
      if (templates != null)
        (l10n.proRowTemplates, l10n.proAll(templates), l10n.proAll(templates)),
      (
        l10n.proRowPacks,
        '${count(themePacks, (p) => !p.pro)}',
        l10n.proPlus(count(themePacks, (p) => p.pro)),
      ),
      (
        l10n.proRowWalls,
        l10n.proFreeWalls(count(walls, (w) => !w.pro)),
        l10n.proProWalls(
          count(walls, (w) => w.pro && w.season == null),
          count(walls, (w) => w.season != null),
        ),
      ),
      (
        l10n.proRowFonts,
        '${count(fontChoices, (f) => !f.pro)}',
        l10n.proPlus(count(fontChoices, (f) => f.pro)),
      ),
      (
        l10n.proRowPapers,
        '${AppColors.freePapers}',
        l10n.proPlusMix(AppColors.notePapers.length - AppColors.freePapers),
      ),
      (
        l10n.proRowPaperStyles,
        _list(
          PaperStyle.values
              .where((s) => !s.pro)
              .map((s) => paperStyleLabel(l10n, s)),
        ),
        l10n.proPlus(count(PaperStyle.values, (s) => s.pro)),
      ),
      (
        l10n.proRowPins,
        _list(
          PinStyle.values
              .where((p) => !p.pro)
              .map((p) => pinStyleLabel(l10n, p)),
        ),
        l10n.proPlus(count(PinStyle.values, (p) => p.pro)),
      ),
      (
        l10n.proRowStickers,
        '$freeStickers',
        l10n.proPlus(stickers.length - freeStickers),
      ),
      (
        l10n.proRowFrames,
        _list(
          PhotoFrame.values
              .where((f) => !f.pro)
              .map((f) => photoFrameName(l10n, f)),
        ),
        l10n.proPlus(count(PhotoFrame.values, (f) => f.pro)),
      ),
      (
        l10n.proRowThreads,
        l10n.proFreeThreads(AppColors.freeYarns),
        l10n.proProThreads(
          count(ThreadStyle.values, (s) => s.pro),
          AppColors.yarns.length - AppColors.freeYarns,
        ),
      ),
      (
        l10n.proRowMarkers,
        l10n.proFreeMarkers(AppColors.freeMarkers),
        l10n.proPlusMix(AppColors.markers.length - AppColors.freeMarkers),
      ),
      (l10n.proRowLock, l10n.appLock, '+ ${l10n.proPrivateTitle}'),
    ];
    Widget head(String s) => Expanded(
      child: Text(
        s,
        style: const TextStyle(fontSize: 14, color: AppColors.inkSoft),
      ),
    );
    Widget cell(String label, String value, {bool pro = false}) => Expanded(
      child: Semantics(
        label: label,
        child: Text(
          value,
          style: TextStyle(
            fontSize: 15,
            height: 1.25,
            color: pro ? AppColors.proInk : AppColors.ink,
            fontWeight: pro ? FontWeight.w600 : null,
          ),
        ),
      ),
    );
    return Column(
      key: const Key('pro-compare'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.proCompareTitle,
            style: const TextStyle(fontSize: 17, color: AppColors.inkSoft),
          ),
        ),
        const SizedBox(height: 8),
        ExcludeSemantics(
          child: Row(
            children: [
              head(l10n.proFree),
              const SizedBox(width: 12),
              head('Pro'),
            ],
          ),
        ),
        for (final r in rows)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.inkHint.withValues(alpha: .5),
                ),
              ),
            ),
            child: MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.$1,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      cell(l10n.proFree, r.$2),
                      const SizedBox(width: 12),
                      cell('Pro', r.$3, pro: true),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// The small "Pro" mark on a paper, wall, font or pin that needs Pro.
class ProMark extends StatelessWidget {
  const ProMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.ink, width: 0.8),
      ),
      child: const Text(
        'PRO',
        style: TextStyle(
          fontFamily: 'BeVietnamPro',
          fontSize: 9,
          height: 1.3,
          fontWeight: FontWeight.bold,
          color: AppColors.ink,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
