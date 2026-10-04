import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/app_state.dart';
import '../models/models.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import 'add_task.dart';
import 'task_detail.dart';

/// One timed item placed on the grid.
class TimelineItem {
  TimelineItem({required this.start, required this.end, this.task, this.event});

  /// Minutes from midnight of the day being shown.
  final int start;
  final int end;
  final Task? task;
  final CalEvent? event;

  /// Set by [layoutTimeline]: which column, out of how many, in its cluster.
  int column = 0;
  int columns = 1;
}

/// Tasks have no duration, so they are drawn as a one-hour block, as in
/// the design.
const taskBlockMinutes = 60;

/// Gives overlapping items side-by-side columns. Items that touch end to
/// start do not count as overlapping.
void layoutTimeline(List<TimelineItem> items) {
  items.sort((a, b) =>
      a.start != b.start ? a.start.compareTo(b.start) : b.end.compareTo(a.end));
  var cluster = <TimelineItem>[];
  var clusterEnd = -1;

  void close() {
    final cols = cluster.fold(0, (m, i) => math.max(m, i.column + 1));
    for (final i in cluster) {
      i.columns = cols;
    }
    cluster = [];
  }

  for (final item in items) {
    if (cluster.isNotEmpty && item.start >= clusterEnd) close();
    // First column whose last item has finished.
    final taken = <int, int>{};
    for (final other in cluster) {
      taken[other.column] = math.max(taken[other.column] ?? 0, other.end);
    }
    var col = 0;
    while ((taken[col] ?? 0) > item.start) {
      col++;
    }
    item.column = col;
    cluster.add(item);
    clusterEnd = math.max(clusterEnd, item.end);
  }
  if (cluster.isNotEmpty) close();
}

/// Hour-by-hour view of one day: timed tasks and calendar events as blocks,
/// untimed ones in an "Anytime" row. Tap an empty slot to add a task there.
class DayTimeline extends StatefulWidget {
  const DayTimeline({super.key, required this.day});

  final DateTime day;

  @override
  State<DayTimeline> createState() => _DayTimelineState();
}

class _DayTimelineState extends State<DayTimeline> {
  // The task being dragged to a new time, and how far it has moved.
  String? _dragId;
  double _dragDy = 0;

  static const _hourHeight = 56.0;
  static const _gutter = 56.0;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    final state = AppScope.of(context);
    final d = dateOnly(widget.day);
    final tasks = state.tasksOn(d);
    final events = state.eventsOn(d);

    final anytimeTasks = tasks.where((t) => !t.hasTime).toList();
    final allDayEvents = events.where((e) => e.allDay).toList();

    int minutesOf(DateTime t) =>
        t.difference(d).inMinutes.clamp(0, 24 * 60);

    final items = <TimelineItem>[
      for (final t in tasks.where((t) => t.hasTime))
        TimelineItem(
          start: minutesOf(t.due!),
          end: math.min(24 * 60, minutesOf(t.due!) + taskBlockMinutes),
          task: t,
        ),
      for (final e in events.where((e) => !e.allDay))
        TimelineItem(
          start: minutesOf(e.start),
          // At least half an hour tall so the title fits.
          end: math.min(24 * 60,
              math.max(minutesOf(e.end), minutesOf(e.start) + 30)),
          event: e,
        ),
    ];
    layoutTimeline(items);

    // Show 8 AM to 6 PM by default, widened to fit anything outside that
    // and, on today, the current time.
    var firstHour = 8;
    var lastHour = 18;
    for (final i in items) {
      firstHour = math.min(firstHour, i.start ~/ 60);
      lastHour = math.max(lastHour, ((i.end + 59) ~/ 60));
    }
    final clock = DateTime.now();
    if (dateOnly(clock) == d) {
      firstHour = math.min(firstHour, clock.hour);
      lastHour = math.max(lastHour, clock.hour + 1);
    }
    lastHour = math.min(lastHour, 24);
    final hours = lastHour - firstHour;
    final height = hours * _hourHeight;

    double yOf(int minutes) => (minutes - firstHour * 60) / 60 * _hourHeight;

