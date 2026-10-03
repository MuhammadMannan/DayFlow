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
    required this.createdAt,
    this.completedAt,
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
  final DateTime createdAt;
  final DateTime? completedAt;

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
    DateTime? Function()? completedAt,
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
        createdAt: createdAt,
        completedAt: completedAt != null ? completedAt() : this.completedAt,
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'notes': notes,
        'tagId': tagId,
        'due': due == null ? null : Timestamp.fromDate(due!),
        'hasTime': hasTime,
        'repeat': repeat.name,
        'remind': remind,
        'createdAt': Timestamp.fromDate(createdAt),
        'completedAt':
            completedAt == null ? null : Timestamp.fromDate(completedAt!),
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
      createdAt: ts(d['createdAt']) ?? DateTime.now(),
      completedAt: ts(d['completedAt']),
    );
  }
}

class Tag {
  const Tag({
    required this.id,
    required this.name,
    required this.color,
    required this.order,
  });

  final String id;
  final String name;

  /// Index into the tag palette in the theme.
  final int color;
  final int order;

  Map<String, dynamic> toMap() => {'name': name, 'color': color, 'order': order};

  factory Tag.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Tag(
      id: doc.id,
      name: (d['name'] as String?) ?? '',
      color: (d['color'] as int?) ?? 0,
      order: (d['order'] as int?) ?? 0,
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
  });

  /// 0 means no goal; otherwise tasks per day.
  final int dailyGoal;
  final String theme;
  final bool remindersOn;
  final bool nudgeOn;
  final bool showCalendar;

  Map<String, dynamic> toMap() => {
        'dailyGoal': dailyGoal,
        'theme': theme,
        'remindersOn': remindersOn,
        'nudgeOn': nudgeOn,
        'showCalendar': showCalendar,
      };

  factory Settings.fromMap(Map<String, dynamic>? d) => Settings(
        dailyGoal: (d?['dailyGoal'] as int?) ?? 0,
        theme: (d?['theme'] as String?) ?? 'system',
        remindersOn: (d?['remindersOn'] as bool?) ?? true,
        nudgeOn: (d?['nudgeOn'] as bool?) ?? true,
        showCalendar: (d?['showCalendar'] as bool?) ?? true,
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
  });

  final String title;
  final DateTime start;
  final DateTime end;
  final String location;
  final bool allDay;

  bool isOn(DateTime day) {
    final d = dateOnly(day);
    final next = d.add(const Duration(days: 1));
    return start.isBefore(next) && end.isAfter(d);
  }
}
