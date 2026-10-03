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
