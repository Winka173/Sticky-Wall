import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/board.dart';
import '../models/note.dart';
import '../screens/trash_screen.dart';
import '../services/app_lock.dart';
import '../services/auto_backup.dart';
import '../services/backup_service.dart';
import '../services/image_service.dart';
import '../services/notes_controller.dart';
import '../services/pro_controller.dart';
import '../services/settings_controller.dart';
import '../services/widget_service.dart';
import '../theme.dart';
import 'action_sheet.dart';
import 'keyboard_tappable.dart';
import 'note_views.dart';
import 'pro_sheet.dart';
import 'restore_preview.dart';

part 'widget_settings_sheet.dart';

/// The published privacy policy (the Play listing links the same page).
const privacyPolicyUrl =
    'https://github.com/Winka173/Sticky-Wall/blob/main/PRIVACY.md';

/// Localized display name for a bundled wall texture.
String wallLabel(AppLocalizations l10n, String id) => switch (id) {
  'cork' => l10n.wallCork,
  'chalk_green' => l10n.wallChalkGreen,
  'chalk_black' => l10n.wallChalkBlack,
  'plaster' => l10n.wallPlaster,
  'brick' => l10n.wallBrick,
  'wood' => l10n.wallWood,
  'kraft' => l10n.wallKraft,
  'marble' => l10n.wallMarble,
  'terrazzo' => l10n.wallTerrazzo,
  'denim' => l10n.wallDenim,
  'felt' => l10n.wallFelt,
  'linen' => l10n.wallLinen,
  'cardboard' => l10n.wallCardboard,
  'cement' => l10n.wallCement,
  'cotton' => l10n.wallCotton,
  'paper' => l10n.wallPaper,
  'moss' => l10n.wallMoss,
  'leather' => l10n.wallLeather,
  'dark_marble' => l10n.wallDarkMarble,
  'dark_wood' => l10n.wallDarkWood,
  'tiles' => l10n.wallTiles,
  'chalk_navy' => l10n.wallChalkNavy,
  'chalk_wine' => l10n.wallChalkWine,
  'blush' => l10n.wallBlush,
  'sage' => l10n.wallSage,
  'sky' => l10n.wallSky,
  'tet' => l10n.wallTet,
  'tet_dao' => l10n.wallTetDao,
  'xmas' => l10n.wallXmas,
  'moon' => l10n.wallMoon,
  'love' => l10n.wallLove,
  _ => id,
};

/// Localized name of a pin style.
String pinStyleLabel(AppLocalizations l10n, PinStyle style) => switch (style) {
  PinStyle.classic => l10n.pinClassic,
  PinStyle.colorful => l10n.pinColorful,
  PinStyle.tack => l10n.pinTack,
  PinStyle.washi => l10n.pinWashi,
  PinStyle.clip => l10n.pinClip,
  PinStyle.magnet => l10n.pinMagnet,
};

/// Whether this platform has a home-screen widget to set up.
bool get _hasHomeWidget => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

/// Localized label for a lights setting.
String nightModeLabel(AppLocalizations l10n, NightMode mode) => switch (mode) {
  NightMode.off => l10n.nightModeOff,
  NightMode.on => l10n.nightModeOn,
  NightMode.system => l10n.nightModeSystem,
  NightMode.schedule => l10n.nightModeSchedule,
};

/// A whole hour the way the device writes times ("22:00", or "10:00 PM"
/// where the 12-hour clock is used).
String hourLabel(BuildContext context, int hour) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: hour, minute: 0),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );

