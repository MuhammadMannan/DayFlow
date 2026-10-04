import '../models/models.dart';

class QuickParse {
  const QuickParse({
    required this.title,
    this.date,
    this.hour,
    this.minute,
    this.matched = '',
    this.ranges = const [],
  });

  /// The text with the date and time phrases removed.
  final String title;
  final DateTime? date;
  final int? hour;
  final int? minute;

  /// The phrase that was recognised, for the "We picked up ..." hint.
  final String matched;

  /// Where the recognised phrases sit in the text that was typed, as
  /// (start, end) pairs, so the input can highlight them.
  final List<(int, int)> ranges;

  bool get hasTime => hour != null;

  DateTime? get due {
    final d = date;
    if (d == null) return null;
    return DateTime(d.year, d.month, d.day, hour ?? 0, minute ?? 0);
  }
}

const _weekdays = {
  'monday': 1, 'mon': 1,
  'tuesday': 2, 'tue': 2, 'tues': 2,
  'wednesday': 3, 'wed': 3,
  'thursday': 4, 'thu': 4, 'thurs': 4,
  'friday': 5, 'fri': 5,
  'saturday': 6, 'sat': 6,
  'sunday': 7, 'sun': 7,
};

final _dateRe = RegExp(
  r'\b(today|tonight|tomorrow|tmrw|next week|(?:on |next )?(?:monday|tuesday|wednesday|thursday|friday|saturday|sunday|mon|tues?|wed|thurs?|fri|sat|sun))\b',
  caseSensitive: false,
);
final _timeRe = RegExp(
  r'\b(?:at )?(\d{1,2})(?::(\d{2}))?\s?(am|pm)\b|\b(?:at )(\d{1,2}):(\d{2})\b|\b(noon|midnight)\b',
  caseSensitive: false,
);

/// Pulls a simple date and time out of text such as "Call mom tomorrow 6pm".
QuickParse parseQuick(String input, {DateTime? now}) {
  final today = dateOnly(now ?? DateTime.now());
  var text = input;
  DateTime? date;
  int? hour, minute;
  final matched = <String>[];
  final ranges = <(int, int)>[];
  // Start and length of the date phrase once it is cut out of [text].
  var cutAt = -1, cutLength = 0;

  final dm = _dateRe.firstMatch(text);
  if (dm != null) {
    final raw = dm.group(0)!;
    final word = raw.toLowerCase().replaceFirst(RegExp(r'^(on|next) '), '');
    if (word == 'today' || word == 'tonight') {
      date = today;
    } else if (word == 'tomorrow' || word == 'tmrw') {
      date = today.add(const Duration(days: 1));
    } else if (raw.toLowerCase() == 'next week') {
      date = today.add(const Duration(days: 7));
    } else if (_weekdays.containsKey(word)) {
      var diff = (_weekdays[word]! - today.weekday) % 7;
      if (diff == 0) diff = 7;
      date = today.add(Duration(days: diff));
    }
    if (date != null) {
      matched.add(raw);
      ranges.add((dm.start, dm.end));
      cutAt = dm.start;
      cutLength = dm.end - dm.start;
      text = text.replaceRange(dm.start, dm.end, '');
      if (word == 'tonight') hour = 20;
    }
  }

  final tm = _timeRe.firstMatch(text);
  if (tm != null) {
    if (tm.group(6) != null) {
      hour = tm.group(6)!.toLowerCase() == 'noon' ? 12 : 0;
      minute = 0;
    } else if (tm.group(1) != null) {
      var h = int.parse(tm.group(1)!);
      final pm = tm.group(3)!.toLowerCase() == 'pm';
      if (h == 12) h = 0;
      hour = h + (pm ? 12 : 0);
      minute = int.tryParse(tm.group(2) ?? '') ?? 0;
    } else {
      hour = int.parse(tm.group(4)!);
      minute = int.parse(tm.group(5)!);
    }
    if (hour < 24 && minute < 60) {
      matched.add(tm.group(0)!.trim());
      // Map back to positions in the original input.
      final shift = cutAt >= 0 && tm.start >= cutAt ? cutLength : 0;
      ranges.add((tm.start + shift, tm.end + shift));
      text = text.replaceRange(tm.start, tm.end, '');
    } else {
      hour = null;
      minute = null;
    }
  }

  var title = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (matched.isNotEmpty) {
    // "Prep slides for Monday" leaves a dangling "for" once the day is removed.
    title = title
        .replaceFirst(
            RegExp(r'\s+(for|on|at|by|due)$', caseSensitive: false), '')
        .trim();
  }

  return QuickParse(
    title: title,
    // A time on its own means today.
    date: date ?? (hour != null ? today : null),
    hour: hour,
    minute: minute,
    matched: matched.join(' '),
    ranges: ranges,
  );
}
