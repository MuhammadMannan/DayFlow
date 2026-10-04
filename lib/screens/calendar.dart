import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/app_state.dart';
import '../data/device_calendar.dart';
import '../models/models.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import 'add_task.dart';
import 'day_timeline.dart';
import 'shell.dart';
import 'task_detail.dart';

enum _View { month, week }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  _View _view = _View.month;
  DateTime _selected = dateOnly(DateTime.now());
  late DateTime _month = DateTime(_selected.year, _selected.month);

  DateTime get _weekStart =>
      _selected.subtract(Duration(days: _selected.weekday - 1));

  void _select(DateTime day) => setState(() {
        _selected = dateOnly(day);
        _month = DateTime(day.year, day.month);
      });

  void _step(int dir) {
    if (_view == _View.month) {
      final m = DateTime(_month.year, _month.month + dir);
      final today = dateOnly(DateTime.now());
      setState(() {
        _month = m;
        _selected =
            (m.year == today.year && m.month == today.month) ? today : m;
      });
    } else {
      _select(_selected.add(Duration(days: 7 * dir)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    final state = AppScope.of(context);
    final tasks = state.tasksOn(_selected);
    final events = state.eventsOn(_selected);

    final String title;
    if (_view == _View.month) {
      title = DateFormat(
              _month.year == DateTime.now().year ? 'MMMM' : 'MMMM y')
          .format(_month);
    } else {
      final end = _weekStart.add(const Duration(days: 6));
      title = _weekStart.month == end.month
          ? '${DateFormat('MMM d').format(_weekStart)} – ${end.day}'
          : '${DateFormat('MMM d').format(_weekStart)} – ${DateFormat('MMM d').format(end)}';
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
                child: Text(title,
                    style: DfText.h1.copyWith(color: c.text),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              DfSegmented<_View>(
                values: const [_View.month, _View.week],
                labels: const ['Month', 'Week'],
                selected: _view,
                onChanged: (v) => setState(() => _view = v),
              ),
            ],
          ),
          const SizedBox(height: DfSpace.s2),
          Row(
            children: [
              _NavButton(
                  icon: LucideIcons.chevronLeft,
                  label: 'Previous',
                  onTap: () => _step(-1)),
              const SizedBox(width: 8),
              _NavButton(
                  icon: LucideIcons.chevronRight,
                  label: 'Next',
                  onTap: () => _step(1)),
              const Spacer(),
              if (_selected != dateOnly(DateTime.now()))
                GestureDetector(
                  onTap: () => _select(DateTime.now()),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text('Today',
                        style: DfText.smallStrong.copyWith(color: c.primary)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: DfSpace.s3),
          if (_view == _View.month)
            _MonthGrid(
              month: _month,
              selected: _selected,
              state: state,
              onSelect: _select,
            )
          else
            _WeekStrip(
              start: _weekStart,
              selected: _selected,
              state: state,
              onSelect: _select,
            ),
          const SizedBox(height: DfSpace.s3),
          Row(
            children: [
              _Legend(color: c.primary, label: 'Tasks & reminders'),
              const SizedBox(width: DfSpace.s4),
              _Legend(color: c.event, label: 'Calendar events'),
            ],
          ),
          const SizedBox(height: DfSpace.s4),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('EEEE, d MMMM').format(_selected),
                        style: DfText.h3.copyWith(color: c.text)),
                    Text(
                      '${events.length} ${events.length == 1 ? 'event' : 'events'} · '
                      '${tasks.length} ${tasks.length == 1 ? 'task' : 'tasks'}',
                      style: DfText.caption.copyWith(color: c.textMuted),
                    ),
                  ],
                ),
              ),
              DfIconButton(
                icon: LucideIcons.plus,
                semanticLabel: 'Add task on this day',
                onPressed: () => showAddTask(context, day: _selected),
              ),
            ],
          ),
          const SizedBox(height: DfSpace.s3),
          if (_view == _View.week)
            DayTimeline(day: _selected)
          else
            ..._agenda(context, state, tasks, events),
          if (state.calendarAccess != CalendarAccess.granted) ...[
            const SizedBox(height: DfSpace.s4),
            _CalendarAccessCard(state: state),
          ],
        ],
      ),
    );
  }

  List<Widget> _agenda(BuildContext context, AppState state, List<Task> tasks,
      List<CalEvent> events) {
    final c = context.df;
    if (tasks.isEmpty && events.isEmpty) {
      return [
        DfCard(
          onTap: () => showAddTask(context, day: _selected),
          child: Row(
            children: [
              Icon(LucideIcons.plus, size: 18, color: c.primary),
              const SizedBox(width: DfSpace.s3),
              Expanded(
                child: Text('Nothing on this day. Tap to add a task.',
                    style: DfText.body.copyWith(color: c.textSecondary)),
              ),
            ],
          ),
        ),
      ];
    }
    final timed = <(DateTime, Widget)>[];
    final untimed = <Widget>[];
    for (final t in tasks) {
      final row = TaskRow(
        task: t,
        onToggle: (v) => toggleTask(context, t, v),
        onTap: () => openTaskDetail(context, t),
      );
      t.hasTime ? timed.add((t.due!, row)) : untimed.add(row);
    }
    for (final e in events) {
      timed.add((e.allDay ? _selected : e.start, EventRow(event: e)));
    }
    timed.sort((a, b) => a.$1.compareTo(b.$1));
    return [
      for (final w in [...timed.map((e) => e.$2), ...untimed]) ...[
        w,
        const SizedBox(height: DfSpace.s2),
      ],
    ];
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DfRadius.sm),
          side: BorderSide(color: c.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
              width: 36,
              height: 32,
              child: Icon(icon, size: 18, color: c.textSecondary)),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label,
              style:
                  DfText.caption.copyWith(color: context.df.textSecondary)),
        ],
      );
}

