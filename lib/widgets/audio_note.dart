import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../services/audio_service.dart';
import '../theme.dart';

/// The voice-note pieces: the play button, the cassette's tape window and
/// label, and the editor's record / re-record panel. The card itself is put
/// together in `note_views.dart` (`StickyNoteCard._cassette`), so every view
/// draws it the same way.

/// The longest a single voice note may run; recording stops by itself there.
const kMaxRecording = Duration(minutes: 10);

/// Plays or pauses one recording; its icon and spoken label follow the
/// shared [AudioPlayback]. A real button: focusable, Enter / Space press it,
/// and it is at least 44 dp across.
class VoicePlayButton extends StatelessWidget {
  const VoicePlayButton({super.key, required this.stored, this.size = 44});

  final String stored;
  final double size;

  Future<void> _toggle(BuildContext context) async {
    unawaited(HapticFeedback.selectionClick());
    final messenger = ScaffoldMessenger.maybeOf(context);
    final words = AppLocalizations.of(context)!.recordingMissing;
    final ok = await AudioPlayback.instance.toggle(stored);
    if (!ok) {
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(words)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: AudioPlayback.instance,
      builder: (context, _) {
        final playing = AudioPlayback.instance.isPlaying(stored);
        final label = playing ? l10n.pauseVoice : l10n.playVoice;
        return Tooltip(
          message: label,
          child: Semantics(
            button: true,
            label: label,
            excludeSemantics: true,
            child: SizedBox.square(
              dimension: math.max(44, size),
              child: Center(
                child: Material(
                  color: AppColors.ink,
                  shape: const CircleBorder(),
                  elevation: 1.5,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _toggle(context),
                    child: SizedBox.square(
                      dimension: size,
                      child: Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: size * 0.6,
                        color: AppColors.chalk,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The cassette's window: two reels with the tape wound from one to the
/// other as [progress] (0..1) runs, turning while [spinning] — unless the
/// system asks for less motion, when they hold still.
class TapeWindow extends StatefulWidget {
  const TapeWindow({
    super.key,
    required this.progress,
    required this.spinning,
    this.height = 34,
  });

  final double progress;
  final bool spinning;
  final double height;

  @override
  State<TapeWindow> createState() => _TapeWindowState();
}

class _TapeWindowState extends State<TapeWindow>
    with SingleTickerProviderStateMixin {
  late final _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  void _sync() {
    final still = MediaQuery.disableAnimationsOf(context);
    if (widget.spinning && !still) {
      if (!_spin.isAnimating) _spin.repeat();
    } else if (_spin.isAnimating) {
      _spin.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(TapeWindow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: widget.height,
        child: AnimatedBuilder(
          animation: _spin,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: _ReelsPainter(
              progress: widget.progress.clamp(0.0, 1.0),
              turn: _spin.value,
            ),
          ),
        ),
      ),
    );
  }
}

/// The dark glass window with its two reels, the brown tape wound on them
/// and the run of tape between, and toothed white hubs.
class _ReelsPainter extends CustomPainter {
  const _ReelsPainter({required this.progress, required this.turn});

  final double progress;
  final double turn;

  static const _tape = Color(0xFF4A3426);

  @override
  void paint(Canvas canvas, Size size) {
    final window = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height / 2),
    );
    canvas.drawRRect(
      window,
      Paint()..color = AppColors.ink.withValues(alpha: 0.82),
    );
    // A soft highlight across the top: glass, not a hole.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.height * 0.4, 2, size.width - size.height * 0.8, 3),
        const Radius.circular(2),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.10),
    );

    final cy = size.height / 2;
    final maxR = size.height / 2 - 3;
    final hubR = maxR * 0.42;
    final gap = math.min(size.width * 0.27, size.width / 2 - maxR - 2);
    final left = Offset(size.width / 2 - gap, cy);
    final right = Offset(size.width / 2 + gap, cy);
    // The tape moves from the left reel to the right one as it plays.
    final leftR = hubR + (maxR - hubR) * (1 - progress * 0.85);
    final rightR = hubR + (maxR - hubR) * (0.15 + progress * 0.85);

    final tape = Paint()..color = _tape;
    canvas
      ..drawLine(
        Offset(left.dx, cy + leftR),
        Offset(right.dx, cy + rightR),
        tape
          ..strokeWidth = 1.4
          ..style = PaintingStyle.stroke,
      )
      ..drawCircle(left, leftR, Paint()..color = _tape)
      ..drawCircle(right, rightR, Paint()..color = _tape);

    for (final c in [left, right]) {
      _hub(canvas, c, hubR);
    }
  }

  void _hub(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(c, r, Paint()..color = AppColors.chalk);
    final teeth = Paint()..color = AppColors.ink.withValues(alpha: 0.75);
    final angle = turn * 2 * math.pi;
    for (var i = 0; i < 6; i++) {
      final a = angle + i * math.pi / 3;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        c + dir * (r * 0.35),
        c + dir * (r * 0.92),
        teeth
          ..strokeWidth = 1.3
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawCircle(c, r * 0.22, Paint()..color = AppColors.ink);
  }

  @override
  bool shouldRepaint(_ReelsPainter old) =>
      old.progress != progress || old.turn != turn;
}

/// A tape window bound to [stored]'s playback: the reels turn while it
/// plays and the tape winds across as it goes.
class PlaybackTape extends StatelessWidget {
  const PlaybackTape({
    super.key,
    required this.stored,
    required this.length,
    this.height = 34,
  });

  final String stored;
  final Duration length;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AudioPlayback.instance,
      builder: (context, _) {
        final playback = AudioPlayback.instance;
        final at = playback.positionOf(stored);
        final total = length.inMilliseconds;
        return TapeWindow(
          height: height,
          progress: total <= 0 ? 0 : at.inMilliseconds / total,
          spinning: playback.isPlaying(stored),
        );
      },
    );
  }
}

/// The counter beside the tape: the length, or "0:12 / 0:42" while playing.
class PlaybackCounter extends StatelessWidget {
  const PlaybackCounter({
    super.key,
    required this.stored,
    required this.length,
    required this.style,
  });

  final String stored;
  final Duration length;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AudioPlayback.instance,
      builder: (context, _) {
        final playback = AudioPlayback.instance;
        final live = playback.current == stored;
        final text = live
            ? '${formatClip(playback.positionOf(stored))} / ${formatClip(length)}'
            : formatClip(length);
        return Text(text, maxLines: 1, softWrap: false, style: style);
      },
    );
  }
}

/// Screws in the four corners and the tape-head notch along the bottom
/// edge: what makes a pastel rectangle read as a cassette.
class CassetteShellPainter extends CustomPainter {
  const CassetteShellPainter({required this.notch});

  /// Height of the notch strip at the bottom (0 for none).
  final double notch;

  @override
  void paint(Canvas canvas, Size size) {
    final screw = Paint()..color = AppColors.ink.withValues(alpha: 0.30);
    final slot = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.45)
      ..strokeWidth = 0.9;
    const inset = 5.0;
    for (final c in [
      const Offset(inset, inset),
      Offset(size.width - inset, inset),
      Offset(inset, size.height - inset),
      Offset(size.width - inset, size.height - inset),
    ]) {
      canvas
        ..drawCircle(c, 2.2, screw)
        ..drawLine(
          c - const Offset(1.4, 1.4),
          c + const Offset(1.4, 1.4),
          slot,
        );
    }
    if (notch <= 0) return;
    // The raised trapezoid along the bottom, with its two capstan holes.
    final w = size.width * 0.56;
    final top = size.height - notch;
    final x0 = (size.width - w) / 2;
    final path = Path()
      ..moveTo(x0 + notch * 0.9, top)
      ..lineTo(x0 + w - notch * 0.9, top)
      ..lineTo(x0 + w, size.height)
      ..lineTo(x0, size.height)
      ..close();
    canvas
      ..drawPath(path, Paint()..color = Colors.black.withValues(alpha: 0.07))
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = AppColors.ink.withValues(alpha: 0.18),
      );
    final holeY = top + notch * 0.55;
    final hole = Paint()..color = AppColors.ink.withValues(alpha: 0.35);
    canvas
      ..drawCircle(Offset(x0 + w * 0.3, holeY), 1.8, hole)
      ..drawCircle(Offset(x0 + w * 0.7, holeY), 1.8, hole);
  }

