import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/app_state.dart';
import '../models/models.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';

/// Opens the sheet for moving [task] to another day, or dropping it.
Future<void> showReschedule(BuildContext context, Task task) {
  final state = AppScope.read(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    barrierColor: context.df.overlay.withValues(alpha: 0.45),
    builder: (_) => AppScope(state: state, child: _RescheduleSheet(task: task)),
  );
}

class _RescheduleSheet extends StatelessWidget {
  const _RescheduleSheet({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    final state = AppScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    final now = DateTime.now();
    final today = dateOnly(now);
    final overdue = task.isOverdue(now);

    Future<void> move(DateTime? day, String label) async {
      Navigator.pop(context);
      try {
        await state.moveTo(task, day);
        _toast(messenger, '“${task.title}” moved to $label',
            () => state.updateTask(task));
      } catch (_) {
        _plain(messenger, 'Could not save. Check your connection.');
      }
    }

    Future<void> pick() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: task.due != null && !task.due!.isBefore(today)
            ? task.due!
            : today,
        firstDate: DateTime(now.year - 1),
        lastDate: DateTime(now.year + 5),
      );
      if (picked != null && context.mounted) {
        await move(picked, DateFormat('EEE, d MMM').format(picked));
      }
    }

    Future<void> drop() async {
      Navigator.pop(context);
      try {
        await state.dropTask(task);
        _toast(messenger, '“${task.title}” marked won’t do',
            () => state.updateTask(task));
      } catch (_) {
        _plain(messenger, 'Could not save. Check your connection.');
      }
    }

    String d(DateTime day) => DateFormat('EEE, d MMM').format(day);
    final tomorrow = today.add(const Duration(days: 1));
    // "Next week" means the coming Monday.
    final nextWeek = today.add(Duration(days: 8 - today.weekday));

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            DfSpace.s5, DfSpace.s3, DfSpace.s5, DfSpace.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: c.borderStrong,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: DfSpace.s4),
            Text(overdue ? 'Move 1 overdue task' : 'Move task',
                style: DfText.h2.copyWith(color: c.text)),
            const SizedBox(height: DfSpace.s3),
            Text(task.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: DfText.body.copyWith(color: c.textSecondary)),
            const SizedBox(height: DfSpace.s4),
            // Today is the suggested choice for an overdue task.
            _Option(
              icon: LucideIcons.sun,
              label: 'Today',
              detail: d(today),
              highlighted: overdue,
              onTap: () => move(today, 'today'),
            ),
            _Option(
              icon: LucideIcons.arrowRight,
              label: 'Tomorrow',
              detail: d(tomorrow),
              onTap: () => move(tomorrow, 'tomorrow'),
            ),
            _Option(
              icon: LucideIcons.calendar,
              label: 'Next week',
              detail: d(nextWeek),
              onTap: () => move(nextWeek, d(nextWeek)),
            ),
            _Option(
              icon: LucideIcons.calendarPlus,
              label: 'Pick a date',
              detail: '',
              onTap: pick,
            ),
            _Option(
              icon: LucideIcons.inbox,
              label: 'Someday',
              detail: 'No date',
              onTap: () => move(null, 'Someday'),
            ),
            const SizedBox(height: DfSpace.s1),
            Semantics(
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: drop,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.x, size: 16, color: c.danger),
                      const SizedBox(width: 6),
                      Text('Mark as won’t do',
                          style:
                              DfText.smallStrong.copyWith(color: c.danger)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// The sheet has closed by the time these show, so they take the messenger
// captured while it was open.
void _toast(
    ScaffoldMessengerState messenger, String message, VoidCallback onUndo) {
  final context = messenger.context;
  if (context.mounted) showUndo(context, message, onUndo);
}

void _plain(ScaffoldMessengerState messenger, String message) {
  final context = messenger.context;
  if (context.mounted) showMessage(context, message);
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.label,
    required this.detail,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final String detail;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    return Padding(
      padding: const EdgeInsets.only(bottom: DfSpace.s2),
      child: Material(
        color: highlighted ? c.primarySoft : c.surfaceMuted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DfRadius.lg),
          side: highlighted
              ? BorderSide(color: c.primary, width: 1.5)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon,
                    size: 20, color: highlighted ? c.primary : c.text),
                const SizedBox(width: DfSpace.s3),
                Expanded(
                  child: Text(label,
                      style: DfText.bodyStrong.copyWith(color: c.text)),
                ),
                Text(detail,
                    style: DfText.small.copyWith(color: c.textMuted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
