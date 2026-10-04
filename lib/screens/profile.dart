import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/app_state.dart';
import '../data/device_calendar.dart';
import '../data/notifications.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import 'calendars.dart';
import 'tags.dart';

void openProfile(BuildContext context) {
  final state = AppScope.read(context);
  Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => AppScope(state: state, child: const ProfileScreen()),
  ));
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<T?> _choose<T>(
    BuildContext context, {
    required String title,
    String? description,
    required List<(T, String)> options,
    required T current,
  }) {
    final c = context.df;
    return showModalBottomSheet<T>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DfSpace.s5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: DfText.h3.copyWith(color: c.text)),
              if (description != null) ...[
                const SizedBox(height: 4),
                Text(description,
                    style: DfText.small.copyWith(color: c.textSecondary)),
              ],
              const SizedBox(height: DfSpace.s3),
              for (final (value, label) in options)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(label, style: DfText.body.copyWith(color: c.text)),
                  trailing: value == current
                      ? Icon(LucideIcons.check, color: c.primary, size: 20)
                      : null,
                  onTap: () => Navigator.pop(ctx, value),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Turning a notification switch on asks iOS for permission if needed.
  Future<void> _setNotify(
      BuildContext context, AppState state, String key, bool on) async {
    if (on && !await Notifications.allowed()) {
      final granted = await Notifications.requestPermission();
      if (!granted && context.mounted) {
        showMessage(context,
            'Notifications are off for DayFlow. Turn them on in Settings › Notifications.');
      }
    }
    if (context.mounted) await _save(context, state, {key: on});
  }

  static String _hourLabel(int h) =>
      '${h % 12 == 0 ? 12 : h % 12}:00 ${h < 12 ? 'AM' : 'PM'}';

  Future<void> _save(
      BuildContext context, AppState state, Map<String, dynamic> patch) async {
    try {
      await state.updateSettings(patch);
    } catch (_) {
      if (context.mounted) {
        showMessage(context, 'Could not save. Check your connection.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    final state = AppScope.of(context);
    final s = state.settings;
    final streak = state.streak;

    final calendarValue = switch (state.calendarAccess) {
      CalendarAccess.granted => !s.showCalendar
          ? 'Hidden'
          : state.calendars.isEmpty
              ? 'Connected'
              : '${state.shownCalendarCount} of ${state.calendars.length} shown',
      CalendarAccess.denied => 'Access off',
      CalendarAccess.notDetermined => 'Not connected',
    };

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              DfSpace.s5, DfSpace.s2, DfSpace.s5, DfSpace.s8),
          children: [
            Row(
              children: [
                DfIconButton(
                  icon: LucideIcons.x,
                  semanticLabel: 'Close',
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text('Profile',
                      textAlign: TextAlign.center,
                      style: DfText.h3.copyWith(color: c.text)),
                ),
                const SizedBox(width: 40),
              ],
            ),
            const SizedBox(height: DfSpace.s4),
            DfCard(
              radius: DfRadius.xl,
              padding: const EdgeInsets.all(DfSpace.s5),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: c.primarySoft, shape: BoxShape.circle),
                    child: Text(state.firstName[0].toUpperCase(),
                        style: DfText.h1.copyWith(color: c.primary)),
                  ),
                  const SizedBox(height: DfSpace.s3),
                  Text(state.displayName,
                      style: DfText.h3.copyWith(color: c.text)),
                  Text(state.user.email ?? '',
                      style: DfText.small.copyWith(color: c.textMuted)),
                  const SizedBox(height: DfSpace.s3),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      StreakChip(
                          days: streak.current,
                          label: '${streak.current}-day streak'),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: c.primarySoft,
                          borderRadius: BorderRadius.circular(DfRadius.full),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.trophy,
                                size: 16, color: c.primary),
                            const SizedBox(width: 6),
                            Text('Best ${streak.best}',
                                style: DfText.smallStrong
                                    .copyWith(color: c.primary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const _Group('Goals'),
            DfCard(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                children: [
                  _SettingRow(
                    icon: LucideIcons.target,
                    tint: c.primary,
                    bg: c.primarySoft,
                    label: 'Daily goal',
                    value: s.dailyGoal == 0
                        ? 'Off'
                        : '${s.dailyGoal} ${s.dailyGoal == 1 ? 'task' : 'tasks'}',
                    onTap: () async {
                      final v = await _choose<int>(
                        context,
                        title: 'Daily goal',
                        description:
                            'Any completed task keeps your streak. A goal is an extra target shown on Home.',
                        options: const [
                          (0, 'Off'),
                          (1, '1 task a day'),
                          (3, '3 tasks a day'),
                          (5, '5 tasks a day'),
                        ],
                        current: s.dailyGoal,
                      );
                      if (v != null && context.mounted) {
                        await _save(context, state, {'dailyGoal': v});
                      }
                    },
                  ),
                  Divider(color: c.border),
                  _SettingRow(
                    icon: LucideIcons.snowflake,
                    tint: c.primary,
                    bg: c.primarySoft,
                    label: 'Streak freezes',
                    value: '1 per week',
                    onTap: () => showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Streak freezes'),
                        content: const Text(
                            'Each week, one missed day is covered automatically so a single off day does not reset your streak. Frozen days keep the streak alive but do not add to it.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('OK')),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const _Group('Organise'),
            DfCard(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                children: [
                  _SettingRow(
                    icon: LucideIcons.tag,
                    tint: c.tag(1),
                    bg: c.tagSoft(1),
                    label: 'Tags',
                    value: '${state.tags.length}',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AppScope(state: state, child: const TagsScreen()),
                      ),
                    ),
                  ),
                  Divider(color: c.border),
                  _SettingRow(
                    icon: LucideIcons.calendar,
                    tint: c.event,
                    bg: c.eventSoft,
                    label: 'Calendar',
                    value: calendarValue,
                    onTap: () async {
                      switch (state.calendarAccess) {
                        case CalendarAccess.notDetermined:
                          await state.connectCalendar();
                        case CalendarAccess.denied:
                          showMessage(context,
                              'Turn on calendar access in Settings › DayFlow › Calendars.');
                        case CalendarAccess.granted:
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              fullscreenDialog: true,
                              builder: (_) => AppScope(
                                  state: state,
                                  child: const CalendarsScreen()),
                            ),
                          );
                      }
                    },
                  ),
                ],
              ),
            ),
            const _Group('Notifications'),
            DfCard(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                children: [
                  _SettingRow(
                    icon: LucideIcons.bell,
                    tint: c.flame,
                    bg: c.flameSoft,
                    label: 'Task reminders',
                    trailing: Switch(
                      value: s.remindersOn,
                      onChanged: (v) =>
                          _setNotify(context, state, 'remindersOn', v),
                    ),
                  ),
                  Divider(color: c.border),
                  _SettingRow(
                    icon: LucideIcons.flame,
                    tint: c.flame,
                    bg: c.flameSoft,
                    label: 'Streak-at-risk nudge',
                    trailing: Switch(
                      value: s.nudgeOn,
                      onChanged: (v) =>
                          _setNotify(context, state, 'nudgeOn', v),
                    ),
                  ),
                  if (s.nudgeOn) ...[
                    Divider(color: c.border),
                    _SettingRow(
                      icon: LucideIcons.clock,
                      tint: c.flame,
                      bg: c.flameSoft,
                      label: 'Nudge time',
                      value: _hourLabel(s.nudgeHour),
                      onTap: () async {
                        final v = await _choose<int>(
                          context,
                          title: 'Nudge time',
                          description:
                              'Sent only on days when you have not finished a task yet.',
                          options: [
                            for (final h in const [17, 18, 19, 20, 21, 22])
                              (h, _hourLabel(h)),
                          ],
                          current: s.nudgeHour,
                        );
                        if (v != null && context.mounted) {
                          await _save(context, state, {'nudgeHour': v});
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
            const _Group('Appearance'),
            DfCard(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: _SettingRow(
                icon: LucideIcons.moon,
                tint: c.textSecondary,
                bg: c.surfaceMuted,
                label: 'Theme',
                value: s.theme[0].toUpperCase() + s.theme.substring(1),
                onTap: () async {
                  final v = await _choose<String>(
                    context,
                    title: 'Theme',
                    options: const [
                      ('system', 'System'),
                      ('light', 'Light'),
                      ('dark', 'Dark'),
                    ],
                    current: s.theme,
                  );
                  if (v != null && context.mounted) {
                    await _save(context, state, {'theme': v});
                  }
                },
              ),
            ),
            const SizedBox(height: DfSpace.s4),
            DfCard(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: _SettingRow(
                icon: LucideIcons.logOut,
                tint: c.danger,
                bg: c.dangerSoft,
                label: 'Sign out',
                labelColor: c.danger,
                showChevron: false,
                onTap: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Sign out?'),
                      content: const Text(
                          'Your tasks and streak stay saved to your account.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel')),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text('Sign out',
                              style: TextStyle(color: c.danger)),
                        ),
                      ],
                    ),
                  );
                  if (ok == true && context.mounted) {
                    Navigator.of(context).popUntil((r) => r.isFirst);
                    await FirebaseAuth.instance.signOut();
                  }
                },
              ),
            ),
            const SizedBox(height: DfSpace.s4),
            Center(
              child: Text('DayFlow 2.0',
                  style: DfText.caption.copyWith(color: c.textMuted)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: DfSpace.s5, bottom: DfSpace.s2),
        child: Overline(title),
      );
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.tint,
    required this.bg,
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
    this.labelColor,
    this.showChevron = true,
  });

  final IconData icon;
  final Color tint;
  final Color bg;
  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? labelColor;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 58),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(DfRadius.sm)),
              child: Icon(icon, size: 18, color: tint),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: DfText.body.copyWith(color: labelColor ?? c.text)),
            ),
            if (value != null)
              Text(value!, style: DfText.small.copyWith(color: c.textMuted)),
            if (trailing != null)
              trailing!
            else if (showChevron) ...[
              const SizedBox(width: 8),
              Icon(LucideIcons.chevronRight, size: 18, color: c.textMuted),
            ],
          ],
        ),
      ),
    );
  }
}
