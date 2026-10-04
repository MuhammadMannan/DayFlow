import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/app_state.dart';
import '../models/models.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';

/// Icons a tag can use, keyed by the name stored with the tag.
const tagIcons = <String, IconData>{
  'tag': LucideIcons.tag,
  'briefcase': LucideIcons.briefcase,
  'graduationCap': LucideIcons.graduationCap,
  'user': LucideIcons.user,
  'heart': LucideIcons.heart,
  'dumbbell': LucideIcons.dumbbell,
  'house': LucideIcons.house,
  'shoppingCart': LucideIcons.shoppingCart,
  'book': LucideIcons.book,
  'plane': LucideIcons.plane,
  'music': LucideIcons.music,
  'code': LucideIcons.code,
  'wallet': LucideIcons.wallet,
  'users': LucideIcons.users,
  'star': LucideIcons.star,
  'leaf': LucideIcons.leaf,
};

IconData tagIcon(Tag tag) => tagIcons[tag.icon] ?? LucideIcons.tag;

/// Opens the editor to create a tag, or to change [tag]. Returns the id of
/// the tag that was created or saved, or null if cancelled or deleted.
Future<String?> showTagEditor(BuildContext context, {Tag? tag}) {
  final state = AppScope.read(context);
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    barrierColor: context.df.overlay.withValues(alpha: 0.45),
    builder: (_) => AppScope(state: state, child: _TagEditor(tag: tag)),
  );
}

class _TagEditor extends StatefulWidget {
  const _TagEditor({this.tag});
  final Tag? tag;

  @override
  State<_TagEditor> createState() => _TagEditorState();
}

class _TagEditorState extends State<_TagEditor> {
  late final _name = TextEditingController(text: widget.tag?.name ?? '');
  late int _color = widget.tag?.color ?? 4;
  late String _icon = widget.tag?.icon ?? 'tag';
  String? _error;
  bool _saving = false;

