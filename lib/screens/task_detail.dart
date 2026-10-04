import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/app_state.dart';
import '../models/models.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import 'add_task.dart';

void openTaskDetail(BuildContext context, Task task) {
  final state = AppScope.read(context);
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(
      builder: (_) => AppScope(
        state: state,
        child: TaskDetailScreen(id: task.id),
      ),
    ),
  );
}

class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    final state = AppScope.of(context);
    Task? task;
    for (final t in state.tasks) {
      if (t.id == id) task = t;
    }
    if (task == null) {
      // Deleted (possibly from another device): leave the screen.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
      return const Scaffold(body: SizedBox.shrink());
    }
    final t = task;
    final tag = state.tagFor(t);
    final now = DateTime.now();
    final overdue = t.isOverdue(now);
    final today = dateOnly(now);

    Future<void> move(DateTime? day) async {
      try {
        await state.moveTo(t, day);
        if (context.mounted) {
          showMessage(
            context,
            day == null ? 'Moved to Someday' : 'Moved to ${relativeDay(day)}',
          );
        }
      } catch (_) {
        if (context.mounted) {
          showMessage(context, 'Could not save. Check your connection.');
        }
      }
    }

    Future<void> pickDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: t.due ?? now,
        firstDate: DateTime(now.year - 1),
        lastDate: DateTime(now.year + 5),
      );
      if (picked != null) await move(picked);
    }

    Future<void> delete() async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete this task?'),
          content: Text('“${t.title}” will be removed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Delete', style: TextStyle(color: c.danger)),
            ),
          ],
        ),
      );
      if (ok != true) return;
      try {
        await state.deleteTask(t);
      } catch (_) {
        if (context.mounted) {
          showMessage(context, 'Could not delete. Check your connection.');
        }
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DfSpace.s5,
                DfSpace.s2,
                DfSpace.s5,
                0,
              ),
              child: Row(
                children: [
                  DfIconButton(
                    icon: LucideIcons.chevronLeft,
                    semanticLabel: 'Back',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  DfIconButton(
                    icon: LucideIcons.ellipsis,
                    semanticLabel: 'More actions',
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      builder: (ctx) => SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DfSpace.s5,
                            vertical: DfSpace.s3,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  LucideIcons.pencil,
                                  size: 20,
                                  color: c.text,
                                ),
                                title: Text(
                                  'Edit task',
                                  style: DfText.body.copyWith(color: c.text),
                                ),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  showAddTask(context, task: t);
                                },
                              ),
                              if (!t.isDone && t.due != null)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(
                                    LucideIcons.inbox,
                                    size: 20,
                                    color: c.text,
                                  ),
                                  title: Text(
                                    'Move to Someday',
                                    style: DfText.body.copyWith(color: c.text),
                                  ),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    move(null);
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(DfSpace.s5),
                children: [
                  if (tag != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TagChip(tag: tag),
                    ),
                  const SizedBox(height: DfSpace.s3),
                  Text(t.title, style: DfText.h1.copyWith(color: c.text)),
                  if (overdue) ...[
                    const SizedBox(height: DfSpace.s2),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.circleAlert,
                          size: 16,
                          color: c.danger,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Overdue since ${relativeDay(t.due!).toLowerCase()}'
                          '${t.hasTime ? ', ${formatTime(t.due!)}' : ''}',
                          style: DfText.small.copyWith(color: c.danger),
                        ),
                      ],
                    ),
                  ],
                  if (t.isDone) ...[
                    const SizedBox(height: DfSpace.s2),
                    Row(
                      children: [
                        Icon(LucideIcons.check, size: 16, color: c.success),
                        const SizedBox(width: 6),
                        Text(
                          'Completed ${relativeDay(t.completedAt!).toLowerCase()}',
                          style: DfText.small.copyWith(color: c.success),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: DfSpace.s4),
                  DfCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: LucideIcons.calendar,
                          label: 'Due',
                          value: t.due == null
                              ? 'No date'
                              : DateFormat('EEE, d MMMM').format(t.due!),
                        ),
                        Divider(color: c.border),
                        _InfoRow(
                          icon: LucideIcons.clock,
                          label: 'Time',
                          value: t.hasTime ? formatTime(t.due!) : 'Anytime',
                        ),
                        Divider(color: c.border),
                        _InfoRow(
                          icon: LucideIcons.bell,
                          label: 'Reminder',
                          value: reminderLabel(
                            t.remind && t.hasTime,
                            t.remindMinutes,
                          ),
                        ),
                        Divider(color: c.border),
                        _InfoRow(
                          icon: LucideIcons.repeat,
                          label: 'Repeat',
                          value: repeatLabel(t.repeat, t.due),
                        ),
                      ],
                    ),
                  ),
                  if (t.notes.isNotEmpty) ...[
                    const SizedBox(height: DfSpace.s3),
                    DfCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Overline('Notes'),
                          const SizedBox(height: 6),
                          Text(
                            t.notes,
                            style: DfText.body.copyWith(color: c.text),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (!t.isDone) ...[
                    const SizedBox(height: DfSpace.s5),
                    const Overline('Move it'),
                    const SizedBox(height: DfSpace.s3),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          DfPill(label: 'Today', onTap: () => move(today)),
                          const SizedBox(width: 8),
                          DfPill(
                            label: 'Tomorrow',
                            onTap: () =>
                                move(today.add(const Duration(days: 1))),
                          ),
                          const SizedBox(width: 8),
                          DfPill(
                            label: 'Next week',
                            onTap: () =>
                                move(today.add(Duration(days: 8 - today.weekday))),
                          ),
                          const SizedBox(width: 8),
                          DfPill(label: 'Pick date', onTap: pickDate),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Pinned to the bottom, as in the design.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DfSpace.s5,
                DfSpace.s2,
                DfSpace.s5,
                DfSpace.s2,
              ),
              child: Column(
                children: [
                  DfButton(
                    label: t.isDone ? 'Mark as not done' : 'Mark complete',
                    icon: t.isDone ? null : LucideIcons.check,
                    kind: t.isDone
                        ? DfButtonKind.secondary
                        : DfButtonKind.success,
                    onPressed: () async {
                      await toggleTask(context, t, !t.isDone);
                      if (!t.isDone && context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const SizedBox(height: DfSpace.s2),
                  DfButton(
                    label: 'Delete task',
                    icon: LucideIcons.trash,
                    kind: DfButtonKind.dangerText,
                    onPressed: delete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: c.textMuted),
          const SizedBox(width: 12),
          Text(label, style: DfText.body.copyWith(color: c.textSecondary)),
          const Spacer(),
          Text(value, style: DfText.bodyStrong.copyWith(color: c.text)),
        ],
      ),
    );
  }
}