/// A choice chip whose selected state reads without colour vision: a check
/// replaces the icon, the fill is the strong accent and the outline is ink.
Widget _choiceChip({
  required String label,
  required bool selected,
  required VoidCallback onSelected,
  IconData? icon,
}) {
  return ChoiceChip(
    avatar: icon == null || selected ? null : Icon(icon, size: 18),
    showCheckmark: true,
    checkmarkColor: AppColors.ink,
    selectedColor: AppColors.accent,
    side: BorderSide(
      color: selected ? AppColors.ink : AppColors.inkHint,
      width: selected ? 1.5 : 1,
    ),
    label: Text(
      label,
      style: TextStyle(fontWeight: selected ? FontWeight.bold : null),
    ),
    selected: selected,
    onSelected: (_) => onSelected(),
  );
}

/// Opens the customization sheet: Pro, wall texture, lights, font, pins,
/// language, privacy, the home-screen widget, auto-tidy and backup.
Future<void> showSettingsSheet(
  BuildContext context, {
  required SettingsController settings,
  required NotesController notes,
}) {
  final pro = ProScope.maybeOf(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    // Light, so the wall above shows what is being tried on.
    barrierColor: Colors.black.withValues(alpha: 0.18),
    builder: (context) => ListenableBuilder(
      listenable: Listenable.merge([settings, notes]),
      builder: (context, _) => _SettingsSheet(settings: settings, notes: notes),
    ),
  ).whenComplete(
    () => _endTryOn(settings, notes, keep: pro?.unlocked ?? false),
  );
}

/// Ends trying on Pro things: bought meanwhile, they are kept (the wall on
/// the open board); otherwise everything is put back as it was.
void _endTryOn(
  SettingsController settings,
  NotesController notes, {
  required bool keep,
}) {
  if (!settings.tryingOn) return;
  if (!keep) {
    settings.endTryOn();
    return;
  }
  final wall = settings.tryWall;
  if (wall != null) notes.setCurrentBoardWall(wall);
  settings.keepTryOn();
}