  @override
  bool shouldRepaint(CassetteShellPainter old) => old.notch != notch;
}

/// Faint ruled lines on the cassette's label sticker.
class CassetteLabelPainter extends CustomPainter {
  const CassetteLabelPainter({required this.stripe});

  /// The coloured band across the top of the sticker.
  final Color stripe;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 4),
      Paint()..color = stripe,
    );
    final rule = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.10)
      ..strokeWidth = 1;
    for (var y = size.height - 6; y > 12; y -= 12) {
      canvas.drawLine(Offset(6, y), Offset(size.width - 6, y), rule);
    }
  }

  @override
  bool shouldRepaint(CassetteLabelPainter old) => old.stripe != stripe;
}

/// The editor's recording panel: a big microphone to start (tap, or hold
/// and let go), a running counter and a stop button while recording, and —
/// once there is a recording — play, record again and delete.
///
/// Recordings are handed up through [onRecorded]; the editor decides which
/// files to keep. The microphone permission is asked for on the first
/// press, and a refusal comes back through [onProblem].
class VoiceRecorderPanel extends StatefulWidget {
  const VoiceRecorderPanel({
    super.key,
    required this.stored,
    required this.length,
    required this.onRecorded,
    required this.onDelete,
    required this.onProblem,
    this.onRecordingChanged,
  });