    final now = DateTime.now();
    final isToday = dateOnly(now) == d;
    final nowMinutes = now.hour * 60 + now.minute;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (anytimeTasks.isNotEmpty || allDayEvents.isNotEmpty) ...[
          DfCard(
            radius: DfRadius.lg,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Overline('Anytime'),
                ),
                const SizedBox(width: DfSpace.s3),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final e in allDayEvents) _AllDayPill(event: e),
                      for (final t in anytimeTasks) _AnytimePill(task: t),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DfSpace.s3),
        ],
        SizedBox(
          // Half an hour-label of headroom so the first label is not clipped.
          height: height + 16,
          child: LayoutBuilder(builder: (context, box) {
            final width = box.maxWidth - _gutter;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Hour lines and labels.
                for (var h = 0; h <= hours; h++)
                  Positioned(
                    top: 8 + h * _hourHeight - 8,
                    left: 0,
                    right: 0,
                    child: Row(
                      children: [
                        SizedBox(
                          width: _gutter,
                          child: Text(
                            _hourLabel(firstHour + h),
                            style:
                                DfText.caption.copyWith(color: c.textMuted),
                          ),
                        ),
                        Expanded(child: Container(height: 1, color: c.border)),
                      ],
                    ),
                  ),
                // Empty slots: tap to add a task at that half hour.
                Positioned(
                  top: 8,
                  left: _gutter,
                  right: 0,
                  height: height,
                  child: Semantics(
                    label: 'Empty time. Tap to add a task at that time.',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (details) {
                        final minutes = firstHour * 60 +
                            (details.localPosition.dy / _hourHeight * 60);
                        final snapped =
                            ((minutes / 30).floor() * 30).clamp(0, 23 * 60 + 30);
                        showAddTask(
                          context,
                          day: d,
                          time: TimeOfDay(
                              hour: snapped ~/ 60, minute: snapped % 60),
                        );
                      },
                    ),
                  ),
                ),
                for (final item in items)
                  Positioned(
                    top: 8 +
                        yOf(item.start) +
                        2 +
                        (item.task?.id == _dragId ? _dragDy : 0),
                    left: _gutter + width / item.columns * item.column + 2,
                    width: width / item.columns - 4,
                    height:
                        math.max(46, yOf(item.end) - yOf(item.start) - 4),
                    child: item.task != null
                        ? _draggable(context, item, state)
                        : _EventBlock(
                            event: item.event!, narrow: item.columns > 1),
                  ),
                if (isToday &&
                    nowMinutes >= firstHour * 60 &&
                    nowMinutes <= lastHour * 60)
                  Positioned(
                    top: 8 + yOf(nowMinutes) - 4,
                    left: _gutter - 4,
                    right: 0,
                    child: IgnorePointer(
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                                color: c.danger, shape: BoxShape.circle),
                          ),
                          Expanded(
                              child: Container(height: 1.5, color: c.danger)),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          }),
        ),
        const SizedBox(height: DfSpace.s3),
        Text(
          'Tap an empty slot to add a task at that time. Long-press and drag to move a task. Events from your phone calendars are read-only.',
          style: DfText.small.copyWith(color: c.textMuted),
        ),
      ],
    );
  }

  /// Hold a task block, then drag it up or down to change its time.
  Widget _draggable(BuildContext context, TimelineItem item, AppState state) {
    final task = item.task!;
    final dragging = task.id == _dragId;
    return GestureDetector(
      onLongPressStart: task.isDone
          ? null
          : (_) => setState(() {
                _dragId = task.id;
                _dragDy = 0;
              }),
      onLongPressMoveUpdate: (d) {
        if (_dragId == task.id) {
          setState(() => _dragDy = d.offsetFromOrigin.dy);
        }
      },
      onLongPressEnd: (_) async {
        if (_dragId != task.id) return;
        // Snap to the nearest quarter hour and keep it on the same day.
        final moved = (_dragDy / _hourHeight * 60 / 15).round() * 15;
        final minutes = (item.start + moved).clamp(0, 23 * 60 + 45);
        setState(() {
          _dragId = null;
          _dragDy = 0;
        });
        if (minutes == item.start) return;
        final due = task.due!;
        final next = DateTime(
            due.year, due.month, due.day, minutes ~/ 60, minutes % 60);
        try {
          await state.updateTask(task.copyWith(due: () => next));
          if (context.mounted) {
            showUndo(context, '“${task.title}” moved to ${formatTime(next)}',
                () => state.updateTask(task));
          }
        } catch (_) {
          if (context.mounted) {
            showMessage(context, 'Could not save. Check your connection.');
          }
        }
      },
      onLongPressCancel: () => setState(() {
        _dragId = null;
        _dragDy = 0;
      }),
      child: AnimatedScale(
        scale: dragging ? 1.03 : 1,
        duration: const Duration(milliseconds: 120),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DfRadius.md),
            boxShadow: dragging ? DfShadow.floating : null,
          ),
          child: _TaskBlock(task: task, narrow: item.columns > 1),
        ),
      ),
    );
  }

  static String _hourLabel(int h) {
    final hour = h % 24;
    if (hour == 0) return '12 AM';
    if (hour == 12) return '12 PM';
    return hour < 12 ? '$hour AM' : '${hour - 12} PM';
  }
}

