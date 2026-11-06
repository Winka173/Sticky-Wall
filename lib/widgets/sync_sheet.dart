import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/sync/drive_backend.dart';
import '../services/sync/sync_service.dart';
import '../theme.dart';
import 'action_sheet.dart';

/// One line saying where sync stands, for the Customize row and the sheet.
String syncStatusText(
  AppLocalizations l10n,
  SyncService sync,
  BuildContext context,
) {
  final last = sync.lastSync;
  String when() {
    if (last == null) return '';
    final ml = MaterialLocalizations.of(context);
    return '${ml.formatShortMonthDay(last)} '
        '${ml.formatTimeOfDay(TimeOfDay.fromDateTime(last))}';
  }

  return switch (sync.state) {
    SyncState.off => l10n.syncOffHint,
    SyncState.syncing => l10n.syncSyncing,
    SyncState.idle => last == null ? l10n.syncReady : l10n.syncDone(when()),
    SyncState.offline => l10n.syncOffline,
    SyncState.authNeeded => l10n.syncAuthNeeded,
    SyncState.quota => l10n.syncQuota,
    SyncState.failed => l10n.syncFailed,
  };
}

/// Sync across devices: what it does, on/off, Sync now, locked boards, and
/// an honest status. Off by default; nothing here is needed to use the app.
Future<void> showSyncSheet(BuildContext context, SyncService sync) {
  return showActionSheet<void>(
    context,
    title: AppLocalizations.of(context)!.syncTitle,
    children: [_SyncBody(sync: sync)],
  );
}

class _SyncBody extends StatefulWidget {
  const _SyncBody({required this.sync});

  final SyncService sync;

  @override
  State<_SyncBody> createState() => _SyncBodyState();
}

class _SyncBodyState extends State<_SyncBody> {
  bool _connecting = false;

  Future<void> _turnOn() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _connecting = true);
    final ok = await DriveSyncBackend.authorize();
    if (!mounted) return;
    setState(() => _connecting = false);
    if (!ok) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.syncConnectFailed)));
      return;
    }
    await widget.sync.enable(DriveSyncBackend());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sync = widget.sync;
    return ListenableBuilder(
      listenable: sync,
      builder: (context, _) {
        final on = sync.enabled;
        const body = TextStyle(
          fontSize: 14,
          color: AppColors.ink,
          height: 1.35,
        );
        const soft = TextStyle(fontSize: 13, color: AppColors.inkSoft);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.syncExplain, style: body),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.syncWithDrive),
                subtitle: Semantics(
                  liveRegion: true,
                  child: Text(syncStatusText(l10n, sync, context), style: soft),
                ),
                value: on,
                onChanged: _connecting
                    ? null
                    : (v) => v ? _turnOn() : sync.disable(),
              ),
              if (_connecting) const LinearProgressIndicator(),
              if (on) ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.syncIncludeLocked),
                  subtitle: Text(l10n.syncIncludeLockedHint, style: soft),
                  value: sync.includeLocked,
                  onChanged: sync.setIncludeLocked,
                ),
                if (sync.lastConflicts > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      l10n.syncConflicts(sync.lastConflicts),
                      style: soft,
                    ),
                  ),
                if (sync.missingMedia > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      l10n.syncMissing(sync.missingMedia),
                      style: soft,
                    ),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(48, 44),
                    ),
                    icon: const Icon(Icons.sync),
                    label: Text(l10n.syncNow),
                    onPressed: sync.state == SyncState.syncing
                        ? null
                        : sync.syncNow,
                  ),
                ),
                const SizedBox(height: 10),
                Text(l10n.syncOffNote, style: soft),
              ],
              const SizedBox(height: 8),
              Text(l10n.syncPrivacy, style: soft),
            ],
          ),
        );
      },
    );
  }
}
