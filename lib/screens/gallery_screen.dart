import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/note.dart';
import '../services/notes_controller.dart';
import '../services/pro_controller.dart';
import '../services/template_library.dart';
import '../services/theme_packs.dart';
import '../theme.dart';
import '../util/text_fold.dart';
import '../widgets/note_views.dart';
import '../widgets/pro_sheet.dart';
import '../widgets/wall_background.dart';
import '../widgets/wall_view.dart';

/// What the gallery did, for the screen underneath to say so.
sealed class GalleryResult {
  const GalleryResult();
}

/// A board was started from a template (and is now the open one).
class TemplateUsed extends GalleryResult {
  const TemplateUsed(this.name);
  final String name;
}

/// A theme pack was put on the open board; [undo] takes it off again.
class ThemeApplied extends GalleryResult {
  const ThemeApplied(this.name, this.undo);
  final String name;
  final VoidCallback undo;
}

/// Says what the gallery did, with Undo for a theme.
void showGalleryResult(BuildContext context, GalleryResult? result) {
  if (result == null) return;
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
  switch (result) {
    case TemplateUsed(:final name):
      messenger.showSnackBar(SnackBar(content: Text(l10n.templateUsed(name))));
    case ThemeApplied(:final name, :final undo):
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.themeApplied(name)),
          action: SnackBarAction(label: l10n.undo, onPressed: undo),
        ),
      );
  }
}

/// The library: board templates (editable boards to start from) and theme
/// packs (a whole look for the open board), each shown by the app's own
/// wall renderer, never by a picture of one.
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({
    super.key,
    required this.notes,
    this.themes = false,
    this.into,
  });

  final NotesController notes;

  /// A template fills this board instead of making a new one.
  final String? into;

  /// Opens on the themes rather than the templates.
  final bool themes;

  static Future<GalleryResult?> open(
    BuildContext context, {
    required NotesController notes,
    bool themes = false,
    String? into,
  }) => Navigator.of(context).push<GalleryResult>(
    MaterialPageRoute(
      builder: (_) => GalleryScreen(notes: notes, themes: themes, into: into),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      initialIndex: themes ? 1 : 0,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.galleryTitle),
          bottom: TabBar(
            labelColor: AppColors.ink,
            indicatorColor: AppColors.ink,
            tabs: [
              Tab(text: l10n.galleryTemplates),
              Tab(text: l10n.galleryThemes),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TemplatesTab(notes: notes, into: into),
            _ThemesTab(notes: notes),
          ],
        ),
      ),
    );
  }
}

String _categoryLabel(AppLocalizations l10n, Object c) => switch (c) {
  TemplateCategory.productivity => l10n.catProductivity,
  TemplateCategory.study || ThemeCategory.study => l10n.catStudy,
  TemplateCategory.creative || ThemeCategory.creative => l10n.catCreative,
  TemplateCategory.personal || ThemeCategory.personal => l10n.catPersonal,
  TemplateCategory.family || ThemeCategory.family => l10n.catFamily,
  TemplateCategory.seasonal || ThemeCategory.seasonal => l10n.catSeasonal,
  ThemeCategory.classic => l10n.catClassic,
  _ => '',
};

/// A row of filter chips that scrolls sideways inside itself.
class _Chips<T> extends StatelessWidget {
  const _Chips({
    required this.values,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final List<T?> values;
  final String Function(T?) label;
  final T? selected;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final v in values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(label(v)),
                selected: v == selected,
                onSelected: (_) => onSelected(v),
              ),
            ),
        ],
      ),
    );
  }
}

class _TemplatesTab extends StatefulWidget {
  const _TemplatesTab({required this.notes, this.into});

  final NotesController notes;
  final String? into;

  @override
  State<_TemplatesTab> createState() => _TemplatesTabState();
}