  bool get _editing => widget.tag != null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final state = AppScope.read(context);
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Give the tag a name.');
      return;
    }
    final clash = state.tags.any((t) =>
        t.id != widget.tag?.id && t.name.toLowerCase() == name.toLowerCase());
    if (clash) {
      setState(() => _error = 'You already have a tag with that name.');
      return;
    }
    setState(() => _saving = true);
    try {
      final String id;
      if (_editing) {
        id = widget.tag!.id;
        await state.updateTag(widget.tag!,
            name: name, color: _color, icon: _icon);
      } else {
        id = await state.addTag(name, _color, icon: _icon);
      }
      if (mounted) Navigator.pop(context, id);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save. Check your connection.';
        });
      }
    }
  }

  Future<void> _delete() async {
    final c = context.df;
    final state = AppScope.read(context);
    final tag = widget.tag!;
    final count = state.tasks.where((t) => t.tagId == tag.id).length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete “${tag.name}”?'),
        content: Text(count == 0
            ? 'No tasks use this tag.'
            : '$count ${count == 1 ? 'task keeps its' : 'tasks keep their'} details but will show no tag.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: c.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await state.deleteTag(tag);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not delete. Check your connection.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    final preview = Tag(
      id: '',
      name: _name.text.trim().isEmpty ? 'Tag name' : _name.text.trim(),
      color: _color,
      order: 0,
      icon: _icon,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
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
              Row(
                children: [
                  Expanded(
                    child: Text(_editing ? 'Edit tag' : 'New tag',
                        style: DfText.h3.copyWith(color: c.text)),
                  ),
                  TagChip(tag: preview),
                ],
              ),
              const SizedBox(height: DfSpace.s4),
              DfTextField(
                controller: _name,
                label: 'Name',
                hint: 'Side project',
                icon: tagIcons[_icon],
                error: _error,
                onChanged: (_) => setState(() => _error = null),
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: DfSpace.s4),
              Text('Colour', style: DfText.smallStrong.copyWith(color: c.text)),
              const SizedBox(height: DfSpace.s2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < c.tagColors.length; i++)
                    Semantics(
                      button: true,
                      selected: _color == i,
                      label: 'Colour ${i + 1}',
                      child: GestureDetector(
                        onTap: () => setState(() => _color = i),
                        child: Container(
                          width: 38,
                          height: 38,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  _color == i ? c.text : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                                color: c.tagColors[i],
                                shape: BoxShape.circle),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: DfSpace.s4),
              Text('Icon', style: DfText.smallStrong.copyWith(color: c.text)),
              const SizedBox(height: DfSpace.s2),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in tagIcons.entries)
                    Semantics(
                      button: true,
                      selected: _icon == entry.key,
                      label: '${entry.key} icon',
                      child: GestureDetector(
                        onTap: () => setState(() => _icon = entry.key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: _icon == entry.key
                                ? c.tagSoft(_color)
                                : c.surfaceMuted,
                            borderRadius: BorderRadius.circular(DfRadius.badge),
                            border: Border.all(
                              color: _icon == entry.key
                                  ? c.tag(_color)
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            entry.value,
                            size: 18,
                            color: _icon == entry.key
                                ? c.tag(_color)
                                : c.textSecondary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: DfSpace.s5),
              DfButton(
                label: _editing ? 'Save tag' : 'Create tag',
                loading: _saving,
                onPressed: _save,
              ),
              if (_editing) ...[
                const SizedBox(height: DfSpace.s1),
                DfButton(
                  label: 'Delete tag',
                  icon: LucideIcons.trash,
                  kind: DfButtonKind.dangerText,
                  onPressed: _delete,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class TagsScreen extends StatelessWidget {
  const TagsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    final state = AppScope.of(context);
    final monthStart = DateTime(DateTime.now().year, DateTime.now().month);
    final monthEnd = DateTime(monthStart.year, monthStart.month + 1);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              DfSpace.s5, DfSpace.s2, DfSpace.s5, DfSpace.s8),
          children: [
            Row(
              children: [
                DfIconButton(
                  icon: LucideIcons.chevronLeft,
                  semanticLabel: 'Back',
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text('Tags',
                      textAlign: TextAlign.center,
                      style: DfText.h3.copyWith(color: c.text)),
                ),
                SizedBox(
                  width: 40,
                  child: TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () => showTagEditor(context),
                    child: Text('Add',
                        style: DfText.bodyStrong.copyWith(color: c.primary)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DfSpace.s4),
            Text(
              'Each task gets one tag. Tags drive colours on the calendar and the breakdown in Analytics. Tap a tag to rename it or change its colour and icon.',
              style: DfText.small.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: DfSpace.s4),
            if (state.tags.isNotEmpty)
              DfCard(
                radius: DfRadius.card,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: [
                    for (var i = 0; i < state.tags.length; i++) ...[
                      if (i > 0) Divider(color: c.border),
                      Builder(builder: (context) {
                        final tag = state.tags[i];
                        final count = state.tasks
                            .where((t) =>
                                t.tagId == tag.id &&
                                // Due or finished this month.
                                ((t.due != null &&
                                        !t.due!.isBefore(monthStart) &&
                                        t.due!.isBefore(monthEnd)) ||
                                    (t.completedAt != null &&
                                        !t.completedAt!.isBefore(monthStart))))
                            .length;
                        return InkWell(
                          onTap: () => showTagEditor(context, tag: tag),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: c.tagSoft(tag.color),
                                    borderRadius:
                                        BorderRadius.circular(DfRadius.badge),
                                  ),
                                  child: Icon(tagIcon(tag),
                                      size: 18, color: c.tag(tag.color)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(tag.name,
                                          style: DfText.bodyStrong
                                              .copyWith(color: c.text)),
                                      Text(
                                          '$count ${count == 1 ? 'task' : 'tasks'} this month',
                                          style: DfText.small
                                              .copyWith(color: c.textMuted)),
                                    ],
                                  ),
                                ),
                                Icon(LucideIcons.chevronRight,
                                    size: 18, color: c.textMuted),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: DfSpace.s6),
                child: Text(
                  'No tags yet. Add one to start grouping your tasks.',
                  textAlign: TextAlign.center,
                  style: DfText.small.copyWith(color: c.textMuted),
                ),
              ),
            const SizedBox(height: DfSpace.s4),
            DfButton(
              label: 'New tag',
              icon: LucideIcons.plus,
              kind: DfButtonKind.secondary,
              onPressed: () => showTagEditor(context),
            ),
          ],
        ),
      ),
    );
  }
}