  final String stored;
  final Duration length;
  final void Function(String stored, int ms) onRecorded;
  final VoidCallback onDelete;
  final void Function(RecordProblem problem) onProblem;

  /// Told when recording starts and stops, so the editor can hold off
  /// saving or closing mid-take.
  final ValueChanged<bool>? onRecordingChanged;

  @override
  State<VoiceRecorderPanel> createState() => VoiceRecorderPanelState();
}

/// Public so the editor can [finish] a take before saving.
class VoiceRecorderPanelState extends State<VoiceRecorderPanel>
    with SingleTickerProviderStateMixin {
  /// Whether a take is in progress.
  bool get isRecording => _recorder.isRecording;

  /// Ends a take in progress (handing it up through `onRecorded`), so Save
  /// keeps what was said rather than throwing it away.
  Future<void> finish() => _stop();

  final _recorder = VoiceRecorder();
  Timer? _tick;
  bool _starting = false;

  /// Set when the take began with a long press: letting go stops it.
  bool _held = false;

  /// The finger is still on the microphone (between long-press start and
  /// end). A hold that ends while the recorder is still starting — the
  /// permission prompt, say — leaves a take that a tap on Stop ends.
  bool _pressing = false;

  late final AnimationController _pulse;

  bool get _recording => _recorder.isRecording;

  @override
  void initState() {
    super.initState();
    // Made here, not lazily: a panel closed without ever recording would
    // otherwise create its ticker in dispose.
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _tick?.cancel();
    _pulse.dispose();
    unawaited(_recorder.dispose());
    super.dispose();
  }

  Future<void> _start({bool held = false}) async {
    if (_recording || _starting) return;
    _starting = true;
    final problem = await _recorder.start();
    _starting = false;
    if (!mounted) {
      unawaited(_recorder.cancel());
      return;
    }
    if (problem != null) {
      widget.onProblem(problem);
      return;
    }
    unawaited(HapticFeedback.mediumImpact());
    _held = held && _pressing;
    if (!MediaQuery.disableAnimationsOf(context)) {
      unawaited(_pulse.repeat(reverse: true));
    }
    _tick = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted) return;
      if (_recorder.elapsed >= kMaxRecording) {
        unawaited(_stop());
      } else {
        setState(() {});
      }
    });
    setState(() {});
    widget.onRecordingChanged?.call(true);
  }

  Future<void> _stop() async {
    if (!_recording) return;
    _tick?.cancel();
    _tick = null;
    _pulse
      ..stop()
      ..value = 0;
    _held = false;
    final take = await _recorder.stop();
    if (!mounted) return;
    unawaited(HapticFeedback.selectionClick());
    setState(() {});
    widget.onRecordingChanged?.call(false);
    if (take != null) widget.onRecorded(take.$1, take.$2);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final Widget child;
    if (_recording) {
      child = _recordingRow(l10n);
    } else if (widget.stored.isEmpty) {
      child = _micButton(l10n);
    } else {
      child = _playbackRows(l10n);
    }
    // Letting go of a hold is caught here, above the switch: once the take
    // starts, the microphone (and its long-press recognizer) is replaced by
    // the recording row, so its own "long press end" would never come.
    return Listener(
      onPointerUp: (_) => _letGo(),
      onPointerCancel: (_) => _letGo(),
      child: AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        child: KeyedSubtree(
          key: ValueKey(
            _recording
                ? 'rec'
                : widget.stored.isEmpty
                ? 'empty'
                : 'play',
          ),
          child: child,
        ),
      ),
    );
  }

  void _letGo() {
    _pressing = false;
    if (_held) unawaited(_stop());
  }

  /// Tap to start (and tap stop to finish), or hold and let go.
  Widget _micButton(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Tooltip(
            message: l10n.recordStart,
            child: Semantics(
              button: true,
              label: l10n.recordStart,
              hint: l10n.recordHint,
              excludeSemantics: true,
              child: GestureDetector(
                onLongPressStart: (_) {
                  _pressing = true;
                  _start(held: true);
                },
                child: Material(
                  color: AppColors.ink,
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _start,
                    child: const SizedBox.square(
                      dimension: 64,
                      child: Icon(
                        Icons.mic_rounded,
                        size: 32,
                        color: AppColors.chalk,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.recordHint,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }

  Widget _recordingRow(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          FadeTransition(
            opacity: Tween(begin: 1.0, end: 0.25).animate(_pulse),
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.pin,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(dimension: 12),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                '${l10n.recordingNow}  ${formatClip(_recorder.elapsed)}',
                style: const TextStyle(fontSize: 16, color: AppColors.ink),
              ),
            ),
          ),
          Expanded(
            child: TapeWindow(
              progress:
                  _recorder.elapsed.inMilliseconds /
                  kMaxRecording.inMilliseconds,
              spinning: true,
              height: 30,
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: l10n.recordStop,
            child: Semantics(
              button: true,
              label: l10n.recordStop,
              excludeSemantics: true,
              child: Material(
                color: AppColors.pin,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _stop,
                  child: const SizedBox.square(
                    dimension: 56,
                    child: Icon(
                      Icons.stop_rounded,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _playbackRows(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              VoicePlayButton(stored: widget.stored, size: 48),
              const SizedBox(width: 10),
              Expanded(
                child: PlaybackTape(
                  stored: widget.stored,
                  length: widget.length,
                ),
              ),
              const SizedBox(width: 10),
              PlaybackCounter(
                stored: widget.stored,
                length: widget.length,
                style: const TextStyle(fontSize: 14, color: AppColors.inkSoft),
              ),
            ],
          ),
          Wrap(
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  minimumSize: const Size(44, 44),
                ),
                onPressed: _start,
                icon: const Icon(Icons.mic_none_rounded, size: 20),
                label: Text(l10n.recordAgain),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.warnText,
                  minimumSize: const Size(44, 44),
                ),
                onPressed: () {
                  if (AudioPlayback.instance.current == widget.stored) {
                    unawaited(AudioPlayback.instance.stop());
                  }
                  widget.onDelete();
                },
                icon: const Icon(Icons.delete_outline, size: 20),
                label: Text(l10n.deleteRecording),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