class _TemplatesTabState extends State<_TemplatesTab>
    with AutomaticKeepAliveClientMixin {
  final _search = TextEditingController();
  TemplateCategory? _category;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(BoardTemplateDef t) {
    if (_category != null && t.category != _category) return false;
    final q = foldText(_search.text.trim());
    if (q.isEmpty) return true;
    return [
      t.name.en,
      t.name.vi,
      t.description.en,
      t.description.vi,
      ...t.tags,
    ].any((s) => foldText(s).contains(q));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    return FutureBuilder<List<BoardTemplateDef>>(
      future: TemplateLibrary.load(),
      initialData: TemplateLibrary.loaded,
      builder: (context, snap) {
        final all = snap.data;
        if (all == null) {
          return Center(
            child: snap.hasError
                ? Text(l10n.galleryNothing)
                : const CircularProgressIndicator(),
          );
        }
        final shown = all.where(_matches).toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _search,
                textAlignVertical: TextAlignVertical.center,
                textInputAction: TextInputAction.search,
                decoration: searchFieldDecoration(l10n.gallerySearch),
              ),
            ),
            _Chips<TemplateCategory>(
              values: [null, ...TemplateCategory.values],
              label: (c) =>
                  c == null ? l10n.galleryAll : _categoryLabel(l10n, c),
              selected: _category,
              onSelected: (c) => setState(() => _category = c),
            ),
            Expanded(
              child: shown.isEmpty
                  ? Center(child: Text(l10n.galleryNothing))
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 220,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.56,
                          ),
                      itemCount: shown.length,
                      itemBuilder: (context, i) {
                        final t = shown[i];
                        return _Card(
                          preview: TemplatePreview(
                            template: t,
                            look: t.themePack == null
                                ? null
                                : lookFor(
                                    t.themePack!,
                                    pro: ProScope.unlockedOf(context),
                                  ),
                          ),
                          title: t.name.of(lang),
                          subtitle: t.description.of(lang),
                          onTap: () => _open(context, t),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _open(BuildContext context, BoardTemplateDef t) async {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final pro = ProScope.unlockedOf(context);
    final pack = t.themePack;
    final lockedLook = pack != null && pack.pro && !pro;
    // Without Pro the free twin is what the board will be made in, so that
    // is what the preview shows.
    final made = pack == null ? null : lookFor(pack, pro: pro);
    final use = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _DetailSheet(
        preview: TemplatePreview(template: t, look: made),
        title: t.name.of(lang),
        body: [
          Text(t.description.of(lang), style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in t.tags)
                Chip(label: Text(tag), visualDensity: VisualDensity.compact),
            ],
          ),
          if (pack != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  l10n.templateLook(pack.name(lang)),
                  style: const TextStyle(color: AppColors.inkSoft),
                ),
                if (pack.pro) ...[const SizedBox(width: 6), const ProMark()],
              ],
            ),
            if (lockedLook)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l10n.templateFreeLook(made!.name(lang)),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
          ],
        ],
        action: l10n.useTemplate,
      ),
    );
    if (use != true || !context.mounted) return;
    widget.notes.addBoardFromTemplate(
      t,
      lang,
      // Exactly what the preview showed.
      pack: made,
      into: widget.into,
    );
    Navigator.of(context).pop(TemplateUsed(t.name.of(lang)));
  }
}

class _ThemesTab extends StatefulWidget {
  const _ThemesTab({required this.notes});

  final NotesController notes;

  @override
  State<_ThemesTab> createState() => _ThemesTabState();
}

/// The theme filter: everything, the free packs, or one shelf.
sealed class _ThemeFilter {
  const _ThemeFilter();
}

class _FreeOnly extends _ThemeFilter {
  const _FreeOnly();
  @override
  bool operator ==(Object other) => other is _FreeOnly;
  @override
  int get hashCode => 1;
}

class _Shelf extends _ThemeFilter {
  const _Shelf(this.category);
  final ThemeCategory category;
  @override
  bool operator ==(Object other) =>
      other is _Shelf && other.category == category;
  @override
  int get hashCode => category.hashCode;
}

class _ThemesTabState extends State<_ThemesTab>
    with AutomaticKeepAliveClientMixin {
  _ThemeFilter? _filter;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final pro = ProScope.unlockedOf(context);
    final filter = _filter;
    bool near(ThemePack t) =>
        t.wallStyle.season != null && t.wallStyle.inSeason;
    final matching = [
      for (final t in themePacks)
        if (switch (filter) {
          null => true,
          _FreeOnly() => !t.pro,
          _Shelf(:final category) => t.category == category,
        })
          t,
    ];
    // A pack whose occasion is near comes first; the rest keep their order.
    final shown = [...matching.where(near), ...matching.where((t) => !near(t))];
    return Column(
      children: [
        const SizedBox(height: 8),
        _Chips<_ThemeFilter>(
          values: [
            null,
            const _FreeOnly(),
            for (final c in ThemeCategory.values) _Shelf(c),
          ],
          label: (f) => switch (f) {
            null => l10n.galleryAll,
            _FreeOnly() => l10n.galleryFree,
            _Shelf(:final category) => _categoryLabel(l10n, category),
          },
          selected: _filter,
          onSelected: (f) => setState(() => _filter = f),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisSpacing: 16,
              crossAxisSpacing: 14,
              childAspectRatio: 0.6,
            ),
            itemCount: shown.length,
            itemBuilder: (context, i) {
              final t = shown[i];
              return _Card(
                preview: ThemePreview(pack: t),
                title: t.name(lang),
                pro: t.pro && !pro,
                onTap: () => _open(context, t),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _open(BuildContext context, ThemePack t) async {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final locked = t.pro && !ProScope.unlockedOf(context);
    final board = widget.notes.currentBoard;
    final boardName = board.name.isEmpty ? l10n.defaultBoardName : board.name;
    final apply = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _DetailSheet(
        preview: ThemePreview(pack: t),
        title: t.name(lang),
        body: [
          Text(l10n.themeKeepsContent, style: const TextStyle(fontSize: 15)),
        ],
        action: locked ? l10n.proUnlock : l10n.applyTheme(boardName),
        pro: locked,
      ),
    );
    if (apply != true || !context.mounted) return;
    if (locked) {
      await showProSheet(context);
      return;
    }
    // A shut private board is not dressed behind its lock.
    if (widget.notes.currentBoardShut) return;
    final undo = widget.notes.applyTheme(board.id, t);
    Navigator.of(context).pop(ThemeApplied(t.name(lang), undo));
  }
}

/// One entry in a gallery grid: the live preview with its name under it.
class _Card extends StatelessWidget {
  const _Card({
    required this.preview,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.pro = false,
  });

  final Widget preview;
  final String title;
  final String? subtitle;
  final bool pro;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.control),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.control),
                    child: preview,
                  ),
                  if (pro) const Positioned(top: 8, right: 8, child: ProMark()),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            if (subtitle case final s?)
              Text(
                s,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.inkSoft,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A large preview, what it is, and one button; pops true on the button.
class _DetailSheet extends StatelessWidget {
  const _DetailSheet({
    required this.preview,
    required this.title,
    required this.body,
    required this.action,
    this.pro = false,
  });

  final Widget preview;
  final String title;
  final List<Widget> body;
  final String action;
  final bool pro;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: height * 0.9),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: height * 0.42,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: previewSize.aspectRatio,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.control),
                      child: preview,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  if (pro) ...[const SizedBox(width: 8), const ProMark()],
                ],
              ),
              const SizedBox(height: 6),
              ...body,
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(action),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The phone-sized wall every preview is laid out on, then scaled down.
const previewSize = Size(360, 600);

