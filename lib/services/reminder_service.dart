import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/note.dart';

/// Wraps [FlutterLocalNotificationsPlugin] for note reminders.
///
/// [init] must be called once at startup before scheduling. All methods no-op
/// safely when the platform has no notification support (e.g. in tests or on
/// the web), so callers never need to guard.
class ReminderService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    try {
      tz.initializeTimeZones();
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings();
      await _plugin.initialize(
        settings: const InitializationSettings(android: android, iOS: darwin),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _ready = true;
    } catch (e) {
      // Unsupported platform / no plugin — reminders simply won't fire.
      debugPrint('ReminderService unavailable: $e');
    }
  }

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'reminders',
      'Reminders',
      channelDescription: 'Sticky Wall note reminders',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// A stable per-note notification id derived from the guid.
  int _idFor(Note note) => note.guid.hashCode & 0x7fffffff;

  Future<void> sync(Note note) async {
    await cancel(note);
    final at = note.reminderAt;
    if (!_ready || at == null || at.isBefore(DateTime.now())) return;

    try {
      await _plugin.zonedSchedule(
        id: _idFor(note),
        title:
            note.emoji.isEmpty ? note.content : '${note.emoji} ${note.content}',
        body: null,
        scheduledDate: tz.TZDateTime.from(at, tz.local),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Failed to schedule reminder: $e');
    }
  }

  Future<void> cancel(Note note) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: _idFor(note));
    } catch (_) {}
  }
}
