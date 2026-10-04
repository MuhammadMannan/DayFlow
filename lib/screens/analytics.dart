import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/app_state.dart';
import '../data/streak.dart';
import '../models/models.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import 'shell.dart';

enum _Range { week, month, all }

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  _Range _range = _Range.month;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    final state = AppScope.of(context);
    final now = DateTime.now();
    final today = dateOnly(now);
    final streak = state.streak;
    final byDay = completionsByDay(state.tasks);

    // Range window, and the equal-length window before it for comparison.
    final DateTime? from = switch (_range) {
      _Range.week => today.subtract(Duration(days: today.weekday - 1)),
      _Range.month => DateTime(today.year, today.month, 1),
      _Range.all => null,
    };
    final DateTime? prevFrom = switch (_range) {
      _Range.week => from!.subtract(const Duration(days: 7)),
      _Range.month => DateTime(today.year, today.month - 1, 1),
      _Range.all => null,
    };
    final rangeLabel = switch (_range) {
      _Range.week => 'this week',
      _Range.month => 'this month',
      _Range.all => 'all time',
    };
    final prevLabel = switch (_range) {
      _Range.week => 'last week',
      _Range.month => DateFormat('MMMM').format(prevFrom!),
      _Range.all => '',
    };

    bool inRange(DateTime d) => from == null || !d.isBefore(from);
    final done = state.tasks
        .where((t) => t.completedAt != null && inRange(t.completedAt!))
        .toList();
    final prevDone = prevFrom == null
        ? 0
        : state.tasks
            .where((t) =>
                t.completedAt != null &&
                !t.completedAt!.isBefore(prevFrom) &&
                t.completedAt!.isBefore(from!))
            .length;

    // Completion rate: of tasks due in the range up to today, how many are done.
    final planned = state.tasks
        .where((t) =>
            t.due != null &&
            inRange(t.due!) &&
            !dateOnly(t.due!).isAfter(today))
        .toList();
    final rate = planned.isEmpty
        ? null
        : planned.where((t) => t.isDone).length / planned.length;

    // Busiest weekday and average per active day.
    final perWeekday = List<int>.filled(7, 0);
    final activeDays = <DateTime>{};
    for (final t in done) {
      perWeekday[t.completedAt!.weekday - 1]++;
      activeDays.add(dateOnly(t.completedAt!));
    }
    final maxWd = perWeekday.reduce(math.max);
    final busiest = maxWd == 0
        ? '–'
        : DateFormat('EEEE')
            .format(DateTime(2024, 1, 1 + perWeekday.indexOf(maxWd)));
    final avg = activeDays.isEmpty ? 0.0 : done.length / activeDays.length;

    // By tag.
    final tagCounts = <String?, int>{};
    for (final t in done) {
      final id = state.tags.any((g) => g.id == t.tagId) ? t.tagId : null;
      tagCounts[id] = (tagCounts[id] ?? 0) + 1;
    }

    final String delta;
    final bool up;
    if (_range == _Range.all || prevDone == 0) {
      delta = '';
      up = true;
    } else {
      final pct = ((done.length - prevDone) / prevDone * 100).round();
      up = pct >= 0;
      delta = '${pct.abs()}% vs $prevLabel';
    }

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            DfSpace.s5, DfSpace.s3, DfSpace.s5, kTabBarClearance),
        children: [
          Row(
            children: [
              Expanded(
                child:
                    Text('Analytics', style: DfText.h1.copyWith(color: c.text)),
              ),
              DfSegmented<_Range>(
                values: const [_Range.week, _Range.month, _Range.all],
                labels: const ['Week', 'Month', 'All'],
                selected: _range,
                onChanged: (v) => setState(() => _range = v),
              ),
            ],
          ),
          const SizedBox(height: DfSpace.s4),
          Row(
            children: [
              Expanded(
                child: _StreakCard(
                  icon: LucideIcons.flame,
                  iconColor: c.flame,
                  iconBg: c.flameSoft,
                  value: streak.current,
                  label: 'Current streak',
                ),
              ),
              const SizedBox(width: DfSpace.s3),
              Expanded(
                child: _StreakCard(
                  icon: LucideIcons.trophy,
                  iconColor: c.primary,
                  iconBg: c.primarySoft,
                  value: streak.best,
                  label: 'Best streak',
                ),
              ),
            ],
          ),
          const SizedBox(height: DfSpace.s3),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.primarySoft,
              borderRadius: BorderRadius.circular(DfRadius.field),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.snowflake, size: 18, color: c.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    streak.freezeAvailable
                        ? '1 streak freeze left this week. It covers a missed day automatically.'
                        : 'This week’s streak freeze has been used. It resets on Monday.',
                    style: DfText.small.copyWith(color: c.text),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DfSpace.s3),
          _Heatmap(byDay: byDay),
          const SizedBox(height: DfSpace.s3),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Completed $rangeLabel',
                  value: '${done.length}',
                  note: delta,
                  noteUp: up,
                ),
              ),
              const SizedBox(width: DfSpace.s3),
              Expanded(
                child: _StatCard(
                  label: 'Completion rate',
                  value: rate == null ? '–' : '${(rate * 100).round()}%',
                  note: 'done vs planned',
                ),
              ),
            ],
          ),
          const SizedBox(height: DfSpace.s3),
          Row(
            children: [
              Expanded(
                  child: _StatCard(label: 'Busiest day', value: busiest)),
              const SizedBox(width: DfSpace.s3),
              Expanded(
                child: _StatCard(
                    label: 'Average per active day',
                    value: avg == 0 ? '–' : avg.toStringAsFixed(1)),
              ),
            ],
          ),
          const SizedBox(height: DfSpace.s3),
          _ByTag(
            counts: tagCounts,
            tags: state.tags,
            total: done.length,
            rangeLabel: rangeLabel,
          ),
          const SizedBox(height: DfSpace.s3),
          _WeeklyBars(byDay: byDay),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    return DfCard(
      radius: DfRadius.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: DfSpace.s3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$value',
                  style: DfText.numericLarge.copyWith(color: c.text)),
              const SizedBox(width: 6),
              Text(value == 1 ? 'day' : 'days',
                  style: DfText.bodyStrong.copyWith(color: c.textSecondary)),
            ],
          ),
          const SizedBox(height: 2),
          Text(label, style: DfText.small.copyWith(color: c.textMuted)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.note = '',
    this.noteUp,
  });

  final String label;
  final String value;
  final String note;
  final bool? noteUp;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    return DfCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: DfText.caption.copyWith(color: c.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: DfText.h2.copyWith(color: c.text)),
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (noteUp != null) ...[
                  Icon(
                    noteUp! ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 14,
                    color: noteUp! ? c.success : c.danger,
                  ),
                  const SizedBox(width: 2),
                ],
                Expanded(
                  child: Text(note,
                      style: DfText.caption.copyWith(color: c.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Heatmap extends StatelessWidget {
  const _Heatmap({required this.byDay});
  final Map<DateTime, int> byDay;

  static const _weeks = 16;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    final today = dateOnly(DateTime.now());
    final thisMonday = today.subtract(Duration(days: today.weekday - 1));
    final start = thisMonday.subtract(const Duration(days: 7 * (_weeks - 1)));

    var total = 0;
    var peak = 0;
    for (var i = 0; i < _weeks * 7; i++) {
      final n = byDay[DateTime(start.year, start.month, start.day + i)] ?? 0;
      total += n;
      peak = math.max(peak, n);
    }
    int level(int n) {
      if (n == 0) return 0;
      if (peak <= 4) return n.clamp(1, 4);
      return (n / peak * 4).ceil().clamp(1, 4);
    }

    const dayLabels = ['M', '', 'W', '', 'F', '', 'S'];

    return DfCard(
      radius: DfRadius.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Last $_weeks weeks',
                    style: DfText.h3.copyWith(color: c.text)),
              ),
              Text('$total completed',
                  style: DfText.small.copyWith(color: c.textMuted)),
            ],
          ),
          const SizedBox(height: DfSpace.s3),
          LayoutBuilder(builder: (context, box) {
            const labelW = 18.0;
            const gap = 3.0;
            final cell = (box.maxWidth - labelW - gap * (_weeks - 1)) / _weeks;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month labels above the first week of each month.
                Padding(
                  padding: const EdgeInsets.only(left: labelW),
                  child: SizedBox(
                    height: 16,
                    child: Stack(
                      children: [
                        for (var w = 0; w < _weeks; w++)
                          if (w == 0 ||
                              start.add(Duration(days: w * 7)).month !=
                                  start.add(Duration(days: (w - 1) * 7)).month)
                            Positioned(
                              left: w * (cell + gap),
                              child: Text(
                                DateFormat('MMM').format(
                                    start.add(Duration(days: w * 7))),
                                style: DfText.overline.copyWith(
                                    color: c.textMuted,
                                    letterSpacing: 0,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 10),
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
                for (var d = 0; d < 7; d++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: gap),
                    child: Row(
                      children: [
                        SizedBox(
                          width: labelW,
                          child: Text(dayLabels[d],
                              style: DfText.overline.copyWith(
                                  color: c.textMuted,
                                  letterSpacing: 0,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 10)),
                        ),
                        for (var w = 0; w < _weeks; w++)
                          Builder(builder: (context) {
                            final day = DateTime(start.year, start.month,
                                start.day + w * 7 + d);
                            final future = day.isAfter(today);
                            final n = byDay[day] ?? 0;
                            return Container(
                              width: cell,
                              height: cell,
                              margin: EdgeInsets.only(
                                  right: w == _weeks - 1 ? 0 : gap),
                              decoration: BoxDecoration(
                                color: future
                                    ? Colors.transparent
                                    : c.heat[level(n)],
                                borderRadius: BorderRadius.circular(4),
                                border: day == today
                                    ? Border.all(color: c.text, width: 1.5)
                                    : future
                                        ? Border.all(color: c.border)
                                        : null,
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
              ],
            );
          }),
          const SizedBox(height: DfSpace.s2),
          Row(
            children: [
              Text('Less',
                  style: DfText.caption.copyWith(color: c.textMuted)),
              const SizedBox(width: 6),
              for (final color in c.heat)
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(right: 3),
                  decoration: BoxDecoration(
                      color: color, borderRadius: BorderRadius.circular(3)),
                ),
              const SizedBox(width: 3),
              Text('More',
                  style: DfText.caption.copyWith(color: c.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ByTag extends StatelessWidget {
  const _ByTag({
    required this.counts,
    required this.tags,
    required this.total,
    required this.rangeLabel,
  });

  final Map<String?, int> counts;
  final List<Tag> tags;
  final int total;
  final String rangeLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    // (name, colour, count), largest first; untagged last.
    final rows = <(String, Color, int)>[
      for (final t in tags)
        if ((counts[t.id] ?? 0) > 0) (t.name, c.tag(t.color), counts[t.id]!),
    ]..sort((a, b) => b.$3.compareTo(a.$3));
    if ((counts[null] ?? 0) > 0) {
      rows.add(('No tag', c.borderStrong, counts[null]!));
    }

    return DfCard(
      radius: DfRadius.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Completed by tag',
                    style: DfText.h3.copyWith(color: c.text)),
              ),
              Text(rangeLabel[0].toUpperCase() + rangeLabel.substring(1),
                  style: DfText.small.copyWith(color: c.textMuted)),
            ],
          ),
          const SizedBox(height: DfSpace.s3),
          if (rows.isEmpty)
            Text(
              'Complete a few tasks and you’ll see which kinds you finish most.',
              style: DfText.small.copyWith(color: c.textSecondary),
            )
          else ...[
            // 2px surface gaps separate the segments.
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Row(
                children: [
                  for (var i = 0; i < rows.length; i++)
                    Expanded(
                      flex: rows[i].$3,
                      child: Container(
                        height: 12,
                        margin: EdgeInsets.only(
                            right: i == rows.length - 1 ? 0 : 2),
                        decoration: BoxDecoration(
                          color: rows[i].$2,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: DfSpace.s2),
            for (final (name, color, count) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(name,
                          style: DfText.body.copyWith(color: c.text)),
                    ),
                    Text('$count',
                        style: DfText.bodyStrong.copyWith(color: c.text)),
                    SizedBox(
                      width: 48,
                      child: Text(
                        '${(count / total * 100).round()}%',
                        textAlign: TextAlign.right,
                        style: DfText.small.copyWith(color: c.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _WeeklyBars extends StatelessWidget {
  const _WeeklyBars({required this.byDay});
  final Map<DateTime, int> byDay;

  static const _weeks = 8;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    final today = dateOnly(DateTime.now());
    final thisMonday = today.subtract(Duration(days: today.weekday - 1));
    final starts = [
      for (var i = _weeks - 1; i >= 0; i--)
        DateTime(thisMonday.year, thisMonday.month, thisMonday.day - 7 * i),
    ];
    final totals = [
      for (final s in starts)
        [
          for (var d = 0; d < 7; d++)
            byDay[DateTime(s.year, s.month, s.day + d)] ?? 0
        ].reduce((a, b) => a + b),
    ];
    final peak = totals.reduce(math.max);
    final best = totals.indexOf(peak);

    return DfCard(
      radius: DfRadius.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tasks completed per week',
              style: DfText.h3.copyWith(color: c.text)),
          const SizedBox(height: DfSpace.s4),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < _weeks; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Label only the best week and the current week.
                          if (peak > 0 && (i == best || i == _weeks - 1))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text('${totals[i]}',
                                  style: DfText.caption
                                      .copyWith(color: c.textSecondary)),
                            ),
                          Container(
                            height: peak == 0
                                ? 4
                                : math.max(4, 118 * totals[i] / peak),
                            decoration: BoxDecoration(
                              color: totals[i] == 0
                                  ? c.surfaceMuted
                                  : i == _weeks - 1
                                      ? c.heat[2]
                                      : c.primary,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(color: c.border),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var i = 0; i < _weeks; i++)
                Expanded(
                  child: Text(
                    i == _weeks - 1
                        ? 'This wk'
                        : i.isEven
                            ? DateFormat('MMM d').format(starts[i])
                            : '',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    style: DfText.overline.copyWith(
                        color: c.textMuted,
                        letterSpacing: 0,
                        fontWeight: FontWeight.w500,
                        fontSize: 10),
                  ),
                ),
            ],
          ),
          const SizedBox(height: DfSpace.s3),
          Text(
            peak == 0
                ? 'Complete tasks to see your weekly trend here.'
                : 'This week is still in progress.',
            style: DfText.small.copyWith(color: c.textMuted),
          ),
        ],
      ),
    );
  }
}