void _noop() {}
void _noopIndex(int _) {}
const _still = NoteCallbacks(
  onEdit: _noop,
  onTogglePin: _noop,
  onToggleItem: _noopIndex,
  onLongPress: _noop,
);

/// Notes and threads on a wall, drawn by the wall itself (held still) at
/// phone size and scaled to fit, in [pack]'s handwriting and pin.
class BoardPreview extends StatelessWidget {
  const BoardPreview({
    super.key,
    required this.wall,
    required this.notes,
    this.links = const [],
    this.pack,
  });

  final WallStyle wall;
  final List<Note> notes;
  final List<NoteLink> links;
  final ThemePack? pack;

  @override
  Widget build(BuildContext context) {
    final night = isNight(context);
    final look = pack;
    final theme = look == null
        ? Theme.of(context)
        : buildAppTheme(fontChoiceById(look.font), night: night, pin: look.pin);
    return ExcludeSemantics(
      child: IgnorePointer(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox.fromSize(
            size: previewSize,
            child: Theme(
              data: theme,
              // A Material under the theme, so the notes' text takes the
              // pack's handwriting rather than the page's.
              child: MediaQuery.withNoTextScaling(
                child: Material(
                  type: MaterialType.transparency,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: WallBackground(
                          wall: night ? wall.atNight : wall,
                          decor: false,
                        ),
                      ),
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
                          child: WallView(
                            notes: notes,
                            links: links,
                            callbacksFor: (_) => _still,
                            onMove: (_, _, _) {},
                            onResize: (_, _) {},
                            onBringToFront: (_) {},
                            onCreateAt: (_, _) {},
                            still: true,
                          ),
                        ),
                      ),
                    ],
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

/// A template as it will land: its own notes, threads and theme pack.
class TemplatePreview extends StatelessWidget {
  const TemplatePreview({super.key, required this.template, this.look});

  final BoardTemplateDef template;

  /// The pack to show it in instead of its own (a free twin without Pro).
  final ThemePack? look;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final pack = look ?? template.themePack;
    final made = template.build(
      'preview',
      lang,
      pack: pack,
      now: DateTime(2026),
    );
    return BoardPreview(
      wall: pack?.wallStyle ?? walls.first,
      notes: made.notes,
      links: made.links,
      pack: pack,
    );
  }
}

/// A theme pack on a small sample board.
class ThemePreview extends StatelessWidget {
  const ThemePreview({super.key, required this.pack});

  final ThemePack pack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notes = [
      Note(
        guid: 'p1',
        content: l10n.previewNoteA,
        createdAt: DateTime(2026),
        boardId: 'preview',
        colorIndex: pack.paperAt(0),
        paper: pack.paper,
        x: 0.05,
        y: 0.05,
      ),
      Note(
        guid: 'p2',
        content: '',
        type: NoteType.checklist,
        checklist: [
          ChecklistItem(text: l10n.previewItemA, done: true),
          ChecklistItem(text: l10n.previewItemB),
        ],
        createdAt: DateTime(2026, 1, 2),
        boardId: 'preview',
        colorIndex: pack.paperAt(1),
        paper: pack.paper.suits(NoteType.checklist)
            ? pack.paper
            : PaperStyle.plain,
        x: 0.95,
        y: 0.3,
      ),
      Note(
        guid: 'p3',
        content: l10n.previewNoteB,
        createdAt: DateTime(2026, 1, 3),
        boardId: 'preview',
        colorIndex: pack.paperAt(2),
        paper: pack.paper,
        pinned: true,
        x: 0.1,
        y: 0.7,
      ),
    ];
    return BoardPreview(
      wall: pack.wallStyle,
      notes: notes,
      links: [NoteLink('p1', 'p3', style: pack.thread, color: pack.yarn)],
      pack: pack,
    );
  }
}
