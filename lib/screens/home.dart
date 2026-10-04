import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/app_state.dart';
import '../data/device_calendar.dart';
import '../data/streak.dart';
import '../models/models.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import 'add_task.dart';
import 'profile.dart';
import 'shell.dart';
import 'task_detail.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting(int hour) {
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    final state = AppScope.of(context);
    final now = DateTime.now();
    final today = dateOnly(now);
    final streak = state.streak;
    final todayTasks = state.today;
    final overdue = state.overdue;
    final events = state.eventsOn(today);
    final isEmpty = state.loaded && state.tasks.isEmpty;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            DfSpace.s5, DfSpace.s3, DfSpace.s5, kTabBarClearance),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Overline(DateFormat('EEEE, d MMMM').format(now)),
                    const SizedBox(height: 2),
                    Text('${_greeting(now.hour)}, ${state.firstName}',
                        style: DfText.h2.copyWith(color: c.text),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              StreakChip(days: streak.current),
              const SizedBox(width: DfSpace.s2),
              Semantics(
                button: true,
                label: 'Profile and settings',
                child: GestureDetector(
                  onTap: () => openProfile(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: Text(state.firstName[0].toUpperCase(),
                        style: DfText.bodyStrong.copyWith(color: c.primary)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DfSpace.s4),
          if (state.error != null) ...[
            DfCard(
              color: c.dangerSoft,
              child: Text(state.error!,
                  style: DfText.small.copyWith(color: c.danger)),
            ),
            const SizedBox(height: DfSpace.s4),
          ],
          if (!state.loaded)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (isEmpty)
            ..._emptyState(context, state)
          else ...[
            _WeekStrip(state: state),
            const SizedBox(height: DfSpace.s4),
            _ProgressCard(tasks: todayTasks, streak: streak, state: state),
            if (events.isNotEmpty) ..._upNext(context, events, now),
            if (overdue.isNotEmpty) ...[
              const SizedBox(height: DfSpace.s5),
              SectionHeader(
                title: 'Overdue · ${overdue.length}',
                color: c.danger,
                action: 'Move to today',
                onAction: () async {
                  try {
                    await state.moveOverdueToToday();
                  } catch (_) {
                    if (context.mounted) {
                      showMessage(context,
                          'Could not move tasks. Check your connection.');
                    }
                  }
                },
              ),
              const SizedBox(height: DfSpace.s3),
              for (final t in overdue) ...[
                TaskRow(
                  task: t,
                  onToggle: (v) => toggleTask(context, t, v),
                  onTap: () => openTaskDetail(context, t),
                ),
                const SizedBox(height: DfSpace.s2),
              ],
            ],
            const SizedBox(height: DfSpace.s5),
            SectionHeader(
              title: 'Today · ${todayTasks.length + events.length}',
              action: 'See all',
              onAction: () => Shell.of(context).goTo(2),
            ),
            const SizedBox(height: DfSpace.s3),
            if (todayTasks.isEmpty && events.isEmpty)
              DfCard(
                onTap: () => showAddTask(context, day: today),
                child: Row(
                  children: [
                    Icon(LucideIcons.plus, size: 18, color: c.primary),
                    const SizedBox(width: DfSpace.s3),
                    Expanded(
                      child: Text('Nothing planned today. Add a task.',
                          style: DfText.body.copyWith(color: c.textSecondary)),
                    ),
                  ],
                ),
              )
            else
              ..._timeline(context, todayTasks, events),
            ..._comingUp(context, state, today),
          ],
          if (state.loaded &&
              state.calendarAccess == CalendarAccess.notDetermined) ...[
            const SizedBox(height: DfSpace.s5),
            _ConnectCalendarCard(state: state),
          ],
        ],
      ),
    );
  }

  List<Widget> _emptyState(BuildContext context, AppState state) {
    final c = context.df;
    const ideas = [
      (LucideIcons.sun, 'Drink a glass of water'),
      (LucideIcons.textAlignStart, 'Plan tomorrow in 5 minutes'),
      (LucideIcons.user, 'Text a friend back'),
    ];
    return [
      DfCard(
        radius: DfRadius.xl,
        padding: const EdgeInsets.all(DfSpace.s5),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration:
                  BoxDecoration(color: c.primarySoft, shape: BoxShape.circle),
              child: Icon(LucideIcons.sparkle, color: c.primary, size: 28),
            ),
            const SizedBox(height: DfSpace.s4),
            Text('Your day is a blank page',
                style: DfText.h3.copyWith(color: c.text)),
            const SizedBox(height: DfSpace.s2),
            Text(
              'Add a task, even a small one. Finish it and you’ve started your streak.',
              textAlign: TextAlign.center,
              style: DfText.small.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: DfSpace.s4),
            DfButton(
              label: 'Add your first task',
              onPressed: () => showAddTask(context),
            ),
          ],
        ),
      ),
      const SizedBox(height: DfSpace.s5),
      const Overline('Try one of these'),
      const SizedBox(height: DfSpace.s3),
      for (final (icon, title) in ideas) ...[
        DfCard(
          borderColor: c.border,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          onTap: () async {
            try {
              await state.addTask(
                  title: title, due: dateOnly(DateTime.now()));
            } catch (_) {
              if (context.mounted) {
                showMessage(context, 'Could not save. Check your connection.');
              }
            }
          },
          child: Row(
            children: [
              Icon(icon, size: 18, color: c.textSecondary),
              const SizedBox(width: DfSpace.s3),
              Expanded(
                child: Text(title, style: DfText.body.copyWith(color: c.text)),
              ),
              Icon(LucideIcons.plus, size: 18, color: c.primary),
            ],
          ),
        ),
        const SizedBox(height: DfSpace.s2),
      ],
    ];
  }

  List<Widget> _upNext(
      BuildContext context, List<CalEvent> events, DateTime now) {
    final c = context.df;
    CalEvent? next;
    for (final e in events) {
      if (!e.allDay && e.end.isAfter(now)) {
        next = e;
        break;
      }
    }
    if (next == null) return const [];
    final mins = next.start.difference(now).inMinutes;
    final label = mins <= 0
        ? 'now'
        : mins < 60
            ? 'in $mins min'
            : 'in ${mins ~/ 60} h ${mins % 60} min';
    return [
      const SizedBox(height: DfSpace.s5),
      SectionHeader(
        title: 'Up next',
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: c.eventSoft,
            borderRadius: BorderRadius.circular(DfRadius.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.clock, size: 12, color: c.event),
              const SizedBox(width: 4),
              Text(label, style: DfText.caption.copyWith(color: c.event)),
            ],
          ),
        ),
      ),
      const SizedBox(height: DfSpace.s3),
      EventRow(event: next),
    ];
  }

  /// Timed tasks and events in time order, then untimed tasks.
  List<Widget> _timeline(
      BuildContext context, List<Task> tasks, List<CalEvent> events) {
    final items = <(DateTime, Widget)>[];
    final untimed = <Widget>[];
    for (final t in tasks) {
      final row = TaskRow(
        task: t,
        onToggle: (v) => toggleTask(context, t, v),
        onTap: () => openTaskDetail(context, t),
      );
      if (t.hasTime && t.isOn(DateTime.now())) {
        items.add((t.due!, row));
      } else {
        untimed.add(row);
      }
    }
    for (final e in events) {
      items.add((e.allDay ? dateOnly(e.start) : e.start, EventRow(event: e)));
    }
    items.sort((a, b) => a.$1.compareTo(b.$1));
    return [
      for (final w in [...items.map((i) => i.$2), ...untimed]) ...[
        w,
        const SizedBox(height: DfSpace.s2),
      ],
    ];
  }

  List<Widget> _comingUp(BuildContext context, AppState state, DateTime today) {
    final c = context.df;
    final entries = <(DateTime, Widget)>[];
    for (final t in state.upcoming.take(6)) {
      final tag = state.tagFor(t);
      entries.add((
        t.due!,
        _ComingRow(
          day: t.due!,
          title: t.title,
          subtitle: t.hasTime ? formatTime(t.due!) : 'Anytime',
          trailing: tag == null ? null : TagChip(tag: tag),
          onTap: () => openTaskDetail(context, t),
        )
      ));
    }
    if (state.showEvents) {
      final end = today.add(const Duration(days: 8));
      for (final e in state.events) {
        if (e.start.isAfter(today.add(const Duration(days: 1))) &&
            e.start.isBefore(end)) {
          entries.add((
            e.start,
            _ComingRow(
              day: e.start,
              title: e.title,
              subtitle: e.allDay ? 'Event · all day' : 'Event · ${formatTime(e.start)}',
              isEvent: true,
              trailing: Icon(LucideIcons.calendar, size: 18, color: c.event),
            )
          ));
        }
      }
    }
    if (entries.isEmpty) return const [];
    entries.sort((a, b) => a.$1.compareTo(b.$1));
    final rows = entries.take(5).map((e) => e.$2).toList();
    return [
      const SizedBox(height: DfSpace.s5),
      SectionHeader(
        title: 'Coming up',
        action: 'Calendar',
        onAction: () => Shell.of(context).goTo(1),
      ),
      const SizedBox(height: DfSpace.s3),
      DfCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) Divider(color: c.border),
              rows[i],
            ],
          ],
        ),
      ),
    ];
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    final today = dateOnly(DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Builder(builder: (context) {
              final day = monday.add(Duration(days: i));
              final isToday = day == today;
              final has = state.tasksOn(day).isNotEmpty ||
                  state.eventsOn(day).isNotEmpty;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isToday ? c.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(DfRadius.md),
                ),
                child: Column(
                  children: [
                    Text(DateFormat('EEE').format(day),
                        style: DfText.caption.copyWith(
                            color: isToday ? Colors.white : c.textMuted)),
                    const SizedBox(height: 2),
                    Text('${day.day}',
                        style: DfText.h3.copyWith(
                            color: isToday ? Colors.white : c.text)),
                    const SizedBox(height: 4),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: !has
                            ? Colors.transparent
                            : isToday
                                ? Colors.white
                                : c.primary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard(
      {required this.tasks, required this.streak, required this.state});

  final List<Task> tasks;
  final StreakInfo streak;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    final total = tasks.length;
    final done = tasks.where((t) => t.isDone).length;
    final left = total - done;
    final pct = total == 0 ? 0.0 : done / total;
    final goal = state.settings.dailyGoal;

    final String title;
    final String body;
    if (total == 0) {
      title = 'Nothing planned yet';
      body = streak.current > 0
          ? 'Complete any task today to keep your ${streak.current}-day streak.'
          : 'Add a task and finish it to start a streak.';
    } else if (left == 0) {
      title = 'All $total done today';
      body = streak.current > 1
          ? 'That’s ${streak.current} days in a row. See you tomorrow.'
          : 'Nice work. Come back tomorrow to build your streak.';
    } else {
      title = '$done of $total done today';
      if (streak.doneToday) {
        body = '$left more to go. Your ${streak.current}-day streak is safe.';
      } else if (streak.current > 0) {
        body =
            '$left to go. Finish one to keep your ${streak.current}-day streak.';
      } else {
        body = '$left to go. Finish one to start a streak.';
      }
    }
    final goalLine = goal == 0
        ? ''
        : done >= goal
            ? ' Daily goal met.'
            : ' Goal: $done of $goal.';

    final days = completionsByDay(state.tasks);
    final today = dateOnly(DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1));
    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.all(DfSpace.s5),
      decoration: BoxDecoration(
        color: c.primary,
        borderRadius: BorderRadius.circular(DfRadius.xl),
        boxShadow: DfShadow.floating,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: CustomPaint(
              painter: _RingPainter(pct),
              child: Center(
                child: Text('${(pct * 100).round()}%',
                    style: DfText.h3.copyWith(color: Colors.white)),
              ),
            ),
          ),
          const SizedBox(width: DfSpace.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: DfText.h3.copyWith(color: Colors.white)),
                const SizedBox(height: 4),
                Text('$body$goalLine',
                    style: DfText.small.copyWith(
                        color: Colors.white.withValues(alpha: 0.85))),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (var i = 0; i < 7; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Column(
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (days[monday.add(Duration(days: i))] ??
                                            0) >
                                        0
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(letters[i],
                                style: DfText.overline.copyWith(
                                    color:
                                        Colors.white.withValues(alpha: 0.7),
                                    letterSpacing: 0,
                                    fontSize: 10)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(5);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..color = Colors.white.withValues(alpha: 0.25);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;
    canvas.drawArc(r, 0, math.pi * 2, false, track);
    if (progress > 0) {
      canvas.drawArc(r, -math.pi / 2, math.pi * 2 * progress, false, arc);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

class _ComingRow extends StatelessWidget {
  const _ComingRow({
    required this.day,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.isEvent = false,
    this.onTap,
  });

  final DateTime day;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final bool isEvent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isEvent ? c.eventSoft : c.surfaceMuted,
                borderRadius: BorderRadius.circular(DfRadius.sm),
              ),
              child: Column(
                children: [
                  Text(DateFormat('EEE').format(day).toUpperCase(),
                      style: DfText.overline.copyWith(
                          color: isEvent ? c.event : c.textMuted,
                          fontSize: 10)),
                  Text('${day.day}',
                      style: DfText.bodyStrong
                          .copyWith(color: isEvent ? c.event : c.text)),
                ],
              ),
            ),
            const SizedBox(width: DfSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: DfText.bodyStrong.copyWith(color: c.text),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  Text(subtitle,
                      style: DfText.small.copyWith(color: c.textMuted)),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: DfSpace.s2),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class _ConnectCalendarCard extends StatelessWidget {
  const _ConnectCalendarCard({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    return DfCard(
      color: c.eventSoft,
      onTap: state.connectCalendar,
      child: Row(
        children: [
          Icon(LucideIcons.calendar, color: c.event, size: 22),
          const SizedBox(width: DfSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Connect your calendar',
                    style: DfText.bodyStrong.copyWith(color: c.text)),
                Text('See meetings next to your tasks',
                    style: DfText.small.copyWith(color: c.textSecondary)),
              ],
            ),
          ),
          Icon(LucideIcons.chevronRight, color: c.textMuted, size: 18),
        ],
      ),
    );
  }
}
