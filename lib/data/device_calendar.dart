import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';

enum CalendarAccess { notDetermined, granted, denied }

/// Read-only bridge to the phone's calendars (EventKit on iOS).
class DeviceCalendar {
  static const _channel = MethodChannel('dayflow/calendar');

  static CalendarAccess _parse(Object? v) => switch (v) {
        'granted' => CalendarAccess.granted,
        'denied' => CalendarAccess.denied,
        _ => CalendarAccess.notDetermined,
      };

  static Future<CalendarAccess> status() async {
    try {
      return _parse(await _channel.invokeMethod<String>('status'));
    } on MissingPluginException {
      return CalendarAccess.denied;
    } on PlatformException catch (e) {
      debugPrint('Calendar status failed: $e');
      return CalendarAccess.denied;
    }
  }

  static Future<CalendarAccess> request() async {
    try {
      return _parse(await _channel.invokeMethod<String>('request'));
    } on MissingPluginException {
      return CalendarAccess.denied;
    } on PlatformException catch (e) {
      debugPrint('Calendar request failed: $e');
      return CalendarAccess.denied;
    }
  }

  /// Opens DayFlow's page in the iOS Settings app.
  static Future<void> openSettings() async {
    try {
      await _channel.invokeMethod<void>('openSettings');
    } on MissingPluginException {
      // Not available on this platform.
    } on PlatformException catch (e) {
      debugPrint('Open settings failed: $e');
    }
  }

  /// Opens the iOS share sheet with [text] and an optional PNG image.
  static Future<void> share(String text, {Uint8List? image}) async {
    try {
      await _channel.invokeMethod<void>('share', {
        'text': text,
        if (image != null) 'image': image,
      });
    } on MissingPluginException {
      // Not available on this platform.
    } on PlatformException catch (e) {
      debugPrint('Share failed: $e');
    }
  }

  static Future<List<DeviceCal>> calendars() async {
    try {
      final raw = await _channel.invokeListMethod<Map>('calendars');
      return (raw ?? const [])
          .map((m) => DeviceCal(
                id: (m['id'] as String?) ?? '',
                title: (m['title'] as String?) ?? '',
                source: (m['source'] as String?) ?? '',
                color: (m['color'] as num?)?.toInt() ?? 0xFF0EA5A0,
              ))
          .toList()
        ..sort((a, b) {
          final s = a.source.toLowerCase().compareTo(b.source.toLowerCase());
          return s != 0
              ? s
              : a.title.toLowerCase().compareTo(b.title.toLowerCase());
        });
    } on MissingPluginException {
      return const [];
    } on PlatformException catch (e) {
      debugPrint('Calendar list failed: $e');
      return const [];
    }
  }

  static Future<List<CalEvent>> events(DateTime start, DateTime end) async {
    try {
      final raw = await _channel.invokeListMethod<Map>('events', {
        'start': start.millisecondsSinceEpoch,
        'end': end.millisecondsSinceEpoch,
      });
      final list = (raw ?? const [])
          .map((m) => CalEvent(
                title: (m['title'] as String?) ?? '',
                start: DateTime.fromMillisecondsSinceEpoch(
                    (m['start'] as num).toInt()),
                end: DateTime.fromMillisecondsSinceEpoch(
                    (m['end'] as num).toInt()),
                location: (m['location'] as String?) ?? '',
                allDay: (m['allDay'] as bool?) ?? false,
                calendarId: (m['calendarId'] as String?) ?? '',
              ))
          .toList()
        ..sort((a, b) => a.start.compareTo(b.start));
      return list;
    } on MissingPluginException {
      return const [];
    } on PlatformException catch (e) {
      debugPrint('Calendar events failed: $e');
      return const [];
    }
  }
}
