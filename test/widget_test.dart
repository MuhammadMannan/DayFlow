import 'package:dayflow/data/notifications.dart';
import 'package:dayflow/data/quick_parse.dart';
import 'package:dayflow/data/streak.dart';
import 'package:dayflow/models/models.dart';
import 'package:dayflow/screens/milestone.dart';
import 'package:flutter_test/flutter_test.dart';

Task _done(DateTime day) => Task(
      id: day.toIso8601String(),
      title: 't',
      createdAt: day,
      completedAt: day.add(const Duration(hours: 10)),
    );

void main() {
  // Saturday 3 October 2026.
  final now = DateTime(2026, 10, 3, 18);
  DateTime ago(int days) => DateTime(2026, 10, 3 - days);

  group('computeStreak', () {
    test('no completions', () {
      final s = computeStreak([], now);
      expect(s.current, 0);
      expect(s.best, 0);
      expect(s.freezeAvailable, isTrue);
    });

    test('counts consecutive days including today', () {
      final s = computeStreak([_done(ago(0)), _done(ago(1)), _done(ago(2))], now);
      expect(s.current, 3);
      expect(s.doneToday, isTrue);
    });

    test('an unfinished today does not break the streak', () {
      final s = computeStreak([_done(ago(1)), _done(ago(2))], now);
      expect(s.current, 2);
      expect(s.doneToday, isFalse);
    });

    test('one missed day in a week is frozen, not counted', () {
      // Done Mon, Tue, missed Wed, done Thu, Fri, Sat.
      final s = computeStreak(
          [5, 4, 2, 1, 0].map((d) => _done(ago(d))).toList(), now);
      expect(s.current, 5);
      expect(s.freezeAvailable, isFalse);
    });

    test('a second missed day in the same week resets', () {
      // Done Mon, missed Tue and Wed, done Thu, Fri, Sat.
      final s = computeStreak(
          [5, 2, 1, 0].map((d) => _done(ago(d))).toList(), now);
      expect(s.current, 3);
    });

    test('best streak survives a later reset', () {
      final tasks = [
        for (var d = 30; d >= 21; d--) _done(ago(d)),
        _done(ago(0)),
      ];
      final s = computeStreak(tasks, now);
      expect(s.best, 10);
      expect(s.current, 1);
    });
  });

  group('parseQuick', () {
    test('date and time', () {
      final p = parseQuick('Call mom tomorrow 6pm', now: now);
      expect(p.title, 'Call mom');
      expect(p.due, DateTime(2026, 10, 4, 18));
      expect(p.hasTime, isTrue);
    });

    test('weekday rolls forward', () {
      final p = parseQuick('Gym on Monday', now: now);
      expect(p.title, 'Gym');
      expect(p.date, DateTime(2026, 10, 5));
      expect(p.hasTime, isFalse);
    });

    test('time with minutes', () {
      final p = parseQuick('Standup at 9:30am', now: now);
      expect(p.title, 'Standup');
      expect(p.due, DateTime(2026, 10, 3, 9, 30));
    });

    test('drops a dangling preposition', () {
      final p = parseQuick('Prep slides for Monday 7:30pm', now: now);
      expect(p.title, 'Prep slides');
      expect(p.due, DateTime(2026, 10, 5, 19, 30));
    });

    test('plain text is left alone', () {
      final p = parseQuick('Buy 2 notebooks', now: now);
      expect(p.title, 'Buy 2 notebooks');
      expect(p.due, isNull);
    });

    test('12am and 12pm', () {
      expect(parseQuick('x 12pm', now: now).hour, 12);
      expect(parseQuick('x 12am', now: now).hour, 0);
    });
  });

  group('planNotifications', () {
    Task timed(String id, DateTime due,
            {bool remind = true, int lead = 0, DateTime? done}) =>
        Task(
          id: id,
          title: id,
          due: due,
          hasTime: true,
          remind: remind,
          remindMinutes: lead,
          createdAt: now,
          completedAt: done,
        );

    test('schedules future reminders with lead time', () {
      final plan = planNotifications(
        tasks: [timed('a', DateTime(2026, 10, 3, 20), lead: 60)],
        tags: const [],
        settings: const Settings(nudgeOn: false),
        now: now,
      );
      expect(plan, hasLength(1));
      expect(plan.single.at, DateTime(2026, 10, 3, 19));
      expect(plan.single.body, 'At 8:00 PM');
    });

    test('skips past, completed and reminder-off tasks', () {
      final plan = planNotifications(
        tasks: [
          timed('past', DateTime(2026, 10, 3, 9)),
          timed('done', DateTime(2026, 10, 3, 21), done: now),
          timed('off', DateTime(2026, 10, 3, 21), remind: false),
        ],
        tags: const [],
        settings: const Settings(nudgeOn: false),
        now: now,
      );
      expect(plan, isEmpty);
    });

    test('respects the reminders switch', () {
      final plan = planNotifications(
        tasks: [timed('a', DateTime(2026, 10, 3, 21))],
        tags: const [],
        settings: const Settings(remindersOn: false, nudgeOn: false),
        now: now,
      );
      expect(plan, isEmpty);
    });

    test('nudges today only when nothing is done yet', () {
      final open = planNotifications(
        tasks: const [],
        tags: const [],
        settings: const Settings(remindersOn: false),
        now: now,
      );
      expect(open.first.at, DateTime(2026, 10, 3, 20));

      final done = planNotifications(
        tasks: [_done(ago(0))],
        tags: const [],
        settings: const Settings(remindersOn: false),
        now: now,
      );
      expect(done.first.at, DateTime(2026, 10, 4, 20));
      expect(done.first.title, 'Keep your 1-day streak');
    });
  });

  group('milestoneReached', () {
    test('fires when a milestone is crossed', () {
      expect(milestoneReached(6, 7), 7);
      expect(milestoneReached(29, 30), 30);
    });

    test('does not fire between or on repeat', () {
      expect(milestoneReached(7, 8), isNull);
      expect(milestoneReached(7, 7), isNull);
      expect(milestoneReached(0, 1), isNull);
    });
  });
}