/// Body of [showSettingsSheet]; rebuilds as the settings change.
class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet({required this.settings, required this.notes});

  final SettingsController settings;
  final NotesController notes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pro = ProScope.unlockedOf(context);
    // Bought while trying on: what was on show is simply kept.
    if (pro && settings.tryingOn) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _endTryOn(settings, notes, keep: true),
      );
    }

    return DraggableScrollableSheet(
      expand: false,
      // Opens just past the wall picker; drag up for lights, fonts and data.
      initialChildSize: 0.58,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      // While something is tried on, the bar to keep or put it back stays
      // at the foot of the sheet, wherever the list is scrolled.
      builder: (context, scrollController) => Column(
        children: [
          Expanded(child: _list(context, l10n, scrollController, pro)),
          if (settings.tryingOn && !pro)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: _TryOnBar(settings: settings),
              ),
            ),
        ],
      ),
    );
  }

  Widget _list(
    BuildContext context,
    AppLocalizations l10n,
    ScrollController scrollController,
    bool pro,
  ) {
    final board = notes.currentBoard;
    // Every wall is offered all year; the seasonal ones come last, the one
    // whose occasion is near first among them.
    final offered = [
      for (final w in walls)
        if (w.season == null) w,
      for (final w in walls)
        if (w.season != null && w.inSeason) w,
      for (final w in walls)
        if (w.season != null && !w.inSeason) w,
    ];
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        Center(
          child: Text(
            l10n.customize,
            style: const TextStyle(fontSize: 24, color: AppColors.ink),
          ),
        ),
        const SizedBox(height: 4),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const ProMark(),
          title: Text(
            l10n.proTitle,
            style: const TextStyle(fontSize: 16, color: AppColors.ink),
          ),
          subtitle: Text(
            pro ? l10n.proSettingsThanks : l10n.proSettingsHint,
            style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
          ),
          trailing: pro
              ? const Icon(Icons.check_circle, color: AppColors.ink)
              : const Icon(Icons.chevron_right, color: AppColors.inkSoft),
          onTap: () => showProSheet(context),
        ),
        _SectionTitle(l10n.wallSection),
        SizedBox(
          height: 116,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            // Tiles run on past the sheet's margin to its edge: a tile
            // cut there reads as "more this way", not as clipped.
            clipBehavior: Clip.none,
            itemCount: offered.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, at) {
              if (at == offered.length) {
                return _PhotoWallTile(
                  board: board,
                  l10n: l10n,
                  // The kept photo comes back in one tap; once it is on
                  // show, a tap offers to change or remove it.
                  onTap: !board.hasWallImage && board.hasSavedWallImage
                      ? () => notes.setCurrentBoardWallImage(
                          board.savedWallImage,
                          dark: board.savedWallImageDark,
                        )
                      : () => _photoWallFlow(context, l10n),
                );
              }
              final wall = offered[at];
              final index = walls.indexOf(wall);
              final tried = settings.tryWall;
              final selected = tried != null
                  ? index == tried
                  : !board.hasWallImage && index == board.wallIndex;
              final locked = wall.pro && !pro;
              return _WallTile(
                label: wallLabel(l10n, wall.id),
                selected: selected,
                locked: locked,
                // A Pro wall is tried on first; a second tap offers Pro.
                onTap: locked
                    ? (tried == index
                          ? () => showProSheet(context)
                          : () => settings.setTryWall(index))
                    : () {
                        settings.setTryWall(null);
                        notes.setCurrentBoardWall(index);
                      },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(wall.asset, fit: BoxFit.cover),
                    ColoredBox(color: wall.overlay),
                  ],
                ),
              );
            },
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            l10n.wallDecor,
            style: const TextStyle(fontSize: 16, color: AppColors.ink),
          ),
          value: settings.wallDecor,
          onChanged: settings.setWallDecor,
        ),
        // A busy wall can take the eye from the notes: calm it down.
        Row(
          children: [
            const Icon(Icons.blur_on, color: AppColors.ink),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.wallSoften,
                style: const TextStyle(fontSize: 16, color: AppColors.ink),
              ),
            ),
          ],
        ),
        Slider(
          value: settings.wallSoften,
          divisions: 5,
          label: '${(settings.wallSoften * 100).round()}%',
          semanticFormatterCallback: (v) => '${(v * 100).round()}%',
          onChanged: settings.setWallSoften,
        ),
        const SizedBox(height: 8),
        _SectionTitle(l10n.nightSection),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final mode in NightMode.values)
              _choiceChip(
                icon: switch (mode) {
                  NightMode.off => Icons.light_mode_outlined,
                  NightMode.on => Icons.dark_mode_outlined,
                  NightMode.system => Icons.phone_android_outlined,
                  NightMode.schedule => Icons.schedule_outlined,
                },
                label: nightModeLabel(l10n, mode),
                selected: settings.nightMode == mode,
                onSelected: () => settings.setNightMode(mode),
              ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: settings.nightMode == NightMode.schedule
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _HourField(
                          label: l10n.nightStart,
                          value: settings.nightStart,
                          onChanged: (h) => settings.setNightHours(
                            start: h,
                            end: settings.nightEnd,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _HourField(
                          label: l10n.nightEnd,
                          value: settings.nightEnd,
                          onChanged: (h) => settings.setNightHours(
                            start: settings.nightStart,
                            end: h,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: 8),
        _SectionTitle(l10n.fontSection),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            // Tiles run on past the sheet's margin to its edge: a tile
            // cut there reads as "more this way", not as clipped.
            clipBehavior: Clip.none,
            itemCount: fontChoices.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final font = fontChoices[index];
              final locked = font.pro && !pro;
              return _FontPaper(
                font: font,
                preview: l10n.fontPreview,
                selected: settings.fontFor(pro: pro).id == font.id,
                locked: locked,
                tilt: (index.isEven ? -1 : 1) * 0.03,
                onTap: locked
                    ? (settings.tryFont == font.id
                          ? () => showProSheet(context)
                          : () => settings.setTryFont(font.id))
                    : () {
                        settings.setTryFont(null);
                        settings.setFontId(font.id);
                      },
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        _SectionTitle(l10n.pinSection),
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: PinStyle.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final style = PinStyle.values[index];
              final locked = style.pro && !pro;
              return _PinTile(
                style: style,
                label: pinStyleLabel(l10n, style),
                selected: settings.pinStyleFor(pro: pro) == style,
                locked: locked,
                onTap: locked
                    ? (settings.tryPin == style
                          ? () => showProSheet(context)
                          : () => settings.setTryPin(style))
                    : () {
                        settings.setTryPin(null);
                        settings.setPinStyle(style);
                      },
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        _SectionTitle(l10n.languageSection),
        Wrap(
          spacing: 8,
          children: [
            // English first: it is the default.
            for (final (code, label) in [
              ('en', 'English'),
              ('vi', 'Tiếng Việt'),
              ('system', l10n.langSystem),
            ])
              _choiceChip(
                label: label,
                selected: settings.languageCode == code,
                onSelected: () => settings.setLanguageCode(code),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _SectionTitle(l10n.privacySection),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.lock_outline, color: AppColors.ink),
          title: Text(
            l10n.appLock,
            style: const TextStyle(fontSize: 16, color: AppColors.ink),
          ),
          subtitle: Text(
            l10n.appLockHint,
            style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
          ),
          isThreeLine: true,
          value: settings.appLock,
          onChanged: (on) => _setAppLock(context, l10n, on),
        ),
        if (_hasHomeWidget)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.widgets_outlined, color: AppColors.ink),
            title: Text(
              l10n.widgetSection,
              style: const TextStyle(fontSize: 16, color: AppColors.ink),
            ),
            subtitle: Text(
              l10n.widgetSettingsHint,
              style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.inkSoft),
            onTap: () => showWidgetSettingsSheet(
              context,
              settings: settings,
              notes: notes,
            ),
          ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.policy_outlined, color: AppColors.ink),
          title: Text(
            l10n.privacyPolicy,
            style: const TextStyle(fontSize: 16, color: AppColors.ink),
          ),
          subtitle: Text(
            l10n.privacyPolicyHint,
            style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
          ),
          trailing: const Icon(Icons.open_in_new, color: AppColors.inkSoft),
          onTap: () => unawaited(
            launchUrl(
              Uri.parse(privacyPolicyUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _SectionTitle(l10n.dataSection),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.delete_outline, color: AppColors.ink),
          title: Text(
            l10n.trash,
            style: const TextStyle(fontSize: 16, color: AppColors.ink),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (notes.trashCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.ink.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${notes.trashCount}',
                    style: const TextStyle(fontSize: 13, color: AppColors.ink),
                  ),
                ),
              const Icon(Icons.chevron_right, color: AppColors.inkSoft),
            ],
          ),
          onTap: () {
            final nav = Navigator.of(context);
            nav.pop();
            nav.push(
              MaterialPageRoute<void>(
                builder: (_) => TrashScreen(notes: notes),
              ),
            );
          },
        ),
        _autoBackupTile(context, l10n),
        if (settings.lastAutoBackup != null)
          Padding(
            // In line with the switch's words, past its icon.
            padding: const EdgeInsets.only(left: 40),
            child: Wrap(
              spacing: 4,
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    minimumSize: const Size(44, 44),
                  ),
                  onPressed: () => _restoreAutoBackup(context, l10n),
                  icon: const Icon(Icons.settings_backup_restore, size: 20),
                  label: Text(l10n.autoBackupRestore),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    minimumSize: const Size(44, 44),
                  ),
                  onPressed: () => _shareAutoBackup(context, l10n),
                  icon: const Icon(Icons.share_outlined, size: 20),
                  label: Text(l10n.share),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _BusyButton(
                onPressed: () => _backupFlow(context, l10n),
                icon: const Icon(Icons.ios_share),
                label: Text(l10n.exportData),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _importFlow(context, l10n),
                icon: const Icon(Icons.download),
                label: Text(l10n.importData),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Switching the lock on asks for the phone's lock first: that proves
  /// there is one, and that whoever holds the phone may set it.
  Future<void> _setAppLock(
    BuildContext context,
    AppLocalizations l10n,
    bool on,
  ) async {
    if (!on) {
      settings.setAppLock(false);
      return;
    }
    final result = await const AppLock().authenticate(l10n.confirmItsYou);
    if (!context.mounted) return;
    switch (result) {
      case UnlockResult.unlocked:
        settings.setAppLock(true);
      case UnlockResult.noLock:
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            content: Text(l10n.appLockNoLock),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.gotIt),
              ),
            ],
          ),
        );
      case UnlockResult.failed:
        break;
    }
  }

  Future<void> _photoWallFlow(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final board = notes.currentBoard;
    if (board.hasSavedWallImage) {
      final action = await showActionSheet<String>(
        context,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.changePhoto),
            onTap: () => Navigator.pop(context, 'change'),
          ),
          ListTile(
            leading: const Icon(Icons.hide_image_outlined),
            title: Text(l10n.removePhoto),
            onTap: () => Navigator.pop(context, 'remove'),
          ),
        ],
      );
      if (action == null) return;
      if (action == 'remove') {
        notes.setCurrentBoardWall(board.wallIndex, forgetPhoto: true);
        return;
      }
    }
    final picked = await ImageService().pickWallImage();
    if (picked == null) return;
    final (stored, dark) = picked;
    notes.setCurrentBoardWallImage(stored, dark: dark);
  }

  Future<void> _backupFlow(BuildContext context, AppLocalizations l10n) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await BackupService().share(
        notes.boards,
        notes.allNotes,
        notes.links,
        subject: l10n.backupShareSubject,
        deletedBoards: notes.deletedBoards,
      );
    } catch (_) {
      // The snackbar lives under this sheet: close it so the message shows.
      if (context.mounted) Navigator.of(context).pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.backupFailed)));
    }
  }

  /// The weekly backup switch, saying when the last one was made.
  Widget _autoBackupTile(BuildContext context, AppLocalizations l10n) {
    final last = settings.lastAutoBackup;
    final when = last == null
        ? l10n.autoBackupNone
        : l10n.autoBackupLast(
            MaterialLocalizations.of(context).formatMediumDate(last),
          );
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        l10n.autoBackup,
        style: const TextStyle(fontSize: 16, color: AppColors.ink),
      ),
      subtitle: Text(
        '${l10n.autoBackupHint}\n$when',
        style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
      ),
      isThreeLine: true,
      secondary: const Icon(Icons.update, color: AppColors.ink),
      value: settings.autoBackup,
      onChanged: (on) {
        settings.setAutoBackup(on);
        // Switched back on after a long pause: the copy owed is made now.
        if (on) unawaited(AutoBackup.runIfDue(settings, notes));
      },
    );
  }

  /// Loads the newest automatic backup through the restore preview, with
  /// Undo as for any loaded backup.
  Future<void> _restoreAutoBackup(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final file = await AutoBackup.latest();
    if (!context.mounted) return;
    if (file == null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.autoBackupMissing)));
      return;
    }
    final Backup backup;
    try {
      backup = BackupService().decode(await file.readAsString());
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.importFailed)));
      return;
    }
    if (context.mounted) await _applyBackup(context, l10n, backup);
  }

  Future<void> _shareAutoBackup(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await AutoBackup.latest();
      if (file == null) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.autoBackupMissing)));
        return;
      }
      await AutoBackup.share(file, subject: l10n.backupShareSubject);
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.shareFailed)));
    }
  }

  /// The dialog only hands back a backup it has already read, so a bad file
  /// is explained there, with the text still in place to fix.
  Future<void> _importFlow(BuildContext context, AppLocalizations l10n) async {
    final backup = await showDialog<Backup>(
      context: context,
      builder: (context) => _ImportDialog(l10n: l10n),
    );
    if (backup == null || !context.mounted) return;
    await _applyBackup(context, l10n, backup);
  }

  /// Shows what [backup] holds and how it would load; then adds it to the
  /// wall or replaces the wall with it (its files first), with Undo on the
  /// snackbar either way, and closes the sheet so the snackbar shows.
  /// Nothing changes before a choice is made, and a failure to write the
  /// files changes nothing at all.
  Future<void> _applyBackup(
    BuildContext context,
    AppLocalizations l10n,
    Backup backup,
  ) async {
    final mode = await showRestorePreview(
      context,
      backup: backup,
      notes: notes,
    );
    if (mode == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    // Kept for Undo. replaceAll never deletes photo files, so the photos
    // these notes show are still on disk when they come back.
    final oldBoards = List.of(notes.boards);
    final oldNotes = List.of(notes.allNotes);
    final oldLinks = List.of(notes.links);
    final oldDeleted = List.of(notes.deletedBoards);
    try {
      await BackupService().restorePhotos(backup);
    } catch (_) {
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.importFailed)));
      return;
    }
    switch (mode) {
      case RestoreMode.replace:
        notes.replaceAll(
          backup.boards,
          backup.notes,
          links: backup.links,
          deletedBoards: backup.deletedBoards,
        );
      case RestoreMode.merge:
        notes.mergeAll(
          backup.boards,
          backup.notes,
          links: backup.links,
          deletedBoards: backup.deletedBoards,
        );
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            mode == RestoreMode.merge ? l10n.restoreMerged : l10n.importSuccess,
          ),
          action: SnackBarAction(
            label: l10n.undo,
            onPressed: () => notes.replaceAll(
              oldBoards,
              oldNotes,
              links: oldLinks,
              deletedBoards: oldDeleted,
            ),
          ),
        ),
      );
    if (navigator.mounted) navigator.pop();
  }
}

