import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

import 'image_service.dart';

/// Voice-note files: recorded into `<documents>/note_audio/` and stored on a
/// note by *file name* only, exactly like photos (see `ImageService.resolve`
/// for why a full path would rot).
class AudioService {
  AudioService._();

  static const _folder = 'note_audio';

  // Unique names even when two recordings finish within one microsecond.
  static int _seq = 0;

  /// Absolute path for a stored recording reference (only the name counts,
  /// so an absolute path from elsewhere heals).
  static String resolve(String stored) {
    if (stored.isEmpty) return stored;
    final dir = ImageService.documentsPathOrNull;
    if (dir == null) return stored;
    final name = stored.split(RegExp(r'[\\/]')).last;
    return '$dir/$_folder/$name';
  }

  /// A fresh file name for a recording and the absolute path to record it
  /// to; the folder is created on the way.
  static Future<(String, String)> newRecording() async {
    final docs = await ImageService.documentsPath();
    final dir = Directory('$docs/$_folder');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final seq = (_seq++ % 1000).toString().padLeft(3, '0');
    final name = 'voice_${DateTime.now().microsecondsSinceEpoch}$seq.m4a';
    return (name, '${dir.path}/$name');
  }

  /// Removes a recording. Missing files and I/O errors are ignored — this is
  /// best-effort housekeeping.
  static Future<void> deleteFile(String stored) async {
    if (stored.isEmpty) return;
    if (AudioPlayback.instance.current == stored) {
      await AudioPlayback.instance.stop();
    }
    try {
      final file = File(resolve(stored));
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  /// The bytes of a stored recording, or null when it is missing — a backup
  /// then simply goes without it.
  static Future<Uint8List?> readStored(String stored) async {
    if (stored.isEmpty) return null;
    try {
      await ImageService.documentsPath();
      final file = File(resolve(stored));
      if (!await file.exists()) return null;
      return await file.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  /// Writes a recording carried by a backup back under its stored name. A
  /// file already there is left alone: names are unique.
  static Future<void> writeStored(String stored, Uint8List bytes) async {
    if (stored.isEmpty) return;
    // Only the name counts, so a crafted "../x" stays inside the folder.
    final name = stored.split(RegExp(r'[\\/]')).last;
    if (name.isEmpty || name == '.' || name == '..') return;
    final docs = await ImageService.documentsPath();
    final dir = Directory('$docs/$_folder');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final file = File('${dir.path}/$name');
    if (await file.exists()) return;
    await file.writeAsBytes(bytes, flush: true);
  }
}

/// Why a recording could not start.
enum RecordProblem { denied, failed }

/// One recording at a time, for the editor. The microphone permission is
/// asked for only here, when the user actually starts recording.
class VoiceRecorder {
  AudioRecorder? _recorder;
  final _clock = Stopwatch();
  String? _name;

  bool get isRecording => _name != null;

  /// How long the current recording has been running.
  Duration get elapsed => _clock.elapsed;

  /// Starts recording into a new file. Returns null on success, else why it
  /// could not start.
  Future<RecordProblem?> start() async {
    if (isRecording) return null;
    await AudioPlayback.instance.stop();
    try {
      final recorder = _recorder ??= AudioRecorder();
      if (!await recorder.hasPermission()) return RecordProblem.denied;
      final (name, path) = await AudioService.newRecording();
      await recorder.start(
        const RecordConfig(
          // AAC in an .m4a: small, and plays back on Android and iOS alike.
          bitRate: 64000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: path,
      );
      _name = name;
      _clock
        ..reset()
        ..start();
      return null;
    } catch (e) {
      debugPrint('Could not start recording: $e');
      return RecordProblem.failed;
    }
  }

  /// Stops and returns the stored name and length of what was recorded, or
  /// null when nothing usable came of it (too short, or the recorder failed).
  Future<(String, int)?> stop() async {
    final name = _name;
    if (name == null) return null;
    _name = null;
    _clock.stop();
    final ms = _clock.elapsedMilliseconds;
    try {
      await _recorder?.stop();
    } catch (e) {
      debugPrint('Could not stop recording: $e');
      unawaited(AudioService.deleteFile(name));
      return null;
    }
    // A brush of the button is not a recording.
    if (ms < 400) {
      unawaited(AudioService.deleteFile(name));
      return null;
    }
    return (name, ms);
  }

  /// Drops a recording in progress, file and all.
  Future<void> cancel() async {
    final name = _name;
    _name = null;
    _clock.stop();
    try {
      await _recorder?.cancel();
    } catch (_) {}
    if (name != null) unawaited(AudioService.deleteFile(name));
  }

  Future<void> dispose() async {
    await cancel();
    try {
      await _recorder?.dispose();
    } catch (_) {}
    _recorder = null;
  }
}

/// The one voice note playing anywhere in the app — starting another stops
/// it, as on a real tape deck. Cards and the editor listen to it for their
/// play / pause state and the turning reels.
class AudioPlayback extends ChangeNotifier {
  AudioPlayback._();

  static final instance = AudioPlayback._();

  AudioPlayer? _player;
  final _subs = <StreamSubscription<Object?>>[];
  String? _current;
  bool _playing = false;
  Duration _position = Duration.zero;

  /// The recording loaded in the player (playing or paused), if any.
  String? get current => _current;

  bool isPlaying(String stored) => _playing && _current == stored;

  /// How far into [stored] playback is (zero unless it is the current one).
  Duration positionOf(String stored) =>
      _current == stored ? _position : Duration.zero;

  /// Created on first use, so tests and screens that never play anything
  /// never touch the platform channel.
  AudioPlayer _ensurePlayer() {
    final existing = _player;
    if (existing != null) return existing;
    final player = AudioPlayer();
    _subs
      ..add(
        player.onPlayerStateChanged.listen((s) {
          final playing = s == PlayerState.playing;
          if (playing != _playing) {
            _playing = playing;
            notifyListeners();
          }
        }),
      )
      ..add(
        player.onPositionChanged.listen((p) {
          _position = p;
          notifyListeners();
        }),
      )
      ..add(
        player.onPlayerComplete.listen((_) {
          _playing = false;
          _position = Duration.zero;
          _current = null;
          notifyListeners();
        }),
      );
    return _player = player;
  }

  /// Plays [stored], or pauses it when it is the one playing. Returns false
  /// when the file is gone or cannot be played.
  Future<bool> toggle(String stored) async {
    if (stored.isEmpty) return false;
    try {
      final player = _ensurePlayer();
      if (_current == stored) {
        if (_playing) {
          await player.pause();
        } else {
          await player.resume();
        }
        return true;
      }
      await ImageService.documentsPath();
      final path = AudioService.resolve(stored);
      if (!File(path).existsSync()) return false;
      await player.stop();
      _current = stored;
      _position = Duration.zero;
      _playing = true;
      notifyListeners();
      await player.play(DeviceFileSource(path));
      return true;
    } catch (e) {
      debugPrint('Could not play voice note: $e');
      _current = null;
      _playing = false;
      notifyListeners();
      return false;
    }
  }

  /// Stops whatever is playing.
  Future<void> stop() async {
    if (_current == null && !_playing) return;
    _current = null;
    _playing = false;
    _position = Duration.zero;
    notifyListeners();
    try {
      await _player?.stop();
    } catch (_) {}
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _player?.dispose();
    super.dispose();
  }
}

/// "0:42", "12:05" — a recording's length the way a tape counter shows it.
String formatClip(Duration d) {
  final s = d.inSeconds;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}
