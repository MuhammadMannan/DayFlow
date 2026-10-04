import 'package:cloud_firestore/cloud_firestore.dart';

enum Repeat { none, daily, weekdays, weekly, monthly }

extension RepeatLabel on Repeat {
  String get label => switch (this) {
        Repeat.none => 'Never',
        Repeat.daily => 'Daily',
        Repeat.weekdays => 'Weekdays',
        Repeat.weekly => 'Weekly',
        Repeat.monthly => 'Monthly',
      };
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

const _weekdayNames = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
];

/// "Weekly on Sunday", "Monthly on the 4th" and so on.
String repeatLabel(Repeat repeat, DateTime? date) {
  if (date == null) return repeat.label;
  switch (repeat) {
    case Repeat.weekly:
      return 'Weekly on ${_weekdayNames[date.weekday - 1]}';
    case Repeat.monthly:
      final d = date.day;
      final suffix = (d >= 11 && d <= 13)
          ? 'th'
          : switch (d % 10) { 1 => 'st', 2 => 'nd', 3 => 'rd', _ => 'th' };
      return 'Monthly on the $d$suffix';
    default:
      return repeat.label;
  }
}

/// Reminder lead times offered in the app, in minutes before the task.
const reminderLeads = [0, 15, 60, 1440];

String reminderLabel(bool on, int minutes) {
  if (!on) return 'Off';
  return switch (minutes) {
    0 => 'At time of task',
    15 => '15 min before',
    60 => '1 hour before',
    1440 => '1 day before',
    _ => '$minutes min before',
  };
}

class Task {
  Task({
    required this.id,
    required this.title,
    this.notes = '',
    this.tagId,
    this.due,
    this.hasTime = false,
    this.repeat = Repeat.none,
    this.remind = false,
    this.remindMinutes = 0,
    required this.createdAt,
    this.completedAt,
    this.droppedAt,
    this.sort,
  });

  final String id;
  final String title;
  final String notes;
  final String? tagId;

  /// Due date. Midnight when [hasTime] is false. Null means "someday".
  final DateTime? due;
  final bool hasTime;
  final Repeat repeat;
  final bool remind;

  /// How long before [due] the reminder fires. 0 means at the time.
  final int remindMinutes;
  final DateTime createdAt;
  final DateTime? completedAt;

  /// Set when the task was marked "won't do". Dropped tasks leave every
  /// list and are not counted in streaks or analytics.
  final DateTime? droppedAt;

  /// Position set by dragging in the Tasks list. Null until reordered.
  final int? sort;

  bool get isDone => completedAt != null;
  DateTime? get dueDay => due == null ? null : dateOnly(due!);

  bool isOverdue(DateTime now) =>
      !isDone && due != null && dateOnly(due!).isBefore(dateOnly(now));

  bool isOn(DateTime day) => due != null && dateOnly(due!) == dateOnly(day);

  Task copyWith({
    String? title,
    String? notes,
    String? Function()? tagId,
    DateTime? Function()? due,
    bool? hasTime,
    Repeat? repeat,
    bool? remind,
    int? remindMinutes,
    DateTime? Function()? completedAt,
    DateTime? Function()? droppedAt,
    int? sort,
  }) =>
      Task(
        id: id,
        title: title ?? this.title,
        notes: notes ?? this.notes,
        tagId: tagId != null ? tagId() : this.tagId,
        due: due != null ? due() : this.due,
        hasTime: hasTime ?? this.hasTime,
        repeat: repeat ?? this.repeat,
        remind: remind ?? this.remind,
        remindMinutes: remindMinutes ?? this.remindMinutes,
        createdAt: createdAt,
        completedAt: completedAt != null ? completedAt() : this.completedAt,
        droppedAt: droppedAt != null ? droppedAt() : this.droppedAt,
        sort: sort ?? this.sort,
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'notes': notes,
        'tagId': tagId,
        'due': due == null ? null : Timestamp.fromDate(due!),
        'hasTime': hasTime,
        'repeat': repeat.name,
        'remind': remind,
        'remindMinutes': remindMinutes,
        'createdAt': Timestamp.fromDate(createdAt),
        'completedAt':
            completedAt == null ? null : Timestamp.fromDate(completedAt!),
        'droppedAt': droppedAt == null ? null : Timestamp.fromDate(droppedAt!),
        'sort': sort,
      };

