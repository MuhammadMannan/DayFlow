import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' hide Settings;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import '../models/models.dart';
import 'device_calendar.dart';
import 'streak.dart';

/// Holds the signed-in user's tasks, tags, settings and calendar events, and
/// is the only place that talks to Firestore.
class AppState extends ChangeNotifier {
  AppState(this.user) {
    _taskSub = _tasksRef.snapshots().listen((s) {
      tasks = s.docs.map(Task.fromDoc).toList();
      loaded = true;
      error = null;
      notifyListeners();
    }, onError: _onError);
    _tagSub = _tagsRef.orderBy('order').snapshots().listen((s) {
      tags = s.docs.map(Tag.fromDoc).toList();
      if (tags.isEmpty && !_seeded) _seedTags();
      notifyListeners();
    }, onError: _onError);
    _settingsSub = _userRef.snapshots().listen((s) {
      settings = Settings.fromMap(s.data());
      notifyListeners();
    }, onError: _onError);
    refreshCalendar();
  }

  final User user;
  List<Task> tasks = [];
  List<Tag> tags = [];
  Settings settings = const Settings();
  bool loaded = false;
  String? error;

  CalendarAccess calendarAccess = CalendarAccess.notDetermined;
  List<CalEvent> events = [];

  late final StreamSubscription _taskSub, _tagSub, _settingsSub;
  bool _seeded = false;

  DocumentReference<Map<String, dynamic>> get _userRef =>
      FirebaseFirestore.instance.collection('users').doc(user.uid);
  CollectionReference<Map<String, dynamic>> get _tasksRef =>
      _userRef.collection('tasks');
  CollectionReference<Map<String, dynamic>> get _tagsRef =>
      _userRef.collection('tags');

  void _onError(Object e) {
    error = e is FirebaseException && e.code == 'permission-denied'
        ? 'DayFlow could not read your data. Check the Firestore rules allow '
            'each user to read and write users/{uid}.'
        : 'Something went wrong loading your data.';
    loaded = true;
    debugPrint('AppState stream error: $e');
    notifyListeners();
  }

  @override
  void dispose() {
    _taskSub.cancel();
    _tagSub.cancel();
    _settingsSub.cancel();
    super.dispose();
  }

  // ---- Profile ----

  // The live user object carries profile updates made after sign-up.
  User get _me => FirebaseAuth.instance.currentUser ?? user;

  String get firstName {
    final name = _me.displayName?.trim();
    if (name != null && name.isNotEmpty) return name.split(' ').first;
    final local = (user.email ?? 'there').split('@').first;
    final word = local.split(RegExp(r'[._\-+0-9]')).firstWhere(
          (w) => w.isNotEmpty,
          orElse: () => 'there',
        );
    return word[0].toUpperCase() + word.substring(1);
  }

  String get displayName {
    final name = _me.displayName?.trim();
    return (name != null && name.isNotEmpty) ? name : firstName;
  }

  // ---- Derived task lists ----

  Tag? tagFor(Task t) {
    for (final tag in tags) {
      if (tag.id == t.tagId) return tag;
    }
    return null;
  }

  static int _byDue(Task a, Task b) {
    final ad = a.due, bd = b.due;
    if (ad == null && bd == null) return a.createdAt.compareTo(b.createdAt);
    if (ad == null) return 1;
    if (bd == null) return -1;
    // Untimed tasks sort after timed ones on the same day.
    final day = dateOnly(ad).compareTo(dateOnly(bd));
    if (day != 0) return day;
    if (a.hasTime != b.hasTime) return a.hasTime ? -1 : 1;
    final c = ad.compareTo(bd);
    return c != 0 ? c : a.createdAt.compareTo(b.createdAt);
  }

  List<Task> get overdue {
    final now = DateTime.now();
    return tasks.where((t) => t.isOverdue(now)).toList()..sort(_byDue);
  }

  /// Everything dated [day]: open tasks, plus tasks completed on that day.
  List<Task> tasksOn(DateTime day) {
    final d = dateOnly(day);
    return tasks.where((t) => t.isOn(d)).toList()..sort(_byDue);
  }

  /// Today's list: due today, or completed today (even if it was overdue).
  List<Task> get today {
    final d = dateOnly(DateTime.now());
    return tasks
        .where((t) =>
            t.isOn(d) ||
            (t.completedAt != null &&
                dateOnly(t.completedAt!) == d &&
                t.due != null &&
                dateOnly(t.due!).isBefore(d)))
        .toList()
      ..sort(_byDue);
  }

  List<Task> get upcoming {
    final d = dateOnly(DateTime.now());
    return tasks
        .where((t) => !t.isDone && t.due != null && dateOnly(t.due!).isAfter(d))
        .toList()
      ..sort(_byDue);
  }

  List<Task> get someday =>
      tasks.where((t) => !t.isDone && t.due == null).toList()..sort(_byDue);

