import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/note.dart';
import '../util/stable_hash.dart';

/// Wraps [FlutterLocalNotificationsPlugin] for note reminders.
///
/// [init] must be called once at startup before scheduling. All methods no-op
/// safely when the platform has no notification support (e.g. in tests or on
/// the web), so callers never need to guard.
///
/// The notification permission is requested lazily — the first time a reminder
/// is actually scheduled — rather than on first launch, so a new user isn't
/// greeted by a system prompt before they've done anything.
class ReminderService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool _permissionAsked = false;

  /// Words the system shows for the reminder channel (in Android's app
  /// settings) and for a note with nothing to show. Set from the app's
  /// language at start-up; English until then.
  static ({String channel, String description, String fallback}) labels = (
    channel: 'Reminders',
    description: 'Sticky Wall note reminders',
    fallback: 'Sticky Wall',
  );

  /// Guids of notes whose reminder the user tapped while the app was running.
  static final _opened = StreamController<String>.broadcast();
  static Stream<String> get opened => _opened.stream;

  /// The note whose reminder launched the app, if one did. Read once.
  static String? _launchedFor;
  static String? takeLaunchNote() {
    final guid = _launchedFor;
    _launchedFor = null;
    return guid;
  }

  Future<void> init() async {
    try {
      tz.initializeTimeZones();
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        settings: const InitializationSettings(android: android, iOS: darwin),
        onDidReceiveNotificationResponse: (response) {
          final guid = response.payload;
          if (guid != null && guid.isNotEmpty) _opened.add(guid);
        },
      );
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        _launchedFor = launch!.notificationResponse?.payload;
      }
      _ready = true;
    } catch (e) {
      // Unsupported platform / no plugin — reminders simply won't fire.
      debugPrint('ReminderService unavailable: $e');
    }
  }

  static NotificationDetails get _details => NotificationDetails(
    android: AndroidNotificationDetails(
      'reminders',
      labels.channel,
      channelDescription: labels.description,
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: const DarwinNotificationDetails(),
  );

  /// A stable per-note notification id derived from the guid. Must survive a
  /// restart so an edited reminder replaces (not duplicates) the old one.
  int _idFor(Note note) => stableHash(note.guid) & 0x7fffffff;

  /// What the notification says. A to-do or drawing note may have no title,
  /// so fall back to its items, then to the app name — never a blank banner.
  static String titleFor(Note note) {
    var text = note.content.trim();
    if (text.isEmpty) {
      text = note.checklist
          .map((i) => i.text.trim())
          .where((t) => t.isNotEmpty)
          .join(', ');
    }
    if (text.isEmpty) text = labels.fallback;
    return note.emoji.isEmpty ? text : '${note.emoji} $text';
  }

  Future<void> _ensurePermission() async {
    if (_permissionAsked) return;
    _permissionAsked = true;
    await requestPermission();
  }

  /// Asks for (or re-checks) permission to show notifications. False only
  /// when the system says no — so the editor can tell the user their
  /// reminder will stay silent; platforms without the question say yes.
  static Future<bool> requestPermission() async {
    final plugin = FlutterLocalNotificationsPlugin();
    try {
      final android = await plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      final ios = await plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return (android ?? true) && (ios ?? true);
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
      return true;
    }
  }

  /// Which fields of the date the OS should match to fire again: a daily
  /// reminder repeats at the same time, weekly on the same weekday, monthly
  /// on the same day of the month. Null for a one-off.
  static DateTimeComponents? _repeatOf(ReminderRepeat repeat) =>
      switch (repeat) {
        ReminderRepeat.none => null,
        ReminderRepeat.daily => DateTimeComponents.time,
        ReminderRepeat.weekly => DateTimeComponents.dayOfWeekAndTime,
        ReminderRepeat.monthly => DateTimeComponents.dayOfMonthAndTime,
      };

  /// (Re)schedules the notification for [note]: the next occurrence of a
  /// repeating reminder, or the one date of a single reminder if it is still
  /// ahead. Trashed notes never ring.
  Future<void> sync(Note note) async {
    await cancel(note);
    if (!_ready || note.isTrashed) return;
    final at = note.nextReminder();
    if (at == null || at.isBefore(DateTime.now())) return;

    await _ensurePermission();
    final when = tz.TZDateTime.from(at, tz.local);

    // Android 14+ denies SCHEDULE_EXACT_ALARM by default; rather than lose the
    // reminder entirely, fall back to an inexact alarm (fires within minutes).
    for (final mode in const [
      AndroidScheduleMode.exactAllowWhileIdle,
      AndroidScheduleMode.inexactAllowWhileIdle,
    ]) {
      try {
        await _plugin.zonedSchedule(
          id: _idFor(note),
          title: titleFor(note),
          body: null,
          scheduledDate: when,
          notificationDetails: _details,
          androidScheduleMode: mode,
          // Tapping the notification opens this note.
          payload: note.guid,
          matchDateTimeComponents: _repeatOf(note.repeat),
        );
        return;
      } catch (e) {
        debugPrint('Failed to schedule reminder ($mode): $e');
      }
    }
  }

  Future<void> cancel(Note note) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: _idFor(note));
    } catch (_) {}
  }
}
