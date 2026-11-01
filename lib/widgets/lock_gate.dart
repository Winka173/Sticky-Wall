import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/app_lock.dart';
import '../theme.dart';

/// Covers the whole app — dialogs and sheets included, since it sits above
/// the navigator — until the phone's lock is given. Locks when the app
/// starts and again when it comes back after [awayLimit] in the background,
/// so stepping out to pick a photo or answer a message does not ask again.
class LockGate extends StatefulWidget {
  const LockGate({
    super.key,
    required this.enabled,
    required this.child,
    this.lock = const AppLock(),
    this.awayLimit = const Duration(minutes: 1),
  });

  final bool enabled;
  final Widget child;
  final AppLock lock;
  final Duration awayLimit;

  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> with WidgetsBindingObserver {
  late bool _locked = widget.enabled;
  bool _asking = false;
  DateTime? _awayAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_locked) WidgetsBinding.instance.addPostFrameCallback((_) => _ask());
  }

  @override
  void didUpdateWidget(LockGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Switching the lock on does not lock at once (the owner just proved
    // who they are); switching it off opens up straight away.
    if (!widget.enabled && _locked) _locked = false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.enabled) return;
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        // The lock prompt itself can send the app to the background.
        if (!_asking) _awayAt ??= DateTime.now();
      case AppLifecycleState.resumed:
        final away = _awayAt;
        _awayAt = null;
        // Only a real trip away asks by itself. Coming back from a cancelled
        // prompt must not open it again, or Back could never leave it; the
        // Unlock button is there for that.
        if (away == null) break;
        if (!_locked && DateTime.now().difference(away) >= widget.awayLimit) {
          setState(() => _locked = true);
        }
        if (_locked) unawaited(_ask());
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _ask() async {
    if (_asking || !_locked || !mounted) return;
    _asking = true;
    final reason = AppLocalizations.of(context)!.appLockReason;
    final result = await widget.lock.authenticate(reason);
    _asking = false;
    if (!mounted) return;
    // A phone whose screen lock was removed since cannot be asked any more;
    // locking its owner out of their own notes would help no one.
    if (result != UnlockResult.failed) setState(() => _locked = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Kept in the tree (so nothing is lost) but out of reach.
        ExcludeFocus(
          excluding: _locked,
          child: ExcludeSemantics(
            excluding: _locked,
            child: IgnorePointer(ignoring: _locked, child: widget.child),
          ),
        ),
        if (_locked) _LockedCover(onUnlock: _ask),
      ],
    );
  }
}

/// What shows while locked: the bare wall with one note on it.
class _LockedCover extends StatelessWidget {
  const _LockedCover({required this.onUnlock});

  final VoidCallback onUnlock;

  /// The splash's wall colour, so a locked start looks like the splash.
  static const _wall = Color(0xFF6B5849);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: _wall,
      child: SafeArea(
        child: Center(
          child: Container(
            width: 260,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            decoration: BoxDecoration(
              color: paperColorOf(context, 0, ''),
              borderRadius: BorderRadius.circular(AppRadii.paper),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 12,
                  offset: Offset(2, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 36, color: AppColors.ink),
                const SizedBox(height: 12),
                Text(
                  l10n.appLockLocked,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22 * noteFontScale(context),
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  autofocus: true,
                  onPressed: onUnlock,
                  icon: const Icon(Icons.fingerprint),
                  label: Text(l10n.appLockUnlock),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
