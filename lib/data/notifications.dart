import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/models.dart';
import 'streak.dart';

/// A notification that should be pending on the device.
@immutable
class PlannedNotification {
  const PlannedNotification({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
  });

  final int id;
  final DateTime at;
  final String title;
  final String body;
}

String _clock(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
}

/// Works out which notifications should exist for the current data. Kept
/// free of plugin calls so it can be unit tested.
List<PlannedNotification> planNotifications({
  required List<Task> tasks,
  required List<Tag> tags,
  required Settings settings,
  required DateTime now,
}) {
  final planned = <PlannedNotification>[];

  if (settings.remindersOn) {
    final due = tasks
        .where((t) => !t.isDone && t.remind && t.hasTime && t.due != null)
        .map((t) => (t, t.due!.subtract(Duration(minutes: t.remindMinutes))))
        .where((e) => e.$2.isAfter(now))
        .toList()
      ..sort((a, b) => a.$2.compareTo(b.$2));
    // iOS keeps at most 64 pending notifications; leave room for the nudges.
    for (final (task, at) in due.take(58)) {
      String? tagName;
      for (final tag in tags) {
        if (tag.id == task.tagId) tagName = tag.name;
      }
      final sameDay = dateOnly(task.due!) == dateOnly(at);
      final when = task.remindMinutes == 0
          ? 'Due now'
          : sameDay
              ? 'At ${_clock(task.due!)}'
              : 'Tomorrow at ${_clock(task.due!)}';
      planned.add(PlannedNotification(
        // Stable per task so a re-sync replaces rather than duplicates.
        id: task.id.hashCode & 0x3fffffff,
        at: at,
        title: task.title,
        body: tagName == null ? when : '$when · $tagName',
      ));
    }
  }

  if (settings.nudgeOn) {
    final streak = computeStreak(tasks, now);
    final today = dateOnly(now);
    // Today only if nothing is done yet; the following days always, since a
    // later sync cancels them once a task is completed on that day.
    for (var i = 0; i < 3; i++) {
      final day = DateTime(today.year, today.month, today.day + i);
      final at = DateTime(day.year, day.month, day.day, settings.nudgeHour);
      if (!at.isAfter(now)) continue;
      if (i == 0 && streak.doneToday) continue;
      final days = streak.current;
      planned.add(PlannedNotification(
        id: 0x40000000 + i,
        at: at,
        title: days > 0
            ? 'Keep your $days-day streak'
            : 'Start a streak today',
        body: 'You haven’t finished a task today. One quick win keeps it going.',
      ));
    }
  }

  return planned;
}

/// Schedules local notifications for task reminders and the streak nudge.
class Notifications {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static String _lastSignature = '';

  static Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      await _plugin.initialize(
        settings: const InitializationSettings(
          // Permission is asked for in onboarding or Profile, not at launch.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('Notifications init failed: $e');
    }
  }

  static IOSFlutterLocalNotificationsPlugin? get _ios =>
      _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

  /// Whether the user has allowed notifications for the app.
  static Future<bool> allowed() async {
    if (!_ready) return false;
    try {
      return (await _ios?.checkPermissions())?.isEnabled ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Shows the system permission prompt (once; iOS remembers the answer).
  static Future<bool> requestPermission() async {
    await init();
    try {
      return await _ios?.requestPermissions(alert: true, sound: true) ?? false;
    } catch (e) {
      debugPrint('Notification permission failed: $e');
      return false;
    }
  }

  /// Replaces all pending notifications with what the data calls for.
  static Future<void> sync({
    required List<Task> tasks,
    required List<Tag> tags,
    required Settings settings,
  }) async {
    if (!_ready) return;
    final planned = planNotifications(
      tasks: tasks,
      tags: tags,
      settings: settings,
      now: DateTime.now(),
    );
    final signature =
        planned.map((p) => '${p.id}@${p.at.toIso8601String()}|${p.title}|${p.body}').join(';');
    if (signature == _lastSignature) return;
    _lastSignature = signature;

    try {
      await _plugin.cancelAll();
      for (final p in planned) {
        await _plugin.zonedSchedule(
          id: p.id,
          // An absolute instant, so the device's zone does not need looking up.
          scheduledDate: tz.TZDateTime.from(p.at, tz.UTC),
          title: p.title,
          body: p.body,
          notificationDetails: const NotificationDetails(
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBanner: true,
              presentList: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (e) {
      _lastSignature = '';
      debugPrint('Notification sync failed: $e');
    }
  }

  static Future<int> pendingCount() async {
    if (!_ready) return 0;
    try {
      return (await _plugin.pendingNotificationRequests()).length;
    } catch (_) {
      return 0;
    }
  }

  /// Clears everything, e.g. on sign-out.
  static Future<void> clear() async {
    _lastSignature = '';
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
