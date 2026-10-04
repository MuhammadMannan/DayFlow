import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/app_state.dart';
import '../data/streak.dart';
import '../models/models.dart';
import '../screens/milestone.dart';
import '../theme/tokens.dart';

/// White rounded card used across the app.
class DfCard extends StatelessWidget {
  const DfCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(DfSpace.s4),
    this.color,
    this.borderColor,
    this.radius = DfRadius.card,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: borderColor == null
          ? BorderSide.none
          : BorderSide(color: borderColor!),
    );
    return Material(
      color: color ?? c.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

enum DfButtonKind { primary, secondary, success, dark, dangerText }

class DfButton extends StatelessWidget {
  const DfButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = DfButtonKind.primary,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final DfButtonKind kind;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    final (bg, fg, border) = switch (kind) {
      DfButtonKind.primary => (c.primary, c.onPrimary, null),
      DfButtonKind.secondary => (c.surface, c.text, c.border),
      DfButtonKind.success => (c.success, Colors.white, null),
      DfButtonKind.dark => (c.text, c.surface, null),
      DfButtonKind.dangerText => (Colors.transparent, c.danger, null),
    };
    final enabled = onPressed != null && !loading;
    return Opacity(
      opacity: enabled || loading ? 1 : 0.5,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DfRadius.lg),
          side: border == null ? BorderSide.none : BorderSide(color: border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          child: SizedBox(
            height: 54,
            child: Center(
              child: loading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: fg),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 18, color: fg),
                          const SizedBox(width: DfSpace.s2),
                        ],
                        Text(label,
                            style: DfText.bodyStrong.copyWith(color: fg)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 40pt square icon button with a border, used in headers.
class DfIconButton extends StatelessWidget {
  const DfIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DfRadius.md),
          side: BorderSide(color: c.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 20, color: c.text),
          ),
        ),
      ),
    );
  }
}

class TagChip extends StatelessWidget {
  const TagChip({super.key, required this.tag, this.selected = false});