  List<Task> get completed => tasks.where((t) => t.isDone).toList()
    ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));

  StreakInfo get streak => computeStreak(tasks, DateTime.now());

  // ---- Task writes ----

  Future<void> _guard(Future<void> Function() write) async {
    try {
      await write();
    } catch (e) {
      debugPrint('Write failed: $e');
      rethrow;
    }
  }

  Future<String> addTask({
    required String title,
    String notes = '',
    String? tagId,
    DateTime? due,
    bool hasTime = false,
    Repeat repeat = Repeat.none,
    bool remind = false,
  }) async {
    final ref = _tasksRef.doc();
    final task = Task(
      id: ref.id,
      title: title.trim(),
      notes: notes.trim(),
      tagId: tagId,
      due: due,
      hasTime: hasTime,
      repeat: repeat,
      remind: remind,
      createdAt: DateTime.now(),
    );
    await _guard(() => ref.set(task.toMap()));
    return ref.id;
  }

  Future<void> updateTask(Task task) =>
      _guard(() => _tasksRef.doc(task.id).set(task.toMap()));

  Future<void> deleteTask(Task task) =>
      _guard(() => _tasksRef.doc(task.id).delete());

  Future<void> restoreTask(Task task) => updateTask(task);

  static DateTime _nextOccurrence(DateTime due, Repeat r) {
    DateTime plus(int days) => DateTime(
        due.year, due.month, due.day + days, due.hour, due.minute);
    switch (r) {
      case Repeat.daily:
        return plus(1);
      case Repeat.weekdays:
        var next = plus(1);
        while (next.weekday > 5) {
          next = DateTime(next.year, next.month, next.day + 1, next.hour,
              next.minute);
        }
        return next;
      case Repeat.weekly:
        return plus(7);
      case Repeat.monthly:
        return DateTime(due.year, due.month + 1, due.day, due.hour, due.minute);
      case Repeat.none:
        return due;
    }
  }

  /// Completes or reopens a task. Completing a repeating task also creates
  /// its next occurrence. Returns the id of that new task, if any.
  Future<String?> setDone(Task task, bool done) async {
    await updateTask(
        task.copyWith(completedAt: () => done ? DateTime.now() : null));
    if (done && task.repeat != Repeat.none && task.due != null) {
      var next = _nextOccurrence(task.due!, task.repeat);
      final today = dateOnly(DateTime.now());
      while (dateOnly(next).isBefore(today)) {
        next = _nextOccurrence(next, task.repeat);
      }
      return addTask(
        title: task.title,
        notes: task.notes,
        tagId: task.tagId,
        due: next,
        hasTime: task.hasTime,
        repeat: task.repeat,
        remind: task.remind,
      );
    }
    return null;
  }

  Future<void> deleteTaskById(String id) =>
      _guard(() => _tasksRef.doc(id).delete());

  /// Moves a task to [day], keeping its time of day.
  Future<void> moveTo(Task task, DateTime? day) {
    if (day == null) {
      return updateTask(task.copyWith(due: () => null, hasTime: false));
    }
    final old = task.due;
    final due = task.hasTime && old != null
        ? DateTime(day.year, day.month, day.day, old.hour, old.minute)
        : dateOnly(day);
    return updateTask(task.copyWith(due: () => due));
  }

  Future<void> moveOverdueToToday() async {
    final batch = FirebaseFirestore.instance.batch();
    final today = DateTime.now();
    for (final t in overdue) {
      final old = t.due!;
      final due = t.hasTime
          ? DateTime(today.year, today.month, today.day, old.hour, old.minute)
          : dateOnly(today);
      batch.update(_tasksRef.doc(t.id), {'due': Timestamp.fromDate(due)});
    }
    await _guard(batch.commit);
  }

  // ---- Tags ----

  Future<void> _seedTags() async {
    _seeded = true;
    const names = ['Work', 'School', 'Personal', 'Health'];
    final batch = FirebaseFirestore.instance.batch();
    for (var i = 0; i < names.length; i++) {
      batch.set(_tagsRef.doc(names[i].toLowerCase()),
          Tag(id: '', name: names[i], color: i, order: i).toMap());
    }
    try {
      await batch.commit();
    } catch (e) {
      _onError(e);
    }
  }

  Future<void> addTag(String name, int color) => _guard(() => _tagsRef.add(
      Tag(id: '', name: name.trim(), color: color, order: tags.length)
          .toMap()));

  Future<void> updateTag(Tag tag, {String? name, int? color}) =>
      _guard(() => _tagsRef.doc(tag.id).update({
            if (name != null) 'name': name.trim(),
            if (color != null) 'color': color,
          }));

  Future<void> deleteTag(Tag tag) => _guard(() => _tagsRef.doc(tag.id).delete());

  // ---- Settings ----

  Future<void> updateSettings(Map<String, dynamic> patch) =>
      _guard(() => _userRef.set(patch, SetOptions(merge: true)));

  // ---- Calendar ----

  /// Loads events for roughly two months either side of today.
  Future<void> refreshCalendar() async {
    calendarAccess = await DeviceCalendar.status();
    if (calendarAccess == CalendarAccess.granted) {
      final now = DateTime.now();
      events = await DeviceCalendar.events(
        DateTime(now.year, now.month - 2, 1),
        DateTime(now.year, now.month + 3, 1),
      );
    } else {
      events = [];
    }
    notifyListeners();
  }

  Future<void> connectCalendar() async {
    calendarAccess = await DeviceCalendar.request();
    await refreshCalendar();
  }

  bool get showEvents =>
      settings.showCalendar && calendarAccess == CalendarAccess.granted;

  List<CalEvent> eventsOn(DateTime day) =>
      showEvents ? events.where((e) => e.isOn(day)).toList() : const [];
}

/// Makes [AppState] available to the widget tree and rebuilds on change.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