/// Small completion ring used on timeline blocks and Anytime pills.
class _Ring extends StatelessWidget {
  const _Ring({
    required this.task,
    required this.size,
    required this.color,
    this.stroke = 2,
  });

  final Task task;
  final double size;
  final Color color;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    return Semantics(
      checked: task.isDone,
      label: task.isDone ? 'Mark as not done' : 'Mark as done',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => toggleTask(context, task, !task.isDone),
        // Padded so the tap target is larger than the ring itself.
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: task.isDone ? c.success : Colors.transparent,
              border: Border.all(
                  color: task.isDone ? c.success : color, width: stroke),
            ),
            child: task.isDone
                ? Icon(LucideIcons.check,
                    size: size * 0.62, color: Colors.white)
                : null,
          ),
        ),
      ),
    );
  }
}

class _TaskBlock extends StatelessWidget {
  const _TaskBlock({required this.task, required this.narrow});

  final Task task;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    final state = AppScope.of(context);
    final tag = state.tagFor(task);
    final tint = tag == null ? c.primary : c.tag(tag.color);
    final bg = tag == null ? c.primarySoft : c.tagSoft(tag.color);
    final detail = [
      formatTime(task.due!),
      if (task.remind)
        task.remindMinutes == 0
            ? 'reminder'
            : 'reminder ${reminderLabel(true, task.remindMinutes)}',
    ].join(' · ');

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(DfRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openTaskDetail(context, task),
        child: Opacity(
          opacity: task.isDone ? 0.6 : 1,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 2 + 8 padding puts the 18pt ring 10 from the left edge.
              const SizedBox(width: 2),
              _Ring(task: task, size: 18, color: tint),
              const SizedBox(width: 2),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DfText.smallStrong.copyWith(color: c.text)),
                      if (!narrow)
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(detail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: DfText.caption
                                  .copyWith(color: c.textSecondary)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventBlock extends StatelessWidget {
  const _EventBlock({required this.event, required this.narrow});

  final CalEvent event;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    final time = '${formatTime(event.start)} – ${formatTime(event.end)}';
    final detail =
        event.location.isEmpty ? time : '$time · ${event.location}';
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        color: c.eventSoft,
        borderRadius: BorderRadius.circular(DfRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 3,
            decoration: BoxDecoration(
                color: c.event, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title.isEmpty ? 'Busy' : event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DfText.smallStrong.copyWith(color: c.text)),
                if (!narrow)
                  Flexible(
                    child: Text(detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DfText.caption
                            .copyWith(color: c.textSecondary)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnytimePill extends StatelessWidget {
  const _AnytimePill({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    return Material(
      color: Colors.transparent,
      shape: StadiumBorder(side: BorderSide(color: c.border)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openTaskDetail(context, task),
        child: SizedBox(
          height: 30,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Ring(
                  task: task, size: 12, color: c.borderStrong, stroke: 1.5),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DfText.smallStrong.copyWith(
                      color: task.isDone ? c.textMuted : c.text),
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _AllDayPill extends StatelessWidget {
  const _AllDayPill({required this.event});
  final CalEvent event;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: c.eventSoft,
        borderRadius: BorderRadius.circular(DfRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.calendar, size: 14, color: c.event),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              event.title.isEmpty ? 'All day' : event.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DfText.smallStrong.copyWith(color: c.text),
            ),
          ),
        ],
      ),
    );
  }
}
