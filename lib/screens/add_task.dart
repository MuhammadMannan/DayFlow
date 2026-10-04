import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/app_state.dart';
import '../data/quick_parse.dart';
import '../models/models.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import 'tags.dart';

/// Opens the add sheet. Pass [task] to edit, or [day] / [title] to prefill.
Future<void> showAddTask(
  BuildContext context, {
  Task? task,
  DateTime? day,
  TimeOfDay? time,
  String? title,
}) {
  final state = AppScope.read(context);
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    barrierColor: context.df.overlay.withValues(alpha: 0.45),
    builder: (_) => AppScope(
      state: state,
      child: AddTaskSheet(task: task, day: day, time: time, title: title),
    ),
  );
}

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key, this.task, this.day, this.time, this.title});

  final Task? task;
  final DateTime? day;
  final TimeOfDay? time;
  final String? title;

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  late final _HighlightController _title;
  late final TextEditingController _notes;
  late bool _expanded;
  DateTime? _date;
  TimeOfDay? _time;
  bool _remind = false;
  bool _remindTouched = false;
  int _remindMinutes = 0;
  Repeat _repeat = Repeat.none;
  String? _tagId;
  bool _saving = false;
  String? _error;

  // Set once the user picks a date or time by hand, so typing stops
  // overriding their choice.
  bool _dateTouched = false;
  bool _timeTouched = false;
  QuickParse _parsed = const QuickParse(title: '');

  bool get _editing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _title = _HighlightController(text: t?.title ?? widget.title ?? '');
    _notes = TextEditingController(text: t?.notes ?? '');
    _expanded = _editing;
    if (t != null) {
      _date = t.dueDay;
      _time = t.hasTime ? TimeOfDay.fromDateTime(t.due!) : null;
      _remind = t.remind;
      _remindMinutes = t.remindMinutes;
      _repeat = t.repeat;
      _tagId = t.tagId;
      _dateTouched = _timeTouched = true;
    } else {
      _date = dateOnly(widget.day ?? DateTime.now());
      _dateTouched = widget.day != null;
      if (widget.time != null) {
        _time = widget.time;
        _timeTouched = true;
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _onTitleChanged(String text) {
    if (_editing) {
      setState(() => _error = null);
      return;
    }
    final p = parseQuick(text);
    setState(() {
      _error = null;
      _parsed = p;
      if (!_dateTouched && p.date != null) _date = p.date;
      if (!_timeTouched) {
        _time = p.hasTime ? TimeOfDay(hour: p.hour!, minute: p.minute!) : null;
        // A typed time implies wanting a reminder, unless they chose otherwise.
        if (!_remindTouched) _remind = p.hasTime;
      }
      _title.ranges = p.ranges;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _dateTouched = true;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _time = picked;
        _timeTouched = true;
        _date ??= dateOnly(DateTime.now());
      });
    }
  }

  void _setDate(DateTime? d) => setState(() {
    _date = d;
    _dateTouched = true;
    if (d == null) {
      _time = null;
      _timeTouched = true;
      _repeat = Repeat.none;
    }
  });

  /// A reminder needs a time to fire at, so turning one on asks for it.
  Future<void> _setReminder(bool on, [int? minutes]) async {
    if (on && _time == null) {
      await _pickTime();
      if (_time == null) return;
    }
    setState(() {
      _remind = on;
      _remindTouched = true;
      if (minutes != null) _remindMinutes = minutes;
    });
  }

  Future<void> _pickRepeat() async {
    final c = context.df;
    final picked = await showModalBottomSheet<Repeat>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DfSpace.s5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Repeat', style: DfText.h3.copyWith(color: c.text)),
              const SizedBox(height: DfSpace.s2),
              for (final r in Repeat.values)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    repeatLabel(r, _date),
                    style: DfText.body.copyWith(color: c.text),
                  ),
                  trailing: r == _repeat
                      ? Icon(LucideIcons.check, color: c.primary, size: 20)
                      : null,
                  onTap: () => Navigator.pop(ctx, r),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) setState(() => _repeat = picked);
  }

  Future<void> _pickReminder() async {
    final c = context.df;
    // -1 stands for "Off".
    final current = _remind ? _remindMinutes : -1;
    final picked = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DfSpace.s5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reminder', style: DfText.h3.copyWith(color: c.text)),
              const SizedBox(height: DfSpace.s2),
              for (final m in [-1, ...reminderLeads])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    reminderLabel(m >= 0, m),
                    style: DfText.body.copyWith(color: c.text),
                  ),
                  trailing: m == current
                      ? Icon(LucideIcons.check, color: c.primary, size: 20)
                      : null,
                  onTap: () => Navigator.pop(ctx, m),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null) return;
    await _setReminder(picked >= 0, picked >= 0 ? picked : null);
  }

  Future<void> _pickTag() async {
    final state = AppScope.read(context);
    final c = context.df;
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DfSpace.s5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tag', style: DfText.h3.copyWith(color: c.text)),
              const SizedBox(height: DfSpace.s4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in state.tags)
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx, tag.id),
                      child: TagChip(tag: tag, selected: tag.id == _tagId),
                    ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx, ''),
                    child: _Pill(label: 'No tag', selected: _tagId == null),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) {
      setState(() => _tagId = picked.isEmpty ? null : picked);
    }
  }

  Future<void> _save() async {
    final rawTitle = _title.text.trim();
    final title = _editing || _parsed.title.isEmpty ? rawTitle : _parsed.title;
    if (title.isEmpty) {
      setState(() => _error = 'Give the task a name first.');
      return;
    }
    setState(() => _saving = true);
    final state = AppScope.read(context);
    DateTime? due;
    if (_date != null) {
      due = DateTime(
        _date!.year,
        _date!.month,
        _date!.day,
        _time?.hour ?? 0,
        _time?.minute ?? 0,
      );
    }
    try {
      if (_editing) {
        await state.updateTask(
          widget.task!.copyWith(
            title: title,
            notes: _notes.text.trim(),
            tagId: () => _tagId,
            due: () => due,
            hasTime: _time != null,
            repeat: _repeat,
            remind: _remind && _time != null,
            remindMinutes: _remindMinutes,
          ),
        );
      } else {
        await state.addTask(
          title: title,
          notes: _notes.text,
          tagId: _tagId,
          due: due,
          hasTime: _time != null,
          repeat: _repeat,
          remind: _remind && _time != null,
          remindMinutes: _remindMinutes,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save. Check your connection and try again.';
        });
      }
    }
  }

  String get _dateLabel => _date == null ? 'No date' : relativeDay(_date!);

  String get _timeLabel => _time == null ? 'Time' : _time!.format(context);

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    final media = MediaQuery.of(context);
    final bottom = media.viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            DfSpace.s5,
            DfSpace.s3,
            DfSpace.s5,
            DfSpace.s4,
          ),
          child: ConstrainedBox(
            // The full form rises to just below the status bar.
            constraints: BoxConstraints(
              minHeight: _expanded && bottom == 0
                  ? media.size.height - media.padding.vertical - 70 - 28
                  : 0,
            ),
            child: IntrinsicHeight(
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
                  const SizedBox(height: DfSpace.s3),
                  if (_expanded) ..._full(c) else ..._quick(c),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _quick(DfColors c) {
    final state = AppScope.of(context);
    Tag? tag;
    for (final t in state.tags) {
      if (t.id == _tagId) tag = t;
    }
    return [
      Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: c.borderStrong, width: 2),
            ),
          ),
          const SizedBox(width: DfSpace.s3),
          Expanded(
            child: TextField(
              controller: _title,
              autofocus: true,
              onChanged: _onTitleChanged,
              onSubmitted: (_) => _save(),
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.sentences,
              style: DfText.h3.copyWith(color: c.text),
              cursorColor: c.primary,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Add a task… e.g. “Call mom tomorrow 6pm”',
                hintStyle: DfText.body.copyWith(color: c.textMuted),
              ),
            ),
          ),
        ],
      ),
      if (_parsed.matched.isNotEmpty) ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: c.primarySoft,
            borderRadius: BorderRadius.circular(DfRadius.badge),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.sparkle, size: 14, color: c.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'We picked up “${_parsed.matched}”',
                  style: DfText.small.copyWith(color: c.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DfSpace.s3),
      ],
      if (_error != null) ...[
        Text(_error!, style: DfText.small.copyWith(color: c.danger)),
        const SizedBox(height: DfSpace.s2),
      ],
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _QuickChip(
              icon: LucideIcons.calendar,
              label: _dateLabel,
              active: _date != null,
              onTap: _pickDate,
            ),
            const SizedBox(width: 8),
            _QuickChip(
              icon: LucideIcons.clock,
              label: _timeLabel,
              active: _time != null,
              onTap: _pickTime,
            ),
            const SizedBox(width: 8),
            _QuickChip(
              icon: LucideIcons.bell,
              label: 'Remind',
              active: _remind && _time != null,
              onTap: () => _setReminder(!_remind),
            ),
            const SizedBox(width: 8),
            _QuickChip(
              icon: LucideIcons.tag,
              label: tag?.name ?? 'Tag',
              active: tag != null,
              onTap: _pickTag,
            ),
          ],
        ),
      ),
      const SizedBox(height: DfSpace.s3),
      Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() {
                _expanded = true;
                _title.ranges = const [];
                if (_parsed.title.isNotEmpty) _title.text = _parsed.title;
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Icon(LucideIcons.repeat, size: 18, color: c.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'Repeat, notes and more',
                      style: DfText.small.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: 'Add task',
            child: Material(
              color: c.primary,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _saving ? null : _save,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: _saving
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          LucideIcons.arrowRight,
                          size: 20,
                          color: Colors.white,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _full(DfColors c) {
    final state = AppScope.of(context);
    final today = dateOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    var weekend = today;
    while (weekend.weekday != DateTime.saturday) {
      weekend = weekend.add(const Duration(days: 1));
    }
    final isCustom =
        _date != null &&
        _date != today &&
        _date != tomorrow &&
        _date != weekend;

    return [
      Row(
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: DfText.body.copyWith(color: c.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              _editing ? 'Edit task' : 'New task',
              textAlign: TextAlign.center,
              style: DfText.bodyStrong.copyWith(color: c.text),
            ),
          ),
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(
              'Save',
              style: DfText.bodyStrong.copyWith(color: c.primary),
            ),
          ),
        ],
      ),
      const SizedBox(height: DfSpace.s2),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: c.surfaceMuted,
          borderRadius: BorderRadius.circular(DfRadius.card),
        ),
        child: Column(
          children: [
            TextField(
              controller: _title,
              onChanged: (_) => setState(() => _error = null),
              textCapitalization: TextCapitalization.sentences,
              style: DfText.h2.copyWith(color: c.text),
              cursorColor: c.primary,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Task name',
                hintStyle: DfText.h2.copyWith(color: c.textMuted),
              ),
            ),
            TextField(
              controller: _notes,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              style: DfText.body.copyWith(color: c.textSecondary),
              cursorColor: c.primary,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Add notes',
                hintStyle: DfText.body.copyWith(color: c.textMuted),
              ),
            ),
          ],
        ),
      ),
      if (_error != null) ...[
        const SizedBox(height: DfSpace.s2),
        Text(_error!, style: DfText.small.copyWith(color: c.danger)),
      ],
      const SizedBox(height: DfSpace.s5),
      const Overline('When'),
      const SizedBox(height: DfSpace.s3),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _Pill(
              label: 'Today',
              selected: _date == today,
              onTap: () => _setDate(today),
            ),
            const SizedBox(width: 8),
            _Pill(
              label: 'Tomorrow',
              selected: _date == tomorrow,
              onTap: () => _setDate(tomorrow),
            ),
            const SizedBox(width: 8),
            _Pill(
              label: 'Weekend',
              selected: _date == weekend && _date != today && _date != tomorrow,
              onTap: () => _setDate(weekend),
            ),
            const SizedBox(width: 8),
            _Pill(label: 'Pick date', selected: isCustom, onTap: _pickDate),
            const SizedBox(width: 8),
            _Pill(
              label: 'No date',
              selected: _date == null,
              onTap: () => _setDate(null),
            ),
          ],
        ),
      ),
      const SizedBox(height: DfSpace.s4),
      Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(DfRadius.card),
          border: Border.all(color: c.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(
          children: [
            _FormRow(
              icon: LucideIcons.calendar,
              label: 'Date',
              value: _date == null
                  ? 'None'
                  : DateFormat('EEEE, d MMMM').format(_date!),
              onTap: _pickDate,
            ),
            Divider(color: c.border),
            _FormRow(
              icon: LucideIcons.clock,
              label: 'Time',
              value: _time == null ? 'Anytime' : _time!.format(context),
              onTap: _pickTime,
              onClear: _time == null
                  ? null
                  : () => setState(() {
                      _time = null;
                      _timeTouched = true;
                    }),
            ),
            Divider(color: c.border),
            _FormRow(
              icon: LucideIcons.bell,
              label: 'Reminder',
              value: reminderLabel(_remind && _time != null, _remindMinutes),
              onTap: _pickReminder,
            ),
            Divider(color: c.border),
            _FormRow(
              icon: LucideIcons.repeat,
              label: 'Repeat',
              value: repeatLabel(_repeat, _date),
              onTap: _date == null ? null : _pickRepeat,
            ),
          ],
        ),
      ),
      const SizedBox(height: DfSpace.s5),
      const Overline('Tag'),
      const SizedBox(height: DfSpace.s3),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final tag in state.tags)
            GestureDetector(
              onTap: () =>
                  setState(() => _tagId = _tagId == tag.id ? null : tag.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: TagChip(tag: tag, selected: tag.id == _tagId),
              ),
            ),
          GestureDetector(
            onTap: () async {
              final id = await showTagEditor(context);
              if (id != null && mounted) setState(() => _tagId = id);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(DfRadius.full),
                border: Border.all(color: c.border, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.plus, size: 13, color: c.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'New',
                    style: DfText.smallStrong.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      const Spacer(),
      const SizedBox(height: DfSpace.s6),
      DfButton(
        label: _editing ? 'Save changes' : 'Create task',
        loading: _saving,
        onPressed: _save,
      ),
    ];
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    final fg = active ? c.primaryStrong : c.textSecondary;
    return Material(
      color: active ? c.primarySoft : c.surfaceMuted,
      borderRadius: BorderRadius.circular(DfRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(label, style: DfText.smallStrong.copyWith(color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.selected, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.text : c.surface,
          borderRadius: BorderRadius.circular(DfRadius.full),
          border: Border.all(color: selected ? c.text : c.border),
        ),
        child: Text(
          label,
          style: DfText.smallStrong.copyWith(
            color: selected ? c.surface : c.text,
          ),
        ),
      ),
    );
  }
}

/// Outlined pill used for "move it" shortcuts elsewhere.
class DfPill extends StatelessWidget {
  const DfPill({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) =>
      _Pill(label: label, selected: selected, onTap: onTap);
}

class _FormRow extends StatelessWidget {
  const _FormRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.onClear,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    return InkWell(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.45 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: c.surfaceMuted,
                  borderRadius: BorderRadius.circular(DfRadius.badge),
                ),
                child: Icon(icon, size: 18, color: c.textSecondary),
              ),
              const SizedBox(width: 12),
              Text(label, style: DfText.body.copyWith(color: c.textSecondary)),
              const Spacer(),
              Text(value, style: DfText.bodyStrong.copyWith(color: c.text)),
              const SizedBox(width: 6),
              if (onClear != null)
                GestureDetector(
                  onTap: onClear,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(LucideIcons.x, size: 16, color: c.textMuted),
                  ),
                )
              else
                Icon(LucideIcons.chevronRight, size: 18, color: c.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Text controller that paints recognised date and time phrases in blue.
class _HighlightController extends TextEditingController {
  _HighlightController({super.text});

  List<(int, int)> _ranges = const [];

  set ranges(List<(int, int)> value) {
    _ranges = value;
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final value = text;
    final valid =
        _ranges
            .where((r) => r.$1 >= 0 && r.$2 <= value.length && r.$1 < r.$2)
            .toList()
          ..sort((a, b) => a.$1.compareTo(b.$1));
    if (valid.isEmpty) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }
    final highlight = style?.copyWith(color: context.df.primary);
    final spans = <TextSpan>[];
    var at = 0;
    for (final (start, end) in valid) {
      if (start < at) continue;
      if (start > at) spans.add(TextSpan(text: value.substring(at, start)));
      spans.add(TextSpan(text: value.substring(start, end), style: highlight));
      at = end;
    }
    if (at < value.length) spans.add(TextSpan(text: value.substring(at)));
    return TextSpan(style: style, children: spans);
  }
}