class _Dots extends StatelessWidget {
  const _Dots({required this.tasks, required this.events});
  final int tasks;
  final int events;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    final dots = <Color>[
      if (events > 0) c.event,
      for (var i = 0; i < tasks.clamp(0, 2); i++) c.primary,
    ];
    return SizedBox(
      height: 5,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final color in dots)
            Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.state,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime selected;
  final AppState state;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    final first = DateTime(month.year, month.month, 1);
    final gridStart = first.subtract(Duration(days: first.weekday - 1));
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final weeks = ((first.weekday - 1 + daysInMonth) / 7).ceil();
    final today = dateOnly(DateTime.now());
    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return DfCard(
      radius: DfRadius.card,
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
      child: Column(
        children: [
          Row(
            children: [
              for (final l in letters)
                Expanded(
                  child: Center(
                    child: Text(l,
                        style: DfText.caption.copyWith(color: c.textMuted)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (var w = 0; w < weeks; w++)
            Row(
              children: [
                for (var d = 0; d < 7; d++)
                  Expanded(
                    child: Builder(builder: (context) {
                      final day = DateTime(gridStart.year, gridStart.month,
                          gridStart.day + w * 7 + d);
                      final inMonth = day.month == month.month;
                      final isSelected = day == selected;
                      final isToday = day == today;
                      final open = state
                          .tasksOn(day)
                          .where((t) => !t.isDone)
                          .length;
                      final events = state.eventsOn(day).length;
                      return Semantics(
                        button: true,
                        selected: isSelected,
                        label: DateFormat('EEEE d MMMM').format(day),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onSelect(day),
                          child: SizedBox(
                            height: 52,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? c.primary
                                        : isToday
                                            ? c.primarySoft
                                            : Colors.transparent,
                                  ),
                                  child: Text(
                                    '${day.day}',
                                    style: DfText.bodyStrong.copyWith(
                                      color: isSelected
                                          ? Colors.white
                                          : isToday
                                              ? c.primary
                                              : inMonth
                                                  ? c.text
                                                  : c.textMuted,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                _Dots(tasks: open, events: events),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.start,
    required this.selected,
    required this.state,
    required this.onSelect,
  });

  final DateTime start;
  final DateTime selected;
  final AppState state;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(DateTime.now());
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Builder(builder: (context) {
              final day = start.add(Duration(days: i));
              return DayPill(
                day: day,
                selected: day == selected,
                isToday: day == today,
                hasItems:
                    state.tasksOn(day).any((t) => !t.isDone) ||
                        state.eventsOn(day).isNotEmpty,
                onTap: () => onSelect(day),
              );
            }),
          ),
      ],
    );
  }
}

class _CalendarAccessCard extends StatelessWidget {
  const _CalendarAccessCard({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    final denied = state.calendarAccess == CalendarAccess.denied;
    return DfCard(
      color: c.eventSoft,
      onTap: denied ? null : state.connectCalendar,
      child: Row(
        children: [
          Icon(LucideIcons.calendar, color: c.event, size: 22),
          const SizedBox(width: DfSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    denied
                        ? 'Calendar access is off'
                        : 'Connect your calendar',
                    style: DfText.bodyStrong.copyWith(color: c.text)),
                Text(
                  denied
                      ? 'Turn it on in Settings › DayFlow › Calendars to see your events here.'
                      : 'See meetings and appointments next to your tasks. Read-only.',
                  style: DfText.small.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
          if (!denied)
            Icon(LucideIcons.chevronRight, color: c.textMuted, size: 18),
        ],
      ),
    );
  }
}
