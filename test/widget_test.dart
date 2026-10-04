import 'package:dayflow/data/quick_parse.dart';
import 'package:dayflow/data/streak.dart';
import 'package:dayflow/models/models.dart';
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
}