/// Shown while a Pro wall, font or pin is tried on: what it is, how to keep
/// it, and how to put things back.
class _TryOnBar extends StatelessWidget {
  const _TryOnBar({required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(top: 4, bottom: 4),
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(AppRadii.control),
          border: Border.all(color: AppColors.ink, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.visibility_outlined, color: AppColors.ink),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.tryingOn,
                    style: const TextStyle(fontSize: 15, color: AppColors.ink),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                TextButton(
                  style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
                  onPressed: settings.endTryOn,
                  child: Text(l10n.tryOnStop),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(44, 44),
                  ),
                  onPressed: () => showProSheet(context),
                  child: Text(l10n.tryOnKeep),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A wall texture swatch with its name, outlined when selected.
class _WallTile extends StatelessWidget {
  const _WallTile({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
    this.locked = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  /// A Pro wall without Pro: marked, and tapping it offers Pro.
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: locked ? AppLocalizations.of(context)!.proLocked(label) : label,
      excludeSemantics: true,
      child: KeyboardTappable(
        onActivate: onTap,
        borderRadius: BorderRadius.circular(AppRadii.control),
        child: GestureDetector(onTap: onTap, child: _tile()),
      ),
    );
  }

  Widget _tile() {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.ink : Colors.black26,
              width: selected ? 3 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                child,
                if (selected)
                  const Center(
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                if (locked)
                  const Positioned(top: 5, right: 5, child: ProMark()),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.ink,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

/// The last wall tile: the board's own photo when it has one (on show or
/// kept while a texture is tried), otherwise an invitation to pick one.
class _PhotoWallTile extends StatelessWidget {
  const _PhotoWallTile({
    required this.board,
    required this.l10n,
    required this.onTap,
  });

  final Board board;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _WallTile(
      label: l10n.customWall,
      selected: board.hasWallImage,
      onTap: onTap,
      child: board.hasSavedWallImage
          ? Image.file(
              File(ImageService.resolveWall(board.savedWallImage)),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _PhotoPlaceholder(),
            )
          : const _PhotoPlaceholder(),
    );
  }
}

/// The "your photo" tile before a photo has been chosen.
class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.ink.withValues(alpha: 0.10),
            AppColors.ink.withValues(alpha: 0.22),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.add_photo_alternate_outlined,
          color: AppColors.ink,
          size: 30,
        ),
      ),
    );
  }
}

