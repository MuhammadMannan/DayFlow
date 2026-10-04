import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/app_state.dart';
import '../data/quick_parse.dart';
import '../models/models.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import 'add_task.dart';
import 'profile.dart';
import 'reschedule.dart';
import 'tags.dart';
import 'shell.dart';
import 'task_detail.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _quick = TextEditingController();
  final _search = TextEditingController();
  String? _tagFilter;
  bool _searching = false;
  final _collapsed = <String>{'Completed'};

  @override
  void dispose() {
    _quick.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _quickAdd() async {
    final text = _quick.text.trim();
    if (text.isEmpty) return;
    final p = parseQuick(text);
    final state = AppScope.read(context);
    try {
      await state.addTask(
        title: p.title.isEmpty ? text : p.title,
        // Default to today so nothing new is created without a home.
        due: p.due ?? dateOnly(DateTime.now()),
        hasTime: p.hasTime,
        tagId: _tagFilter,
      );
      _quick.clear();
    } catch (_) {
      if (mounted) {
        showMessage(context, 'Could not save. Check your connection.');
      }
    }
  }

  void _showMore() {
    final c = context.df;
    final state = AppScope.read(context);
    const sections = ['Overdue', 'Today', 'Upcoming', 'Someday', 'Completed'];
    Widget item(IconData icon, String label, VoidCallback onTap) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, size: 20, color: c.text),
          title: Text(label, style: DfText.body.copyWith(color: c.text)),
          onTap: () {
            Navigator.pop(context);
            onTap();
          },
        );
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: DfSpace.s5, vertical: DfSpace.s3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              item(LucideIcons.chevronDown, 'Expand all sections',
                  () => setState(_collapsed.clear)),
              item(LucideIcons.chevronUp, 'Collapse all sections',
                  () => setState(() => _collapsed.addAll(sections))),
              item(
                LucideIcons.tag,
                'Manage tags',
                () => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        AppScope(state: state, child: const TagsScreen()),
                  ),
                ),
              ),
              item(LucideIcons.user, 'Profile and settings',
                  () => openProfile(context)),
            ],
          ),
        ),
      ),
    );
  }

  bool _matches(Task t) {
    if (_tagFilter != null && t.tagId != _tagFilter) return false;
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    return t.title.toLowerCase().contains(q) ||
        t.notes.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    final state = AppScope.of(context);
    final overdue = state.overdue.where(_matches).toList();
    final today = state.today.where((t) => !t.isDone && _matches(t)).toList();
    final upcoming = state.upcoming.where(_matches).toList();
    final someday = state.someday.where(_matches).toList();
    final completed = state.completed.where(_matches).toList();
    final nothing = overdue.isEmpty &&
        today.isEmpty &&
        upcoming.isEmpty &&
        someday.isEmpty &&
        completed.isEmpty;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            DfSpace.s5, DfSpace.s3, DfSpace.s5, kTabBarClearance),
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Tasks', style: DfText.h1.copyWith(color: c.text)),
              ),
              DfIconButton(
                icon: _searching ? LucideIcons.x : LucideIcons.search,
                semanticLabel: _searching ? 'Close search' : 'Search tasks',
                onPressed: () => setState(() {
                  _searching = !_searching;
                  if (!_searching) _search.clear();
                }),
              ),
              const SizedBox(width: 8),
              DfIconButton(
                icon: LucideIcons.ellipsis,
                semanticLabel: 'More',
                onPressed: _showMore,
              ),
            ],
          ),
          if (_searching) ...[
            const SizedBox(height: DfSpace.s3),
            DfTextField(
              controller: _search,
              hint: 'Search tasks',
              icon: LucideIcons.search,
              onSubmitted: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: DfSpace.s3),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                DfPill(
                  label: 'All',
                  selected: _tagFilter == null,
                  onTap: () => setState(() => _tagFilter = null),
                ),
                for (final tag in state.tags) ...[
                  const SizedBox(width: 8),
                  _TagFilter(
                    tag: tag,
                    selected: _tagFilter == tag.id,
                    onTap: () => setState(() =>
                        _tagFilter = _tagFilter == tag.id ? null : tag.id),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: DfSpace.s3),
          Container(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(DfRadius.row),
              border: Border.all(color: c.primary, width: 1.5),
            ),
            constraints: const BoxConstraints(minHeight: 63),
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: Row(
              children: [
                Icon(LucideIcons.plus, size: 20, color: c.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _quick,
                    onSubmitted: (_) => _quickAdd(),
                    textInputAction: TextInputAction.done,
                    keyboardType: TextInputType.text,
                    minLines: 1,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    style: DfText.body.copyWith(color: c.text),
                    cursorColor: c.primary,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintMaxLines: 2,
                      hintText: 'Add a task… e.g. “Call mom tomorrow 6pm”',
                      hintStyle: DfText.body.copyWith(color: c.textMuted),
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Add task',
                  child: Material(
                    color: c.primarySoft,
                    borderRadius: BorderRadius.circular(DfRadius.md),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: _quickAdd,
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(LucideIcons.arrowRight,
                            size: 18, color: c.primary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!state.loaded)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (nothing)
            Padding(
              padding: const EdgeInsets.only(top: 56),
              child: Column(
                children: [
                  Icon(LucideIcons.listChecks, size: 40, color: c.textMuted),
                  const SizedBox(height: DfSpace.s3),
                  Text(
                    _search.text.isNotEmpty || _tagFilter != null
                        ? 'No tasks match'
                        : 'No tasks yet',
                    style: DfText.h3.copyWith(color: c.text),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Type above and press return to add one.',
                    style: DfText.small.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
            )
          else ...[
            ..._section('Overdue', overdue, color: c.danger),
            ..._section('Today', today, reorderable: true),
            ..._section('Upcoming', upcoming, groupByDay: true),
            ..._section('Someday', someday, reorderable: true),
            ..._section('Completed', completed, muted: true, showDate: true),
            const SizedBox(height: DfSpace.s4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: c.primarySoft,
                borderRadius: BorderRadius.circular(DfRadius.field),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.sparkle, size: 16, color: c.primaryStrong),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Swipe right to complete, left to reschedule. Hold and drag to reorder.',
                      style: DfText.caption.copyWith(color: c.primaryStrong),
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

  List<Widget> _section(
    String title,
    List<Task> tasks, {
    Color? color,
    bool groupByDay = false,
    bool muted = false,
    bool showDate = false,
    bool reorderable = false,
  }) {
    if (tasks.isEmpty) return const [];
    final c = context.df;
    final collapsed = _collapsed.contains(title);
    final today = dateOnly(DateTime.now());
    final rows = <Widget>[];
    if (!collapsed && reorderable && tasks.length > 1) {
      // Hold and drag to reorder within the section.
      rows.add(ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tasks.length,
        proxyDecorator: (child, index, animation) =>
            Material(color: Colors.transparent, child: child),
        onReorder: (from, to) async {
          final ordered = [...tasks];
          final moved = ordered.removeAt(from);
          ordered.insert(to > from ? to - 1 : to, moved);
          try {
            await AppScope.read(context).reorder(ordered);
          } catch (_) {
            if (mounted) {
              showMessage(context, 'Could not save. Check your connection.');
            }
          }
        },
        itemBuilder: (context, i) {
          final t = tasks[i];
          return Padding(
            key: ValueKey('row-${t.id}'),
            padding: const EdgeInsets.only(bottom: 10),
            child: _Swipeable(
              task: t,
              child: TaskRow(
                task: t,
                onToggle: (v) => toggleTask(context, t, v),
                onTap: () => openTaskDetail(context, t),
              ),
            ),
          );
        },
      ));
    } else if (!collapsed) {
      DateTime? lastDay;
      for (final t in tasks) {
        if (groupByDay && t.dueDay != lastDay) {
          lastDay = t.dueDay;
          final diff = lastDay!.difference(today).inDays;
          final label = diff == 1
              ? 'Tomorrow · ${DateFormat('EEE d').format(lastDay)}'
              : DateFormat('EEE d MMM').format(lastDay);
          rows.add(Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Overline(label),
          ));
        }
        rows.add(_Swipeable(
          key: ValueKey(t.id),
          task: t,
          child: TaskRow(
            task: t,
            showDate: showDate && !t.isDone,
            onToggle: (v) => toggleTask(context, t, v),
            onTap: () => openTaskDetail(context, t),
          ),
        ));
        rows.add(const SizedBox(height: 10));
      }
    }
    return [
      const SizedBox(height: DfSpace.s5),
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() =>
            collapsed ? _collapsed.remove(title) : _collapsed.add(title)),
        child: Row(
          children: [
            Text(title,
                style: DfText.h3.copyWith(
                    color: color ?? (muted ? c.textMuted : c.text))),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: c.surfaceMuted,
                borderRadius: BorderRadius.circular(DfRadius.full),
              ),
              child: Text('${tasks.length}',
                  style: DfText.caption.copyWith(color: c.textSecondary)),
            ),
            const Spacer(),
            Icon(collapsed ? LucideIcons.chevronDown : LucideIcons.chevronUp,
                size: 20, color: c.textMuted),
          ],
        ),
      ),
      const SizedBox(height: DfSpace.s3),
      ...rows,
    ];
  }
}

class _TagFilter extends StatelessWidget {
  const _TagFilter(
      {required this.tag, required this.selected, required this.onTap});

  final Tag tag;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.tagSoft(tag.color) : c.surface,
          borderRadius: BorderRadius.circular(DfRadius.full),
          border: Border.all(color: selected ? c.tag(tag.color) : c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                  color: c.tag(tag.color), shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(tag.name, style: DfText.smallStrong.copyWith(color: c.text)),
          ],
        ),
      ),
    );
  }
}

/// Swipe right to complete, left to delete, both with Undo.
class _Swipeable extends StatelessWidget {
  const _Swipeable({super.key, required this.task, required this.child});

  final Task task;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    Widget bg(Color color, IconData icon, String label, bool leading) =>
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(DfRadius.row),
          ),
          child: Row(
            mainAxisAlignment:
                leading ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(label,
                  style: DfText.smallStrong.copyWith(color: Colors.white)),
            ],
          ),
        );
    return Dismissible(
      key: ValueKey('swipe-${task.id}-${task.isDone}'),
      background: bg(c.success, LucideIcons.check,
          task.isDone ? 'Not done' : 'Done', true),
      secondaryBackground:
          bg(c.primary, LucideIcons.calendar, 'Reschedule', false),
      // A finished task has nothing to reschedule.
      direction: task.isDone
          ? DismissDirection.startToEnd
          : DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await toggleTask(context, task, !task.isDone);
        } else {
          await showReschedule(context, task);
        }
        // The list rebuilds from Firestore, so never remove the row locally.
        return false;
      },
      child: child,
    );
  }
}