  factory Task.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    DateTime? ts(Object? v) => v is Timestamp ? v.toDate() : null;
    return Task(
      id: doc.id,
      title: (d['title'] as String?) ?? '',
      notes: (d['notes'] as String?) ?? '',
      tagId: d['tagId'] as String?,
      due: ts(d['due']),
      hasTime: (d['hasTime'] as bool?) ?? false,
      repeat: Repeat.values.firstWhere(
        (r) => r.name == d['repeat'],
        orElse: () => Repeat.none,
      ),
      remind: (d['remind'] as bool?) ?? false,
      remindMinutes: (d['remindMinutes'] as int?) ?? 0,
      createdAt: ts(d['createdAt']) ?? DateTime.now(),
      completedAt: ts(d['completedAt']),
      droppedAt: ts(d['droppedAt']),
      sort: d['sort'] as int?,
    );
  }
}

class Tag {
  const Tag({
    required this.id,
    required this.name,
    required this.color,
    required this.order,
    this.icon = 'tag',
  });

  final String id;
  final String name;

  /// Index into the tag palette in the theme.
  final int color;
  final int order;

  /// Key into the tag icon set.
  final String icon;

  Map<String, dynamic> toMap() =>
      {'name': name, 'color': color, 'order': order, 'icon': icon};

  factory Tag.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Tag(
      id: doc.id,
      name: (d['name'] as String?) ?? '',
      color: (d['color'] as int?) ?? 0,
      order: (d['order'] as int?) ?? 0,
      icon: (d['icon'] as String?) ?? 'tag',
    );
  }
}

class Settings {
  const Settings({
    this.dailyGoal = 0,
    this.theme = 'system',
    this.remindersOn = true,
    this.nudgeOn = true,
    this.showCalendar = true,
    this.nudgeHour = 20,
    this.onboarded = false,
    this.hiddenCalendars = const [],
  });

  /// 0 means no goal; otherwise tasks per day.
  final int dailyGoal;
  final String theme;
  final bool remindersOn;
  final bool nudgeOn;
  final bool showCalendar;

  /// Hour of the day (0-23) for the streak-at-risk nudge.
  final int nudgeHour;

  /// False until the user has finished or skipped onboarding.
  final bool onboarded;

  /// Ids of device calendars the user has switched off. Stored as the
  /// hidden ones so calendars added later show up by default.
  final List<String> hiddenCalendars;

  Map<String, dynamic> toMap() => {
        'dailyGoal': dailyGoal,
        'theme': theme,
        'remindersOn': remindersOn,
        'nudgeOn': nudgeOn,
        'showCalendar': showCalendar,
        'nudgeHour': nudgeHour,
        'onboarded': onboarded,
        'hiddenCalendars': hiddenCalendars,
      };

  factory Settings.fromMap(Map<String, dynamic>? d) => Settings(
        dailyGoal: (d?['dailyGoal'] as int?) ?? 0,
        theme: (d?['theme'] as String?) ?? 'system',
        remindersOn: (d?['remindersOn'] as bool?) ?? true,
        nudgeOn: (d?['nudgeOn'] as bool?) ?? true,
        showCalendar: (d?['showCalendar'] as bool?) ?? true,
        nudgeHour: (d?['nudgeHour'] as int?) ?? 20,
        onboarded: (d?['onboarded'] as bool?) ?? false,
        hiddenCalendars: [
          for (final id in (d?['hiddenCalendars'] as List?) ?? const [])
            if (id is String) id,
        ],
      );
}

/// A read-only event from the phone's calendars.
class CalEvent {
  const CalEvent({
    required this.title,
    required this.start,
    required this.end,
    this.location = '',
    this.allDay = false,
    this.calendarId = '',
  });

  final String title;
  final DateTime start;
  final DateTime end;
  final String location;
  final bool allDay;
  final String calendarId;

  bool isOn(DateTime day) {
    final d = dateOnly(day);
    final next = d.add(const Duration(days: 1));
    return start.isBefore(next) && end.isAfter(d);
  }
}

/// One of the phone's calendars (iCloud, Google, Outlook and so on).
class DeviceCal {
  const DeviceCal({
    required this.id,
    required this.title,
    required this.source,
    required this.color,
  });

  final String id;
  final String title;

  /// The account it belongs to, e.g. "iCloud".
  final String source;

  /// ARGB colour the calendar uses in the system Calendar app.
  final int color;
}