/// Dropdown of whole hours for the lights schedule.
class _HourField extends StatelessWidget {
  const _HourField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isDense: true,
          isExpanded: true,
          items: [
            for (var h = 0; h < 24; h++)
              DropdownMenuItem(value: h, child: Text(hourLabel(context, h))),
          ],
          onChanged: (h) {
            if (h != null) onChanged(h);
          },
        ),
      ),
    );
  }
}

/// A font choice rendered the way it will actually look: on a small sticky
/// note, slightly askew, with the preview line as handwriting.
class _FontPaper extends StatelessWidget {
  const _FontPaper({
    required this.font,
    required this.preview,
    required this.selected,
    required this.tilt,
    required this.onTap,
    this.locked = false,
  });

  final FontChoice font;
  final String preview;
  final bool selected;
  final double tilt;
  final VoidCallback onTap;

  /// A Pro font without Pro: marked, and tapping it offers Pro.
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final paper = paperColorOf(context, null, font.id);
    return Semantics(
      button: true,
      selected: selected,
      label: locked
          ? AppLocalizations.of(context)!.proLocked(font.label)
          : font.label,
      excludeSemantics: true,
      child: KeyboardTappable(
        onActivate: onTap,
        child: GestureDetector(onTap: onTap, child: _paper(paper)),
      ),
    );
  }

  Widget _paper(Color paper) {
    return Transform.rotate(
      angle: selected ? 0 : tilt,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 150,
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 10),
        decoration: BoxDecoration(
          color: paper,
          border: selected
              ? Border.all(color: AppColors.ink, width: 2.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: selected ? 0.28 : 0.18),
              blurRadius: selected ? 10 : 6,
              offset: Offset(0, selected ? 5 : 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  font.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: font.family,
                    fontSize: 18 * font.scale,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  preview,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: font.family,
                    fontSize: 15 * font.scale,
                    height: 1.25,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
            // A little pin so it reads as a note, not a card.
            Positioned(
              top: -12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? AppColors.pin : Colors.black38,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black38,
                        blurRadius: 3,
                        offset: Offset(0, 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (selected)
              const Positioned(
                right: 0,
                bottom: 0,
                child: Icon(Icons.check_circle, color: AppColors.ink, size: 18),
              ),
            if (locked) const Positioned(right: 0, bottom: 0, child: ProMark()),
          ],
        ),
      ),
    );
  }
}

