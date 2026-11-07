// Native profile-only harness. The actual app UI uses in-memory fixture data;
// existing on-device notes/preferences are never read or overwritten.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/main.dart' as app;
import 'package:sticky_wall/models/board.dart';
import 'package:sticky_wall/models/note.dart';
import 'package:sticky_wall/models/view_mode.dart';

app.StickyWallApp? _app;
int _checkStamp = 0;
bool _dialog = false;
Stopwatch? _pending;
Stopwatch? _pressed;
Duration? _downTime;
int _heldMicros = 0;
DateTime? _lastUp;
int _beforeCheck = 0;
bool _beforeDialog = false;

void _readState() {
  _dialog = false;
  void visit(Element element) {
    if (element.widget case final app.StickyWallApp widget) _app = widget;
    if (element.widget is Dialog) _dialog = true;
    element.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(visit);
  _checkStamp = 0;
  for (final note in _app?.notes.allNotes ?? <Note>[]) {
    for (final item in note.checklist) {
      _checkStamp = _checkStamp * 31 + (item.done ? 1 : 0);
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final count = const int.fromEnvironment('PERF_NOTES', defaultValue: 50);
  final fixtures = [
    Note(
      guid: 'perf-open',
      content: 'Open immediately',
      boardId: 'default',
      createdAt: DateTime(2026),
      x: .08,
      y: .12,
    ),
    Note(
      guid: 'perf-check',
      content: 'Performance QA',
      type: NoteType.checklist,
      checklist: [ChecklistItem(text: 'Check immediately')],
      boardId: 'default',
      createdAt: DateTime(2026),
      x: .7,
      y: .45,
      colorIndex: 1,
    ),
    for (var i = 2; i < count; i++)
      Note(
        guid: 'perf-$i',
        content: 'Fixture $i',
        boardId: 'default',
        createdAt: DateTime(2026),
        x: 1.3 + (i % 5) * .5,
        y: 1.5 + (i ~/ 5) * .2,
      ),
  ];
  SharedPreferences.setMockInitialValues({
    'notes': jsonEncode(fixtures.map((n) => n.toJson()).toList()),
    'boards': jsonEncode([
      Board(id: 'default', name: 'Performance QA').toJson(),
    ]),
    'viewMode': ViewMode.wall.name,
    'language': 'en',
    'welcomePending': false,
    'tipsPending': false,
    'autoBackup': false,
  });
  await app.main();
  WidgetsBinding.instance.pointerRouter.addGlobalRoute((event) {
    if (event is PointerDownEvent) {
      _pressed = Stopwatch()..start();
      _downTime = event.timeStamp;
      _readState();
      _beforeCheck = _checkStamp;
      _beforeDialog = _dialog;
      _pending = null;
    } else if (event is PointerUpEvent) {
      _heldMicros =
          (event.timeStamp - (_downTime ?? event.timeStamp)).inMicroseconds;
      _pending = _pressed;
      _lastUp = DateTime.now();
    }
  });
  void frame(Duration _) {
    final watch = _pending;
    if (watch != null) {
      _readState();
      final kind = _beforeCheck != _checkStamp
          ? 'checkbox'
          : !_beforeDialog && _dialog
          ? 'open_note'
          : null;
      if (kind != null) {
        debugPrint(
          'STICKY_PERF ${jsonEncode({'action': kind, 'inputToUiFrameMs': (watch.elapsedMicroseconds - _heldMicros).clamp(0, 10000000) / 1000, 'fixtureNotes': count})}',
        );
        _pending = null;
      } else if (watch.elapsedMilliseconds > 1500) {
        _pending = null;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback(frame);
  }

  WidgetsBinding.instance.addPostFrameCallback(frame);
  WidgetsBinding.instance.addTimingsCallback((frames) {
    final last = _lastUp;
    if (last == null || DateTime.now().difference(last).inMilliseconds > 1000) {
      return;
    }
    for (final frame in frames) {
      debugPrint(
        'STICKY_FRAME ${jsonEncode({'buildMs': frame.buildDuration.inMicroseconds / 1000, 'rasterMs': frame.rasterDuration.inMicroseconds / 1000})}',
      );
    }
  });
  debugPrint('STICKY_PERF_READY fixtures=$count');
}
