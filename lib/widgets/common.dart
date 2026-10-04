import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/app_state.dart';
import '../models/models.dart';
import '../theme/tokens.dart';

/// White rounded card used across the app.
class DfCard extends StatelessWidget {
  const DfCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(DfSpace.s4),
    this.color,
    this.borderColor,
    this.radius = DfRadius.lg,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: c.tagSoft(tag.color),
        borderRadius: BorderRadius.circular(DfRadius.full),
        border: Border.all(
          color: selected ? color : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(tag.name, style: DfText.smallStrong.copyWith(color: color)),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.flameSoft,
        borderRadius: BorderRadius.circular(DfRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.flame, size: 16, color: c.flame),
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

class DfCheckbox extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final c = context.df;
    return Semantics(
      checked: checked,
      label: checked ? 'Mark as not done' : 'Mark as done',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null ? null : () => onChanged!(!checked),
        // 44pt tap target around a 24pt circle.
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
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
                      : danger
                          ? c.danger
                          : (color ?? c.borderStrong),
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

    return DfCard(
      onTap: onTap,
      borderColor: overdue ? c.danger.withValues(alpha: 0.35) : null,
      padding: const EdgeInsets.fromLTRB(6, 10, 14, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DfCheckbox(
            checked: task.isDone,
            danger: overdue,
            onChanged: onToggle,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: DfText.bodyStrong.copyWith(
                      color: task.isDone ? c.textMuted : c.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
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
                            style: DfText.small.copyWith(
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
              padding: const EdgeInsets.only(top: 12, left: 8),
              child: Icon(LucideIcons.bell, size: 18, color: c.textMuted),
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
        borderRadius: BorderRadius.circular(DfRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
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
                const SizedBox(height: 2),
                Text(detail,
                    style: DfText.small.copyWith(color: c.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Icon(LucideIcons.calendar, size: 18, color: c.event),
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
                  borderRadius: BorderRadius.circular(9),
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
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    OutlineInputBorder border(Color color, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(DfRadius.lg),
          borderSide: BorderSide(color: color, width: w),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: DfText.smallStrong.copyWith(color: c.text)),
          const SizedBox(height: DfSpace.s2),
        ],
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          autocorrect: false,
          onSubmitted: onSubmitted,
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
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
  try {
    final nextId = await state.setDone(task, done);
    if (!context.mounted) return;
    if (done) {
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