/// A pin style shown for real: a scrap of paper held up by it.
class _PinTile extends StatelessWidget {
  const _PinTile({
    required this.style,
    required this.label,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final PinStyle style;
  final String label;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The card's pin reads its style from the theme; this tile shows its
    // own style whatever is chosen.
    final shown = theme.copyWith(
      extensions: [
        ...theme.extensions.values.where((e) => e is! PinLook),
        PinLook(style),
      ],
    );
    return Semantics(
      button: true,
      selected: selected,
      label: locked ? AppLocalizations.of(context)!.proLocked(label) : label,
      excludeSemantics: true,
      child: KeyboardTappable(
        onActivate: onTap,
        borderRadius: BorderRadius.circular(AppRadii.control),
        child: GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: 84,
            child: Column(
              children: [
                SizedBox(
                  width: 84,
                  height: 70,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        top: 14,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 60,
                          height: 52,
                          decoration: BoxDecoration(
                            color: paperColorOf(context, 0, ''),
                            border: Border.all(
                              color: selected
                                  ? AppColors.ink
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(1, 2),
                              ),
                            ],
                          ),
                          child: selected
                              ? const Align(
                                  alignment: Alignment.bottomRight,
                                  child: Padding(
                                    padding: EdgeInsets.all(2),
                                    child: Icon(
                                      Icons.check_circle,
                                      color: AppColors.ink,
                                      size: 16,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        child: SizedBox(
                          width: 44,
                          height: 28,
                          child: Center(
                            child: Theme(
                              data: shown,
                              child: const NotePin(
                                pinned: false,
                                seed: 'pin-tile',
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (locked)
                        const Positioned(right: 4, bottom: 0, child: ProMark()),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.1,
                    color: AppColors.ink,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
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

/// Paste a backup or choose its file. Owns its controller so it is
/// disposed with the dialog, not while the field is still animating off
/// screen. Pops with the [Backup] once it has been read; a document that
/// cannot be read keeps the dialog open with the reason under the field.
class _ImportDialog extends StatefulWidget {
  const _ImportDialog({required this.l10n});

  final AppLocalizations l10n;

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  final _controller = TextEditingController();
  String? _error;
  bool _reading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _reason(BackupProblem problem) {
    final l10n = widget.l10n;
    return switch (problem) {
      BackupProblem.notJson => l10n.importNotJson,
      BackupProblem.notBackup => l10n.importNotBackup,
      BackupProblem.newerVersion => l10n.importNewerVersion,
      BackupProblem.tooLarge => l10n.importTooLarge,
    };
  }

  /// Reads [source]; pops with the backup, or shows why it can't be used.
  void _load(String source) {
    try {
      Navigator.pop(context, BackupService().decode(source));
    } on BackupFormatException catch (e) {
      setState(() => _error = _reason(e.problem));
    }
  }

  Future<void> _chooseFile() async {
    setState(() => _reading = true);
    try {
      // Any type: providers label .json files inconsistently (text/plain,
      // octet-stream), and a filter would grey out the very file wanted.
      final file = await FilePicker.pickFile();
      if (file == null || !mounted) return;
      // Too big to read safely on a phone: say so before reading it.
      if ((await file.length() ?? 0) > BackupService.maxDocumentChars) {
        if (mounted) _error = _reason(BackupProblem.tooLarge);
        return;
      }
      final String text;
      try {
        text = utf8.decode(await file.readAsBytes());
      } on FormatException {
        if (mounted) _error = _reason(BackupProblem.notJson);
        return;
      }
      if (mounted) _load(text);
    } catch (_) {
      if (mounted) _error = widget.l10n.importFailed;
    } finally {
      if (mounted) setState(() => _reading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      title: Text(l10n.importData),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.importReplaceWarning,
              style: const TextStyle(fontSize: 14, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _reading ? null : _chooseFile,
              icon: _reading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.file_open_outlined),
              label: Text(l10n.importChooseFile),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 6,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              decoration: InputDecoration(
                hintText: l10n.importHint,
                border: const OutlineInputBorder(),
                errorText: _error,
                errorMaxLines: 4,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => FilledButton(
            onPressed: _controller.text.trim().isEmpty || _reading
                ? null
                : () => _load(_controller.text),
            child: Text(l10n.importData),
          ),
        ),
      ],
    );
  }
}

/// Small caps heading above each settings group.
/// An outlined button whose action takes a while (a backup reads every
/// photo): it shows a spinner and ignores taps until the action is done, so
/// a second tap does not start a second copy.
class _BusyButton extends StatefulWidget {
  const _BusyButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final Future<void> Function() onPressed;
  final Widget icon;
  final Widget label;

  @override
  State<_BusyButton> createState() => _BusyButtonState();
}

class _BusyButtonState extends State<_BusyButton> {
  bool _busy = false;

  Future<void> _run() async {
    setState(() => _busy = true);
    try {
      await widget.onPressed();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _busy ? null : _run,
      icon: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : widget.icon,
      label: widget.label,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          color: AppColors.ink,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