  final Tag tag;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    final color = c.tag(tag.color);
    return Container(
      height: 24,
      padding: const EdgeInsets.only(left: 8, right: 10),
      decoration: BoxDecoration(
        color: c.tagSoft(tag.color),
        borderRadius: BorderRadius.circular(DfRadius.full),
        border: Border.all(
          color: selected ? color : Colors.transparent,
          width: 1.5,
          // Drawn outside so a selected chip keeps its 24pt height.
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            tag.name,
            style: DfText.caption
                .copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class StreakChip extends StatelessWidget {
  const StreakChip({super.key, required this.days, this.label});

  final int days;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    return Container(
      height: 30,
      padding: const EdgeInsets.only(left: 10, right: 12),
      decoration: BoxDecoration(
        color: c.flameSoft,
        borderRadius: BorderRadius.circular(DfRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.flame, size: 18, color: c.flame),
          const SizedBox(width: 6),
          Text(label ?? '$days',
              style: DfText.smallStrong.copyWith(color: c.flame)),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
    this.color,
    this.trailing,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final Color? color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    return Row(
      children: [
        Expanded(
          child: Text(title, style: DfText.h3.copyWith(color: color ?? c.text)),
        ),
        if (trailing != null) trailing!,
        if (action != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(action!,
                  style: DfText.smallStrong.copyWith(color: c.primary)),
            ),
          ),
      ],
    );
  }
}

class Overline extends StatelessWidget {
  const Overline(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: DfText.overline.copyWith(color: context.df.textMuted),
      );
}

class DfCheckbox extends StatefulWidget {
  const DfCheckbox({
    super.key,
    required this.checked,
    required this.onChanged,
    this.danger = false,
    this.color,
  });

  final bool checked;
  final ValueChanged<bool>? onChanged;
  final bool danger;
  final Color? color;

  @override
  State<DfCheckbox> createState() => _DfCheckboxState();
}

class _DfCheckboxState extends State<DfCheckbox>
    with SingleTickerProviderStateMixin {
  // Plays once when the box becomes checked: the circle pops and a ring
  // expands and fades around it.
  late final _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    value: 1,
  );

  @override
  void didUpdateWidget(DfCheckbox old) {
    super.didUpdateWidget(old);
    if (widget.checked && !old.checked) {
      if (MediaQuery.of(context).disableAnimations) {
        _burst.value = 1;
      } else {
        _burst.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  void _tap() {
    final next = !widget.checked;
    if (next) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.selectionClick();
    }
    widget.onChanged!(next);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    final checked = widget.checked;
    return Semantics(
      checked: checked,
      label: checked ? 'Mark as not done' : 'Mark as done',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onChanged == null ? null : _tap,
        // 44pt tap target around a 24pt circle.
        child: SizedBox(
          width: 44,
          height: 44,
          child: AnimatedBuilder(
            animation: _burst,
            builder: (context, child) {
              final t = _burst.value;
              final scale = t >= 1
                  ? 1.0
                  : 1 + 0.28 * Curves.easeOutBack.transform(t) * (1 - t) * 2.2;
              return Stack(
                alignment: Alignment.center,
                children: [
                  if (t < 1)
                    Opacity(
                      opacity: (1 - t) * 0.5,
                      child: Container(
                        width: 24 + 20 * Curves.easeOut.transform(t),
                        height: 24 + 20 * Curves.easeOut.transform(t),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: c.success, width: 2),
                        ),
                      ),
                    ),
                  Transform.scale(scale: scale, child: child),
                ],
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: checked ? c.success : Colors.transparent,
                border: Border.all(
                  color: checked
                      ? c.success
                      : widget.danger
                          ? c.danger
                          : (widget.color ?? c.borderStrong),
                  width: 2,
                ),
              ),
              child: checked
                  ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

String formatTime(DateTime d) => DateFormat('h:mm a').format(d);

String relativeDay(DateTime day, {DateTime? now}) {
  final today = dateOnly(now ?? DateTime.now());
  final diff = dateOnly(day).difference(today).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  if (diff == -1) return 'Yesterday';
  if (diff > 1 && diff < 7) return DateFormat('EEEE').format(day);
  return DateFormat('EEE, d MMM').format(day);
}

class TaskRow extends StatelessWidget {
  const TaskRow({
    super.key,
    required this.task,
    required this.onToggle,
    this.onTap,
    this.showDate = false,
  });

  final Task task;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onTap;

  /// Show the day as well as the time (used outside day-grouped lists).
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    final state = AppScope.of(context);
    final tag = state.tagFor(task);
    final overdue = task.isOverdue(DateTime.now());

    final String when;
    if (task.due == null) {
      when = 'No date';
    } else if (overdue) {
      when = relativeDay(task.due!);
    } else {
      final time = task.hasTime ? formatTime(task.due!) : 'Anytime';
      when = showDate ? '${relativeDay(task.due!)} · $time' : time;
    }
    final repeat =
        task.repeat == Repeat.none ? '' : ' · repeats ${task.repeat.label.toLowerCase()}';

    // Figma: 72 high, radius 18, padding 14/16, 14 between checkbox and text.
    // The checkbox keeps a 44pt tap target, so its own 10pt inset is taken
    // off the surrounding padding.
    return DfCard(
      onTap: onTap,
      radius: DfRadius.row,
      borderColor: overdue ? c.dangerSoft : null,
      padding: const EdgeInsets.fromLTRB(6, 4, 16, 4),
      child: Row(
        children: [
          DfCheckbox(
            checked: task.isDone,
            danger: overdue,
            onChanged: onToggle,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
                    style: DfText.bodyStrong.copyWith(
                      color: task.isDone ? c.textMuted : c.text,
                    ),
                    child: Text(task.title),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            overdue ? LucideIcons.circleAlert : LucideIcons.clock,
                            size: 14,
                            color: overdue ? c.danger : c.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$when$repeat',
                            style: DfText.caption.copyWith(
                              color: overdue ? c.danger : c.textMuted,
                            ),
                          ),
                        ],
                      ),
                      if (tag != null) TagChip(tag: tag),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (task.remind && task.hasTime)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(LucideIcons.bell, size: 16, color: c.textMuted),
            ),
        ],
      ),
    );
  }
}

class EventRow extends StatelessWidget {
  const EventRow({super.key, required this.event});

  final CalEvent event;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    final time = event.allDay
        ? 'All day'
        : '${formatTime(event.start)} – ${formatTime(event.end)}';
    final detail =
        event.location.isEmpty ? time : '$time · ${event.location}';
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
      decoration: BoxDecoration(
        color: c.eventSoft,
        borderRadius: BorderRadius.circular(DfRadius.row),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: c.event,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title.isEmpty ? 'Busy' : event.title,
                    style: DfText.bodyStrong.copyWith(color: c.text),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(detail,
                    style: DfText.caption.copyWith(color: c.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Icon(LucideIcons.calendar, size: 16, color: c.event),
        ],
      ),
    );
  }
}

/// Two-option pill switch, e.g. Month / Week.
class DfSegmented<T> extends StatelessWidget {
  const DfSegmented({
    super.key,
    required this.values,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<T> values;
  final List<String> labels;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(DfRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < values.length; i++)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(values[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: values[i] == selected ? c.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: values[i] == selected ? DfShadow.card : null,
                ),
                child: Text(
                  labels[i],
                  style: DfText.smallStrong.copyWith(
                    color: values[i] == selected ? c.text : c.textMuted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class DfTextField extends StatelessWidget {
  const DfTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.icon,
    this.obscure = false,
    this.error,
    this.keyboardType,
    this.suffix,
    this.autofillHints,
    this.onSubmitted,
    this.onChanged,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final IconData? icon;
  final bool obscure;
  final String? error;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    OutlineInputBorder border(Color color, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(DfRadius.field),
          borderSide: BorderSide(color: color, width: w),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!,
              style: DfText.smallStrong.copyWith(color: c.textSecondary)),
          const SizedBox(height: DfSpace.s2),
        ],
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          autocorrect: false,
          onSubmitted: onSubmitted,
          onChanged: onChanged,
          textInputAction: textInputAction,
          style: DfText.body.copyWith(color: c.text),
          cursorColor: c.primary,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: DfText.body.copyWith(color: c.textMuted),
            filled: true,
            fillColor: c.surface,
            prefixIcon: icon == null
                ? null
                : Icon(icon, size: 20, color: c.textSecondary),
            suffixIcon: suffix,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            enabledBorder: border(error != null ? c.danger : c.border,
                error != null ? 1.5 : 1),
            focusedBorder:
                border(error != null ? c.danger : c.primary, 1.5),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: DfSpace.s2),
          Row(
            children: [
              Icon(LucideIcons.circleAlert, size: 14, color: c.danger),
              const SizedBox(width: 6),
              Expanded(
                child: Text(error!,
                    style: DfText.small.copyWith(color: c.danger)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Shows a message with an optional Undo action.
void showUndo(BuildContext context, String message, VoidCallback onUndo) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    content: Text(message),
    duration: const Duration(seconds: 4),
    // Snack bars with an action stay up by default; this one should time out.
    persist: false,
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
    action: SnackBarAction(label: 'Undo', onPressed: onUndo),
  ));
}

void showMessage(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    content: Text(message),
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
  ));
}

/// Toggles a task and offers Undo. Shared by every list.
Future<void> toggleTask(BuildContext context, Task task, bool done) async {
  final state = AppScope.read(context);
  final before = state.streak.current;
  try {
    final nextId = await state.setDone(task, done);
    if (!context.mounted) return;
    if (done) {
      // Work the streak out from this completion directly, since the
      // Firestore snapshot may not have come back yet.
      final now = DateTime.now();
      final tasks = [
        for (final t in state.tasks)
          if (t.id != task.id) t,
        task.copyWith(completedAt: () => now),
      ];
      final milestone =
          milestoneReached(before, computeStreak(tasks, now).current);
      if (milestone != null) {
        await showMilestone(context,
            days: milestone, completions: completionsByDay(tasks));
        if (!context.mounted) return;
      }
      showUndo(context, 'Completed “${task.title}”', () async {
        await state.updateTask(task);
        if (nextId != null) await state.deleteTaskById(nextId);
      });
    }
  } catch (_) {
    if (context.mounted) {
      showMessage(context, 'Could not save. Check your connection.');
    }
  }
}

/// One day in a week strip. Figma: 46 by 66, radius 16.
class DayPill extends StatelessWidget {
  const DayPill({
    super.key,
    required this.day,
    required this.selected,
    required this.isToday,
    required this.hasItems,
    this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool isToday;
  final bool hasItems;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    // Today is outlined when another day is the selected one.
    final outlined = isToday && !selected;
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: DateFormat('EEEE d MMMM').format(day),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Container(
            width: 46,
            height: 66,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? c.primary
                  : outlined
                      ? c.surface
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: outlined
                  ? Border.all(color: c.primary, width: 1.5)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('EEE').format(day),
                  style: DfText.caption.copyWith(
                    fontSize: 11,
                    height: 16 / 11,
                    color: selected ? Colors.white : c.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${day.day}',
                  style: DfText.h3.copyWith(
                    height: 20 / 17,
                    color: selected ? Colors.white : c.text,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: !hasItems
                        ? Colors.transparent
                        : selected
                            ? Colors.white
                            : c.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
