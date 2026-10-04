import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';

/// Debug-only helpers that fill an account with the same content the Figma
/// screens show, so the app can be compared against the design.
class SampleData {
  static CollectionReference<Map<String, dynamic>> _tasks(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('tasks');

  /// Deletes every task for [uid].
  static Future<void> clear(String uid) async {
    final docs = (await _tasks(uid).get()).docs;
    for (var i = 0; i < docs.length; i += 400) {
      final batch = FirebaseFirestore.instance.batch();
      for (final d in docs.skip(i).take(400)) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
  }

  /// Replaces all tasks with a sample day, upcoming items and 16 weeks of
  /// completed history ending in a 12-day streak.
  static Future<void> load(String uid) async {
    await clear(uid);
    final now = DateTime.now();
    final today = dateOnly(now);
    DateTime at(int dayOffset, [int hour = 0, int minute = 0]) =>
        DateTime(today.year, today.month, today.day + dayOffset, hour, minute);

    final tasks = <Task>[];
    var n = 0;
    void add(
      String title, {
      String? tag,
      DateTime? due,
      bool hasTime = false,
      bool remind = false,
      int remindMinutes = 0,
      Repeat repeat = Repeat.none,
      String notes = '',
      DateTime? done,
    }) {
      tasks.add(Task(
        id: 'sample-${n++}',
        title: title,
        notes: notes,
        tagId: tag,
        due: due,
        hasTime: hasTime,
        remind: remind,
        remindMinutes: remindMinutes,
        repeat: repeat,
        createdAt: (done ?? due ?? now).subtract(const Duration(days: 1)),
        completedAt: done,
      ));
    }

    // Today, as on the Home design.
    add('Morning run',
        tag: 'health', due: at(0, 7, 30), hasTime: true, done: at(0, 7, 55));
    add('Read chapter 4 of Sapiens',
        tag: 'personal', due: at(0), done: at(0, 9, 10));
    add('Finish physics problem set',
        tag: 'school',
        due: at(0, 16),
        hasTime: true,
        remind: true,
        done: at(0, 10, 40));
    add('Prep slides for Monday',
        tag: 'work', due: at(0, 19, 30), hasTime: true, remind: true);
    add('Call mom',
        tag: 'personal', due: at(0, 20, 30), hasTime: true, remind: true);

    // Overdue.
    add('Submit chemistry lab report',
        tag: 'school',
        due: at(-1, 17),
        hasTime: true,
        remind: true,
        remindMinutes: 60,
        notes:
            'Include the titration graphs and the error analysis section. Upload as PDF to the course portal.');

    // Upcoming.
    add('Grocery run', tag: 'personal', due: at(1, 10), hasTime: true);
    add('Lab report feedback session',
        tag: 'school', due: at(2, 9), hasTime: true, remind: true, remindMinutes: 15);
    add('Pay rent', tag: 'personal', due: at(2), repeat: Repeat.monthly);
    add('Gym: leg day',
        tag: 'health', due: at(2, 18), hasTime: true, remind: true);
    add('Dentist appointment',
        tag: 'health', due: at(3, 14, 30), hasTime: true, remind: true);

    // Someday.
    add('Learn to make sourdough', tag: 'personal');
    add('Update portfolio site', tag: 'work');

    // History: 16 weeks, fixed seed so every load looks the same. The last
    // 11 days before today are all active, giving a 12-day streak with today.
    final r = Random(7);
    const tags = ['work', 'work', 'work', 'school', 'school', 'school', 'personal', 'personal', 'health'];
    const titles = [
      'Review notes', 'Reply to emails', 'Draft essay outline', 'Team sync prep',
      'Problem set', 'Laundry', 'Stretch', 'Plan the week', 'Read 20 pages',
    ];
    for (var d = 1; d <= 111; d++) {
      final inStreak = d <= 11;
      // A longer unbroken run about two months back sets the best streak.
      final inBestRun = d >= 40 && d <= 70;
      final active = inStreak || inBestRun || r.nextDouble() < 0.72;
      if (!active || d == 12) continue;
      final count = 1 + r.nextInt(4);
      for (var i = 0; i < count; i++) {
        final k = r.nextInt(titles.length);
        add(titles[k],
            tag: tags[r.nextInt(tags.length)],
            due: at(-d),
            done: at(-d, 9 + r.nextInt(10), r.nextInt(60)));
      }
    }

    for (var i = 0; i < tasks.length; i += 400) {
      final batch = FirebaseFirestore.instance.batch();
      for (final t in tasks.skip(i).take(400)) {
        batch.set(_tasks(uid).doc(t.id), t.toMap());
      }
      await batch.commit();
    }
  }
}
