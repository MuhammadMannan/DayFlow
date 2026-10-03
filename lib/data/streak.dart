import '../models/models.dart';

class StreakInfo {
  const StreakInfo({
    required this.current,
    required this.best,
    required this.freezeAvailable,
    required this.doneToday,
  });

  final int current;
  final int best;

  /// True when this week's automatic freeze has not been used.
  final bool freezeAvailable;
  final bool doneToday;
}

DateTime _weekStart(DateTime d) =>
    dateOnly(d).subtract(Duration(days: d.weekday - 1));

/// Completions per calendar day.
Map<DateTime, int> completionsByDay(Iterable<Task> tasks) {
  final map = <DateTime, int>{};
  for (final t in tasks) {
    final c = t.completedAt;
    if (c == null) continue;
    final day = dateOnly(c);
    map[day] = (map[day] ?? 0) + 1;
  }
  return map;
}

/// A day counts when at least one task was completed. One missed day per
/// calendar week (Monday to Sunday) is covered automatically by a freeze.
/// Frozen days keep the streak alive but do not add to its length.
StreakInfo computeStreak(Iterable<Task> tasks, DateTime now) {
  final days = completionsByDay(tasks);
  final today = dateOnly(now);
  final doneToday = (days[today] ?? 0) > 0;
  if (days.isEmpty) {
    return const StreakInfo(
        current: 0, best: 0, freezeAvailable: true, doneToday: false);
  }

  final first = days.keys.reduce((a, b) => a.isBefore(b) ? a : b);
  final frozenWeeks = <DateTime>{};
  var run = 0;
  var best = 0;

  // Walk forward from the first completion to yesterday, then handle today
  // separately so an unfinished today does not break the streak.
  final yesterday = today.subtract(const Duration(days: 1));
  for (var d = first;
      !d.isAfter(yesterday);
      d = DateTime(d.year, d.month, d.day + 1)) {
    if ((days[d] ?? 0) > 0) {
      run++;
    } else if (run > 0 && frozenWeeks.add(_weekStart(d))) {
      // Freeze spent: streak survives, length unchanged.
    } else {
      run = 0;
    }
    if (run > best) best = run;
  }
  if (doneToday) run++;
  if (run > best) best = run;

  return StreakInfo(
    current: run,
    best: best,
    freezeAvailable: !frozenWeeks.contains(_weekStart(today)),
    doneToday: doneToday,
  );
}
